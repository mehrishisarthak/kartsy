import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle boldTextStyle(
  ) {
    return TextStyle(
      fontFamily: 'Lato',
      fontSize:  28.0,
      color: const Color.fromRGBO(0, 0, 0, 1),
      fontWeight: FontWeight.bold,
    );
  }

 static TextStyle lightTextStyle(
  ) {
    return TextStyle(
      fontFamily: 'Lato',
      fontSize:  20.0,
      color: Colors.grey[600],
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle buttonTextStyle(
  ) {
    return TextStyle(
      fontFamily: 'Lato',
      fontSize:  16.0,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
  }

}