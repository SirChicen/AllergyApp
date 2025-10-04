import '../constants/allergens.dart';

class AnalysisResult {
  final String? restaurantName;
  final String? cuisineType;
  final SafetyRating overallSafety;
  final int confidence;
  final List<String> detectedAllergens;
  final List<MenuItem> menuItems;
  final String generalNotes;
  final List<String> followUpQuestions;
  final DateTime analyzedAt;

  AnalysisResult({
    this.restaurantName,
    this.cuisineType,
    required this.overallSafety,
    required this.confidence,
    required this.detectedAllergens,
    required this.menuItems,
    required this.generalNotes,
    required this.followUpQuestions,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantName': restaurantName,
      'cuisineType': cuisineType,
      'overallSafety': overallSafety.name,
      'confidence': confidence,
      'detectedAllergens': detectedAllergens,
      'menuItems': menuItems.map((item) => item.toJson()).toList(),
      'generalNotes': generalNotes,
      'followUpQuestions': followUpQuestions,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    SafetyRating safety;
    switch (json['overallSafety']) {
      case 'safe':
        safety = SafetyRating.safe;
        break;
      case 'avoid':
        safety = SafetyRating.avoid;
        break;
      default:
        safety = SafetyRating.caution;
    }

    return AnalysisResult(
      restaurantName: json['restaurantName'],
      cuisineType: json['cuisineType'],
      overallSafety: safety,
      confidence: json['confidence'] ?? 0,
      detectedAllergens: List<String>.from(json['detectedAllergens'] ?? []),
      menuItems: (json['menuItems'] as List<dynamic>?)
          ?.map((item) => MenuItem.fromJson(item))
          .toList() ?? [],
      generalNotes: json['generalNotes'] ?? '',
      followUpQuestions: List<String>.from(json['followUpQuestions'] ?? []),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }
}

class MenuItem {
  final String name;
  final String description;
  final SafetyRating safety;
  final List<String> detectedAllergens;
  final String reasoning;
  final List<String> followUpQuestions;
  final List<String> alternatives;

  MenuItem({
    required this.name,
    required this.description,
    required this.safety,
    required this.detectedAllergens,
    required this.reasoning,
    required this.followUpQuestions,
    this.alternatives = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'safety': safety.name,
      'detectedAllergens': detectedAllergens,
      'reasoning': reasoning,
      'followUpQuestions': followUpQuestions,
      'alternatives': alternatives,
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    SafetyRating safety;
    switch (json['safety']) {
      case 'safe':
        safety = SafetyRating.safe;
        break;
      case 'avoid':
        safety = SafetyRating.avoid;
        break;
      default:
        safety = SafetyRating.caution;
    }

    return MenuItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      safety: safety,
      detectedAllergens: List<String>.from(json['detectedAllergens'] ?? []),
      reasoning: json['reasoning'] ?? '',
      followUpQuestions: List<String>.from(json['followUpQuestions'] ?? []),
      alternatives: List<String>.from(json['alternatives'] ?? []),
    );
  }
}

class AllergenProfile {
  final List<String> selectedAllergens;
  final DateTime createdAt;
  final DateTime updatedAt;

  AllergenProfile({
    required this.selectedAllergens,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'selectedAllergens': selectedAllergens,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AllergenProfile.fromJson(Map<String, dynamic> json) {
    return AllergenProfile(
      selectedAllergens: List<String>.from(json['selectedAllergens'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  AllergenProfile copyWith({
    List<String>? selectedAllergens,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllergenProfile(
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}