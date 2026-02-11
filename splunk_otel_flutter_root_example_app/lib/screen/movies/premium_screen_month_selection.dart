import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/premium_payment_failure_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/premium_payment_success_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/premium_widget.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_button.dart';

class PremiumScreenMonthSelection extends StatefulWidget {
  const PremiumScreenMonthSelection({super.key});

  @override
  State<PremiumScreenMonthSelection> createState() =>
      _PremiumScreenMonthSelectionState();
}

class _PremiumScreenMonthSelectionState
    extends State<PremiumScreenMonthSelection> {
  double _currentSliderValue = 6;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      paddingHorizontal: screenWidth * 0.08,
      widgets: [
        const PremiumWidget(
          description: "How many months you\nwould like to subscribe for?",
        ),
        SizedBox(height: screenHeight * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Months:"),
            Text(
              _currentSliderValue.toInt().toString(),
            )
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        Row(
          children: [
            const Text("1"),
            Expanded(
              child: Slider(
                value: _currentSliderValue,
                min: 1,
                max: 12,
                divisions: 11,
                label: _currentSliderValue.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _currentSliderValue = value;
                  });
                },
                thumbColor: ColorPalette.buttonBlue,
                activeColor: ColorPalette.buttonBlue,
              ),
            ),
            const Text("12"),
          ],
        ),
        const Spacer(),
        PrimaryButton(
          text: "PURCHASE",
          onTap: () {
            // Track purchase button click with Splunk RUM
            SplunkRum.instance.customTracking.trackCustomEvent(
              name: 'purchase_initiated',
              attributes: MutableAttributes(
                attributes: {
                  'months': MutableAttributeInt(value: _currentSliderValue.toInt()),
                  'subscription_type': MutableAttributeString(value: 'premium'),
                },
              ),
            );
            if (_currentSliderValue == 2) {
              // Track failed purchase
              SplunkRum.instance.navigation.track(screenName: 'Purchase Failed Screen');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => const PremiumPaymentFailureScreen(),
                ),
              );
            } else {
              // Track successful purchase
              SplunkRum.instance.navigation.track(screenName: 'Purchase Succeeded Screen');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => const PremiumPaymentSuccessScreen(),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
