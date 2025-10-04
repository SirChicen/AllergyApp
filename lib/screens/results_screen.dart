import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../core/models/analysis_result.dart';
import '../core/constants/allergens.dart';
import '../core/services/claude_service.dart';
import '../core/database/database_helper.dart';

class ResultsScreen extends StatefulWidget {
  final AnalysisResult result;
  final File imageFile;
  final String? savedMenuName;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.imageFile,
    this.savedMenuName,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ImagePicker _picker = ImagePicker();
  final ClaudeService _claudeService = ClaudeService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  late AnalysisResult _currentResult;
  bool _isRescanning = false;
  String _searchQuery = '';
  String _userMenuName = '';
  List<MenuItem> _filteredMenuItems = [];

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
    _filteredMenuItems = _currentResult.menuItems;
    _userMenuName = widget.savedMenuName ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                Navigator.of(context).pop(null); // Cancel
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

  void _showMenuNameDialog() {
    final TextEditingController controller = TextEditingController(text: _userMenuName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this Menu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter a custom name for this menu',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              setState(() {
                _userMenuName = newName;
              });
              
              // Note: This only updates the display. The database
              // was already saved with the proper name during analysis.
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newName.isEmpty 
                      ? 'Menu name cleared' 
                      : 'Display name updated to "$newName"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _filterMenuItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMenuItems = _currentResult.menuItems;
      } else {
        _filteredMenuItems = _currentResult.menuItems.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase()) ||
                 item.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _quickRescan() async {
    setState(() {
      _isRescanning = true;
    });

    try {
      HapticFeedback.lightImpact();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 3000,
        maxHeight: 3000,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        // Get user allergens from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userAllergens = prefs.getStringList('selected_allergens') ?? [];
        
        final newResult = await _claudeService.analyzeMenuImage(
          File(image.path),
          userAllergens,
        );

        if (mounted) {
          // Show mandatory naming dialog for re-scan
          final menuName = await _showMandatoryNamingDialog(newResult.restaurantName);
          
          if (menuName != null) {
            // Save new analysis to database
            await _databaseHelper.saveAnalysis(
              result: newResult,
              imagePath: image.path,
              userAllergens: userAllergens,
              restaurantName: newResult.restaurantName,
              userMenuName: menuName,
            );
            
            setState(() {
              _currentResult = newResult;
              _userMenuName = menuName;
              _isRescanning = false;
            });
            
            // Update filtered items with new result
            _filterMenuItems(_searchQuery);
            
            HapticFeedback.lightImpact();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Menu re-scanned and saved!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            setState(() {
              _isRescanning = false;
            });
          }
        }
      } else {
        setState(() {
          _isRescanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRescanning = false;
        });
        HapticFeedback.heavyImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-scan failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Menu Analysis',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxHeight: 300,
                minHeight: 150,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                  cacheWidth: 800, // Optimize memory usage
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Restaurant info
            if (_currentResult.restaurantName != null || _currentResult.cuisineType != null || _userMenuName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User custom menu name or restaurant name
                    if (_userMenuName.isNotEmpty || _currentResult.restaurantName != null) ...[
                      Row(
                        children: [
                          Icon(
                            _userMenuName.isNotEmpty ? Icons.edit : Icons.restaurant, 
                            color: _userMenuName.isNotEmpty ? Colors.blue : Colors.green, 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _userMenuName.isNotEmpty ? _userMenuName : _currentResult.restaurantName!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.grey.shade600, size: 20),
                            onPressed: _showMenuNameDialog,
                          ),
                        ],
                      ),
                    ],
                    if (_currentResult.cuisineType != null) ...[
                      if (_currentResult.restaurantName != null) const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_dining, color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _currentResult.cuisineType!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Menu items analysis
            if (_currentResult.menuItems.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu Items Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    '${_filteredMenuItems.length} items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search bar for menu items
              if (_currentResult.menuItems.length > 1) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterMenuItems,
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search, 
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear, 
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterMenuItems('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              ..._filteredMenuItems.map((item) => _buildMenuItemCard(item)).toList(),
            ],

            const SizedBox(height: 20),

            // Detected allergens summary
            if (_currentResult.detectedAllergens.isNotEmpty) _buildDetectedAllergensCard(),

            const SizedBox(height: 20),

            // Quick re-scan button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isRescanning ? null : _quickRescan,
                icon: _isRescanning 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isRescanning ? 'Scanning...' : 'Quick Re-scan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Disclaimer
            _buildDisclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSafetyCard() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String description;

    switch (_currentResult.overallSafety) {
      case SafetyRating.safe:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        title = 'Safe';
        description = 'No allergens detected in menu items';
        break;
      case SafetyRating.caution:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.warning;
        title = 'Caution';
        description = 'Some items may contain allergens or ingredients are unclear';
        break;
      case SafetyRating.avoid:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        title = 'Avoid';
        description = 'Menu contains items with your selected allergens';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: textColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (_currentResult.confidence > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Confidence: ${_currentResult.confidence}%',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    Color statusColor;
    IconData statusIcon;
    
    switch (item.safety) {
      case SafetyRating.safe:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SafetyRating.caution:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case SafetyRating.avoid:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              if (item.followUpQuestions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Ask Staff',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
          if (item.detectedAllergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Detected allergens:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.detectedAllergens.map((allergen) {
                final displayName = AllergenConstants.allergenDisplayNames[allergen] ?? allergen;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.reasoning,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade300 
                      : Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (item.followUpQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Ask restaurant staff:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...item.followUpQuestions.map((question) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $question',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
          // Alternative suggestions for AVOID items
          if (item.safety == SafetyRating.avoid && item.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Try instead:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...item.alternatives.map((alternative) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $alternative',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetectedAllergensCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Allergens Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentResult.detectedAllergens.map((allergen) {
              final displayName = AllergenConstants.allergenDisplayNames[allergen] ?? allergen;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Important Reminder',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This analysis is for guidance only. Always verify ingredients and preparation methods with restaurant staff. Cross-contamination and hidden ingredients may not be detected.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}