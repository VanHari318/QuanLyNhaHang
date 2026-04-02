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
    String? targetUnit,
    int orderQuantity = 1,
  }) {
    // 1. Calculate per-serving amount and multiply by order quantity
    double needed = (totalQuantityForBulk / bulkServings) * orderQuantity;
    
    // 2. Unit normalization:
    // If the bulk recipe uses g/ml but inventory is in kg/l, we MUST convert.
    final u = unit.toLowerCase();
    final tu = targetUnit?.toLowerCase() ?? '';

    // Gram -> Kilogram
    if (u == 'g' && (tu == 'kg' || totalQuantityForBulk >= 1000)) {
      needed /= 1000;
    }
    
    // Milliliter -> Liter
    if ((u == 'ml' || u == 'mlit' || u == 'mlitre') && 
        (tu == 'l' || tu == 'lít' || tu == 'lit' || totalQuantityForBulk >= 1000)) {
      needed /= 1000;
    }
    
    return needed;
  }
}
