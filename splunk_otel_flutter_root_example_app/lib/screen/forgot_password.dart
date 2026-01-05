import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_textfield.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_button.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_text.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/round_icon.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/secondary_text.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      alignment: CrossAxisAlignment.start,
      doUnFocus: true,
      widgets: [
        const Spacer(flex: 2),
        const PrimaryText(text: "Forgot\nPassword?"),
        SizedBox(height: screenHeight * 0.02),
        const SecondaryText(
          text: "Don't worry. It happens.\nPlease enter email account.",
        ),
        SizedBox(height: screenHeight * 0.03),
        CustomTextField(
          controller: _controller,
          labelText: "Email",
        ),
        const Spacer(flex: 3),
        PrimaryButton(
            text: "Submit",
            onTap: () {
              if (_controller.text == "jan@smartlook.com" ||
                  _controller.text == "ondrej@smartlook.com" ||
                  _controller.text == "pavel@smartlook.com") {
                // Track successful password reset
                SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
                  name: 'password_reset',
                  attributes: MutableAttributes(
                    attributes: {
                      'status': MutableAttributeString(value: 'success'),
                    },
                  ),
                );
                showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(screenWidth * 0.04),
                        topLeft: Radius.circular(screenWidth * 0.04),
                      ),
                    ),
                    builder: (BuildContext context) {
                      return const ModalBottomSheet();
                    });
              } else if (!_controller.text.contains("@")) {
                exit(0);
              } else {
                // Track failed password reset
                SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
                  name: 'password_reset',
                  attributes: MutableAttributes(
                    attributes: {
                      'status': MutableAttributeString(value: 'failed'),
                      'reason': MutableAttributeString(value: 'invalid_email'),
                    },
                  ),
                );
                showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(screenWidth * 0.04),
                        topLeft: Radius.circular(screenWidth * 0.04),
                      ),
                    ),
                    builder: (BuildContext context) {
                      return const ModalBottomSheet(isSuccess: false);
                    });
              }
            }),
      ],
    );
  }
}

class ModalBottomSheet extends StatelessWidget {
  final bool isSuccess;
  const ModalBottomSheet({this.isSuccess = true, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenHeight * 0.33,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(screenWidth * 0.05),
          topLeft: Radius.circular(screenWidth * 0.05),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: screenHeight * 0.025),
            RoundIconWidget(
              successWidget: isSuccess
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: screenWidth * 0.08,
                    )
                  : null,
              failureWidget: isSuccess
                  ? null
                  : Icon(
                      Icons.close,
                      color: Colors.white,
                      size: screenWidth * 0.08,
                    ),
              isSuccess: isSuccess,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              isSuccess
                  ? "New password was sent to email"
                  : 'Failed to send new password\n to email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22.0,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            SizedBox(
              width: screenWidth * 0.82,
              child: PrimaryButton(
                  text: "OK",
                  onTap: () {
                    Navigator.pop(context);
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
