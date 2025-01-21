import 'package:flutter/material.dart';

class EventHandlers {
  void handleWebEvent(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'mouseEvent':
        _handleMouseEvent(data);
        break;
      case 'keyboardEvent':
        _handleKeyboardEvent(data);
        break;
      case 'selectionEvent':
        _handleSelectionEvent(data);
        break;
      case 'buttonEvent':
        _handleButtonEvent(data);
        break;
    }
  }

  void _handleMouseEvent(Map<String, dynamic> data) {
    debugPrint(
        'Mouse event: ${data['eventType']} at (${data['x']}, ${data['y']})');
    if (data['target'] != null) {
      debugPrint('Target: ${data['target']}');
    }
  }

  void _handleKeyboardEvent(Map<String, dynamic> data) {
    debugPrint(
        'Keyboard event: ${data['eventType']} key: ${data['key']} code: ${data['code']}');
  }

  void _handleSelectionEvent(Map<String, dynamic> data) {
    debugPrint('Selection changed: ${data['text']}');
  }

  void _handleButtonEvent(Map<String, dynamic> data) {
    debugPrint(
        'Button event: ${data['eventType']} isActive: ${data['isActive']}');
  }
}
