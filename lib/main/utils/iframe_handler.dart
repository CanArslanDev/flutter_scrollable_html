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
    final js = '''
      (function() {
        try {
          const element = document.elementFromPoint(${position.dx}, ${position.dy});
          if (element) {
            // Mouse event'ini oluştur ve gönder
            const eventInit = {
              bubbles: true,
              cancelable: true,
              view: window,
              detail: 1,
              screenX: ${event.position.dx},
              screenY: ${event.position.dy},
              clientX: ${position.dx},
              clientY: ${position.dy},
              ctrlKey: ${event.down},
              altKey: false,
              shiftKey: false,
              metaKey: false,
              button: ${event is PointerDownEvent ? 0 : event.buttons - 1},
              buttons: ${event.buttons},
              relatedTarget: null
            };

            const mouseEvent = new MouseEvent('$eventType', eventInit);
            element.dispatchEvent(mouseEvent);
            
            // Text selection logic
            if ('$eventType' === 'mousedown') {
              // Başlangıç seçimi için
              if (window.getSelection && document.caretPositionFromPoint) {
                const selection = window.getSelection();
                const range = document.caretRangeFromPoint(${position.dx}, ${position.dy});
                if (range) {
                  selection.removeAllRanges();
                  selection.addRange(range);
                }
              }
            } else if ('$eventType' === 'mousemove' && $isPointerDown) {
              // Sürükleme sırasında seçimi güncelle
              if (window.getSelection) {
                const selection = window.getSelection();
                if (selection.rangeCount > 0) {
                  // Mevcut seçimi genişlet
                  const newPosition = document.caretRangeFromPoint(${position.dx}, ${position.dy});
                  if (newPosition) {
                    try {
                      // Seçimi yeni pozisyona kadar genişlet
                      selection.extend(newPosition.startContainer, newPosition.startOffset);
                      
                      // Seçilen metni görünür yap
                      const range = selection.getRangeAt(0);
                      range.startContainer.parentElement?.scrollIntoView({ block: 'nearest' });
                    } catch (e) {
                      console.error('Selection error:', e);
                    }
                  }
                }
              }
            } else if ('$eventType' === 'mouseup') {
              // Mouse bırakıldığında
              const clickEvent = new MouseEvent('click', eventInit);
              element.dispatchEvent(clickEvent);
              
              // Özel elementler için focus
              if (element.tagName === 'TEXTAREA' || 
                  element.tagName === 'INPUT' || 
                  element.hasAttribute('contenteditable') ||
                  element.tagName === 'DIV' && element.id === 'ascii') {
                element.focus();
              }
              
              // Seçim varsa koru
              const selection = window.getSelection();
              if (selection && selection.toString().length > 0) {
                // Seçim varsa, seçimi koru
                document.designMode = 'off';
              }
            }

            // Seçim değişikliğini engellememek için event'i durdurma
            if (('$eventType' === 'mousemove' && $isPointerDown) || 
                '$eventType' === 'mousedown' || 
                '$eventType' === 'mouseup') {
              event.stopPropagation();
            }
          }
        } catch (e) {
          console.error('Error dispatching mouse event:', e);
        }
      })();
    ''';

    iframeElement.contentWindow?.postMessage(js, '*');
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
    final js = '''
      const event = new KeyboardEvent('${event.runtimeType.toString().contains('KeyDownEvent') ? 'keydown' : 'keyup'}', {
        key: '${event.logicalKey.keyLabel}',
        code: '${event.logicalKey.keyLabel}',
        location: 0,
        ctrlKey: ${HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.control)},
        altKey: ${HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.alt)},
        shiftKey: ${HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shift)},
        metaKey: ${HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.meta)},
        repeat: false,
        isComposing: false,
        charCode: 0,
        keyCode: ${event.logicalKey.keyId},
        which: ${event.logicalKey.keyId}
      });
      
      const activeElement = document.activeElement || document.body;
      activeElement.dispatchEvent(event);
      
      if (event.type === 'keydown' && activeElement.tagName === 'TEXTAREA') {
        const inputEvent = new InputEvent('input', {
          bubbles: true,
          cancelable: true,
          data: '${event.character}'
        });
        activeElement.dispatchEvent(inputEvent);
      }
    ''';
    iframeElement.contentWindow?.postMessage(js, '*');
  }
}
