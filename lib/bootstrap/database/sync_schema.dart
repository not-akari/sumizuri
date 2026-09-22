import 'package:drift/drift.dart';

const _nowMs = "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)";
const _notApplying = '(SELECT applying FROM sync_state WHERE id = 0) = 0';

const syncedTables = {
  'categories': 'categories',
  'library_entries': 'entries',
  'entry_branches': 'branches',
  'content_units': 'chapters',
  'chapter_progress': 'progress',
  'reading_sessions': 'sessions',
  'installed_sources': 'sources',
  'repos': 'repos',
};

String _touch(String table, String idExpr) =>
    'UPDATE $table SET updated_at = $_nowMs WHERE id = $idExpr';

String _profileOf(String table) => switch (table) {
  'library_entries' || 'categories' => 'OLD.profile_id',
  _ => '(SELECT profile_id FROM active_profile WHERE id = 0)',
};

List<Trigger> _entityTriggers(String table, String entity) => [
  Trigger(
    'CREATE TRIGGER trg_${table}_sync_insert AFTER INSERT ON $table '
        'WHEN NEW.updated_at = 0 AND $_notApplying '
        'BEGIN ${_touch(table, 'NEW.id')}; END',
    'trg_${table}_sync_insert',
  ),
  Trigger(
    'CREATE TRIGGER trg_${table}_sync_update AFTER UPDATE ON $table '
        'WHEN NEW.updated_at = OLD.updated_at AND $_notApplying '
        'BEGIN ${_touch(table, 'NEW.id')}; END',
    'trg_${table}_sync_update',
  ),
  Trigger(
    'CREATE TRIGGER trg_${table}_sync_delete AFTER DELETE ON $table '
        'WHEN OLD.client_id IS NOT NULL AND $_notApplying '
        "BEGIN INSERT OR IGNORE INTO sync_deletions (profile_id, entity, client_id) VALUES (${_profileOf(table)}, '$entity', OLD.client_id); END",
    'trg_${table}_sync_delete',
  ),
];

List<Trigger> _relatedTriggers() {
  Trigger touchEntry(String name, String event, String row) => Trigger(
    'CREATE TRIGGER $name AFTER $event ON entry_categories WHEN $_notApplying '
    'BEGIN ${_touch('library_entries', '$row.library_entry_id')}; END',
    name,
  );
  return [
    touchEntry('trg_entry_categories_sync_insert', 'INSERT', 'NEW'),
    touchEntry('trg_entry_categories_sync_delete', 'DELETE', 'OLD'),
  ];
}

final List<Trigger> settingValueTriggers = [
  Trigger(
    'CREATE TRIGGER trg_setting_values_sync_insert AFTER INSERT ON setting_values '
        'WHEN NEW.updated_at = 0 AND $_notApplying '
        'BEGIN UPDATE setting_values SET updated_at = $_nowMs WHERE id = NEW.id; END',
    'trg_setting_values_sync_insert',
  ),
  Trigger(
    'CREATE TRIGGER trg_setting_values_sync_update AFTER UPDATE ON setting_values '
        'WHEN NEW.updated_at = OLD.updated_at AND $_notApplying '
        'BEGIN UPDATE setting_values SET updated_at = $_nowMs WHERE id = NEW.id; END',
    'trg_setting_values_sync_update',
  ),
  Trigger(
    'CREATE TRIGGER trg_profiles_remove_settings AFTER DELETE ON profiles '
        'BEGIN DELETE FROM setting_values WHERE profile_id = OLD.id; END',
    'trg_profiles_remove_settings',
  ),
];

final List<Trigger> syncTriggers = [
  for (final e in syncedTables.entries) ..._entityTriggers(e.key, e.value),
  ..._relatedTriggers(),
];
