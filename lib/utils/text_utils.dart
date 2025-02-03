import 'package:shared_preferences/shared_preferences.dart';

class TextUtils {
  static Future<double> getTextSizeOffset() async {
    final prefs = await SharedPreferences.getInstance();
    String selectedTextSize = prefs.getString('selectedTextSize') ?? 'normal';
    return selectedTextSize == 'petit' ? -2.0 : selectedTextSize == 'grand' ? 2.0 : 0.0;
  }

}
