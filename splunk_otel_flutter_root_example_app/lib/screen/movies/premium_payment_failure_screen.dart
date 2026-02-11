import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/round_icon.dart';

class PremiumPaymentFailureScreen extends StatelessWidget {
  const PremiumPaymentFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      widgets: [
        const Spacer(flex: 3),
        RoundIconWidget(
          failureWidget: Icon(
            Icons.credit_card_off_outlined,
            color: Colors.white,
            size: screenWidth * 0.08,
          ),
          isSuccess: false,
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          "Payment failed",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.0,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          "Not enough money on the card",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.0,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: screenHeight * 0.05),
        TextButton(
            onPressed: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/detail'),
              );
            },
            child: const Text(
              "GO BACK",
              style: TextStyle(
                fontSize: 18.0,
                color: ColorPalette.buttonBlue,
                fontWeight: FontWeight.w700,
              ),
            )),
        const Spacer(flex: 2),
      ],
    );
  }
}
