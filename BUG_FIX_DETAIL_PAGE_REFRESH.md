# Bug Fix: Detail Page Not Refreshing After Product Edit

## Problem Description

When you:
1. Go to "Поступление товара" (Products Inflow)
2. Open product preview/detail page
3. Edit the product (click edit button)
4. Return to preview page

**Issue:** The product data on the preview page was not updating with the changes made in the edit form. The page showed stale data instead of the updated values.

---

## Root Cause

The `_refreshProductData()` method in both detail pages had two issues:

### Issue 1: Missing Include Parameters
```dart
// BEFORE (broken)
final response = await dio.get('/products/${_currentProduct!.id}');

// AFTER (fixed)
final response = await dio.get(
  '/products/${_currentProduct!.id}',
  queryParameters: {
    'include': 'template,warehouse,creator,producer'
  }
);
```

**Problem:** Without the `include` parameter, related data (warehouse, producer, template) was not being loaded from the API. This caused related object fields to remain empty even after update.

### Issue 2: Incomplete Response Parsing
```dart
// BEFORE (broken)
if (response.data is Map<String, dynamic>) {
  final data = response.data as Map<String, dynamic>;
  if (data['success'] == true && data['data'] != null) {
    final productData = data['data'] as Map<String, dynamic>;
    _currentProduct = ProductInflowModel.fromJson(productData);
  }
}

// AFTER (fixed)
if (response.data is Map<String, dynamic>) {
  final data = response.data as Map<String, dynamic>;
  
  AcceptanceModel? updatedProduct;
  if (data['success'] == true && data['data'] != null) {
    updatedProduct = AcceptanceModel.fromJson(data['data'] as Map<String, dynamic>);
  } else if (data['product'] != null) {
    // Alternative format with 'product' key
    updatedProduct = AcceptanceModel.fromJson(data['product'] as Map<String, dynamic>);
  } else {
    // Direct format without wrapper
    updatedProduct = AcceptanceModel.fromJson(data);
  }
}
```

**Problem:** The old code only handled one response format. If the API returned a different format, the parsing would fail silently and the data wouldn't update.

---

## Solution Implemented

Updated `_refreshProductData()` method in both:
1. `lib/features/products_inflow/presentation/pages/product_inflow_detail_page.dart`
2. `lib/features/acceptance/presentation/pages/acceptance_detail_page.dart`

**Changes:**
1. Added `include` query parameters to load related data
2. Added robust response parsing for multiple API response formats
3. Added proper `setState()` call to trigger UI rebuild

---

## How It Works Now

```
User edits product
   ↓
Form validates and sends update request to API
   ↓
API updates product and returns updated data
   ↓
User clicks back/returns from edit screen
   ↓
Navigator.pop(true) triggers in edit form
   ↓
Detail page catches result == true
   ↓
Detail page calls _refreshProductData()
   ↓
_refreshProductData() fetches updated product with include parameters
   ↓
Product is parsed and _currentProduct is updated
   ↓
setState(() {}) triggers rebuild
   ↓
UI displays fresh data ✅
```

---

## Data Flow

### Before Fix
```
Detail Page → Edit Form → API Update
                             ↓
                          Update OK
                             ↓
                          Return true
                             ↓
Detail Page receives true
   ↓
Calls _refreshProductData()
   ↓
Fetches /products/{id} WITHOUT include params
   ↓
Parsing fails or returns incomplete data
   ↓
UI doesn't update ❌
```

### After Fix
```
Detail Page → Edit Form → API Update
                             ↓
                          Update OK
                             ↓
                          Return true
                             ↓
Detail Page receives true
   ↓
Calls _refreshProductData()
   ↓
Fetches /products/{id}?include=template,warehouse,creator,producer
   ↓
Complete product data received
   ↓
Robust parsing handles all response formats
   ↓
setState() triggers rebuild
   ↓
UI displays fresh data ✅
```

---

## Files Modified

### 1. lib/features/products_inflow/presentation/pages/product_inflow_detail_page.dart
- **Method:** `_refreshProductData()` (lines 39-60)
- **Changes:**
  - Added include query parameters
  - Improved response parsing with multiple format support
  - Added comments for clarity

### 2. lib/features/acceptance/presentation/pages/acceptance_detail_page.dart
- **Method:** `_refreshProductData()` (lines 97-116)
- **Changes:**
  - Same as above

---

## Testing

### Test Scenario
1. Navigate to "Поступление товара"
2. Click on a product to open detail view
3. Click the edit button (pencil icon)
4. Change some values (e.g., warehouse, quantity, attributes)
5. Click save
6. Return to detail view

**Expected Result:** ✅
- All changed values are displayed correctly
- Related data (warehouse name, producer name) shows updated values
- Volume calculation reflects the updated values
- Product name is regenerated based on new attributes

**Before Fix:** ❌
- Fields showed old values
- Related data remained empty
- Volume didn't update

---

## API Endpoints Used

### Get Product with Related Data
```
GET /products/{id}?include=template,warehouse,creator,producer
```

Response includes:
- Product base data
- Product template with attributes
- Warehouse information
- Creator user info
- Producer information

---

## Technical Details

### Query Parameters
The `include` parameter tells the API to eager-load relationships instead of lazy-loading them. This is essential because:

1. **Warehouse data:** If not included, warehouse will be null in the response, and display field shows "Не указан"
2. **Producer data:** Same issue for producer information
3. **Template data:** Needed for attribute name mapping
4. **Creator data:** Shows who created the product

### Response Format Handling
The updated code handles three potential response formats:

1. **Wrapped format:** `{success: true, data: {...product}}`
2. **Product key format:** `{product: {...product}}`
3. **Direct format:** `{...product}` (direct product data)

This makes the code resilient to API changes and different endpoint variations.

---

## Performance Impact
- **Minimal:** Only adds one API call on edit completion (already happening)
- **Network:** One additional query parameter string
- **Processing:** Slightly more robust parsing logic, negligible impact

---

## Backward Compatibility
✅ Fully backward compatible
- No changes to data models
- No changes to API contracts
- Improved parsing handles existing response formats

---

## Related Issues Fixed
- ✅ Detail page not showing updated warehouse after edit
- ✅ Detail page not showing updated related data (producer, creator)
- ✅ Volume calculation not updating if formula inputs changed
- ✅ Attribute values not showing if format varies

