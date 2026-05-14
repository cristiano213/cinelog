class FinanceLedgerEntry {
  final String id;              
  final String movieId;         
  final String movieTitle;      
  final String cinema;          
  final double priceEur;        
  final DateTime dateTime;      
  final int count;              

  const FinanceLedgerEntry({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinema,
    required this.priceEur,
    required this.dateTime,
    this.count = 1,
  });

  String get formattedPrice => '€${priceEur.toStringAsFixed(2)}';
  String get monthKey => '${dateTime.year}-${dateTime.month}';  
  int get dayOfMonth => dateTime.day;
  double get totalPrice => priceEur * count;

  factory FinanceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return FinanceLedgerEntry(
      id: json['id'] ?? '',
      movieId: json['movieId'] ?? '',
      movieTitle: json['movieTitle'] ?? 'Unknown',
      cinema: json['cinema'] ?? 'Unknown Cinema',
      priceEur: (json['priceEur'] ?? 0.0).toDouble(),
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      count: json['count'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'cinema': cinema,
      'priceEur': priceEur,
      'dateTime': dateTime.toIso8601String(),
      'count': count,
    };
  }

  FinanceLedgerEntry copyWith({
    String? id,
    String? movieId,
    String? movieTitle,
    String? cinema,
    double? priceEur,
    DateTime? dateTime,
    int? count,
  }) {
    return FinanceLedgerEntry(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      cinema: cinema ?? this.cinema,
      priceEur: priceEur ?? this.priceEur,
      dateTime: dateTime ?? this.dateTime,
      count: count ?? this.count,
    );
  }
}