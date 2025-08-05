/// API configuration constants for external services
class ApiConfig {
  // Google Vision API Configuration
  static const String googleVisionApiKey = 'YOUR_GOOGLE_VISION_API_KEY_HERE';
  static const String googleVisionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  // OpenAI API Configuration
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String openAiModel = 'gpt-4o';
  
  // API request timeouts (in seconds)
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Cost optimization settings
  static const int maxImageSizeBytes = 4 * 1024 * 1024; // 4MB
  static const double imageCompressionQuality = 0.8;
  
  /// Validate if API keys are properly configured
  static bool get isGoogleVisionConfigured => 
      googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY_HERE' && 
      googleVisionApiKey.isNotEmpty;
  
  static bool get isOpenAiConfigured => 
      openAiApiKey != 'YOUR_OPENAI_API_KEY_HERE' && 
      openAiApiKey.isNotEmpty;
  
  static bool get isFullyConfigured => 
      isGoogleVisionConfigured && isOpenAiConfigured;
}