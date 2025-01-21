import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../controllers/main_page_controller.dart';

class HtmlViewSection extends StatelessWidget {
  final MainPageController controller;

  const HtmlViewSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20),
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
                key: controller.htmlElementKey,
                viewType: controller.iframeHandler.viewID,
              ),
            ),
            PointerInterceptor(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: controller.handlePointerEvent,
                onPointerMove: controller.handlePointerEvent,
                onPointerUp: controller.handlePointerEvent,
                onPointerHover: controller.handlePointerEvent,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
