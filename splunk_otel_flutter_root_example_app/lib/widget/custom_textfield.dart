import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/test_flags.dart';

class CustomTextField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final String labelText;
  final String? semanticsLabel;
  const CustomTextField({
    this.fieldKey,
    required this.controller,
    required this.labelText,
    this.semanticsLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return appiumSemantics(
      label: semanticsLabel ?? labelText,
      textField: true,
      child: TextField(
        key: fieldKey,
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: labelText,
          labelStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
          ),
          alignLabelWithHint: true,
        ),
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: Colors.black.withAlpha(87),
        ),
      ),
    );
  }
}
