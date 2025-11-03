import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DraggableImageWidget extends HookWidget {
  final String imagePath;
  final double imageWidth;
  final double imageHeight;
  final bool isNetworkImage;
  final Duration animationDuration;
  final double minScale;
  final double maxScale;
  final bool isDebug;

  const DraggableImageWidget({
    super.key,
    required this.imagePath,
    this.imageWidth = 200,
    this.imageHeight = 200,
    this.isNetworkImage = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.isDebug = false,
  });

  // วาดรูปอย่างเดียว
  Widget _buildImageOnly(BuildContext context) {
    final imageWidget = isNetworkImage
        ? CachedNetworkImage(
            imageUrl: imagePath,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => Container(
              width: imageWidth,
              height: imageHeight,
              color: Colors.grey[100],
              child: Skeletonizer.zone(
                effect: const ShimmerEffect(
                  baseColor: Color(0xFFE0E0E0),
                  highlightColor: Color(0xFFF5F5F5),
                  duration: Duration(seconds: 1),
                ),
                child: Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: imageWidth,
              height: imageHeight,
              color: Colors.grey[300],
              child: const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 32,
              ),
            ),
          )
        : Image.asset(
            imagePath,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, __, ___) => _errorBox(imageWidth, imageHeight),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---------- states ----------
    final position = useState(Offset.zero);
    final scale = useState(1.0);
    final isDragging = useState(false);
    final touchCount = useState(0);

    const originalPosition = Offset.zero;
    const originalScale = 1.0;

    // refs gesture
    final startPosition = useRef(Offset.zero);
    final startScale = useRef(1.0);
    final initialFocalPoint = useRef(Offset.zero);
    final hadTwoFingers = useRef(false);

    // ---------- overlay control ----------
    final layerLink = useMemoized(() => LayerLink(), const []);
    final overlayEntryRef = useRef<OverlayEntry?>(null);
    final inOverlay = useState(false);

    // ---------- animation ----------
    final controller = useAnimationController(duration: animationDuration);
    final curved = useMemoized(
      () => CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      [controller],
    );
    final posTweenRef = useRef<Tween<Offset>?>(null);
    final scaleTweenRef = useRef<Tween<double>?>(null);

    void removeOverlay() {
      overlayEntryRef.value?.remove();
      overlayEntryRef.value = null;
      inOverlay.value = false;
    }

    useEffect(() {
      void tick() {
        final pt = posTweenRef.value;
        final st = scaleTweenRef.value;
        if (pt != null && st != null) {
          position.value = pt.evaluate(curved);
          scale.value = st.evaluate(curved);
        }
        // ไม่ต้อง markNeedsBuild ระหว่างอนิเมชันเพราะ AnimatedBuilder จะทำให้เอง
      }

      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          position.value = originalPosition;
          scale.value = originalScale;
          if (inOverlay.value) removeOverlay();
        }
      }

      controller.addListener(tick);
      controller.addStatusListener(onStatus);
      return () {
        controller.removeListener(tick);
        controller.removeStatusListener(onStatus);
        removeOverlay();
      };
    }, [controller, curved]);

    void animateBackToOrigin() {
      posTweenRef.value = Tween<Offset>(
        begin: position.value,
        end: originalPosition,
      );
      scaleTweenRef.value = Tween<double>(
        begin: scale.value,
        end: originalScale,
      );
      controller.forward(from: 0);
    }

    void _insertOverlay() {
      if (overlayEntryRef.value != null) return;

      overlayEntryRef.value = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              // จุดสำคัญ: ใช้ AnimatedBuilder ให้ overlay รีเฟรชทุกเฟรมของ controller
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(position.value.dx, position.value.dy)
                      ..scale(scale.value),
                    child: child,
                  );
                },
                child: _buildImageOnly(context),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context, rootOverlay: true).insert(overlayEntryRef.value!);
      inOverlay.value = true;
    }

    // ---------- ตัวรับ gesture ----------
    Widget _buildInteractive() {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(position.value.dx, position.value.dy)
          ..scale(scale.value),
        child: GestureDetector(
          onScaleStart: (details) {
            startPosition.value = position.value;
            startScale.value = scale.value;
            initialFocalPoint.value = details.focalPoint;
            controller.stop();
          },
          onScaleUpdate: (details) {
            touchCount.value = details.pointerCount;

            if (details.pointerCount >= 2) {
              hadTwoFingers.value = true;
              isDragging.value = true;

              if (!inOverlay.value) _insertOverlay();

              final delta = details.focalPoint - initialFocalPoint.value;
              position.value = startPosition.value + delta;

              final next = (startScale.value * details.scale).clamp(
                minScale,
                maxScale,
              );
              scale.value = next.toDouble();

              // ตอนลากด้วยมือ (ไม่ได้ใช้ controller) ต้องสั่ง overlay ให้ rebuild
              overlayEntryRef.value?.markNeedsBuild();
            } else {
              if (hadTwoFingers.value) {
                hadTwoFingers.value = false;
                isDragging.value = false;
                animateBackToOrigin(); // overlay จะ animate กลับอย่างลื่นด้วย AnimatedBuilder
              }
            }
          },
          onScaleEnd: (_) {
            isDragging.value = false;
            touchCount.value = 0;
            if (position.value != originalPosition ||
                scale.value != originalScale) {
              animateBackToOrigin();
            } else {
              if (inOverlay.value) removeOverlay();
            }
          },
          child: _buildImageOnly(context),
        ),
      );
    }

    // ---------- UI ----------
    return Stack(
      children: [
        CompositedTransformTarget(
          link: layerLink,
          child: Opacity(
            opacity: inOverlay.value ? 0.0 : 1.0,
            child: _buildInteractive(),
          ),
        ),
        if (isDebug)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('จำนวนนิ้วที่สัมผัส: ${touchCount.value}'),
                    Text(
                      'สถานะ: ${isDragging.value ? "กำลังลาก/ซูม (overlay)" : "ปกติ"}',
                    ),
                    Text('ซูม: ${scale.value.toStringAsFixed(2)}x'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _errorBox(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: Colors.grey[300],
      child: const Icon(Icons.error_outline, color: Colors.red, size: 50),
    );
  }
}
