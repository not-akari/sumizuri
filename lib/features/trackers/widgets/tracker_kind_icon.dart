import 'package:flutter/material.dart';

import 'package:sumizuri/features/trackers/models/tracker_models.dart';

/// The icon a tracker is known by in lists and rows.
IconData trackerKindIcon(TrackerKind kind) => switch (kind) {
  TrackerKind.anilist => Icons.auto_awesome_outlined,
  TrackerKind.mal => Icons.format_list_bulleted_rounded,
};
