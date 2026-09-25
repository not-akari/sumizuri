// Reads a Mihon (.tachibk) backup: gzip-compressed protobuf without bundled schema.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

class MihonChapter {
  const MihonChapter({
    required this.url,
    required this.name,
    required this.scanlator,
    required this.isRead,
    required this.lastPageRead,
    required this.dateUpload,
    required this.number,
  });

  final String url;
  final String name;
  final String? scanlator;
  final bool isRead;

  /// The last page index read (Mihon stores index without total page count).
  final int? lastPageRead;
  final DateTime? dateUpload;
  final double? number;
}

class MihonHistoryEntry {
  const MihonHistoryEntry({required this.chapterUrl, required this.lastReadAt});

  final String chapterUrl;
  final DateTime? lastReadAt;
}

/// A library category from the backup. Titles refer to it by [order], not
/// by id, exactly as Mihon's own restore does.
class MihonCategory {
  const MihonCategory({required this.name, required this.order});

  final String name;
  final int order;
}

/// Favorited title imported from the backup's manga list.
class MihonManga {
  const MihonManga({
    required this.title,
    required this.url,
    required this.coverUrl,
    required this.sourceName,
    required this.chapters,
    required this.history,
    this.categoryOrders = const [],
  });

  final String title;
  final String url;
  final String? coverUrl;

  /// Source display name preserved for reference.
  final String? sourceName;
  final List<MihonChapter> chapters;
  final List<MihonHistoryEntry> history;

  /// The [MihonCategory.order] of each category this title was in.
  final List<int> categoryOrders;
}

/// Library entries extracted from a Mihon backup.
class MihonBackup {
  const MihonBackup({required this.manga, this.categories = const []});

  final List<MihonManga> manga;
  final List<MihonCategory> categories;
}

/// Something in the file could not be read as a Mihon backup.
class MihonBackupUnreadable implements Exception {
  const MihonBackupUnreadable(this.message);

  final String message;

  @override
  String toString() => message;
}

DateTime? _epochMs(int? ms) =>
    ms == null || ms <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);

// Minimal protobuf wire-format parser reading only required field numbers.

class _Field {
  const _Field(this.number, this.wireType, this.value);

  final int number;
  final int wireType;

  /// An int for wire types 0 and 5, a Uint8List for wire type 2.
  final Object value;
}

(int, int) _readVarint(Uint8List buf, int pos) {
  var result = 0;
  var shift = 0;
  while (true) {
    final byte = buf[pos];
    pos++;
    result |= (byte & 0x7f) << shift;
    if ((byte & 0x80) == 0) break;
    shift += 7;
  }
  return (result, pos);
}

List<_Field> _decodeMessage(Uint8List buf, int start, int end) {
  final fields = <_Field>[];
  var pos = start;
  while (pos < end) {
    final (tag, afterTag) = _readVarint(buf, pos);
    final fieldNumber = tag >> 3;
    final wireType = tag & 7;
    switch (wireType) {
      case 0:
        final (value, next) = _readVarint(buf, afterTag);
        fields.add(_Field(fieldNumber, wireType, value));
        pos = next;
      case 2:
        final (len, afterLen) = _readVarint(buf, afterTag);
        fields.add(
          _Field(fieldNumber, wireType, buf.sublist(afterLen, afterLen + len)),
        );
        pos = afterLen + len;
      case 5:
        fields.add(
          _Field(
            fieldNumber,
            wireType,
            ByteData.sublistView(
              buf,
              afterTag,
              afterTag + 4,
            ).getUint32(0, Endian.little),
          ),
        );
        pos = afterTag + 4;
      case 1:
        pos =
            afterTag +
            8; // A 64-bit fixed field; nothing this codec needs uses one.
      default:
        throw MihonBackupUnreadable('Unexpected protobuf wire type $wireType.');
    }
  }
  return fields;
}

