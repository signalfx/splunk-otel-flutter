import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/premium_screen_month_selection.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/premium_widget.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_button.dart';

class PremiumScreenIntro extends StatelessWidget {
  const PremiumScreenIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      paddingHorizontal: screenWidth * 0.06,
      widgets: [
        const PremiumWidget(
          description:
              "You can get a lot more of of the app upgrading\nto the premium account.",
        ),
        const Spacer(),
        PrimaryButton(
            text: "CONTINUE",
            onTap: () {
              // Track navigation to month selection screen
              SplunkOtelFlutter.instance.navigation.track(screenName: 'Premium Account Screen - Month Selection');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => const PremiumScreenMonthSelection(),
                ),
              );
            }),
      ],
    );
  }
}
