import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay.dart';

import 'package:splunk_otel_flutter_root_example_app/screen/movies/bottom_bar_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/forgot_password.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_textfield.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_button.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/primary_text.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/secondary_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey _passwordFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyRecordingMask();
    });
  }

  @override
  void dispose() {
    SplunkSessionReplay.instance.setRecordingMask(mask: null);
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _applyRecordingMask() {
    final renderBox =
        _passwordFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('[LoginScreen] RenderBox is null, cannot apply mask');

      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    debugPrint('[LoginScreen] Password field position: $position, size: $size');

    final maskRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );

    SplunkSessionReplay.instance.setRecordingMask(
      mask: RecordingMask(
        elements: [
          MaskElement(
            rect: maskRect,
            type: MaskType.covering,
          ),
        ],
      ),
    );
    debugPrint('[LoginScreen] Recording mask applied: $maskRect');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      alignment: CrossAxisAlignment.start,
      doUnFocus: true,
      widgets: [
        const Spacer(),
        const PrimaryText(text: "Login"),
        SizedBox(height: screenHeight * 0.05),
        CustomTextField(
          controller: _loginController,
          labelText: "Email",
        ),
        SizedBox(height: screenHeight * 0.05),
        CustomTextField(
          key: _passwordFieldKey,
          controller: _passwordController,
          labelText: "Password",
        ),
        SizedBox(height: screenHeight * 0.05),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () {
              // Track navigation using Splunk RUM
              SplunkRum.instance.navigation.track(screenName: 'Forgot Password Screen');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: const SecondaryText(
              text: "Forgot Password?",
              withUnderScore: true,
              customColor: Colors.black,
            ),
          ),
        ),
        const Spacer(),
        PrimaryButton(
            text: "Login",
            onTap: () async{
              if (_loginController.text == "jan@smartlook.com" ||
                  _loginController.text == "ondrej@smartlook.com" ||
                  _loginController.text == "pavel@smartlook.com") {
                // Track successful login
                await SplunkRum.instance.navigation.track(screenName: 'Home Screen');
                await SplunkRum.instance.customTracking.trackCustomEvent(
                  name: 'login',
                  attributes: MutableAttributes(
                    attributes: {
                      'status': MutableAttributeString(value: 'success'),
                      'user_email': MutableAttributeString(value: _loginController.text),
                    },
                  ),
                );

                // Set user identifier for Splunk RUM
                SplunkRum.instance.globalAttributes.setString(
                  key: 'user.email',
                  value: _loginController.text,
                );
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (builder) => BottomBarScreen(
                      userEmail: _loginController.text,
                    ),
                  ),
                );
              } else if (!_loginController.text.contains("@")) {
                exit(0);
              } else {
                // Track failed login
               await SplunkRum.instance.customTracking.trackCustomEvent(
                  name: 'login',
                  attributes: MutableAttributes(
                    attributes: {
                      'status': MutableAttributeString(value: 'failed'),
                      'reason': MutableAttributeString(value: 'invalid_credentials'),
                    },
                  ),
                );

                final snackBar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    left: screenWidth * 0.06,
                    right: screenWidth * 0.06,
                    bottom: screenWidth * 0.084,
                  ),
                  content: const Text(
                    'Login failed. Please try it again.',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  backgroundColor: const Color(0xFF202020),
                );

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }),
      ],
    );
  }
}
