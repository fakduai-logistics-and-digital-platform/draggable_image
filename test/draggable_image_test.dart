// test/draggable_image_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:draggable_image/draggable_image.dart';

void main() {
  testWidgets('renders DraggableImage.asset without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DraggableImage.asset('assets/fake.png'),
      ),
    ));
    expect(find.byType(DraggableImage), findsOneWidget);
  });
}
