# draggable_image

A Flutter widget for dragging & pinch-to-zoom images with a smooth snap-back animation using Overlay.

## Quick Start

```dart
import 'package:draggable_image/draggable_image.dart';

class Demo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DraggableImage.network(
        'https://picsum.photos/800',
        imageWidth: 260,
        imageHeight: 180,
        minScale: 0.6,
        maxScale: 3.0,
      ),
    );
  }
}
```