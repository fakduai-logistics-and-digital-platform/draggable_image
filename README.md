# draggable_image

A Flutter widget for dragging & pinch-to-zoom images with a smooth snap-back animation using Overlay.


<div align="center">

![image](example.gif)

</div>

## Quick Start

```dart
import 'package:draggable_image/draggable_image.dart';

class Demo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DraggableImageWidget(
            imageWidth: double.infinity,
            imageHeight: 1000,
            imagePath: 'https://picsum.photos/900',
            isNetworkImage: true,
            isDebug: true,
    ));
  }
}
```