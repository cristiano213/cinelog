class CinemaNote {
  final String cinemaName;      
  final String note;            
  final double avgPriceEur;     
  final int visitCount;         
  final DateTime lastVisit;

  const CinemaNote({
    required this.cinemaName,
    required this.note,
    required this.avgPriceEur,
    required this.visitCount,
    required this.lastVisit,
  });

  String get frequencyLabel => '$visitCount volte';

  factory CinemaNote.fromJson(Map<String, dynamic> json) {
    return CinemaNote(
      cinemaName: json['cinemaName'] ?? 'Unknown',
      note: json['note'] ?? '',
      avgPriceEur: (json['avgPriceEur'] ?? 0.0).toDouble(),
      visitCount: json['visitCount'] ?? 0,
      lastVisit: DateTime.tryParse(json['lastVisit'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cinemaName': cinemaName,
      'note': note,
      'avgPriceEur': avgPriceEur,
      'visitCount': visitCount,
      'lastVisit': lastVisit.toIso8601String(),
    };
  }

  CinemaNote copyWith({
    String? cinemaName,
    String? note,
    double? avgPriceEur,
    int? visitCount,
    DateTime? lastVisit,
  }) {
    return CinemaNote(
      cinemaName: cinemaName ?? this.cinemaName,
      note: note ?? this.note,
      avgPriceEur: avgPriceEur ?? this.avgPriceEur,
      visitCount: visitCount ?? this.visitCount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}