# AllerAI API Setup Instructions

## Claude API Configuration

To use the AllerAI app, you need to configure the Claude API service:

1. **Get your Claude API key**:
   - Visit the Anthropic Console: https://console.anthropic.com/
   - Sign up or log in to your account
   - Navigate to API Keys section
   - Generate a new API key

2. **Configure the API key**:
   - Open `lib/core/services/claude_service.dart`
   - Replace `'YOUR_CLAUDE_API_KEY_HERE'` with your actual API key:
   ```dart
   static const String _apiKey = 'sk-ant-api03-...'; // Your actual key
   ```

3. **Test the integration**:
   - Run the app on your device or simulator
   - Complete the allergen setup
   - Take a photo of a menu (or use a sample menu image)
   - The app should analyze the image and return safety ratings

## Important Notes

- **Keep your API key secure**: Never commit your actual API key to version control
- **API costs**: Claude API charges per token used. Menu analysis typically costs $0.01-0.10 per image
- **Rate limits**: Be mindful of API rate limits for your account tier
- **Error handling**: The app includes fallback handling if the API request fails

## Alternative Configuration (Recommended for production)

For production apps, store the API key securely using environment variables or secure storage:

1. Add `flutter_dotenv` to your dependencies
2. Create a `.env` file (add to .gitignore)
3. Load the API key at runtime

## Testing

The app includes basic error handling and will show a fallback analysis result if the Claude API is not properly configured or fails to respond.

## Troubleshooting

- **401 Unauthorized**: Check that your API key is correct
- **429 Rate Limited**: You've exceeded your API quota
- **Network errors**: Check your internet connection
- **Analysis timeouts**: Large images may take longer to process

For support, visit: https://docs.anthropic.com/claude/reference/