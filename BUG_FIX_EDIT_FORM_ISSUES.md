# Bug Fix: Edit Form Issues - Warehouse Display and Volume Calculation

## Issues Fixed

### 1. ❌ Warehouse Not Displayed When Editing Products
**Problem:** When editing a product, the warehouse dropdown showed as empty/null even though a warehouse was selected in the database.

**Root Cause:** The dropdown only displayed warehouses from the current `_warehouses` list. If the product's warehouse was from a different company or wasn't loaded, it wouldn't appear in the dropdown items.

**Solution:** Added logic to always include the selected warehouse in the dropdown items, even if it's not in the current list:

```dart
// Always include the selected warehouse even if not in the list
if (_selectedWarehouseId != null && !_warehouses.any((w) => w.id == _selectedWarehouseId))
  DropdownMenuItem(
    value: _selectedWarehouseId,
    child: Text('Склад #$_selectedWarehouseId'),
  ),
```

**Files Changed:**
- `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart` (lines 485-513)
- `lib/features/acceptance/presentation/pages/acceptance_form_page.dart` (lines 658-686)

---

### 2. ❌ Calculated Volume Not Shown When Editing Products
**Problem:** When opening an edit form, the "Рассчитанный объем" (Calculated Volume) field remained empty even though the product had a volume value.

**Root Cause:** The method `_calculateNameAndVolume()` was only called when:
- User changed quantity (via `onChanged` callback)
- User selected a new template (via `_onTemplateChanged`)
- User changed an attribute (via `_onAttributeChanged`)

But it was **NOT** called after loading template attributes during form initialization, so the volume wasn't calculated from the stored values.

**Solution:** Added call to `_calculateNameAndVolume()` after successfully loading template attributes:

```dart
Future<void> _loadTemplateAttributes() async {
  // ... load attributes ...
  
  // Calculate name and volume after loading attributes
  _calculateNameAndVolume();
  
  setState(() {});
}
```

**Files Changed:**
- `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart` (lines 153-187)
- `lib/features/acceptance/presentation/pages/acceptance_form_page.dart` (lines 216-250)

---

## What Was Wrong

### Before Fixes:

When editing a product:
1. Warehouse dropdown: Shows EMPTY ❌ (user can't see current selection)
2. Volume field: Shows EMPTY ❌ (calculated value not shown)
3. Name field: Shows EMPTY ❌ (auto-generated name not shown)

### After Fixes:

When editing a product:
1. Warehouse dropdown: Shows current warehouse ✅ (user can see and change it)
2. Volume field: Shows calculated value ✅ (formula applied to current values)
3. Name field: Shows auto-generated name ✅ (based on current attributes)

---

## Technical Details

### Issue 1: Warehouse Dropdown Fix

**Pattern used:** Same as in "Товары в пути" (Products In Transit) - includes a fallback option

```dart
// BEFORE (broken)
items: [
  const DropdownMenuItem(value: null, child: Text('Выберите склад')),
  ..._warehouses.map((warehouse) => DropdownMenuItem(
    value: warehouse.id,
    child: Text(warehouse.name),
  )),
],

// AFTER (fixed)
items: [
  const DropdownMenuItem(value: null, child: Text('Выберите склад')),
  if (_selectedWarehouseId != null && !_warehouses.any((w) => w.id == _selectedWarehouseId))
    DropdownMenuItem(
      value: _selectedWarehouseId,
      child: Text('Склад #$_selectedWarehouseId'),
    ),
  ..._warehouses.map((warehouse) => DropdownMenuItem(
    value: warehouse.id,
    child: Text(warehouse.name),
  )),
],
```

### Issue 2: Volume Calculation Fix

The calculation flow now works correctly:

```
Edit Form Opens
    ↓
Load Template & Attributes
    ↓
_calculateNameAndVolume() called ← THIS WAS MISSING
    ↓
Fill fields with calculated values
    ↓
User sees current name and volume ✅
```

---

## Testing Recommendations

### Test 1: Edit Product in "Поступление товара"
1. Create a product in Warehouse A
2. Open edit form
3. ✅ Verify warehouse A is displayed in dropdown (not empty)
4. ✅ Verify calculated volume is shown (not empty)
5. ✅ Verify auto-generated name is shown
6. Change warehouse to B
7. Save and verify it saved correctly

### Test 2: Edit Product in "Приемка"
Same steps as Test 1 but for Acceptance section

### Test 3: Change Attributes During Edit
1. Edit an existing product
2. Change attribute values
3. ✅ Verify name recalculates
4. ✅ Verify volume recalculates with new formula

---

## Impact

- ✅ Users can now properly edit products and see current values
- ✅ Warehouse changes are visible and saveable
- ✅ Volume calculations work correctly on form load
- ✅ No data loss - all fields now display correctly
- ✅ Consistent with other product forms in the app

---

## Files Modified

1. `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`
   - Added warehouse fallback in dropdown (4 lines)
   - Added volume calculation after loading (2 lines)

2. `lib/features/acceptance/presentation/pages/acceptance_form_page.dart`
   - Added warehouse fallback in dropdown (4 lines)
   - Added volume calculation after loading (2 lines)

---

## Build Information

- ✅ No model changes required
- ✅ No API changes required
- ✅ Pure UI/Logic fix
- ✅ Backward compatible
- ✅ All tests passing
