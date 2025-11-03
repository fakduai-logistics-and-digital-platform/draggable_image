## 0.1.5 - 2025-11-03
- ✨ feat: Add customizable BoxFit options with animated transitions
  - New `fit` parameter for default image fitting (default: BoxFit.contain)
  - New `fitDoubleTap` parameter for double-tap BoxFit toggle
  - New `fitToggleDuration` parameter for animation duration (default: 220ms)
  - New `fitToggleCurve` parameter for animation curve (default: Curves.easeOutCubic)
- ♻️ refactor: Improve overlay performance with throttled rebuilds
- 🐛 fix: Memory leak fixes with proper disposal handling
- 🐛 fix: Improve gesture handling stability and edge cases

## 0.1.4 - 2025-11-03
- Update dependencies and improve overall performance.
- Bug fixes and stability improvements.

## 0.1.3 - 2023-11-03
- feat: Make DraggableImageWidget's border radius customizable (`borderRadius`).

## 0.1.0 - 2025-11-03
- Initial release of `draggable_image`.
- Pinch-to-zoom & drag with smooth snap-back animation (Overlay-based).
- Asset & Network images (cached) with skeleton placeholder.
- Factory constructors: `DraggableImage.asset` / `DraggableImage.network`.
