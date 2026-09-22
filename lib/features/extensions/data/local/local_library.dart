import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

const _imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
  '.avif',
  '.bmp',
};
const _archiveExtensions = {'.cbz', '.zip'};

bool _isImage(String path) =>
    _imageExtensions.contains(p.extension(path).toLowerCase());
bool _isArchive(String path) =>
    _archiveExtensions.contains(p.extension(path).toLowerCase());
bool _isEpub(String path) => p.extension(path).toLowerCase() == '.epub';
bool _isText(String path) => p.extension(path).toLowerCase() == '.txt';

// Files a zip made on a Mac adds beside the real ones.
bool _isJunk(String path) =>
    path.contains('__MACOSX') || p.basename(path).startsWith('.');

/// Orders names the way a person would, so chapter 2 comes before chapter 10.
int naturalCompare(String a, String b) {
  final pieces = RegExp(r'(\d+)|(\D+)');
  final left = pieces.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final right = pieces.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    final x = left[i];
    final y = right[i];
    final numbers = int.tryParse(x) != null && int.tryParse(y) != null;
    final order = numbers
        ? BigInt.parse(x).compareTo(BigInt.parse(y))
        : x.compareTo(y);
    if (order != 0) return order;
  }
  return left.length.compareTo(right.length);
}

/// A small stable hash, so the same file always lands in the same cache folder.
String _stableKey(String text) {
  var hash = 0xcbf29ce484222325;
  for (final unit in utf8.encode(text)) {
    hash = ((hash ^ unit) * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash.toRadixString(16);
}

String _cacheKey(FileSystemEntity entity) {
  final stat = entity.statSync();
  return _stableKey(
    '${entity.path}|${stat.modified.millisecondsSinceEpoch}|${stat.size}',
  );
}

Future<T> _withZip<T>(String path, Future<T> Function(Archive zip) body) async {
  final input = InputFileStream(path);
  try {
    return await body(ZipDecoder().decodeStream(input));
  } finally {
    await input.close();
  }
}

List<ArchiveFile> _imagesOf(Archive zip) {
  final images = [
    for (final file in zip.files)
      if (file.isFile && _isImage(file.name) && !_isJunk(file.name)) file,
  ];
  images.sort((a, b) => naturalCompare(a.name, b.name));
  return images;
}

List<FileSystemEntity> _children(String path) {
  try {
    return Directory(path).listSync(followLinks: false);
  } on FileSystemException {
    return const [];
  }
}

List<File> _imageFiles(String dir) => [
  for (final e in _children(dir))
    if (e is File && _isImage(e.path) && !_isJunk(e.path)) e,
]..sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));

String _titleOf(String path) => p.basenameWithoutExtension(path);

/// What a local library holds, kept apart from how a source is asked for it.
class LocalLibrary {
  LocalLibrary({required this.root, required this.type, required this.cache});

  final String root;
  final MediaType type;

  /// A folder for what has to be unpacked, such as the pages of a CBZ.
  final Directory cache;

  /// The titles in the folder, in name order.
  List<FileSystemEntity> titles() {
    final found = [
      for (final e in _children(root))
        if (!_isJunk(e.path) && _isTitle(e)) e,
    ];
    found.sort((a, b) => naturalCompare(_titleOf(a.path), _titleOf(b.path)));
    return found;
  }

  bool _isTitle(FileSystemEntity e) {
    if (e is Directory) return true;
    if (e is! File) return false;
    return type == MediaType.novel
        ? (_isEpub(e.path) || _isText(e.path))
        : _isArchive(e.path);
  }

  /// A title as the browse list shows it, with a cover when one can be found cheaply.
  Future<MEntry> entryFor(FileSystemEntity entity) async {
    return MEntry(
      url: entity.path,
      title: _titleOf(entity.path),
      coverUrl: await coverOf(entity.path),
    );
  }

  /// Everything the title itself says: an EPUB names its author and describes itself.
  Future<MEntry> detailsOf(String path) async {
    final base = MEntry(
      url: path,
      title: _titleOf(path),
      coverUrl: await coverOf(path),
    );
    if (_isEpub(path)) {
      final book = await _readEpub(path);
      if (book != null) {
        return MEntry(
          url: path,
          title: book.title.isEmpty ? base.title : book.title,
          coverUrl: base.coverUrl,
          author: book.author,
          description: book.description,
        );
      }
    }
    return base;
  }

