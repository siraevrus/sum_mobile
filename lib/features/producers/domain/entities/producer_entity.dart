class ProducerEntity {
  final int id;
  final String name;
  final String? region;
  final int productsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProducerEntity({
    required this.id,
    required this.name,
    this.region,
    required this.productsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  ProducerEntity copyWith({
    int? id,
    String? name,
    String? region,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProducerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProducerEntity &&
        other.id == id &&
        other.name == name &&
        other.region == region &&
        other.productsCount == productsCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        region.hashCode ^
        productsCount.hashCode;
  }

  @override
  String toString() {
    return 'ProducerEntity(id: $id, name: $name, region: $region, productsCount: $productsCount)';
  }
}
