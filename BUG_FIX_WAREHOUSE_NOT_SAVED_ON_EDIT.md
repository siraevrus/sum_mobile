# Bug Fix: Warehouse Not Saved When Editing Products

## Problem Description
When editing products in the "Поступление товара" (Products Inflow) and "Приемка" (Acceptance) sections, the warehouse field was not being saved even though the user could change it.

## Root Cause
The `UpdateProductInflowRequest` and `UpdateAcceptanceRequest` models were missing the `warehouseId` field, so even though the user selected a different warehouse in the UI, it was not being sent to the API.

### Comparison with Other Features
- ✅ **Products In Transit** ("Товары в пути") - Already had `warehouseId` in `UpdateProductInTransitRequest` (working correctly)
- ❌ **Products Inflow** ("Поступление товара") - Missing `warehouseId` in `UpdateProductInflowRequest` (broken)
- ❌ **Acceptance** ("Приемка") - Missing `warehouseId` in `UpdateAcceptanceRequest` (broken)

## Solution Applied

### 1. Updated `UpdateProductInflowRequest` Model
**File:** `lib/features/products_inflow/data/models/product_inflow_model.dart`

Added `warehouseId` field:
```dart
const factory UpdateProductInflowRequest({
  // ... other fields ...
  @JsonKey(name: 'warehouse_id') int? warehouseId,
  // ... other fields ...
}) = _UpdateProductInflowRequest;
```

### 2. Updated `_updateProduct()` in ProductInflowFormPage
**File:** `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`

Added `warehouseId` to the update request:
```dart
final updateRequest = UpdateProductInflowRequest(
  // ... other fields ...
  warehouseId: _selectedWarehouseId,
  // ... other fields ...
);
```

### 3. Updated `UpdateAcceptanceRequest` Model
**File:** `lib/features/acceptance/data/models/acceptance_model.dart`

Added `warehouseId` field:
```dart
const factory UpdateAcceptanceRequest({
  // ... other fields ...
  @JsonKey(name: 'warehouse_id') int? warehouseId,
  // ... other fields ...
}) = _UpdateAcceptanceRequest;
```

### 4. Updated `_updateProduct()` in AcceptanceFormPage
**File:** `lib/features/acceptance/presentation/pages/acceptance_form_page.dart`

Added `warehouseId` to the update request:
```dart
final request = UpdateAcceptanceRequest(
  // ... other fields ...
  warehouseId: _selectedWarehouseId,
  // ... other fields ...
);
```

## Files Changed
1. `lib/features/products_inflow/data/models/product_inflow_model.dart`
2. `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`
3. `lib/features/acceptance/data/models/acceptance_model.dart`
4. `lib/features/acceptance/presentation/pages/acceptance_form_page.dart`

## Testing
After these changes:
1. ✅ Users can now change the warehouse when editing products in "Поступление товара"
2. ✅ Users can now change the warehouse when editing products in "Приемка"
3. ✅ The warehouse selection is properly sent to the API and persisted
4. ✅ The behavior now matches the "Товары в пути" section

## Generation
Freezed code was regenerated using:
```bash
dart run build_runner build --delete-conflicting-outputs
```
