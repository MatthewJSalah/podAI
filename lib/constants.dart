import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final fontSizeLarge = TextStyle(fontSize: 32);
final fontSizemed = TextStyle(fontSize: 20);
final fontSizesmall = TextStyle(fontSize: smallValue);

final fontStyle = GoogleFonts.cabin();

const double smallValue = 10;

final boxStyle = BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 2,
      blurRadius: 5,
      offset: Offset(0, 3),
    ),
  ],
);
