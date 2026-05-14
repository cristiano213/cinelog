class Cinema {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  // Ci servirà per la UI della Dashboard o della ricerca
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km da te';

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Cinema Sconosciuto',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }

  Cinema copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) {
    return Cinema(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}