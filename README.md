# draggable_image

A Flutter widget for dragging & pinch-to-zoom images with a smooth snap-back animation using Overlay.


<div align="center">

<video src="example.webm" controls />

</div>

## Quick Start

```dart
import 'package:draggable_image/draggable_image.dart';
```

### Network Image (with caching)

```dart
DraggableImageWidget.network(
  'https://picsum.photos/900',
  imageWidth: double.infinity,
  imageHeight: 300,
  borderRadius: BorderRadius.circular(12),
  fit: BoxFit.cover,
)
```

### Asset Image

```dart
DraggableImageWidget.asset(
  'assets/images/photo.png',
  imageWidth: 200,
  imageHeight: 200,
)
```

### Memory Image (Uint8List)

```dart
// From file picker, camera, etc.
final bytes = await file.readAsBytes();

DraggableImageWidget.memory(
  bytes,
  imageWidth: 300,
  imageHeight: 200,
)
```

### File Image

```dart
final file = File('/path/to/image.jpg');

DraggableImageWidget.file(
  file,
  imageWidth: 300,
  imageHeight: 200,
)
```

### Custom ImageProvider

```dart
DraggableImageWidget.provider(
  ResizeImage(
    NetworkImage('https://example.com/image.jpg'),
    width: 200,
  ),
  imageWidth: 300,
  imageHeight: 200,
)
```

## Features

- 🖼️ **Multiple Image Sources**: Network (cached), Asset, Memory, File, and custom ImageProvider
- 🔍 **Pinch-to-Zoom**: Smooth zoom gesture with configurable min/max scale
- 🖐️ **Drag**: Freely drag the image with overlay rendering for performance
- 🔙 **Snap-back Animation**: Smooth spring-like animation back to original position
- 👆 **Callbacks**: `onTap`, `onLongPress`, `onGestureActiveChanged`
- 🎨 **Customizable**: Overlay color/opacity, placeholder, error widget, border radius
- 📐 **Double-tap**: Toggle between fit modes with animation

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `imageWidth` | `double` | `200` | Width of the image |
| `imageHeight` | `double` | `200` | Height of the image |
| `minScale` | `double` | `0.5` | Minimum zoom scale |
| `maxScale` | `double` | `3.0` | Maximum zoom scale |
| `fit` | `BoxFit?` | `BoxFit.contain` | Default image fit |
| `fitDoubleTap` | `BoxFit?` | `null` | Fit to toggle on double-tap |
| `borderRadius` | `BorderRadiusGeometry` | `BorderRadius.zero` | Border radius of the image |
| `overlayColor` | `Color` | `Colors.black` | Overlay background color |
| `overlayOpacity` | `double` | `0.5` | Overlay background opacity |
| `enableZoom` | `bool` | `true` | Enable/disable zoom gesture |
| `placeholderWidget` | `Widget?` | Skeleton shimmer | Custom loading placeholder |
| `errorWidget` | `Widget?` | Error icon | Custom error widget |
| `onTap` | `VoidCallback?` | `null` | Callback on single tap |
| `onLongPress` | `VoidCallback?` | `null` | Callback on long press |