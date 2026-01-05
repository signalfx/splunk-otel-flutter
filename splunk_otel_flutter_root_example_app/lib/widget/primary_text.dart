import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class PrimaryText extends StatelessWidget {
  final String text;
  final bool withUnderScore;
  const PrimaryText({required this.text, this.withUnderScore = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 40.0,
        color: ColorPalette.blackText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
