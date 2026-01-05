import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/data/mock/mock_movies.dart';
import 'package:splunk_otel_flutter_root_example_app/data/model/movie.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/movie_detail_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/score_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      paddingHorizontal: screenWidth * 0.07,
      widgets: [
        SizedBox(height: screenHeight * 0.07),
        MovieListView(title: "Trending", movies: MockMovies.trendingMovies),
        SizedBox(height: screenHeight * 0.02),
        MovieListView(title: "New", movies: MockMovies.newMovies),
      ],
    );
  }
}

class MovieListView extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  const MovieListView({required this.title, required this.movies, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return movies.isEmpty
        ? const SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22.0, color: Colors.black),
              ),
              SizedBox(height: screenHeight * 0.015),
              SizedBox(
                height: screenHeight * 0.345,
                child: ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == (movies.length - 1) ? 0 : screenWidth * 0.03,
                      ),
                      child: MovieCoverWidget(movie: movies[index]),
                    );
                  },
                  scrollDirection: Axis.horizontal,
                ),
              ),
            ],
          );
  }
}

class MovieCoverWidget extends StatelessWidget {
  final Movie movie;
  const MovieCoverWidget({required this.movie, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return InkWell(
      onTap: () {
        // Track movie detail view with Splunk RUM
        SplunkOtelFlutter.instance.navigation.track(screenName: 'Movie Detail Screen');
        SplunkOtelFlutter.instance.customTracking.trackCustomEvent(
          name: 'movie_view',
          attributes: MutableAttributes(
            attributes: {
              'movie_name': MutableAttributeString(value: movie.name),
            },
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (builder) => MovieDetailScreen(
                    movie: movie,
                  ),
              settings: const RouteSettings(name: "/detail")),
        );
      },
      child: SizedBox(
        width: screenWidth * 0.3667,
        height: screenHeight * 0.345,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: screenHeight * 0.2511,
              child: Image.asset(
                "res/movie_images/${movie.coverUrl}",
                fit: BoxFit.fitHeight,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              movie.name,
              style: const TextStyle(fontSize: 14.0, color: Colors.black),
              maxLines: 2,
            ),
            SizedBox(height: screenHeight * 0.01),
            ScoreWidget(score: movie.imdbRating),
          ],
        ),
      ),
    );
  }
}
