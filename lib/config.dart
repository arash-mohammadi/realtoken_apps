import 'dart:io';

class Config {
  static final String theGraphApiKey = Platform.environment['THE_GRAPH_API_KEY'] ?? 'default_value_if_missing';
}