  // A cover.* file, else the first picture, else the first picture inside the first archive.
  Future<String?> coverOf(String path) async {
    try {
      if (FileSystemEntity.isDirectorySync(path)) {
        final images = _imageFiles(path);
        final named = images.where(
          (f) => p.basenameWithoutExtension(f.path).toLowerCase() == 'cover',
        );
        if (named.isNotEmpty) return named.first.path;
        if (images.isNotEmpty) return images.first.path;
        final inside = _chaptersOfFolder(path);
        return inside.isEmpty ? null : await coverOf(inside.first.path);
      }
      if (_isArchive(path)) return await _coverFromArchive(path);
      if (_isEpub(path)) return await _coverFromEpub(path);
    } on Object {
      // A broken file only means no cover.
    }
    return null;
  }

  Future<String?> _coverFromArchive(String path) async {
    final key = _cacheKey(File(path));
    final existing = _cached('cover_$key');
    if (existing != null) return existing;
    return _withZip(path, (zip) async {
      final images = _imagesOf(zip);
      if (images.isEmpty) return null;
      return _save('cover_$key', images.first.name, images.first.content);
    });
  }

  Future<String?> _coverFromEpub(String path) async {
    final key = _cacheKey(File(path));
    final existing = _cached('cover_$key');
    if (existing != null) return existing;
    final book = await _readEpub(path);
    final cover = book?.coverPath;
    if (cover == null) return null;
    return _withZip(path, (zip) async {
      final file = zip.findFile(cover);
      return file == null ? null : _save('cover_$key', cover, file.content);
    });
  }

  String? _cached(String stem) {
    if (!cache.existsSync()) return null;
    for (final e in cache.listSync()) {
      if (e is File && p.basenameWithoutExtension(e.path) == stem) {
        return e.path;
      }
    }
    return null;
  }

