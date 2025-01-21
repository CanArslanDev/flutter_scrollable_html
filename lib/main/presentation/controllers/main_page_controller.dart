import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/iframe_handler.dart';
import '../../utils/event_handlers.dart';

class MainPageController {
  final IframeHandler iframeHandler;
  final EventHandlers eventHandlers;
  final FocusNode iframeFocusNode;
  final FocusNode textFieldFocusNode;
  final GlobalKey htmlElementKey;

  bool isPointerDown = false;
  bool iframeFocused = false;

  MainPageController()
      : iframeHandler = IframeHandler(),
        eventHandlers = EventHandlers(),
        iframeFocusNode = FocusNode(),
        textFieldFocusNode = FocusNode(),
        htmlElementKey = GlobalKey() {
    iframeHandler.initialize();
    iframeHandler.setupMessageListener(eventHandlers.handleWebEvent);
  }

  void handlePointerEvent(PointerEvent event) {
    iframeHandler.handlePointerEvent(
      event,
      htmlElementKey,
      isPointerDown,
      (value) => isPointerDown = value,
      iframeFocusNode,
    );
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!iframeFocused) return KeyEventResult.ignored;
    iframeHandler.sendKeyEventToWeb(event);
    return KeyEventResult.handled;
  }

  void setIframeFocused(bool value) {
    iframeFocused = value;
  }

  void dispose() {
    iframeFocusNode.dispose();
    textFieldFocusNode.dispose();
  }
}
