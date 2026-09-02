import 'package:flutter/foundation.dart';

class ThemeProvider extends ChangeNotifier {
  String _selectedTheme = 'Adventure';
  
  String get selectedTheme => _selectedTheme;
  
  void setTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }
}
