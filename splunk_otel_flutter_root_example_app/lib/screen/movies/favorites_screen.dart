import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import 'package:splunk_otel_flutter_root_example_app/data/mock/mock_movies.dart';
import 'package:splunk_otel_flutter_root_example_app/data/model/movie.dart';
import 'package:splunk_otel_flutter_root_example_app/screen/movies/movie_detail_screen.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/custom_scaffold.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/score_widget.dart';
import 'package:splunk_otel_flutter_root_example_app/widget/tag_listview.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScaffold(
      paddingHorizontal: screenWidth * 0.08,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.05),
          const Text(
            "Favorites",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF110E47),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          FavoritesListView(movies: MockMovies.favoriteMovies),
        ],
      ),
    );
  }
}

class FavoritesListView extends StatelessWidget {
  final List<Movie> movies;
  const FavoritesListView({required this.movies, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Flexible(
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: movies.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            return Padding(
                padding: EdgeInsets.only(
                    bottom: index == (movies.length - 1) ? 0 : screenHeight * 0.02),
                child: FavoriteMovieWidget(movie: movies[index]));
          }),
    );
  }
}

class FavoriteMovieWidget extends StatelessWidget {
  final Movie movie;
  const FavoriteMovieWidget({required this.movie, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return InkWell(
      onTap: () {
        // Track movie detail view with Splunk RUM
        SplunkRum.instance.navigation.track(screenName: 'Movie Detail Screen');
        SplunkRum.instance.customTracking.trackCustomEvent(
          name: 'movie_view',
          attributes: MutableAttributes(
            attributes: {
              'movie_name': MutableAttributeString(value: movie.name),
              'source': MutableAttributeString(value: 'favorites'),
            },
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (builder) => MovieDetailScreen(movie: movie),
              settings: const RouteSettings(name: "/detail")),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.25,
            child: Image.asset(
              "res/movie_images/${movie.coverUrl}",
              fit: BoxFit.fitWidth,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                ScoreWidget(score: movie.imdbRating),
                SizedBox(height: screenHeight * 0.01),
                SizedBox(height: screenHeight * 0.025, child: TagListWidget(tags: movie.tags)),
                SizedBox(height: screenHeight * 0.01),
                LengthWidget(length: movie.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LengthWidget extends StatelessWidget {
  final String length;
  const LengthWidget({required this.length, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.access_time, size: screenWidth * 0.035),
        SizedBox(width: screenWidth * 0.01),
        Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.001),
          child: Text(
            length,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
