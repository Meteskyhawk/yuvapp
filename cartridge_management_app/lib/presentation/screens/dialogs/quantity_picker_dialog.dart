import 'package:flutter/material.dart';

class QuantityPickerDialog extends StatefulWidget {
  final int currentQuantity;

  const QuantityPickerDialog({
    super.key,
    required this.currentQuantity,
  });

  @override
  State<QuantityPickerDialog> createState() => _QuantityPickerDialogState();
}

class _QuantityPickerDialogState extends State<QuantityPickerDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentQuantity.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Enter Quantity'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Quantity (g)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null && value >= 0) {
              Navigator.pop(context, value);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