  Future<String> _save(String stem, String sourceName, Uint8List bytes) async {
    await cache.create(recursive: true);
    final file = File(p.join(cache.path, '$stem${p.extension(sourceName)}'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// The chapters of a title.
  Future<List<MChapter>> chaptersOf(String path) async {
    if (type == MediaType.novel) return _novelChapters(path);
    if (_isArchive(path)) {
      return [_chapterFor(File(path), 0, single: true)];
    }
    final parts = _chaptersOfFolder(path);
    if (parts.isNotEmpty) {
      return [for (final (i, e) in parts.indexed) _chapterFor(e, i)];
    }
    if (_imageFiles(path).isNotEmpty) {
      return [_chapterFor(Directory(path), 0, single: true)];
    }
    return const [];
  }

  // Archives and folders of pictures inside a title folder, each one a chapter.
  List<FileSystemEntity> _chaptersOfFolder(String dir) {
    final parts = [
      for (final e in _children(dir))
        if (!_isJunk(e.path) &&
            (e is Directory || (e is File && _isArchive(e.path))))
          e,
    ];
    parts.sort((a, b) => naturalCompare(_titleOf(a.path), _titleOf(b.path)));
    return parts;
  }

  MChapter _chapterFor(FileSystemEntity e, int index, {bool single = false}) {
    final name = _titleOf(e.path);
    return MChapter(
      url: e.path,
      title: name,
      number: single ? 1 : chapterNumberOf(name) ?? index + 1.0,
      dateUploaded: e.statSync().modified,
    );
  }

  Future<List<MChapter>> _novelChapters(String path) async {
    if (_isText(path)) {
      return [_chapterFor(File(path), 0, single: true)];
    }
    if (_isEpub(path)) {
      final book = await _readEpub(path);
      if (book == null) return const [];
      final modified = File(path).statSync().modified;
      return [
        for (final (i, doc) in book.spine.indexed)
          MChapter(
            url: '$path#$i',
            title: doc.title ?? 'Chapter ${i + 1}',
            number: i + 1.0,
            dateUploaded: modified,
          ),
      ];
    }
    final texts = [
      for (final e in _children(path))
        if (e is File && _isText(e.path) && !_isJunk(e.path)) e,
    ]..sort((a, b) => naturalCompare(_titleOf(a.path), _titleOf(b.path)));
    return [for (final (i, f) in texts.indexed) _chapterFor(f, i)];
  }

  /// The pages of a chapter: unpacked pictures for a manga, one page of text for a novel.
  Future<List<MPage>> pagesOf(String chapterUrl) async {
    if (type == MediaType.novel) return _novelPages(chapterUrl);
    if (_isArchive(chapterUrl)) return _archivePages(chapterUrl);
    var images = _imageFiles(chapterUrl);
    // A cover.jpg beside the pages is the cover, not a page.
    final withoutCover = [
      for (final f in images)
        if (p.basenameWithoutExtension(f.path).toLowerCase() != 'cover') f,
    ];
    if (withoutCover.isNotEmpty) images = withoutCover;
    return [
      for (final (i, f) in images.indexed)
        MPage(index: i, imageUrl: p.normalize(f.path), isLocalFile: true),
    ];
  }

  Future<List<MPage>> _archivePages(String path) async {
    final folder = Directory(
      p.join(cache.path, 'pages_${_cacheKey(File(path))}'),
    );
    final done = File(p.join(folder.path, '.done'));
    if (!done.existsSync()) {
      await folder.create(recursive: true);
      await _withZip(path, (zip) async {
        for (final (i, image) in _imagesOf(zip).indexed) {
          final name =
              '${i.toString().padLeft(5, '0')}${p.extension(image.name)}';
          await File(p.join(folder.path, name)).writeAsBytes(image.content);
        }
      });
      await done.writeAsString('');
    }
    return [
      for (final (i, f) in _imageFiles(folder.path).indexed)
        MPage(index: i, imageUrl: p.normalize(f.path), isLocalFile: true),
    ];
  }

  Future<List<MPage>> _novelPages(String chapterUrl) async {
    final hash = chapterUrl.lastIndexOf('#');
    if (hash > 0 && _isEpub(chapterUrl.substring(0, hash))) {
      final path = chapterUrl.substring(0, hash);
      final index = int.tryParse(chapterUrl.substring(hash + 1)) ?? 0;
      final book = await _readEpub(path);
      if (book == null || index < 0 || index >= book.spine.length) {
        return const [];
      }
      final entry = book.spine[index].path;
      final text = await _withZip(path, (zip) async {
        final file = zip.findFile(entry);
        return file == null
            ? ''
            : htmlToText(utf8.decode(file.content, allowMalformed: true));
      });
      return [MPage(index: 0, text: text)];
    }
    final bytes = await File(chapterUrl).readAsBytes();
    return [MPage(index: 0, text: utf8.decode(bytes, allowMalformed: true))];
  }

  Future<_Epub?> _readEpub(String path) async {
    try {
      return await _withZip(path, (zip) async => _parseEpub(zip));
    } on Object {
      return null;
    }
  }
}

/// The first number in a name, such as 12.5 in "Chapter 12.5", or null when there is none.
double? chapterNumberOf(String name) {
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(name);
  return match == null ? null : double.tryParse(match[1]!);
}

class _EpubDoc {
  const _EpubDoc(this.path, this.title);

  final String path;
  final String? title;
}

class _Epub {
  const _Epub({
    required this.title,
    required this.author,
    required this.description,
    required this.coverPath,
    required this.spine,
  });

  final String title;
  final String? author;
  final String? description;
  final String? coverPath;
  final List<_EpubDoc> spine;
}

String _decodeEntities(String text) =>
    html.parse(text).documentElement?.text.trim() ?? text.trim();

String? _tag(String xml, String name) {
  final match = RegExp(
    '<$name\\b[^>]*>([\\s\\S]*?)</$name>',
    caseSensitive: false,
  ).firstMatch(xml);
  if (match == null) return null;
  final text = _decodeEntities(match[1]!);
  return text.isEmpty ? null : text;
}

String? _attribute(String tag, String name) {
  final match = RegExp(
    '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')',
    caseSensitive: false,
  ).firstMatch(tag);
  return match == null ? null : (match[1] ?? match[2]);
}

String _resolve(String base, String href) {
  final clean = Uri.decodeFull(href.split('#').first);
  final joined = base.isEmpty || base == '.' ? clean : '$base/$clean';
  return p.posix.normalize(joined);
}

_Epub? _parseEpub(Archive zip) {
  String? read(String name) {
    final file = zip.findFile(name);
    return file == null
        ? null
        : utf8.decode(file.content, allowMalformed: true);
  }

  final container = read('META-INF/container.xml');
  final rootPath = container == null
      ? null
      : RegExp(r'full-path\s*=\s*"([^"]+)"').firstMatch(container)?[1];
  final opf = rootPath == null ? null : read(rootPath);
  if (rootPath == null || opf == null) return null;
  final base = p.posix.dirname(rootPath);

  final manifest = <String, ({String href, String type, String props})>{};
  for (final item in RegExp(r'<item\b[^>]*>').allMatches(opf)) {
    final tag = item[0]!;
    final id = _attribute(tag, 'id');
    final href = _attribute(tag, 'href');
    if (id == null || href == null) continue;
    manifest[id] = (
      href: _resolve(base, href),
      type: _attribute(tag, 'media-type') ?? '',
      props: _attribute(tag, 'properties') ?? '',
    );
  }

  final titles = <String, String>{};
  for (final item in manifest.values) {
    final isNav = item.props.contains('nav');
    final isNcx = item.type == 'application/x-dtbncx+xml';
    if (!isNav && !isNcx) continue;
    final text = read(item.href);
    if (text == null) continue;
    final tocBase = p.posix.dirname(item.href);
    if (isNcx) {
      for (final point in RegExp(
        r'<navPoint\b[\s\S]*?<text>([\s\S]*?)</text>[\s\S]*?<content\b([^>]*)/?>',
        caseSensitive: false,
      ).allMatches(text)) {
        final src = _attribute(point[2]!, 'src');
        if (src != null) {
          titles.putIfAbsent(
            _resolve(tocBase, src),
            () => _decodeEntities(point[1]!),
          );
        }
      }
    } else {
      for (final link in RegExp(
        r'<a\b([^>]*)>([\s\S]*?)</a>',
        caseSensitive: false,
      ).allMatches(text)) {
        final href = _attribute(link[1]!, 'href');
        if (href != null) {
          titles.putIfAbsent(
            _resolve(tocBase, href),
            () => _decodeEntities(link[2]!.replaceAll(RegExp(r'<[^>]+>'), '')),
          );
        }
      }
    }
  }

  final spine = <_EpubDoc>[];
  for (final ref in RegExp(r'<itemref\b[^>]*>').allMatches(opf)) {
    final tag = ref[0]!;
    if (_attribute(tag, 'linear')?.toLowerCase() == 'no') continue;
    final item = manifest[_attribute(tag, 'idref')];
    if (item == null || !item.type.contains('html')) continue;
    spine.add(_EpubDoc(item.href, titles[item.href]));
  }

  String? cover;
  final meta = RegExp(r'<meta\b[^>]*name\s*=\s*"cover"[^>]*>').firstMatch(opf);
  final coverId = meta == null ? null : _attribute(meta[0]!, 'content');
  if (coverId != null) cover = manifest[coverId]?.href;
  cover ??= manifest.values
      .where((i) => i.props.contains('cover-image'))
      .map((i) => i.href)
      .firstOrNull;

  return _Epub(
    title: _tag(opf, 'dc:title') ?? '',
    author: _tag(opf, 'dc:creator'),
    description: _tag(opf, 'dc:description'),
    coverPath: cover,
    spine: spine,
  );
}

const _blockTags = {
  'p',
  'div',
  'br',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'tr',
  'blockquote',
  'section',
  'hr',
};

/// The readable text of a page of HTML, with a blank line between paragraphs.
String htmlToText(String source) {
  final document = html.parse(source);
  final out = StringBuffer();
  void walk(dom.Node node) {
    if (node is dom.Text) {
      out.write(node.text.replaceAll(RegExp(r'\s+'), ' '));
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName;
    if (tag == 'script' || tag == 'style' || tag == 'head') return;
    final block = _blockTags.contains(tag);
    if (block) out.write('\n');
    for (final child in node.nodes) {
      walk(child);
    }
    if (block) out.write('\n');
  }

  walk(document.body ?? document);
  final lines = out.toString().split('\n').map((l) => l.trim()).toList();
  final paragraphs = <String>[];
  for (final line in lines) {
    if (line.isNotEmpty) paragraphs.add(line);
  }
  return paragraphs.join('\n\n');
}
