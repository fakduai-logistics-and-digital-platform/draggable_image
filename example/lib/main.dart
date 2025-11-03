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
        body: Container(
          color: Colors.white,
          child: DraggableImageWidget(
            imageWidth: double.infinity,
            imageHeight: 1000,
            imagePath: 'https://picsum.photos/900',
            isNetworkImage: true,
            isDebug: true,
          ),
        ),
      ),
    );
  }
}
