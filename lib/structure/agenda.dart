import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';

class AgendaCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;

  const AgendaCalendar({super.key, required this.portfolio});

  @override
  AgendaCalendarState createState() => AgendaCalendarState();
}

class AgendaCalendarState extends State<AgendaCalendar> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    _events = _extractTransactions(widget.portfolio);
    _addRentEvents(_events, dataManager.rentData);
  }

  Map<DateTime, List<Map<String, dynamic>>> _extractTransactions(List<Map<String, dynamic>> portfolio) {
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    for (var token in portfolio) {
      if (token.containsKey('transactions') && token['transactions'] is List) {
        for (var transaction in token['transactions']) {
          if (transaction['dateTime'] != null) {
            DateTime date = transaction['dateTime'] is String ? DateTime.parse(transaction['dateTime']) : transaction['dateTime'];
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            events.putIfAbsent(normalizedDate, () => []);

            // 🔥 Ajout du `transactionType` localisé
            events[normalizedDate]!.add({
              'type': 'transaction',
              'amount': transaction['amount'],
              'price': '${currencyUtils.convert(transaction['price'] ?? token['tokenPrice']).toStringAsFixed(2)} ${currencyUtils.currencySymbol}',
              'date': date.toIso8601String(),
              'fullName': token['fullName'],
              'transactionType': transaction['transactionType'] ?? S.of(context).unknownTransaction,
            });
          }
        }
      }
    }
    return events;
  }

  void _addRentEvents(Map<DateTime, List<Map<String, dynamic>>> events, List<Map<String, dynamic>> rentData) {
    for (var rent in rentData) {
      if (rent['date'] != null) {
        DateTime date = rent['date'] is String ? DateTime.parse(rent['date']) : rent['date'];
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(normalizedDate, () => []);
        events[normalizedDate]!.add({
          'type': 'rent',
          'amount': rent['rent'],
          'date': date.toIso8601String(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              DateTime normalizedDay = DateTime(day.year, day.month, day.day);
              return _events[normalizedDay] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                _focusedDay = focusedDay;
              });
            },
            rowHeight: 40,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markersAnchor: 0.5,
              todayDecoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events == null || events.isEmpty) return null;
                List<Widget> markers = [];

                bool hasRent = events.any((e) => (e as Map<String, dynamic>)['type'] == 'rent');
                bool hasPurchase = events.any((e) => (e as Map<String, dynamic>)['type'] == 'transaction' && e['transactionType'] == S.of(context).purchase);
                bool hasYAM = events.any((e) => (e as Map<String, dynamic>)['type'] == 'transaction' && e['transactionType'] == S.of(context).yam);
                bool hasTransfer = events.any((e) => (e as Map<String, dynamic>)['type'] == 'transaction' && e['transactionType'] == S.of(context).internal_transfer);

                if (hasRent) {
                  markers.add(Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)));
                }
                if (hasPurchase) {
                  markers.add(Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)));
                }
                if (hasYAM) {
                  markers.add(Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)));
                }
                if (hasTransfer) {
                  markers.add(Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle)));
                }

                return markers.isNotEmpty ? Row(mainAxisAlignment: MainAxisAlignment.center, children: markers) : null;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: (_events.containsKey(_selectedDay) && _events[_selectedDay]!.isNotEmpty)
                ? ListView.builder(
                    itemCount: _events[_selectedDay]!.length,
                    itemBuilder: (context, index) {
                      final event = _events[_selectedDay]![index] as Map<String, dynamic>;
                      final type = event['type'];
                      final fullName = event.containsKey('fullName') ? event['fullName'] : "N/A";
                      final date = event['date'];
                      final price = event['price'];
                      final amount = event['amount'] ?? 0.0;
                      final transactionType = event.containsKey('transactionType') ? event['transactionType'] : S.of(context).unknownTransaction;

                      return type == 'transaction'
                          ? Card(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: ListTile(
                                leading: Icon(
                                  transactionType == S.of(context).purchase
                                      ? Icons.shopping_cart
                                      : transactionType == S.of(context).internal_transfer
                                          ? Icons.swap_horiz
                                          : transactionType == S.of(context).yam
                                              ? Icons.price_change
                                              : Icons.attach_money,
                                  color: transactionType == S.of(context).purchase
                                      ? Colors.blue
                                      : transactionType == S.of(context).internal_transfer
                                          ? Colors.grey
                                          : transactionType == S.of(context).yam
                                              ? Colors.orange
                                              : Colors.green,
                                ),
                                title: Text(fullName, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Pour aligner le texte à gauche
                                  children: [
                                    Text("${S.of(context).transactionType}: $transactionType", style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                    Text("${S.of(context).quantity}: $amount",style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                    Text("${S.of(context).price}: $price", style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                  ],
                                ),
                              ))
                          : Card(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: ListTile(
                                leading: Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                ),
                                title: Text(S.of(context).rents,
                                    style: TextStyle(
                                      fontSize: 13 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    )),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Pour aligner le texte à gauche
                                  children: [
                                    Text("${S.of(context).amount}: ${currencyUtils.convert(amount).toStringAsFixed(2)} ${currencyUtils.currencySymbol}", style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                  ],
                                ),
                              ),
                            );
                      ;
                    },
                  )
                : Center(child: Text(S.of(context).unknownTransaction)),
          ),
        ],
      ),
    );
  }
}
