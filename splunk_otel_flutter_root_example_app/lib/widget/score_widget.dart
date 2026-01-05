import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class ScoreWidget extends StatelessWidget {
  final String score;
  const ScoreWidget({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Icon(
          Icons.star,
          color: ColorPalette.starYellow,
          size: screenWidth * 0.04,
        ),
        SizedBox(width: screenWidth * 0.01),
        Flexible(
            child: Text(
          score,
          style: const TextStyle(fontSize: 12.0, color: ColorPalette.textGrey),
        )),
      ],
    );
  }
}
