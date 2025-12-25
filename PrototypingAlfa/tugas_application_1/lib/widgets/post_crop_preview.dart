import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PostCropPreview extends StatefulWidget {
  final AssetEntity entity;
  final bool isSquareMode;
  final VoidCallback? onToggleMode;
  final Function(bool)? onScrollLock;
  final TransformationController? controller;
  final bool readOnly;

  const PostCropPreview({
    super.key,
    required this.entity,
    required this.isSquareMode,
    this.onToggleMode,
    this.onScrollLock,
    this.controller,
    this.readOnly = false,
  });

  @override
  State<PostCropPreview> createState() => _PostCropPreviewState();
}

class _PostCropPreviewState extends State<PostCropPreview> with SingleTickerProviderStateMixin {
  late TransformationController _transformController;
  bool _isInteracting = false;

  static const double kBaseWidth = 1080.0;
  static const double kBaseHeightSquare = 1080.0;
  static const double kBaseHeightPortrait = 1350.0;

  @override
  void initState() {
    super.initState();
    _transformController = widget.controller ?? TransformationController();
    // Aman karena ini emang udah di post frame callback dari sananya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerImage();
    });
  }

  @override
  void didUpdateWidget(covariant PostCropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 PERBAIKAN DISINI KING! 🔥
    // Kalau ada perubahan (ganti mode atau ganti gambar), jangan langsung _centerImage().
    // Tunggu frame selesai dulu biar gak tabrakan sama proses Build.
    if (widget.entity != oldWidget.entity || widget.isSquareMode != oldWidget.isSquareMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerImage();
      });
    }
  }

  void _centerImage() {
    if (widget.readOnly) return;

    double imgWidth = widget.entity.width.toDouble();
    double imgHeight = widget.entity.height.toDouble();
    double imgRatio = imgWidth / imgHeight;

    double canvasHeight = widget.isSquareMode ? kBaseHeightSquare : kBaseHeightPortrait;
    double targetFrameRatio = widget.isSquareMode ? 1.0 : 0.8;

    double displayWidth, displayHeight;

    if (targetFrameRatio >= 1.0) {
      displayWidth = kBaseWidth;
      displayHeight = kBaseWidth / targetFrameRatio;
    } else {
      displayWidth = kBaseWidth;
      displayHeight = kBaseWidth / targetFrameRatio;
    }

    double contentWidth = displayWidth;
    double contentHeight = displayWidth / imgRatio;

    if (contentHeight < displayHeight) {
      contentHeight = displayHeight;
      contentWidth = displayHeight * imgRatio;
    }

    double dx = (contentWidth - displayWidth) / 2;
    double dy = (contentHeight - displayHeight) / 2;

    // Reset posisi ke tengah
    _transformController.value = Matrix4.identity()..translate(-dx, -dy);
  }

  @override
  Widget build(BuildContext context) {
    double imgWidth = widget.entity.width.toDouble();
    double imgHeight = widget.entity.height.toDouble();
    double imgRatio = imgWidth / imgHeight;

    double canvasWidth = kBaseWidth;
    double canvasHeight = widget.isSquareMode ? kBaseHeightSquare : kBaseHeightPortrait;

    double targetFrameRatio = widget.isSquareMode ? 1.0 : 0.8;

    double displayWidth, displayHeight;
    if (targetFrameRatio >= 1.0) {
      displayWidth = kBaseWidth;
      displayHeight = kBaseWidth / targetFrameRatio;
    } else {
      displayWidth = kBaseWidth;
      displayHeight = kBaseWidth / targetFrameRatio;
    }

    double contentWidth = displayWidth;
    double contentHeight = displayWidth / imgRatio;
    if (contentHeight < displayHeight) {
      contentHeight = displayHeight;
      contentWidth = displayHeight * imgRatio;
    }

    Widget content = FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: Container(
        width: canvasWidth,
        height: canvasHeight,
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: displayWidth,
                height: displayHeight,
                decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        panEnabled: !widget.readOnly,
                        scaleEnabled: !widget.readOnly,
                        minScale: 1.0,
                        maxScale: 3.0,
                        constrained: false,
                        child: SizedBox(
                          width: contentWidth,
                          height: contentHeight,
                          child: AssetEntityImage(widget.entity, isOriginal: true, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    if (!widget.readOnly)
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _isInteracting ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: _buildGrid(displayWidth, displayHeight),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!widget.readOnly)
              Positioned(
                left: 30,
                bottom: 30,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: widget.onToggleMode,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(
                      widget.isSquareMode ? Icons.unfold_more : Icons.unfold_less,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.readOnly) {
      return IgnorePointer(child: content);
    }

    return Listener(
      onPointerDown: (_) {
        widget.onScrollLock?.call(true);
        setState(() => _isInteracting = true);
      },
      onPointerUp: (_) {
        widget.onScrollLock?.call(false);
        setState(() => _isInteracting = false);
      },
      onPointerCancel: (_) {
        widget.onScrollLock?.call(false);
        setState(() => _isInteracting = false);
      },
      child: content,
    );
  }

  Widget _buildGrid(double w, double h) {
    return Stack(
      children: [
        Positioned(left: w / 3, top: 0, bottom: 0, child: _buildLine(true)),
        Positioned(left: (w / 3) * 2, top: 0, bottom: 0, child: _buildLine(true)),
        Positioned(top: h / 3, left: 0, right: 0, child: _buildLine(false)),
        Positioned(top: (h / 3) * 2, left: 0, right: 0, child: _buildLine(false)),
      ],
    );
  }

  Widget _buildLine(bool vertical) {
    return Container(
      width: vertical ? 2 : double.infinity,
      height: vertical ? double.infinity : 2,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)],
      ),
    );
  }
}
