import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/allergens.dart';

class AllergenSettingsScreen extends StatefulWidget {
  const AllergenSettingsScreen({super.key});

  @override
  State<AllergenSettingsScreen> createState() => _AllergenSettingsScreenState();
}

class _AllergenSettingsScreenState extends State<AllergenSettingsScreen> {
  Set<String> _selectedAllergens = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final allergens = prefs.getStringList('selected_allergens') ?? [];
    setState(() {
      _selectedAllergens = allergens.toSet();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_allergens', _selectedAllergens.toList());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allergen settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate settings were changed
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
          'Allergen Settings',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the allergens you need to avoid:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Allergen list
                        ...AllergenConstants.majorAllergens.map((allergen) {
                          final displayName = AllergenConstants.allergenDisplayNames[allergen]!;
                          final description = AllergenConstants.allergenDescriptions[allergen]!;
                          final isSelected = _selectedAllergens.contains(allergen);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.green.shade50 
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAllergens.add(allergen);
                                  } else {
                                    _selectedAllergens.remove(allergen);
                                  }
                                });
                              },
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isSelected 
                                      ? Colors.black // Always black when selected for visibility on light green
                                      : Theme.of(context).textTheme.titleMedium?.color,
                                ),
                              ),
                              subtitle: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.black87 // Dark text for readability on light green background
                                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                              activeColor: Colors.green,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Save button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Save Settings (${_selectedAllergens.length} selected)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Changes will take effect immediately',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
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