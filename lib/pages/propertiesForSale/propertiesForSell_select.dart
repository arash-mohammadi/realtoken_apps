import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/pages/propertiesForSale/PropertiesForSaleRealt.dart';
import 'package:realtokens/pages/propertiesForSale/PropertiesForSaleSecondary.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';

class PropertiesForSalePage extends StatefulWidget {
  const PropertiesForSalePage({super.key});

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
              expandedHeight: UIUtils.getSliverAppBarHeight(context) - 25,
              automaticallyImplyLeading: false, // Supprime la flèche de retour
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  // Utiliser SafeArea pour éviter le chevauchement
                  child: Container(
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
            ),
          ];
        },
        body: _selectedPage == 'RealT' ? const PropertiesForSaleRealt() : const PropertiesForSaleSecondary(),
      ),
    );
  }

  Widget _buildPageSelector() {
    return Center(
      // Centrer horizontalement
      child: Wrap(
        spacing: 8.0, // Espacement entre les chips
        children: [
          _buildPageChip('RealT', S.of(context).realt),
          _buildPageChip('Secondary', S.of(context).secondary),
        ],
      ),
    );
  }

  Widget _buildPageChip(String value, String label) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedPage == value;

    return ActionChip(
      // Utilisation de ActionChip
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16 + appState.getTextSizeOffset(),
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () {
        setState(() {
          _selectedPage = value;
        });
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Bords arrondis
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 80 : 5, // Agrandir davantage le chip sélectionné
        vertical: 5, // Augmenter la hauteur des chips
      ),
    );
  }
}
