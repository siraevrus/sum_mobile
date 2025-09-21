class ProducerModel {
  final int id;
  final String name;
  final String? region;
  final int productsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProducerModel({
    required this.id,
    required this.name,
    this.region,
    required this.productsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProducerModel.fromJson(Map<String, dynamic> json) {
    return ProducerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      region: json['region'] as String?,
      productsCount: json['products_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'products_count': productsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'region': region,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'region': region,
    };
  }

  ProducerModel copyWith({
    int? id,
    String? name,
    String? region,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProducerModel(
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
    return other is ProducerModel &&
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
    return 'ProducerModel(id: $id, name: $name, region: $region, productsCount: $productsCount)';
  }
}