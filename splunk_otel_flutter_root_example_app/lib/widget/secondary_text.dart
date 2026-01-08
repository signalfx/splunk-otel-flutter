import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class SecondaryText extends StatelessWidget {
  final String text;
  final bool withUnderScore;
  final Color customColor;
  const SecondaryText({
    required this.text,
    this.withUnderScore = false,
    this.customColor = ColorPalette.blackText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 16.0,
          color: ColorPalette.blackText,
          decoration: withUnderScore ? TextDecoration.underline : null,
          fontWeight: FontWeight.w400),
    );
  }
}
