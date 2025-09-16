import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../constants/allergens.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: 'YOUR_CLAUDE_API_KEY_HERE');
  static const String _model = 'claude-3-5-sonnet-20241022';

  Future<AnalysisResult> analyzeMenuImage(File imageFile, List<String> userAllergens) async {
    try {
      // Convert image to base64
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
Please analyze this menu image for food allergens. The user is allergic to: $allergenList

Instructions:
1. Extract all menu items with descriptions from the image
2. For each menu item, analyze if it contains or might contain any of the user's allergens
3. Be CONSERVATIVE but PRACTICAL - focus on real allergen risks, not superstitious contamination fears
4. Consider hidden sources of allergens (e.g., butter contains dairy, soy sauce contains soy)
5. Only flag cross-contamination for HIGH-RISK scenarios (shared fryer for breaded items, not general "air fryer contamination")
6. Rate each item as SAFE, CAUTION, or AVOID
7. Include specific follow-up questions for restaurant staff when ingredients are unclear

Please respond in this exact JSON format:
{
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
      "follow_up_questions": ["Question to ask staff about unclear ingredients"]
    }
  ],
  "general_notes": "Any additional observations",
  "follow_up_questions": ["Important questions to ask restaurant staff"]
}

Remember: Better to be overly cautious than miss a potential allergen. If ingredients are unclear or could be cross-contaminated, mark as CAUTION or AVOID.
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
        );
      }).toList();

      // Parse detected allergens
      final detectedAllergens = List<String>.from(data['detected_allergens'] ?? []);

      return AnalysisResult(
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
          ),
        ],
        generalNotes: 'Analysis failed: $e',
        followUpQuestions: [],
        analyzedAt: DateTime.now(),
      );
    }
  }
}