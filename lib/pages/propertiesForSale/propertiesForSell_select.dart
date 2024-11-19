import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/app_state.dart';
import 'package:realtokens_apps/pages/propertiesForSale/PropertiesForSaleRealt.dart';
import 'package:realtokens_apps/pages/propertiesForSale/PropertiesForSaleSecondary.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:realtokens_apps/generated/l10n.dart';

class PropertiesForSalePage extends StatefulWidget {
  const PropertiesForSalePage({Key? key}) : super(key: key);

  @override
  _PropertiesForSalePageState createState() => _PropertiesForSalePageState();
}

class _PropertiesForSalePageState extends State<PropertiesForSalePage> {
  String _selectedPage = 'RealT'; // Valeur par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Text(S.of(context).properties_for_sale), // Titre de la page
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: Utils.getSliverAppBarHeight(context) - 40,
              automaticallyImplyLeading: false, // Supprime la flèche de retour
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildPageSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _selectedPage == 'RealT' ? const PropertiesForSaleRealt() : const PropertiesForSaleSecondary(),
      ),
    );
  }

  Widget _buildPageSelector() {
    final appState = Provider.of<AppState>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          _buildPageButton('RealT', S.of(context).realt, isFirst: true),
          _buildPageButton('Secondary', S.of(context).secondary, isLast: true),
        ],
      ),
    );
  }

  Widget _buildPageButton(String value, String label, {bool isFirst = false, bool isLast = false}) {
    final appState = Provider.of<AppState>(context);

    final isSelected = _selectedPage == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPage = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Theme.of(context).cardColor,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
