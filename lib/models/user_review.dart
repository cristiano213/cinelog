class UserReview {
  final String movieId;
  final String movieTitle;      
  final int userRating;         
  final String reviewText;      
  final DateTime timestamp;

  const UserReview({
    required this.movieId,
    required this.movieTitle,
    required this.userRating,
    required this.reviewText,
    required this.timestamp,
  });

  bool get hasRating => userRating > 0;
  bool get isPositive => userRating >= 7;
  bool get hasReviewText => reviewText.trim().isNotEmpty;

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      movieId: json['movieId'] ?? '',
      movieTitle: json['movieTitle'] ?? 'Unknown',
      userRating: json['userRating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'userRating': userRating,
      'reviewText': reviewText,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  UserReview copyWith({
    String? movieId,
    String? movieTitle,
    int? userRating,
    String? reviewText,
    DateTime? timestamp,
  }) {
    return UserReview(
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      userRating: userRating ?? this.userRating,
      reviewText: reviewText ?? this.reviewText,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}