import 'package:flutter/material.dart';
import '../controllers/main_page_controller.dart';

class FlutterNativeSection extends StatelessWidget {
  final MainPageController controller;

  const FlutterNativeSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20),
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
              ElevatedButton(
                  onPressed: () {}, child: const Text('Test Button')),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: controller.textFieldFocusNode,
                  onTap: () {
                    controller.setIframeFocused(false);
                    controller.textFieldFocusNode.requestFocus();
                  },
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter text here',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
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
    );
  }
}
