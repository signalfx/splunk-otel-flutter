import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/login_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_text.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/secondary_text.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return CustomScaffold(
      widgets: [
        const Spacer(flex: 4),
        SizedBox(height: screenHeight * 0.024),
        const PrimaryText(text: "SmartCinema"),
        SizedBox(height: screenHeight * 0.012),
        const SecondaryText(text: "Your mobile cinema"),
        const Spacer(flex: 3),
        PrimaryButton(
          text: "Get started",
          onTap: () {
            // Track navigation using Splunk RUM
            SplunkOtelFlutter.instance.navigation.track(screenName: 'Login Screen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (builder) => const LoginScreen(),
              ),
            );
          },
        )
      ],
    );
  }
}
