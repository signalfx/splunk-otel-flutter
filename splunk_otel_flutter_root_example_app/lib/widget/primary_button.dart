import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/test_flags.dart';

class PrimaryButton extends StatelessWidget {
  final Key? buttonKey;
  final String text;
  final String? semanticsLabel;
  final VoidCallback onTap;
  const PrimaryButton({
    this.buttonKey,
    required this.text,
    this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return appiumSemantics(
      label: semanticsLabel ?? text,
      button: true,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            ColorPalette.buttonBlue,
          ),
        ),
        child: SizedBox(
          width: screenWidth,
          height: screenHeight * 0.056,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
