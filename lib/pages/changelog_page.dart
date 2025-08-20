import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/app_state.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  _ChangelogPageState createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  String _markdownData = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarkdown();
  }

  Future<void> _fetchMarkdown() async {
    const url = 'https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _markdownData = response.body;
          _isLoading = false;
        });
      } else {
        setState(() {
          _markdownData = 'Erreur lors du chargement du contenu (code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _markdownData = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFF2F2F7) : const Color(0xFF000000),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // En-tête avec style cohérent
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.2, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Changelog',
                  style: TextStyle(
                    fontSize: 28 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenu principal
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chargement du changelog...',
                              style: TextStyle(
                                fontSize: 16 + appState.getTextSizeOffset(),
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Markdown(
                        data: _markdownData,
                        padding: const EdgeInsets.all(20.0),
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(
                            fontSize: 24 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.headlineLarge?.color,
                            letterSpacing: -0.5,
                          ),
                          h2: TextStyle(
                            fontSize: 20 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: -0.3,
                          ),
                          h3: TextStyle(
                            fontSize: 18 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.headlineSmall?.color,
                            letterSpacing: -0.2,
                          ),
                          p: TextStyle(
                            fontSize: 16 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            height: 1.5,
                            letterSpacing: -0.1,
                          ),
                          listBullet: TextStyle(
                            fontSize: 16 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            height: 1.4,
                          ),
                          code: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            backgroundColor: Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFFF2F2F7)
                                : const Color(0xFF1C1C1E),
                            color: Theme.of(context).primaryColor,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFFF2F2F7)
                                : const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
