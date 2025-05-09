// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IframeHandler {
  late html.IFrameElement iframeElement;
  final String viewID = 'web-event-handler';
  bool isPointerDown = false;

  void initialize() {
    ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      iframeElement = html.IFrameElement()
        ..src = 'assets/web/index.html'
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        ..style.outline = 'none'
        ..allowFullscreen = true;
      return iframeElement;
    });
  }

  void setupMessageListener(Function(Map<String, dynamic>) onWebEvent) {
    html.window.onMessage.listen((html.MessageEvent event) {
      if (event.data != null && event.data is String) {
        try {
          final data = jsonDecode(event.data);
          debugPrint('Received event from web: $data');
          onWebEvent(data);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
    });
  }

  void handlePointerEvent(
    PointerEvent event,
    GlobalKey htmlElementKey,
    bool isPointerDown,
    Function(bool) setPointerDown,
    FocusNode focusNode,
  ) {
    if (iframeElement.contentWindow == null) return;

    final RenderBox? htmlElementBox =
        htmlElementKey.currentContext?.findRenderObject() as RenderBox?;
    if (htmlElementBox == null) return;

    final localPosition =
        event.position - htmlElementBox.localToGlobal(Offset.zero);

    String eventType = _getEventType(event, isPointerDown);
    if (eventType.isEmpty) return;

    if (event is PointerDownEvent) {
      this.isPointerDown = true;
      setPointerDown(true);
      focusNode.requestFocus();
    } else if (event is PointerUpEvent) {
      this.isPointerDown = false;
      setPointerDown(false);
    }

    _sendEventToWeb(eventType, localPosition, event);
  }

  void _sendEventToWeb(String eventType, Offset position, PointerEvent event) {
    final message = {
      'command': 'mouseEvent',
      'eventType': eventType, // 'mousedown', 'mouseup', 'mousemove'
      'clientX': position.dx,
      'clientY': position.dy,
      'screenX': event.position.dx,
      'screenY': event.position.dy,
      'buttons': event.buttons,
      'button': event is PointerDownEvent ? 0 : event.buttons - 1,
      'ctrlKey': event.down,
      'altKey': false,
      'shiftKey': false,
      'metaKey': false,
      'isPointerDown': event.down,
    };

    iframeElement.contentWindow?.postMessage(jsonEncode(message), '*');
  }

  String _getEventType(PointerEvent event, bool isPointerDown) {
    if (event is PointerDownEvent) return 'mousedown';
    if (event is PointerUpEvent) return 'mouseup';
    if (event is PointerMoveEvent) {
      return isPointerDown ? 'mousemove' : 'mouseover';
    }
    if (event is PointerHoverEvent) return 'mouseover';
    return '';
  }

  void sendKeyEventToWeb(KeyEvent event) {
    final message = {
      'command': 'keyboardEvent',
      'eventType': event is KeyDownEvent ? 'keydown' : 'keyup',
      'key': event.logicalKey.keyLabel,
      'code': event.logicalKey.keyLabel,
      'keyCode': event.logicalKey.keyId,
      'which': event.logicalKey.keyId,
      'ctrlKey': HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.control),
      'altKey': HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.alt),
      'shiftKey': HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shift),
      'metaKey': HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.meta),
      'character': event.character ?? '',
    };

    iframeElement.contentWindow?.postMessage(jsonEncode(message), '*');
  }
}
