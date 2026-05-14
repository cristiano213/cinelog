class Movie {
  final String id;
  final String title;
  final String overview;

  // Solo path TMDB, NON url completa
  final String posterPath;
  final String backdropPath;

  final double voteAverage;
  final int runtimeMinutes;

  final DateTime? releaseDate;

  // Lista semplice
  final List<String> genres;
  final List<String> cast;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.runtimeMinutes,
    required this.releaseDate,
    required this.genres,
    required this.cast,
  });

  // =========================
  // COMPUTED GETTERS
  // =========================

  String get formattedDuration {
    if (runtimeMinutes <= 0) return 'N/A';

    final hours = runtimeMinutes ~/ 60;
    final minutes = runtimeMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  String get releaseYear {
    return releaseDate?.year.toString() ?? 'Unknown';
  }

  String get castPreview {
    return cast.take(3).join(', ');
  }

  String get fullPosterUrl {
    if (posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get smallPosterUrl {
    if (posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w185$posterPath';
  }

  String get fullBackdropUrl {
    if (backdropPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  // =========================
  // TMDB PARSING
  // =========================

  factory Movie.fromTmdbJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'].toString(),

      title: json['title'] ?? '',

      overview: json['overview'] ?? '',

      posterPath: json['poster_path'] ?? '',

      backdropPath: json['backdrop_path'] ?? '',

      voteAverage: (json['vote_average'] ?? 0).toDouble(),

      runtimeMinutes: json['runtime'] ?? 0,

      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,

      genres: json['genres'] != null
          ? List<String>.from(
              (json['genres'] as List)
                  .map((g) => g['name'].toString()),
            )
          : [],

      cast: json['credits']?['cast'] != null
          ? List<String>.from(
              (json['credits']['cast'] as List)
                  .map((c) => c['name'].toString()),
            )
          : [],
    );
  }

  // =========================
  // LOCAL STORAGE PARSING
  // =========================

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],

      title: json['title'],

      overview: json['overview'],

      posterPath: json['posterPath'],

      backdropPath: json['backdropPath'],

      voteAverage: (json['voteAverage'] ?? 0).toDouble(),

      runtimeMinutes: json['runtimeMinutes'] ?? 0,

      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'])
          : null,

      genres: List<String>.from(json['genres'] ?? []),

      cast: List<String>.from(json['cast'] ?? []),
    );
  }

  // =========================
  // LOCAL STORAGE SERIALIZATION
  // =========================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'runtimeMinutes': runtimeMinutes,
      'releaseDate': releaseDate?.toIso8601String(),
      'genres': genres,
      'cast': cast,
    };
  }

  // =========================
  // COPY WITH
  // =========================

  Movie copyWith({
    String? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? runtimeMinutes,
    DateTime? releaseDate,
    List<String>? genres,
    List<String>? cast,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
    );
  }
}