import 'package:flutter/material.dart';

class AppSizes {
  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static double _blockWidth = 0;
  static double _blockHeight = 0;

  static void init(BuildContext context) {
    MediaQueryData _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _blockWidth = _screenWidth / 100;
    _blockHeight = _screenHeight / 100;
  }

  static double width(double percentage) {
    return _blockWidth * percentage;
  }

  static double height(double percentage) {
    return _blockHeight * percentage;
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get blockWidth => _blockWidth;
  static double get blockHeight => _blockHeight;
}
