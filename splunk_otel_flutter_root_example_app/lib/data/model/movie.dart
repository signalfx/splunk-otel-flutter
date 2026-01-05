class Movie {
  final String name;
  final String id;
  final String imdbRating;
  final List<String> tags;
  final String length;
  final List<String>? languages;
  final String rating;
  final String description;
  final String coverUrl;
  final String detailUrl;

  Movie(
    this.name,
    this.id,
    this.imdbRating,
    this.tags,
    this.length,
    this.languages,
    this.rating,
    this.description,
    this.coverUrl,
    this.detailUrl,
  );

  Movie.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        id = json['id'],
        imdbRating = json['imdbRating'],
        tags = json['tags'],
        length = json['length'],
        languages = json['language'],
        rating = json['rating'],
        description = json['description'],
        coverUrl = json['coverUrl'],
        detailUrl = json['detailUrl'];
}
