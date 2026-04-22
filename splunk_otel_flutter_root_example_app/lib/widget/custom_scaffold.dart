import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final List<Widget>? widgets;
  final Widget? child;
  final CrossAxisAlignment alignment;
  final double? paddingHorizontal;
  final bool doUnFocus;
  const CustomScaffold({
    this.widgets,
    this.child,
    this.alignment = CrossAxisAlignment.center,
    this.paddingHorizontal,
    this.doUnFocus = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (doUnFocus) {
              FocusScope.of(context).unfocus();
            }
          },
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal ?? screenWidth * 0.1,
              ),
              child: child ??
                  Column(
                    crossAxisAlignment: alignment,
                    children: [
                      ...widgets!,
                      SizedBox(
                        height: screenHeight * 0.03,
                        width: screenWidth,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
