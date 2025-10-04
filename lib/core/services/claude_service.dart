import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../constants/allergens.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = 'your_anthropic_api_key_here';
  static const String _model = 'claude-3-5-sonnet-20241022';

  Future<AnalysisResult> analyzeMenuImage(File imageFile, List<String> userAllergens) async {
    try {
      // Read and process image to maintain quality and orientation
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Get file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      // Create the prompt for Claude
      final prompt = _buildAnalysisPrompt(userAllergens);

      // Make API request to Claude
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mimeType,
                    'data': base64Image,
                  }
                },
                {
                  'type': 'text',
                  'text': prompt,
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final analysisText = responseData['content'][0]['text'] as String;
        
        return _parseAnalysisResult(analysisText, userAllergens);
      } else {
        throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  String _buildAnalysisPrompt(List<String> userAllergens) {
    final allergenList = userAllergens.map((allergen) {
      return AllergenConstants.allergenDisplayNames[allergen] ?? allergen;
    }).join(', ');

    return '''
Please analyze this ENTIRE menu image for food allergens. The user is allergic to: $allergenList

CRITICAL: You MUST find EVERY SINGLE menu item in this image. Do not miss any items.

Step-by-step process:
1. SCAN THE ENTIRE IMAGE systematically:
   - Start at the TOP LEFT corner
   - Read LEFT TO RIGHT across each section
   - Move DOWN row by row
   - Check ALL corners, sides, and sections
   - Look for items in columns, boxes, sections, categories
   - Include appetizers, mains, sides, desserts, drinks - EVERYTHING

2. For EVERY menu item found:
   - SEPARATE EACH ITEM INDIVIDUALLY - do NOT group items together
   - NO categories like "veggie sushis" or "fried items" - list each dish separately
   - Extract the exact item name (e.g., "California Roll", "Chicken Teriyaki", "Caesar Salad")
   - Include any description or ingredients listed
   - Analyze for allergen risks
   - Rate as SAFE, CAUTION, or AVOID

3. Be PRACTICAL but SLIGHTLY CAUTIOUS - focus on realistic allergen risks
4. Consider DIRECT ingredients: butter=dairy, bread=wheat, mayo=eggs, soy sauce=soy, cream=dairy, cheese=dairy
5. Rate items decisively: SAFE (clearly no allergens), AVOID (likely contains allergens), CAUTION (genuinely unclear ingredients only)
6. If an item LIKELY contains an allergen, mark it as AVOID, not CAUTION
7. Include 1-2 practical follow-up questions MAX per item, only for genuinely unclear ingredients that staff would know

VERIFY: Count how many items you found and double-check you didn't miss any sections of the menu.

CRITICAL INSTRUCTION: Each menu item MUST be listed separately. If you see "Appetizers: Spring Rolls, Dumplings, Salad", you must create separate entries for:
- Spring Rolls
- Dumplings  
- Salad
Do NOT create one entry called "Appetizers" or group them together.

Please respond in this exact JSON format:
{
  "restaurant_name": "Restaurant Name if visible on menu (or null)",
  "cuisine_type": "Type of cuisine if identifiable (or null)", 
  "overall_safety": "SAFE/CAUTION/AVOID",
  "confidence": 85,
  "detected_allergens": ["allergen1", "allergen2"],
  "menu_items": [
    {
      "name": "Item Name",
      "description": "Menu description if available",
      "safety": "SAFE/CAUTION/AVOID",
      "detected_allergens": ["allergen1"],
      "reasoning": "Why this rating was given",
      "follow_up_questions": ["Question to ask staff about unclear ingredients"],
      "alternatives": ["Alternative dish from this menu that might be safer (only if AVOID rating)"]
    }
  ],
  "general_notes": "Any additional observations",
  "follow_up_questions": ["Important questions to ask restaurant staff"]
}

Remember: Be decisive. If an item LIKELY has an allergen, mark it AVOID. Only use CAUTION for genuinely unclear cases. 

Good questions (1-2 max): "Is this made with butter?" "Does the sauce contain dairy?" 
Bad questions: "Are prep surfaces separate?" "Is equipment shared?" "Multiple detailed preparation questions"
''';
  }

  AnalysisResult _parseAnalysisResult(String analysisText, List<String> userAllergens) {
    try {
      // Try to extract JSON from the response
      final jsonStart = analysisText.indexOf('{');
      final jsonEnd = analysisText.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No valid JSON found in response');
      }
      
      final jsonString = analysisText.substring(jsonStart, jsonEnd);
      final data = jsonDecode(jsonString);

      // Parse overall safety
      final overallSafetyString = data['overall_safety']?.toString().toUpperCase() ?? 'CAUTION';
      SafetyRating overallSafety;
      switch (overallSafetyString) {
        case 'SAFE':
          overallSafety = SafetyRating.safe;
          break;
        case 'AVOID':
          overallSafety = SafetyRating.avoid;
          break;
        default:
          overallSafety = SafetyRating.caution;
      }

      // Parse menu items
      final menuItemsData = data['menu_items'] as List<dynamic>? ?? [];
      final menuItems = menuItemsData.map((item) {
        final safetyString = item['safety']?.toString().toUpperCase() ?? 'CAUTION';
        SafetyRating safety;
        switch (safetyString) {
          case 'SAFE':
            safety = SafetyRating.safe;
            break;
          case 'AVOID':
            safety = SafetyRating.avoid;
            break;
          default:
            safety = SafetyRating.caution;
        }

        return MenuItem(
          name: item['name']?.toString() ?? 'Unknown Item',
          description: item['description']?.toString() ?? '',
          safety: safety,
          detectedAllergens: List<String>.from(item['detected_allergens'] ?? []),
          reasoning: item['reasoning']?.toString() ?? '',
          followUpQuestions: List<String>.from(item['follow_up_questions'] ?? []),
          alternatives: List<String>.from(item['alternatives'] ?? []),
        );
      }).toList();

      // Parse detected allergens
      final detectedAllergens = List<String>.from(data['detected_allergens'] ?? []);

      return AnalysisResult(
        restaurantName: data['restaurant_name']?.toString(),
        cuisineType: data['cuisine_type']?.toString(),
        overallSafety: overallSafety,
        confidence: (data['confidence'] as num?)?.toInt() ?? 75,
        detectedAllergens: detectedAllergens,
        menuItems: menuItems,
        generalNotes: data['general_notes']?.toString() ?? '',
        followUpQuestions: List<String>.from(data['follow_up_questions'] ?? []),
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      // If parsing fails, create a fallback result
      return AnalysisResult(
        restaurantName: null,
        cuisineType: null,
        overallSafety: SafetyRating.caution,
        confidence: 50,
        detectedAllergens: [],
        menuItems: [
          MenuItem(
            name: 'Analysis Error',
            description: 'Could not properly analyze the menu. Please try again or verify with restaurant staff.',
            safety: SafetyRating.caution,
            detectedAllergens: [],
            reasoning: 'Technical error during analysis: $e',
            followUpQuestions: [],
            alternatives: [],
          ),
        ],
        generalNotes: 'Analysis failed: $e',
        followUpQuestions: [],
        analyzedAt: DateTime.now(),
      );
    }
  }
}