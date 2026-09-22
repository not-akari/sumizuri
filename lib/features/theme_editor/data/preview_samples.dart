import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/library/providers/library_providers.dart';

class PreviewSample {
  const PreviewSample({
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    this.unreadCount,
    this.status,
  });

  final String title;
  final String? coverUrl;
  final String? customCoverPath;
  final int? unreadCount;
  final String? status;
}

const _placeholders = [
  PreviewSample(title: 'Ashes of Kyoto', unreadCount: 3),
  PreviewSample(title: 'Whisper of the Tide', status: 'completed'),
  PreviewSample(title: 'Crimson Loom', unreadCount: 5, status: 'hiatus'),
];

class PreviewSeed extends Notifier<int> {
  @override
  int build() => Random().nextInt(1 << 30);

  void reshuffle() => state = Random().nextInt(1 << 30);
}

final previewSeedProvider = NotifierProvider.autoDispose<PreviewSeed, int>(
  PreviewSeed.new,
);

final previewSamplesProvider = Provider.autoDispose<List<PreviewSample>>((ref) {
  final seed = ref.watch(previewSeedProvider);
  final entries = ref.watch(libraryEntriesProvider()).value ?? const [];
  final picked = [...entries]..shuffle(Random(seed));
  final samples = [
    for (final e in picked.take(3))
      PreviewSample(
        title: e.title,
        coverUrl: e.coverUrl,
        customCoverPath: e.customCoverPath,
        unreadCount: e.unreadCount > 0 ? e.unreadCount : null,
        status: e.status,
      ),
  ];
  return [...samples, ..._placeholders.skip(samples.length)];
});
