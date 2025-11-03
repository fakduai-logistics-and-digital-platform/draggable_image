import 'package:flutter/material.dart';
import 'package:draggable_image/draggable_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'draggable_image example',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _lockScroll = false; // ถูกสลับจาก onGestureActiveChanged

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('draggable_image example')),
      body: SingleChildScrollView(
        physics: _lockScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        child: Container(
          color: Colors.white,
          child: DraggableImageWidget(
            imageWidth: double.infinity,
            imageHeight: 900,
            imagePath: 'https://picsum.photos/900',
            isNetworkImage: true,
            isDebug: true,
            borderRadius: BorderRadius.circular(0),
            fit: BoxFit.contain, // optional
            fitDoubleTap: BoxFit.fitHeight, // optional
            fitToggleCurve: Curves.easeOutCubic, // optional

            onGestureActiveChanged: (active) {
              setState(() => _lockScroll = active);
            },
          ),
        ),
      ),
    );
  }
}
