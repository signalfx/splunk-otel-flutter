import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class PremiumWidget extends StatelessWidget {
  final String description;
  const PremiumWidget({
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.16),
        SizedBox(
          width: screenWidth * 0.24,
          height: screenWidth * 0.24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.account_circle,
                color: ColorPalette.buttonBlue,
                size: screenWidth * 0.22,
              ),
              Positioned(
                right: screenWidth * 0.005,
                bottom: screenWidth * 0.005,
                child: Icon(
                  Icons.star,
                  color: ColorPalette.starYellow,
                  size: screenWidth * 0.08,
                ),
              )
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          "Upgrade to\nPremium Account",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.0,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        )
      ],
    );
  }
}
