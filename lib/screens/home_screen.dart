import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../core/constants/allergens.dart';
import '../core/services/claude_service.dart';
import '../core/database/database_helper.dart';
import '../core/providers/theme_provider.dart';
import 'results_screen.dart';
import 'allergen_settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ClaudeService _claudeService = ClaudeService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<String> _userAllergens = [];
  bool _isProcessing = false;
  DateTime? _processingStartTime;
  Timer? _progressTimer;
  int _currentAnalysisStep = 0; // 0-3 for the 4 steps

  @override
  void initState() {
    super.initState();
    _loadUserAllergens();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final allergens = prefs.getStringList('selected_allergens') ?? [];
    setState(() {
      _userAllergens = allergens;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Add haptic feedback for better user experience
      if (source == ImageSource.camera) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 3000,
        maxHeight: 3000,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        // Success haptic feedback
        HapticFeedback.lightImpact();
        await _processImage(File(image.path));
      }
    } catch (e) {
      // Error haptic feedback
      HapticFeedback.heavyImpact();
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _processingStartTime = DateTime.now();
      _currentAnalysisStep = 0;
    });

    // Start timer to update progress indicators with controlled timing
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted && _isProcessing && _currentAnalysisStep < 2) {
        setState(() {
          _currentAnalysisStep++;
        });
      }
    });

    try {
      // Set step to "Checking for allergens" before API call
      setState(() {
        _currentAnalysisStep = 2;
      });
      
      final analysisResult = await _claudeService.analyzeMenuImage(
        imageFile,
        _userAllergens,
      );
      
      // Set final step "Preparing results"
      setState(() {
        _currentAnalysisStep = 3;
      });
      
      // Brief delay for final step
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        // Show mandatory naming dialog before saving
        final menuName = await _showMandatoryNamingDialog(analysisResult.restaurantName);
        
        if (menuName != null) {
          // Save analysis to database with user-provided name
          await _databaseHelper.saveAnalysis(
            result: analysisResult,
            imagePath: imageFile.path,
            userAllergens: _userAllergens,
            restaurantName: analysisResult.restaurantName,
            userMenuName: menuName,
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                result: analysisResult,
                imageFile: imageFile,
                savedMenuName: menuName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Analysis failed: $e');
    } finally {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStartTime = null;
          _currentAnalysisStep = 0;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatorInfoDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person, 
                color: isDark ? Colors.blue.shade300 : Colors.blue, 
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Meet James', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, I\'m James, and like many people, I\'ve struggled with allergies for most of my life. From navigating hidden ingredients to dealing with unexpected reactions, I know how stressful it can be to stay safe while still enjoying everyday life.',
                style: TextStyle(
                  fontSize: 14, 
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'I created this app because I wanted a simple, reliable tool that helps people like you and I manage allergies with confidence. My goal is to make it easier to find safe foods anywhere you go.',
                style: TextStyle(
                  fontSize: 14, 
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This isn\'t just another app. It\'s built from lived experience, with the hope of making the allergy journey a little less overwhelming and a lot more manageable.',
                style: TextStyle(
                  fontSize: 14, 
                  height: 1.5, 
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
              foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Thanks, James!', 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showMandatoryNamingDialog(String? suggestedName) async {
    final TextEditingController controller = TextEditingController(
      text: '', // Start with empty input box
    );
    bool hasError = false;
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Can't dismiss without naming
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.save, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Name This Menu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Give this menu analysis a name so you can find it later:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'e.g. "McDonald\'s Downtown" or "Lunch Meeting"',
                  border: const OutlineInputBorder(),
                  errorText: hasError ? 'Menu name is required' : null,
                  prefixIcon: const Icon(Icons.restaurant_menu),
                ),
                maxLength: 50,
                onChanged: (value) {
                  if (hasError && value.trim().isNotEmpty) {
                    setState(() => hasError = false);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel analysis
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  setState(() => hasError = true);
                } else {
                  Navigator.of(context).pop(name);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leadingWidth: 120,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showCreatorInfoDialog();
                },
                tooltip: 'About the creator',
                padding: const EdgeInsets.all(8),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.green, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                tooltip: 'History',
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        title: Text(
          'AllerAI',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    themeProvider.toggleTheme();
                  },
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.purple),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllergenSettingsScreen(),
                  ),
                );
                if (result == true) {
                  _loadUserAllergens();
                }
              },
            ),
          ),
        ],
      ),
      body: _isProcessing 
          ? _buildProcessingView()
          : _buildMainView(),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated progress indicator
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    Icons.menu_book,
                    size: 40,
                    color: Colors.green.shade300,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Processing steps indicator
            Column(
              children: [
                _buildProcessingStep('Reading menu text...', 0),
                const SizedBox(height: 8),
                _buildProcessingStep('Identifying ingredients...', 1),
                const SizedBox(height: 8),
                _buildProcessingStep('Checking for allergens...', 2),
                const SizedBox(height: 8),
                _buildProcessingStep('Preparing results...', 3),
              ],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStep(String text, int stepIndex) {
    // Use controlled step progression
    if (!_isProcessing) {
      return _buildStepIndicator(text, false, false);
    }
    
    final isActive = stepIndex <= _currentAnalysisStep;
    final isCompleted = stepIndex < _currentAnalysisStep;
    
    return _buildStepIndicator(text, isActive, isCompleted);
  }

  Widget _buildStepIndicator(String text, bool isActive, bool isCompleted) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? Colors.green.shade300 
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : isActive
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isActive 
                ? (isDark ? Colors.white : Colors.grey.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Allergen Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                if (_userAllergens.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _userAllergens.map((allergen) {
                      final displayName = AllergenConstants.allergenDisplayNames[allergen] ?? allergen;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    'No allergens selected',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Main scanning section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  'Scan a Menu',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Take a photo of a restaurant menu to analyze it for allergens',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Scan button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showImageSourceDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Scan Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Safety reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Always verify with restaurant staff. This app provides guidance only.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}