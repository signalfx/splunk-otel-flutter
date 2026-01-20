import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/color_palette.dart';
import 'package:splunk_otel_flutter_root_example_app/data/model/movie.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/premium_screen_intro.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/score_widget.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/tag_listview.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailScreen({required this.movie, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            child: SizedBox(
              width: screenWidth,
              child: Image.asset(
                "res/movie_images/${movie.detailUrl}",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: screenWidth * 0.075,
                right: screenWidth * 0.05,
                top: screenHeight * 0.03,
              ),
              height: screenHeight * 0.715,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(screenWidth * 0.05),
                    topLeft: Radius.circular(screenWidth * 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: screenHeight * 0.065,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.6,
                          child: Text(
                            movie.name,
                            style: const TextStyle(
                                fontSize: 22.0, color: Colors.black),
                          ),
                        ),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.bookmark_border_sharp))
                      ],
                    ),
                  ),
                  ScoreWidget(score: movie.imdbRating),
                  SizedBox(height: screenHeight * 0.01),
                  SizedBox(
                    height: screenHeight * 0.05,
                    width: screenWidth * 0.9,
                    child: TagListWidget(tags: movie.tags),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  DescriptionRow(
                    length: movie.length,
                    language: (movie.languages?.isEmpty ?? true)
                        ? "-"
                        : movie.languages![0],
                    rating: movie.rating,
                  ),
                  SizedBox(height: screenHeight * 0.028),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.blackText,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    movie.description,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textGrey,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () {
                        _showMyDialog(context);
                      },
                      child: Container(
                        width: screenWidth * 0.143,
                        height: screenWidth * 0.143,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorPalette.buttonBlue,
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return const PremiumDialog();
        });
  }
}

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6.0))),
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
      title: const Text(
        'Premium Account',
        style: TextStyle(
          fontSize: 22.0,
          color: ColorPalette.blackDialogText,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text(
              'In order to download this movie, you need to have premium account.',
              style: TextStyle(
                fontSize: 16.0,
                color: ColorPalette.blackDialogText,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            const Text(
              'Would you like to purchase it?',
              style: TextStyle(
                fontSize: 16.0,
                color: ColorPalette.blackDialogText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL',
              style: TextStyle(
                fontSize: 18.0,
                color: ColorPalette.buttonBlue,
                fontWeight: FontWeight.w700,
              )),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text(
            'PURCHASE',
            style: TextStyle(
              fontSize: 18.0,
              color: ColorPalette.buttonBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            // Track navigation to premium screen
            SplunkRum.instance.navigation.track(screenName: 'Premium Account Screen - Intro');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => const PremiumScreenIntro(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class DescriptionRow extends StatelessWidget {
  final String length;
  final String language;
  final String rating;
  const DescriptionRow({
    required this.length,
    required this.language,
    required this.rating,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        DescriptionWidget(
          title: "Length",
          value: length,
        ),
        SizedBox(width: screenWidth * 0.1),
        DescriptionWidget(
          title: "Language",
          value: language,
        ),
        SizedBox(width: screenWidth * 0.1),
        DescriptionWidget(
          title: "Rating",
          value: rating,
        ),
      ],
    );
  }
}

class DescriptionWidget extends StatelessWidget {
  final String title;
  final String value;

  const DescriptionWidget({
    required this.title,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFA5ADBA),
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          value,
          style: const TextStyle(
            color: ColorPalette.blackText,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
