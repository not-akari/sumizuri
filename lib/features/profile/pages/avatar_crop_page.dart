import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _outputSize = 512;

class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final _editorController = ImageEditorController();
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    final bytes = await _cropToBytes();
    if (!mounted) return;
    if (bytes == null) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  Future<Uint8List?> _cropToBytes() async {
    final editorState = _editorController.state;
    final cropRect = _editorController.getCropRect();
    if (editorState == null || cropRect == null) return null;

    var src = await compute(img.decodeImage, editorState.rawImageData);
    if (src == null) return null;
    src = img.bakeOrientation(src);

    var cropped = img.copyCrop(
      src,
      x: cropRect.left.round().clamp(0, src.width - 1),
      y: cropRect.top.round().clamp(0, src.height - 1),
      width: cropRect.width.round().clamp(1, src.width),
      height: cropRect.height.round().clamp(1, src.height),
    );

    if (cropped.width > _outputSize || cropped.height > _outputSize) {
      cropped = img.copyResize(
        cropped,
        width: _outputSize,
        height: _outputSize,
      );
    }

    return Uint8List.fromList(img.encodePng(cropped));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.profileCropAvatarTitle),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _confirm,
          ),
        ],
      ),
      body: ExtendedImage.file(
        File(widget.imagePath),
        fit: BoxFit.contain,
        mode: ExtendedImageMode.editor,
        cacheRawData: true,
        initEditorConfigHandler: (state) => EditorConfig(
          maxScale: 8.0,
          cropRectPadding: const EdgeInsets.all(24),
          cropAspectRatio: 1.0,
          controller: _editorController,
        ),
      ),
    );
  }
}
