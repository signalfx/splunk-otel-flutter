import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const PrimaryButton({
    required this.text,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ElevatedButton(
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
    );
  }
}
