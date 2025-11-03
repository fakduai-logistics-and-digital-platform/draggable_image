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
  final BorderRadiusGeometry borderRadius;
  final ValueChanged<bool>? onGestureActiveChanged;

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
    this.borderRadius = BorderRadius.zero,
    this.onGestureActiveChanged, // NEW
  });

  void _notifyLock(bool active) => onGestureActiveChanged?.call(active);

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

    return ClipRRect(borderRadius: borderRadius, child: imageWidget);
  }

  @override
  Widget build(BuildContext context) {
    // ---------- states ----------
    final position = useState(const Offset(0, 0));
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

    // Track actual pointer count
    final pointerCount = useState(0);
    final pointerPositions = useState<Map<int, Offset>>({});

    // ---------- overlay control ----------
    final layerLink = useMemoized(() => LayerLink(), const []);
    final targetKey = useMemoized(() => GlobalKey(), const []);
    final overlayEntryRef = useRef<OverlayEntry?>(null);
    final inOverlay = useState(false);
    final overlayRect = useState<Rect?>(null);
    final initialFocalGlobal = useRef<Offset?>(null);

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
      _notifyLock(false); // NEW: ปลดล็อก scroll parent
    }

    useEffect(() {
      void tick() {
        final pt = posTweenRef.value;
        final st = scaleTweenRef.value;
        if (pt != null && st != null) {
          position.value = pt.evaluate(curved);
          scale.value = st.evaluate(curved);
        }
      }

      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          position.value = originalPosition;
          scale.value = originalScale;
          if (inOverlay.value)
            removeOverlay(); // removeOverlay จะ _notifyLock(false)
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

    // ⬇️ เปลี่ยนวิธีวาง Overlay: ให้ overlay เป็นแค่ “ภาพเงา” ที่ตามตำแหน่ง/สเกลเดิม
    //    และไม่รับ gesture ใด ๆ เพื่อให้ gesture ยังอยู่ที่ widget เดิม
    Rect? _measureTargetRect() {
      final ctx = targetKey.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    }

    Offset _twoFingerCenter(Map<int, Offset> positions) {
      if (positions.isEmpty) return Offset.zero;
      var sum = const Offset(0, 0);
      positions.values.forEach((p) => sum += p);
      return sum / positions.length.toDouble();
    }

    void _insertOverlay() {
      if (overlayEntryRef.value != null) return;

      // วัดกรอบเดิม
      final measured = _measureTargetRect();
      overlayRect.value = measured; // อาจเป็น null ได้

      overlayEntryRef.value = OverlayEntry(
        builder: (overlayContext) {
          // เตรียมวิดเจ็ตภาพ (ไม่รับทัช)
          final ghost = IgnorePointer(
            ignoring: true,
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
          );

          // กำหนดตำแหน่ง: ถ้าวัด rect ได้ → วางทับที่เดิม
          // ถ้าวัดไม่ได้ → fallback จัดกลางที่ focal point
          Widget ghostPositioned;
          if (overlayRect.value != null) {
            final r = overlayRect.value!;
            ghostPositioned = Positioned.fromRect(rect: r, child: ghost);
          } else {
            // Fallback: จัดกลางภาพที่จุดกึ่งกลางสองนิ้ว
            // ถ้าอยากแม่นยำ ควรวัดขนาดภาพจริงจาก RenderBox ของ _buildImageOnly
            // ที่นี่จะเดาจากขนาดกรอบของ target (ถ้าวัดไม่ได้จริง ๆ กำหนดไซส์ประมาณการ)
            final estimateSize = Size(imageWidth, imageHeight);
            final center = initialFocalGlobal.value ?? const Offset(0, 0);
            ghostPositioned = Positioned(
              left: center.dx - estimateSize.width / 2,
              top: center.dy - estimateSize.height / 2,
              width: estimateSize.width,
              height: estimateSize.height,
              child: ghost,
            );
          }

          return Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ฉากหลัง: แตะเพื่อตีกลับ
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => animateBackToOrigin(),
                      child: Container(color: Colors.black.withOpacity(0.5)),
                    ),
                  ),
                  // ภาพเงาในตำแหน่งที่คำนวณแล้ว
                  ghostPositioned,
                ],
              ),
            ),
          );
        },
      );

      Overlay.of(context, rootOverlay: true).insert(overlayEntryRef.value!);
      inOverlay.value = true;
      _notifyLock(true);
    }

    // ---------- ตัวรับ gesture ----------
    Widget _buildInteractive() {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(position.value.dx, position.value.dy)
          ..scale(scale.value),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions[event.pointer] = event.position; // global position
            pointerPositions.value = newPositions;
            pointerCount.value = newPositions.length;
            touchCount.value = newPositions.length;

            if (newPositions.length >= 2 && !inOverlay.value) {
              hadTwoFingers.value = true;
              isDragging.value = true;

              // จับจุดกึ่งกลางสองนิ้ว (global) + วัดกรอบเดิม
              initialFocalGlobal.value = _twoFingerCenter(newPositions);
              overlayRect.value = _measureTargetRect();

              startPosition.value = position.value;
              startScale.value = scale.value;
              controller.stop();
              _insertOverlay();
            }
          },
          onPointerUp: (event) {
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions.remove(event.pointer);
            pointerPositions.value = newPositions;
            pointerCount.value = newPositions.length;
            touchCount.value = newPositions.length;

            if (newPositions.length < 2 && hadTwoFingers.value) {
              hadTwoFingers.value = false;
              isDragging.value = false;
              animateBackToOrigin();
            }
          },
          onPointerCancel: (event) {
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions.remove(event.pointer);
            pointerPositions.value = newPositions;
            pointerCount.value = newPositions.length;
            touchCount.value = newPositions.length;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              if (pointerCount.value >= 2) {
                startPosition.value = position.value;
                startScale.value = scale.value;
                initialFocalPoint.value = details
                    .focalPoint; // local focal (ไม่จำเป็นต้องใช้กับ overlay ตรงนี้)
                controller.stop();
                if (!inOverlay.value) {
                  // เผื่อกรณีเริ่มท่า scale ใหม่จากระบบ
                  initialFocalGlobal.value = _twoFingerCenter(
                    pointerPositions.value,
                  );
                  overlayRect.value = _measureTargetRect();
                  _insertOverlay();
                }
              }
            },
            onScaleUpdate: (details) {
              if (pointerCount.value >= 2) {
                final delta = details.focalPoint - initialFocalPoint.value;
                position.value = startPosition.value + delta;

                final next = (startScale.value * details.scale).clamp(
                  minScale,
                  maxScale,
                );
                scale.value = next.toDouble();

                overlayEntryRef.value?.markNeedsBuild();
              }
            },
            onScaleEnd: (_) {
              if (position.value != Offset.zero || scale.value != 1.0) {
                animateBackToOrigin();
              } else if (inOverlay.value) {
                removeOverlay();
              }
            },
            child: _buildImageOnly(context),
          ),
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
            // ใส่ key ตรงนี้เพื่อให้วัดกรอบของ "รูปเดิม"
            child: KeyedSubtree(
              key: targetKey, // NEW
              child: _buildInteractive(),
            ),
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
