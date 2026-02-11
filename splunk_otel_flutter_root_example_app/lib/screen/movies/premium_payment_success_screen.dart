import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/round_icon.dart';

class PremiumPaymentSuccessScreen extends StatelessWidget {
  const PremiumPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      widgets: [
        const Spacer(flex: 3),
        RoundIconWidget(
          successWidget: Icon(
            Icons.credit_score,
            color: Colors.white,
            size: screenWidth * 0.08,
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          "Payment successfully\ncompleted",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.0,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
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
              "DONE",
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
