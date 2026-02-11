import 'package:splunk_otel_flutter_root_example_app/data/model/movie.dart';

class MockMovies {
  static const Map<String, dynamic> json = {
    "movies": [
      {
        "name": "Spiderman: No Way Home",
        "id": "1",
        "imdbRating": "8.3/10 IMDb",
        "tags": ["Action", "Adventure", "Fantasy"],
        "length": "2h 28min",
        "language": ["English"],
        "rating": "PG-13",
        "description":
            "With Spider-Man's identity now revealed, Peter asks Doctor Strange for help. When a spell goes wrong, dangerous foes from other worlds start to appear, forcing Peter to discover what it truly means to be Spider-Man.",
        "coverUrl": "cover/1.jpg",
        "detailUrl": "detail/1.jpeg"
      },
      {
        "name": "Interstellar",
        "id": "2",
        "imdbRating": "8.6/10 IMDb",
        "tags": ["Adventure", "Drama", "Sci-Fi"],
        "length": "2h 49min",
        "language": ["English"],
        "rating": "PG-13",
        "description":
            "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.",
        "coverUrl": "cover/2.jpg",
        "detailUrl": "detail/2.jpeg"
      },
      {
        "name": "The Lord of the Rings: The Fellowship of the Ring",
        "id": "3",
        "imdbRating": "8.8/10 IMDb",
        "tags": ["Action", "Adventure", "Drama"],
        "length": "2h 58min",
        "language": ["English", "Sindarin"],
        "rating": "PG-13",
        "description":
            "A meek Hobbit from the Shire and eight companions set out on a journey to destroy the powerful One Ring and save Middle-earth from the Dark Lord Sauron.",
        "coverUrl": "cover/3.jpg",
        "detailUrl": "detail/3.jpg"
      },
      {
        "name": "Bullet Train",
        "id": "4",
        "imdbRating": "7.4/10 IMDb",
        "tags": ["Action", "Comedy", "Thriller"],
        "length": "2h 7min",
        "language": ["English", "Japanese", "Spanish", "Russian"],
        "rating": "R",
        "description":
            "Five assassins aboard a swiftly-moving bullet train find out that their missions have something in common.",
        "coverUrl": "cover/4.jpg",
        "detailUrl": "detail/4.jpeg"
      },
      {
        "name": "Harry Potter and the Deathly Hallows: Part 2",
        "id": "5",
        "imdbRating": "8.1/10 IMDb",
        "tags": ["Adventure", "Family", "Fantasy"],
        "length": "2h 10min",
        "language": ["English", "Latin"],
        "rating": "PG-13",
        "description":
            "Harry, Ron, and Hermione search for Voldemort's remaining Horcruxes in their effort to destroy the Dark Lord as the final battle rages on at Hogwarts.",
        "coverUrl": "cover/5.jpg",
        "detailUrl": "detail/5.jpeg"
      },
      {
        "name": "Pulp Fiction",
        "id": "6",
        "imdbRating": "8.9/10 IMDb",
        "tags": ["Crime", "Drama"],
        "length": "2h 34min",
        "language": ["English", "Spanish", "French"],
        "rating": "R",
        "description":
            "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.",
        "coverUrl": "cover/6.jpg",
        "detailUrl": "detail/6.jpg"
      },
      {
        "name": "Forrest Gump",
        "id": "7",
        "imdbRating": "8.8/10 IMDb",
        "tags": ["Drama", "Romance"],
        "length": "2h 22min",
        "language": ["English"],
        "rating": "PG-13",
        "description":
            "The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal and other historical events unfold from the perspective of an Alabama man with an IQ of 75, whose only desire is to be reunited with his childhood sweetheart.",
        "coverUrl": "cover/7.jpg",
        "detailUrl": "detail/7.jpeg"
      },
      {
        "name": "WALL·E",
        "id": "8",
        "imdbRating": "8.4/10 IMDb",
        "tags": ["Animation", "Adventure", "Family"],
        "length": "1h 38min",
        "language": ["English", "Hindi"],
        "rating": "TV-G",
        "description":
            "In the distant future, a small waste-collecting robot inadvertently embarks on a space journey that will ultimately decide the fate of mankind.",
        "coverUrl": "cover/8.jpg",
        "detailUrl": "detail/8.jpeg"
      },
      {
        "name": "The Matrix",
        "id": "9",
        "imdbRating": "8.7/10 IMDb",
        "tags": ["Action", "Sci-Fi"],
        "length": "2h 16min",
        "language": ["English"],
        "rating": "R",
        "description":
            "When a beautiful stranger leads computer hacker Neo to a forbidding underworld, he discovers the shocking truth--the life he knows is the elaborate deception of an evil cyber-intelligence.",
        "coverUrl": "cover/9.jpg",
        "detailUrl": "detail/9.jpeg"
      },
      {
        "name": "The Lion King",
        "id": "10",
        "imdbRating": "8.5/10 IMDb",
        "tags": ["Animation", "Adventure", "Drama"],
        "length": "1h 28min",
        "language": ["English", "Swahili", "Xhosa", "Zulu"],
        "rating": "G",
        "description":
            "Lion prince Simba and his father are targeted by his bitter uncle, who wants to ascend the throne himself.",
        "coverUrl": "cover/10.jpg",
        "detailUrl": "detail/10.jpeg"
      }
    ],
    "dashboard": {
      "new": ["1", "2", "3", "4", "5"],
      "trending": ["6", "7", "8", "9", "10"],
      "favorite": ["3", "5", "6", "10"]
    }
  };
  static List<Movie> get newMovies {
    final List<String> newStringList = json["dashboard"]["new"];
    List<Movie> moviesList = [];
    for (final movieJson in json["movies"]) {
      if (newStringList.contains(movieJson["id"])) {
        moviesList.add(Movie.fromJson(movieJson));
      }
    }
    return moviesList;
  }

  static List<Movie> get trendingMovies {
    final List<String> trendingStringList = json["dashboard"]["trending"];
    List<Movie> moviesList = [];
    for (final movieJson in json["movies"]) {
      if (trendingStringList.contains(movieJson["id"])) {
        moviesList.add(Movie.fromJson(movieJson));
      }
    }
    return moviesList;
  }

  static List<Movie> get favoriteMovies {
    final List<String> favoriteStringList = json["dashboard"]["favorite"];
    List<Movie> moviesList = [];
    for (final movieJson in json["movies"]) {
      if (favoriteStringList.contains(movieJson["id"])) {
        moviesList.add(Movie.fromJson(movieJson));
      }
    }
    return moviesList;
  }
}
