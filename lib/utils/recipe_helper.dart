/// Helper class to handle recipe calculations consistently with DatabaseService
class RecipeHelper {
  /// Calculates the needed quantity for a given number of servings
  /// based on bulk recipe data (usually for 100 servings).
  /// 
  /// This logic MUST match DatabaseService._deductInventoryForOrder exactly.
  static double calculateNeededQuantity({
    required double totalQuantityForBulk,
    required int bulkServings,
    required String unit,
    int orderQuantity = 1,
  }) {
    // 1. Calculate per-serving amount and multiply by order quantity
    double needed = (totalQuantityForBulk / bulkServings) * orderQuantity;
    
    // 2. Unit normalization:
    // If the bulk recipe uses g/ml but in large amounts (>=1000),
    // the system assumes inventory is in kg/l.
    // Reference: DatabaseService.dart lines 263-266
    if (totalQuantityForBulk >= 1000 && (unit == 'g' || unit == 'ml')) {
      needed = needed / 1000;
    }
    
    return needed;
  }
}
