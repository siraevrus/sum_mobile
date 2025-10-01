import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/receipt_entity.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

@freezed
class ReceiptModel with _$ReceiptModel {
  const factory ReceiptModel({
    required int id,
    required String name,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'producer_id', fromJson: _parseId) int? producerId,
    required Map<String, dynamic> attributes,
    @JsonKey(name: 'calculated_volume', fromJson: _parseCalculatedVolume) double? calculatedVolume,
    @JsonKey(name: 'quantity', fromJson: _parseQuantity) required int quantity,
    @JsonKey(fromJson: _parseStatus) required ReceiptStatus status,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date', fromJson: _parseDate) DateTime? shippingDate,
    @JsonKey(name: 'expected_arrival_date', fromJson: _parseDate) DateTime? expectedArrivalDate,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'document_path', fromJson: _parseDocumentPath) String? documentPath,
    String? notes,
    @JsonKey(name: 'created_by', fromJson: _parseId) int? createdBy,
    @JsonKey(name: 'created_at', fromJson: _parseDateTime) required DateTime createdAt,
    @JsonKey(name: 'updated_at', fromJson: _parseDateTime) required DateTime updatedAt,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);

  const ReceiptModel._();

  /// Convert to domain entity
  ReceiptEntity toEntity() {
    return ReceiptEntity(
      id: id,
      name: name,
      productTemplateId: productTemplateId,
      warehouseId: warehouseId,
      producerId: producerId,
      attributes: attributes,
      calculatedVolume: calculatedVolume,
      quantity: quantity,
      status: status,
      shippingLocation: shippingLocation,
      shippingDate: shippingDate,
      expectedArrivalDate: expectedArrivalDate,
      transportNumber: transportNumber,
      documentPath: documentPath,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// Helper parsing functions
int _parseQuantity(dynamic value) {
  print('🔵 _parseQuantity: Получено значение: $value, тип: ${value.runtimeType}');
  if (value == null) {
    print('🔴 _parseQuantity: Значение null, возвращаем 0');
    return 0;
  }
  if (value is int) {
    print('🟢 _parseQuantity: Значение int = $value');
    return value;
  }
  if (value is double) {
    print('🟢 _parseQuantity: Значение double = $value, преобразуем в int');
    return value.toInt();
  }
  if (value is String) {
    // Сначала пробуем парсить как int
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      print('🟢 _parseQuantity: String "$value" успешно распарсен как int = $parsedInt');
      return parsedInt;
    }
    
    // Если не получилось, пробуем как double (для строк типа "23233.000")
    final parsedDouble = double.tryParse(value);
    if (parsedDouble != null) {
      final result = parsedDouble.toInt();
      print('🟢 _parseQuantity: String "$value" распарсен как double = $parsedDouble, преобразован в int = $result');
      return result;
    }
    
    print('🔴 _parseQuantity: String "$value" не удалось распарсить, возвращаем 0');
    return 0;
  }
  print('🔴 _parseQuantity: Неизвестный тип ${value.runtimeType}, возвращаем 0');
  return 0;
}

ReceiptStatus _parseStatus(dynamic value) {
  if (value == null || value is! String) return ReceiptStatus.inTransit;
  
  switch (value) {
    case 'in_transit':
      return ReceiptStatus.inTransit;
    case 'for_receipt':
      return ReceiptStatus.forReceipt;
    case 'in_stock':
      return ReceiptStatus.inStock;
    default:
      return ReceiptStatus.inTransit;
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

String? _parseDocumentPath(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    // Если массив пустой, возвращаем null
    if (value.isEmpty) return null;
    // Если массив не пустой, берем первый элемент
    return value.first?.toString();
  }
  if (value is String) {
    return value.isEmpty ? null : value;
  }
  return null;
}

double? _parseCalculatedVolume(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? _parseId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}