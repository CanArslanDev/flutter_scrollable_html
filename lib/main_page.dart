// main_page.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:ui_web' as ui_web;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final String viewID = 'web-event-handler';
  late html.IFrameElement _iframeElement;
  final GlobalKey _htmlElementKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode(); // Yeni FocusNode ekledik
  bool _isPointerDown = false;
  bool _iframeFocused = false;

  @override
  void initState() {
    super.initState();
    _setupIframe();
    _setupMessageListener();
  }

  void _setupIframe() {
    ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      _iframeElement = html.IFrameElement()
        ..src = 'assets/web/index.html'
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        ..style.outline = 'none'
        ..allowFullscreen = true;
      return _iframeElement;
    });
  }

  void _setupMessageListener() {
    html.window.onMessage.listen((html.MessageEvent event) {
      if (event.data != null && event.data is String) {
        try {
          final data = jsonDecode(event.data);
          print('Received event from web: $data');
          _handleWebEvent(data);
        } catch (e) {
          print('Error parsing message: $e');
        }
      }
    });
  }

  void _handleWebEvent(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'mouseEvent':
        _handleMouseEvent(data);
        // if (data['eventType'] == 'mousedown') {
        //   _iframeFocused = true;
        //   // _focusNode.requestFocus();
        // }
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
    print('Mouse event: ${data['eventType']} at (${data['x']}, ${data['y']})');
    if (data['target'] != null) {
      print('Target: ${data['target']}');
    }
  }

  void _handleKeyboardEvent(Map<String, dynamic> data) {
    print(
        'Keyboard event: ${data['eventType']} key: ${data['key']} code: ${data['code']}');
  }

  void _handleSelectionEvent(Map<String, dynamic> data) {
    print('Selection changed: ${data['text']}');
  }

  void _handleButtonEvent(Map<String, dynamic> data) {
    print('Button event: ${data['eventType']} isActive: ${data['isActive']}');
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_iframeElement.contentWindow == null) return;

    final RenderBox? htmlElementBox =
        _htmlElementKey.currentContext?.findRenderObject() as RenderBox?;
    if (htmlElementBox == null) return;

    final Offset localPosition =
        event.position - htmlElementBox.localToGlobal(Offset.zero);

    String eventType;
    if (event is PointerDownEvent) {
      eventType = 'mousedown';
      _isPointerDown = true;
      _focusNode.requestFocus();
    } else if (event is PointerUpEvent) {
      eventType = 'mouseup';
      _isPointerDown = false;
    } else if (event is PointerMoveEvent) {
      eventType = _isPointerDown ? 'mousemove' : 'mouseover';
    } else if (event is PointerHoverEvent) {
      eventType = 'mouseover';
    } else {
      return;
    }

    _sendEventToWeb(eventType, localPosition, event);
  }

  void _sendEventToWeb(String eventType, Offset position, PointerEvent event) {
    final js = '''
      (function() {
        try {
          const element = document.elementFromPoint(${position.dx}, ${position.dy});
          if (element) {
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
              buttons: ${event.buttons}
            };

            const mouseEvent = new MouseEvent('$eventType', eventInit);
            element.dispatchEvent(mouseEvent);
            
            if ('$eventType' === 'mousedown') {
              if (window.getSelection && document.caretPositionFromPoint) {
                const selection = window.getSelection();
                const range = document.caretRangeFromPoint(${position.dx}, ${position.dy});
                if (range) {
                  selection.removeAllRanges();
                  selection.addRange(range);
                }
              }
            } else if ('$eventType' === 'mousemove' && $_isPointerDown) {
              if (window.getSelection) {
                const selection = window.getSelection();
                if (selection.rangeCount > 0) {
                  const range = selection.getRangeAt(0);
                  const newPosition = document.caretRangeFromPoint(${position.dx}, ${position.dy});
                  if (newPosition) {
                    selection.extend(newPosition.startContainer, newPosition.startOffset);
                  }
                }
              }
            } else if ('$eventType' === 'mouseup') {
              const clickEvent = new MouseEvent('click', eventInit);
              element.dispatchEvent(clickEvent);
              
              if (element.tagName === 'TEXTAREA' || 
                  element.tagName === 'INPUT' || 
                  element.hasAttribute('contenteditable') ||
                  element.tagName === 'DIV' && element.id === 'ascii') {
                element.focus();
              }
            }
          }
        } catch (e) {
          console.error('Error dispatching mouse event:', e);
        }
      })();
    ''';

    _iframeElement.contentWindow?.postMessage(js, '*');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        onKey: (node, event) {
          if (!_iframeFocused) return KeyEventResult.ignored;

          final js = '''
            const event = new KeyboardEvent('${event.runtimeType.toString().contains('KeyDownEvent') ? 'keydown' : 'keyup'}', {
              key: '${event.logicalKey.keyLabel}',
              code: '${event.logicalKey.keyLabel}',
              location: 0,
              ctrlKey: ${event.isControlPressed},
              altKey: ${event.isAltPressed},
              shiftKey: ${event.isShiftPressed},
              metaKey: ${event.isMetaPressed},
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
          _iframeElement.contentWindow?.postMessage(js, '*');
          return KeyEventResult.handled;
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Html Code:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width,
                  child: HtmlElementView(
                    key: _htmlElementKey,
                    viewType: viewID,
                  ),
                ),
                PointerInterceptor(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _handlePointerEvent,
                    onPointerMove: _handlePointerEvent,
                    onPointerUp: _handlePointerEvent,
                    onPointerHover: _handlePointerEvent,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Flutter Native Area:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(onPressed: () {}, child: Text('Test Button')),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      focusNode: _textFieldFocusNode, // FocusNode'u ekledik
                      onTap: () {
                        setState(() {
                          _iframeFocused = false; // iframe focus'unu kaldır
                        });
                        _textFieldFocusNode
                            .requestFocus(); // TextField'a focus ver
                      },
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter text here',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      'This is selectable text content.\n'
                      'You can select this text and copy it.\n'
                      'Try different interactions here.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textFieldFocusNode.dispose(); // Yeni FocusNode'u dispose et
    super.dispose();
  }
}
