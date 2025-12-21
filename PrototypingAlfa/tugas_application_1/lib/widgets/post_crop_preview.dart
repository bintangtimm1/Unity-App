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
  // PARAMETER RADIUS DIHAPUS DARI SINI

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

  @override
  void initState() {
    super.initState();
    _transformController = widget.controller ?? TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerImage();
    });
  }

  @override
  void didUpdateWidget(covariant PostCropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity != oldWidget.entity || widget.isSquareMode != oldWidget.isSquareMode) {
      _centerImage();
    }
  }

  void _centerImage() {
    if (widget.readOnly) return;

    double imgWidth = widget.entity.width.toDouble();
    double imgHeight = widget.entity.height.toDouble();
    double imgRatio = imgWidth / imgHeight;

    double targetFrameRatio = widget.isSquareMode ? 1.0 : imgRatio;
    if (!widget.isSquareMode && targetFrameRatio < 0.8) targetFrameRatio = 0.8;

    double displayWidth, displayHeight;
    if (targetFrameRatio >= 1.0) {
      displayWidth = 1080;
      displayHeight = 1080 / targetFrameRatio;
    } else {
      displayHeight = 1080;
      displayWidth = 1080 * targetFrameRatio;
    }

    double contentWidth = displayWidth;
    double contentHeight = displayWidth / imgRatio;
    if (contentHeight < displayHeight) {
      contentHeight = displayHeight;
      contentWidth = displayHeight * imgRatio;
    }

    double dx = (contentWidth - displayWidth) / 2;
    double dy = (contentHeight - displayHeight) / 2;

    _transformController.value = Matrix4.identity()..translate(-dx, -dy);
  }

  @override
  Widget build(BuildContext context) {
    double imgWidth = widget.entity.width.toDouble();
    double imgHeight = widget.entity.height.toDouble();
    double imgRatio = imgWidth / imgHeight;

    double targetFrameRatio = widget.isSquareMode ? 1.0 : imgRatio;
    if (!widget.isSquareMode && targetFrameRatio < 0.8) targetFrameRatio = 0.8;

    double displayWidth, displayHeight;
    if (targetFrameRatio >= 1.0) {
      displayWidth = 1080;
      displayHeight = 1080 / targetFrameRatio;
    } else {
      displayHeight = 1080;
      displayWidth = 1080 * targetFrameRatio;
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
        width: 1080,
        height: 1080,
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              // FRAME GAMBAR KEMBALI TAJAM (NORMAL)
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: displayWidth,
                height: displayHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  // TIDAK ADA BORDER RADIUS DISINI
                ),
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
    // ... (Grid code sama seperti sebelumnya)
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
    // ... (Line code sama seperti sebelumnya)
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
