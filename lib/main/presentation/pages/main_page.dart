import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/main_page_controller.dart';
import '../widgets/html_view_section.dart';
import '../widgets/flutter_native_section.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final MainPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainPageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _controller.iframeFocusNode,
        onKeyEvent: (node, event) {
          // onKey yerine onKeyEvent kullanıyoruz
          if (!_controller.iframeFocused) return KeyEventResult.ignored;
          _controller.iframeHandler.sendKeyEventToWeb(event);
          return KeyEventResult.handled;
        },
        child: ListView(
          children: [
            HtmlViewSection(controller: _controller),
            FlutterNativeSection(controller: _controller),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
