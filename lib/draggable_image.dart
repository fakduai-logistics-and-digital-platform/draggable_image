import 'dart:ui' show lerpDouble;
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
  final BoxFit? fit;
  final BoxFit? fitDoubleTap;
  final Duration fitToggleDuration;
  final Curve fitToggleCurve;

  /// Callback when the image is tapped (single tap).
  final VoidCallback? onTap;

  /// Callback when the image is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color of the overlay when zooming. Default is [Colors.black].
  final Color overlayColor;

  /// Opacity of the overlay background. Default is 0.5.
  final double overlayOpacity;

  /// Custom placeholder widget shown while loading image.
  /// If null, uses default skeleton shimmer effect.
  final Widget? placeholderWidget;

  /// Custom error widget shown when image fails to load.
  /// If null, uses default error icon.
  final Widget? errorWidget;

  /// Whether zoom gesture is enabled. Default is true.
  final bool enableZoom;

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
    this.fit = BoxFit.contain,
    this.fitDoubleTap,
    this.fitToggleDuration = const Duration(milliseconds: 220),
    this.fitToggleCurve = Curves.easeOutCubic,
    this.onGestureActiveChanged,
    this.onTap,
    this.onLongPress,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.5,
    this.placeholderWidget,
    this.errorWidget,
    this.enableZoom = true,
  });

  void _notifyLock(bool active) => onGestureActiveChanged?.call(active);

  Widget _buildRawImage(BoxFit? activeFit) {
    return isNetworkImage
        ? CachedNetworkImage(
            imageUrl: imagePath,
            width: imageWidth,
            height: imageHeight,
            fit: activeFit,
            placeholder: (context, url) =>
                placeholderWidget ??
                Container(
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
            errorWidget: (context, url, error) =>
                this.errorWidget ??
                Container(
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
            fit: activeFit,
            errorBuilder: (_, __, ___) =>
                errorWidget ?? _errorBox(imageWidth, imageHeight),
          );
  }

  Widget _buildImageOnly(BuildContext context, BoxFit? activeFit) {
    final child = _buildRawImage(activeFit);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: AnimatedSwitcher(
          duration: fitToggleDuration,
          switchInCurve: fitToggleCurve,
          switchOutCurve: fitToggleCurve,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(activeFit), child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMounted = useIsMounted();
    final disposedRef = useRef(false);

    void safeSet<T>(ValueNotifier<T> n, T v) {
      if (!isMounted() || disposedRef.value) return;
      n.value = v;
    }

    final position = useState(const Offset(0, 0));
    final scale = useState(1.0);
    final isDragging = useState(false);
    final touchCount = useState(0);

    const originalPosition = Offset.zero;
    const originalScale = 1.0;

    final startPosition = useRef(Offset.zero);
    final startScale = useRef(1.0);
    final initialFocalPoint = useRef(Offset.zero);
    final hadTwoFingers = useRef(false);

    final pointerCount = useState(0);
    final pointerPositions = useState<Map<int, Offset>>({});

    final targetKey = useMemoized(() => GlobalKey(), const []);
    final overlayEntryRef = useRef<OverlayEntry?>(null);
    final inOverlay = useState(false);
    final overlayRect = useState<Rect?>(null);
    final initialFocalGlobal = useRef<Offset?>(null);

    final controller = useAnimationController(duration: animationDuration);
    final rebuildScheduled = useRef<bool>(false);

    final currentFit = useState<BoxFit?>(fit);
    final activeFit = currentFit.value ?? fit;

    void _removeOverlay() {
      overlayEntryRef.value?.remove();
      overlayEntryRef.value = null;
      if (!disposedRef.value) safeSet<bool>(inOverlay, false);
      _notifyLock(false);
    }

    useEffect(() {
      void tick() {
        if (!isMounted() || disposedRef.value) return;
        safeSet<Offset>(
          position,
          Tween<Offset>(
            begin: startPosition.value,
            end: originalPosition,
          ).transform(controller.value),
        );
        safeSet<double>(
          scale,
          Tween<double>(
            begin: startScale.value,
            end: originalScale,
          ).transform(controller.value),
        );
      }

      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed && !disposedRef.value) {
          safeSet<Offset>(position, originalPosition);
          safeSet<double>(scale, originalScale);
          if (inOverlay.value) _removeOverlay();
        }
      }

      controller.addListener(tick);
      controller.addStatusListener(onStatus);
      return () {
        controller.removeListener(tick);
        controller.removeStatusListener(onStatus);
      };
    }, [controller]);

    useEffect(() {
      return () {
        disposedRef.value = true;
        _removeOverlay();
      };
    }, const []);

    void _markOverlayNeedsBuildThrottled() {
      if (rebuildScheduled.value || overlayEntryRef.value == null) return;
      rebuildScheduled.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlayEntryRef.value != null && !disposedRef.value) {
          overlayEntryRef.value!.markNeedsBuild();
        }
        rebuildScheduled.value = false;
      });
    }

    void _animateBackToOrigin() {
      if (disposedRef.value) return;
      startPosition.value = position.value;
      startScale.value = scale.value;
      controller.forward(from: 0);
    }

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
      for (final p in positions.values) {
        sum += p;
      }
      return sum / positions.length.toDouble();
    }

    void _insertOverlay() {
      if (overlayEntryRef.value != null || disposedRef.value) return;

      safeSet<Rect?>(overlayRect, _measureTargetRect());
      final entry = OverlayEntry(
        builder: (overlayContext) {
          final ghost = IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final bool animating = controller.isAnimating;
                final Offset pos = animating
                    ? Offset.lerp(
                        startPosition.value,
                        originalPosition,
                        controller.value,
                      )!
                    : position.value;
                final double scl = animating
                    ? lerpDouble(
                        startScale.value,
                        originalScale,
                        controller.value,
                      )!
                    : scale.value;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(pos.dx, pos.dy)
                    ..scale(scl),
                  child: child,
                );
              },
              child: _buildImageOnly(context, currentFit.value ?? fit),
            ),
          );

          Widget ghostPositioned;
          if (overlayRect.value != null) {
            ghostPositioned = Positioned.fromRect(
              rect: overlayRect.value!,
              child: ghost,
            );
          } else {
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
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _animateBackToOrigin(),
                      child: Container(
                          color: overlayColor.withOpacity(overlayOpacity)),
                    ),
                  ),
                  ghostPositioned,
                ],
              ),
            ),
          );
        },
      );

      Overlay.of(context, rootOverlay: true).insert(entry);
      overlayEntryRef.value = entry;
      safeSet<bool>(inOverlay, true);
      _notifyLock(true);
    }

    Widget _buildInteractive() {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(position.value.dx, position.value.dy)
          ..scale(scale.value),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!isMounted() || disposedRef.value) return;
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions[event.pointer] = event.position;
            safeSet<Map<int, Offset>>(pointerPositions, newPositions);
            safeSet<int>(pointerCount, newPositions.length);
            safeSet<int>(touchCount, newPositions.length);

            if (enableZoom && newPositions.length >= 2 && !inOverlay.value) {
              hadTwoFingers.value = true;
              safeSet<bool>(isDragging, true);

              initialFocalGlobal.value = _twoFingerCenter(newPositions);
              safeSet<Rect?>(overlayRect, _measureTargetRect());

              startPosition.value = position.value;
              startScale.value = scale.value;
              controller.stop();
              _insertOverlay();
            }
          },
          onPointerUp: (event) {
            if (!isMounted() || disposedRef.value) return;
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions.remove(event.pointer);
            safeSet<Map<int, Offset>>(pointerPositions, newPositions);
            safeSet<int>(pointerCount, newPositions.length);
            safeSet<int>(touchCount, newPositions.length);

            if (newPositions.length < 2 && hadTwoFingers.value) {
              hadTwoFingers.value = false;
              safeSet<bool>(isDragging, false);
              _animateBackToOrigin();
            }
          },
          onPointerCancel: (event) {
            if (!isMounted() || disposedRef.value) return;
            final newPositions = Map<int, Offset>.from(pointerPositions.value);
            newPositions.remove(event.pointer);
            safeSet<Map<int, Offset>>(pointerPositions, newPositions);
            safeSet<int>(pointerCount, newPositions.length);
            safeSet<int>(touchCount, newPositions.length);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onLongPress: onLongPress,
            onDoubleTap: () {
              if (fitDoubleTap != null) {
                final baseFit = fit;
                final current = currentFit.value ?? baseFit;
                final toggled =
                    current == fitDoubleTap ? baseFit : fitDoubleTap;
                safeSet<BoxFit?>(currentFit, toggled);
                if (inOverlay.value) _markOverlayNeedsBuildThrottled();
              }
            },
            onScaleStart: (details) {
              if (!enableZoom) return;
              if (!isMounted() || disposedRef.value) return;
              if (pointerCount.value >= 2) {
                startPosition.value = position.value;
                startScale.value = scale.value;
                initialFocalPoint.value = details.focalPoint;
                controller.stop();
                if (!inOverlay.value) {
                  initialFocalGlobal.value = _twoFingerCenter(
                    pointerPositions.value,
                  );
                  safeSet<Rect?>(overlayRect, _measureTargetRect());
                  _insertOverlay();
                }
              }
            },
            onScaleUpdate: (details) {
              if (!enableZoom) return;
              if (!isMounted() || disposedRef.value) return;
              if (pointerCount.value >= 2) {
                final delta = details.focalPoint - initialFocalPoint.value;
                safeSet<Offset>(position, startPosition.value + delta);
                final next = (startScale.value * details.scale).clamp(
                  minScale,
                  maxScale,
                );
                safeSet<double>(scale, next.toDouble());
                _markOverlayNeedsBuildThrottled();
              }
            },
            onScaleEnd: (_) {
              if (!isMounted() || disposedRef.value) return;
              if (position.value != Offset.zero || scale.value != 1.0) {
                _animateBackToOrigin();
              } else if (inOverlay.value) {
                _removeOverlay();
              }
            },
            child: _buildImageOnly(context, activeFit),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Opacity(
          opacity: inOverlay.value ? 0.0 : 1.0,
          child: KeyedSubtree(key: targetKey, child: _buildInteractive()),
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
