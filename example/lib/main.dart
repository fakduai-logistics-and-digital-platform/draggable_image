import 'package:flutter/material.dart';
import 'package:draggable_image/draggable_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'draggable_image example',
      home: Scaffold(
        appBar: AppBar(title: const Text('draggable_image example')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Asset'),
            const SizedBox(height: 8),
            DraggableImage.asset('assets/sample.jpg',
                imageWidth: 300, imageHeight: 200),
            const SizedBox(height: 24),
            const Text('Network'),
            const SizedBox(height: 8),
            DraggableImage.network('https://picsum.photos/900',
                imageWidth: 300, imageHeight: 200),
          ],
        ),
      ),
    );
  }
}
