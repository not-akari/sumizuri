import 'package:drift/drift.dart';

const _nowMs = "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)";
const _notApplying = '(SELECT applying FROM sync_state WHERE id = 0) = 0';

const _queueLinkedTitle =
    'INSERT INTO tracker_outbox (link_id, first_queued_at) '
    'SELECT tl.id, $_nowMs FROM content_units cu '
    'JOIN tracker_links tl ON tl.library_entry_id = cu.library_entry_id '
    'WHERE cu.id = NEW.content_unit_id '
    'ON CONFLICT(link_id) DO UPDATE SET version = version + 1';

final List<Trigger> trackerTriggers = [
  Trigger(
    'CREATE TRIGGER trg_tracker_outbox_progress_insert AFTER INSERT ON chapter_progress '
        'WHEN NEW.consumed = 1 AND $_notApplying '
        'BEGIN $_queueLinkedTitle; END',
    'trg_tracker_outbox_progress_insert',
  ),
  Trigger(
    'CREATE TRIGGER trg_tracker_outbox_progress_update AFTER UPDATE OF consumed ON chapter_progress '
        'WHEN NEW.consumed = 1 AND OLD.consumed = 0 AND $_notApplying '
        'BEGIN $_queueLinkedTitle; END',
    'trg_tracker_outbox_progress_update',
  ),
];
