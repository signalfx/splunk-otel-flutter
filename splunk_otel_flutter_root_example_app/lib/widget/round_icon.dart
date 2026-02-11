import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class RoundIconWidget extends StatelessWidget {
  final Widget? successWidget;
  final Widget? failureWidget;
  final bool isSuccess;
  const RoundIconWidget({
    this.successWidget,
    this.failureWidget,
    this.isSuccess = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth * 0.165,
      height: screenWidth * 0.165,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSuccess ? ColorPalette.successGreen : ColorPalette.failureRed),
      child: isSuccess ? successWidget : failureWidget,
    );
  }
}
