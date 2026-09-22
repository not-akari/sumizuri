import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/features/profile/data/avatar_files.dart';
import 'package:sumizuri/features/profile/pages/avatar_crop_page.dart';

Future<String?> pickProfileAvatar(BuildContext context) async {
  final picked = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Image',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
      ),
    ],
  );
  if (picked == null || !context.mounted) return null;

  final croppedBytes = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => AvatarCropPage(imagePath: picked.path)),
  );
  if (croppedBytes == null) return null;

  return saveAvatarImage(croppedBytes);
}
