import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';

class TagListWidget extends StatelessWidget {
  final List<String> tags;
  const TagListWidget({required this.tags, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == (tags.length - 1) ? 0 : screenWidth * 0.015,
            ),
            child: TagWidget(tag: tags[index]),
          );
        });
  }
}

class TagWidget extends StatelessWidget {
  final String tag;
  const TagWidget({required this.tag, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      alignment: Alignment.center,
      height: screenHeight * 0.025,
      child: Container(
        height: screenHeight * 0.025,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ColorPalette.tagFill,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: Text(
          tag.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.021,
            color: ColorPalette.tagText,
            height: 0.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