String? _str(List<_Field> msg, int number) {
  for (final f in msg) {
    if (f.number == number) {
      return utf8.decode(f.value as Uint8List, allowMalformed: true);
    }
  }
  return null;
}

int? _varint(List<_Field> msg, int number) {
  for (final f in msg) {
    if (f.number == number) return f.value as int;
  }
  return null;
}

/// True when [number] is present at all: a boolean field that protobuf omits when false.
bool _flag(List<_Field> msg, int number) => _varint(msg, number) != null;

List<List<_Field>> _messages(List<_Field> msg, int number) => [
  for (final f in msg)
    if (f.number == number)
      _decodeMessage(f.value as Uint8List, 0, (f.value as Uint8List).length),
];

/// A repeated integer field, whether written one value per entry or packed
/// into a single length-delimited run.
List<int> _varints(List<_Field> msg, int number) {
  final out = <int>[];
  for (final f in msg) {
    if (f.number != number) continue;
    if (f.wireType == 0) {
      out.add(f.value as int);
    } else if (f.wireType == 2) {
      final bytes = f.value as Uint8List;
      var pos = 0;
      while (pos < bytes.length) {
        final (value, next) = _readVarint(bytes, pos);
        out.add(value);
        pos = next;
      }
    }
  }
  return out;
}

double? _float32(List<_Field> msg, int number) {
  for (final f in msg) {
    if (f.number == number) {
      return (ByteData(4)..setUint32(0, f.value as int, Endian.little))
          .getFloat32(0, Endian.little);
    }
  }
  return null;
}

Uint8List _decompress(File file) {
  final bytes = file.readAsBytesSync();
  try {
    return const GZipDecoder().decodeBytes(bytes);
  } catch (error) {
    throw MihonBackupUnreadable('This does not look like a Mihon backup file.');
  }
}

MihonBackup readMihonBackup(File file) {
  final List<_Field> top;
  try {
    final bytes = _decompress(file);
    top = _decodeMessage(bytes, 0, bytes.length);
  } on MihonBackupUnreadable {
    rethrow;
  } catch (error) {
    throw MihonBackupUnreadable('Not a readable Mihon backup: $error');
  }

  // BackupSource holds each source's display name keyed by the id its manga refer to.
  final sourceNames = <int, String>{};
  for (final source in _messages(top, 101)) {
    final id = _varint(source, 2);
    final name = _str(source, 1);
    if (id != null && name != null) sourceNames[id] = name;
  }

  final manga = [
    for (final m in _messages(top, 1))
      // BackupManga.favorite (proto field 100) defaults to true, so
      // kotlinx.serialization omits it from the wire for every favorited
      // manga - only non-favorited entries (favorite = false) get it
      // written, with value 0. Presence therefore means "not a favorite",
      // the opposite of _flag's usual "presence means true" convention.
      if (_varint(m, 100) != 0)
        MihonManga(
          title: (_str(m, 3) ?? '').trim(),
          url: _str(m, 2) ?? '',
          coverUrl: _str(m, 9),
          sourceName: sourceNames[_varint(m, 1)],
          chapters: [
            for (final c in _messages(m, 16))
              MihonChapter(
                url: _str(c, 1) ?? '',
                name: (_str(c, 2) ?? '').trim(),
                scanlator: _str(c, 3),
                isRead: _flag(c, 4),
                lastPageRead: _varint(c, 6),
                dateUpload: _epochMs(_varint(c, 8)),
                number: _float32(c, 9),
              ),
          ],
          categoryOrders: _varints(m, 17),
          history: [
            for (final h in _messages(m, 104))
              MihonHistoryEntry(
                chapterUrl: _str(h, 1) ?? '',
                lastReadAt: _epochMs(_varint(h, 2)),
              ),
          ],
        ),
  ];

  final categories = [
    for (final c in _messages(top, 2))
      if (_str(c, 1) case final name?)
        MihonCategory(name: name.trim(), order: _varint(c, 2) ?? 0),
  ];

  return MihonBackup(manga: manga, categories: categories);
}
