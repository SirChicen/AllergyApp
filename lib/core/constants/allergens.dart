/// List of the 11 major allergens as defined by Health Canada and FDA
class AllergenConstants {
  static const List<String> majorAllergens = [
    'peanuts',
    'tree_nuts',
    'sesame',
    'milk',
    'egg',
    'fish',
    'shellfish',
    'soy',
    'wheat',
    'mustard',
    'sulphites',
  ];

  /// Human-readable allergen names for UI display
  static const Map<String, String> allergenDisplayNames = {
    'peanuts': 'Peanuts',
    'tree_nuts': 'Tree Nuts',
    'sesame': 'Sesame',
    'milk': 'Milk/Dairy',
    'egg': 'Eggs',
    'fish': 'Fish',
    'shellfish': 'Shellfish',
    'soy': 'Soy',
    'wheat': 'Wheat/Gluten',
    'mustard': 'Mustard',
    'sulphites': 'Sulphites',
  };

  /// Detailed descriptions for allergen education
  static const Map<String, String> allergenDescriptions = {
    'peanuts': 'Ground nuts, peanut oil, peanut butter, and peanut-derived ingredients',
    'tree_nuts': 'Almonds, walnuts, cashews, pistachios, hazelnuts, and other tree nuts',
    'sesame': 'Sesame seeds, sesame oil, tahini, and sesame-derived ingredients',
    'milk': 'Dairy products including milk, cheese, butter, cream, and lactose',
    'egg': 'Chicken eggs and egg-derived ingredients in all forms',
    'fish': 'All finfish species and fish-derived ingredients',
    'shellfish': 'Crustaceans (crab, lobster, shrimp) and mollusks (clams, mussels)',
    'soy': 'Soybeans, soy sauce, tofu, tempeh, and soy-derived ingredients',
    'wheat': 'Wheat flour, gluten, and wheat-derived ingredients',
    'mustard': 'Mustard seeds, mustard powder, and prepared mustard',
    'sulphites': 'Sulfur dioxide and sulfite preservatives',
  };

  /// Hidden sources of allergens that might not be obvious
  static const Map<String, List<String>> hiddenSources = {
    'milk': ['butter', 'cream', 'cheese', 'lactose', 'casein', 'whey'],
    'egg': ['albumin', 'lecithin', 'mayonnaise'],
    'wheat': ['flour', 'gluten', 'seitan', 'bulgur', 'couscous'],
    'soy': ['soy sauce', 'tofu', 'tempeh', 'miso', 'edamame'],
    'tree_nuts': ['marzipan', 'nougat', 'praline', 'almond extract'],
    'fish': ['anchovies', 'fish sauce', 'worcestershire sauce'],
    'shellfish': ['crab extract', 'lobster bisque', 'shrimp paste'],
  };
}

/// Safety rating levels for menu items
enum SafetyRating {
  safe,     // Green - No allergens detected
  caution,  // Yellow - Possible allergens or uncertain
  avoid,    // Red - Contains user's allergens
}

/// App-wide constants
class AppConstants {
  static const String appName = 'Allergy App';
  static const String appVersion = '1.0.0';
  
  // API configuration (to be filled with actual values)
  static const String googleVisionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
  static const String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Database constants
  static const String databaseName = 'allergy_app.db';
  static const int databaseVersion = 1;
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
}