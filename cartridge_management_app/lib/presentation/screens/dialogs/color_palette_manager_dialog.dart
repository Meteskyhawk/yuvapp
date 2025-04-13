import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../data/models/color_constants.dart';
import '../../../data/models/color_model.dart';
import '../../../data/services/api_service.dart';

class ColorPaletteManagerDialog extends StatefulWidget {
  const ColorPaletteManagerDialog({super.key});

  @override
  State<ColorPaletteManagerDialog> createState() =>
      _ColorPaletteManagerDialogState();
}

class _ColorPaletteManagerDialogState extends State<ColorPaletteManagerDialog> {
  List<CartridgeColor> allColors = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();
  bool _isApiConnected = false;

  @override
  void initState() {
    super.initState();
    // TheColorAPI URL'sini kullan
    _testApiConnection();
  }

  // API bağlantısını test edelim
  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final connected = await _apiService.testApiConnection();

      setState(() {
        _isApiConnected = connected;
      });

      if (connected) {
        developer.log('API connection successful, fetching colors...',
            name: 'ColorPaletteManagerDialog');
        _fetchColorsFromApi();
      } else {
        _loadLocalColors();
        developer.log('API connection failed, using local colors',
            name: 'ColorPaletteManagerDialog');
      }
    } catch (e) {
      _loadLocalColors();
      developer.log('API connection test error: $e',
          name: 'ColorPaletteManagerDialog');
    }
  }

  void _loadLocalColors() {
    setState(() {
      allColors = CartridgeColors.getAllColors();
      _isLoading = false;
      _errorMessage = 'Could not connect to the API. Using local colors.';
    });
  }

  Future<void> _fetchColorsFromApi() async {
    try {
      final colors = await _apiService.getColors();
      setState(() {
        allColors = colors;
        _isLoading = false;
        _errorMessage = '';
      });

      // API'dan gelen her rengi CartridgeColors'a da kaydet
      for (final color in colors) {
        await CartridgeColors.addOrUpdateColor(color);
      }
    } catch (e) {
      _loadLocalColors();
      setState(() {
        _errorMessage = 'Error fetching colors from API. Using local colors.';
      });
    }
  }

  // Renk ekleyince renk listesini güncelle
  void _addColor(CartridgeColor newColor) async {
    try {
      final success = await _apiService.addColor(newColor);

      if (success) {
        setState(() {
          allColors = [...allColors, newColor];
        });

        // CartridgeColors'a da ekleme yap
        await CartridgeColors.addOrUpdateColor(newColor);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Color added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add color')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while adding color')),
      );
    }
  }

  // Renk güncelleme
  void _updateColor(CartridgeColor updatedColor) async {
    try {
      final success = await _apiService.updateColor(updatedColor);

      if (success) {
        // Renk güncellendiğinde listeyi güncelle
        final index = allColors.indexWhere((c) => c.code == updatedColor.code);
        if (index != -1) {
          final newColors = List<CartridgeColor>.from(allColors);
          newColors[index] = updatedColor;

          setState(() {
            allColors = newColors;
          });
        }

        // CartridgeColors'a da güncelleme yap
        await CartridgeColors.addOrUpdateColor(updatedColor);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Color updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update color')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while updating color')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Color Palette Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isApiConnected)
                      Tooltip(
                        message: 'No API Connection - Local Mode',
                        child: Icon(
                          Icons.cloud_off,
                          color: Colors.red[400],
                          size: 14,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _testApiConnection,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Available Colors:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: allColors.length,
                        itemBuilder: (context, index) {
                          final color = allColors[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.backgroundColor,
                                  radius: 20,
                                  child: Text(
                                    color.code,
                                    style: TextStyle(
                                      color: color.textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        color.code,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        color.displayName.isEmpty
                                            ? color.code
                                            : color.displayName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      iconSize: 14,
                                      onPressed: () =>
                                          _showColorEditDialog(color),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.file_copy,
                                          color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      iconSize: 14,
                                      onPressed: () => _duplicateColor(color),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add New Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: _showAddColorDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showColorEditDialog(CartridgeColor color) {
    _showColorDialogWithState(
      title: 'Edit Color',
      initialColor: color.backgroundColor,
      initialTextColor: color.textColor,
      initialCode: color.code,
      initialDisplayName: color.displayName,
      initialHasBorder: color.hasBorder,
      onSave: (String code, String displayName, Color backgroundColor,
          Color textColor, bool hasBorder) async {
        // Kod alanı boşsa uyarı göster
        if (code.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Color code cannot be empty')),
          );
          return;
        }

        final updatedColor = CartridgeColor(
          code: code,
          displayName: displayName,
          backgroundColor: backgroundColor,
          textColor: textColor,
          hasBorder: hasBorder,
        );

        _updateColor(updatedColor);
      },
    );
  }

  void _showAddColorDialog() {
    _showColorDialogWithState(
      title: 'Add New Color',
      initialColor: Colors.blue,
      initialTextColor: Colors.white,
      initialCode: '',
      initialDisplayName: '',
      initialHasBorder: false,
      onSave: (String code, String displayName, Color backgroundColor,
          Color textColor, bool hasBorder) async {
        // Kod alanı boşsa uyarı göster
        if (code.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Color code cannot be empty')),
          );
          return;
        }

        final newColor = CartridgeColor(
          code: code,
          displayName: displayName,
          backgroundColor: backgroundColor,
          textColor: textColor,
          hasBorder: hasBorder,
        );

        _addColor(newColor);
      },
    );
  }

  void _duplicateColor(CartridgeColor originalColor) async {
    // Generate a unique code by adding a suffix
    String newCode = originalColor.code;
    int suffix = 1;

    // API'dan değil, tüm renk havuzundan kontrol et
    while (allColors.any((c) => c.code == newCode) ||
        CartridgeColors.getColorByCode(newCode) != null) {
      newCode = "${originalColor.code}_$suffix";
      suffix++;
    }

    // Create a duplicate with a new code
    final duplicatedColor = originalColor.copyWith(
      code: newCode,
      displayName: "${originalColor.displayName} Copy",
    );

    try {
      final success = await _apiService.addColor(duplicatedColor);

      if (success) {
        setState(() {
          allColors = [...allColors, duplicatedColor];
        });

        // Duplicate'i CartridgeColors'a da ekle
        await CartridgeColors.addOrUpdateColor(duplicatedColor);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Color duplicated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to duplicate color')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while duplicating color')),
      );
    }
  }

  void _showColorDialogWithState({
    required String title,
    required Color initialColor,
    required Color initialTextColor,
    required String initialCode,
    required String initialDisplayName,
    required bool initialHasBorder,
    required Function(String code, String displayName, Color backgroundColor,
            Color textColor, bool hasBorder)
        onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        title: title,
        initialColor: initialColor,
        initialTextColor: initialTextColor,
        initialCode: initialCode,
        initialDisplayName: initialDisplayName,
        initialHasBorder: initialHasBorder,
        onSave: onSave,
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Color initialTextColor;
  final String initialCode;
  final String initialDisplayName;
  final bool initialHasBorder;
  final Function(String code, String displayName, Color backgroundColor,
      Color textColor, bool hasBorder) onSave;

  const _ColorPickerDialog({
    required this.title,
    required this.initialColor,
    required this.initialTextColor,
    required this.initialCode,
    required this.initialDisplayName,
    required this.initialHasBorder,
    required this.onSave,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late TextEditingController _codeController;
  late TextEditingController _displayNameController;
  late Color _selectedColor;
  late Color _selectedTextColor;
  late bool _hasBorder;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
    _displayNameController =
        TextEditingController(text: widget.initialDisplayName);
    _selectedColor = widget.initialColor;
    _selectedTextColor = widget.initialTextColor;
    _hasBorder = widget.initialHasBorder;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F0F7), // Light purple background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Color Code',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (Optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Background Color:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // First row of color options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorOption(Colors.red),
                  _buildColorOption(Colors.blue),
                  _buildColorOption(Colors.green),
                  _buildColorOption(Colors.yellow),
                  _buildColorOption(Colors.purple),
                  _buildColorOption(Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              // Second row of color options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorOption(Colors.white),
                  _buildColorOption(Colors.black),
                  _buildColorOption(const Color(0xFF8B4513)), // Brown
                  _buildColorOption(const Color(0xFFF5F5DC)), // Beige
                  _buildColorOption(const Color(0xFFFFA500)), // Orange
                  _buildColorOption(const Color(0xFF87CEEB)), // Sky Blue
                ],
              ),
              const SizedBox(height: 12),
              // Third row of color options
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFF8A2BE2)), // Purple/Violet
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFFE6E6FA)), // Light violet
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Text Color:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Text color options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextColorOption(Colors.white),
                  const SizedBox(width: 60),
                  _buildTextColorOption(Colors.black),
                ],
              ),
              const SizedBox(height: 24),
              // Add Border option with checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Border',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Checkbox(
                    value: _hasBorder,
                    onChanged: (value) {
                      setState(() {
                        _hasBorder = value ?? false;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Preview of the color
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: _hasBorder
                      ? Border.all(color: Colors.black, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    _codeController.text.isEmpty ? 'ABC' : _codeController.text,
                    style: TextStyle(
                      color: _selectedTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(
                        _codeController.text,
                        _displayNameController.text,
                        _selectedColor,
                        _selectedTextColor,
                        _hasBorder,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (color == Colors.white ? Colors.grey : Colors.transparent),
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTextColorOption(Color color) {
    final isSelected = _selectedTextColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTextColor = color;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (color == Colors.white ? Colors.black : Colors.transparent),
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
