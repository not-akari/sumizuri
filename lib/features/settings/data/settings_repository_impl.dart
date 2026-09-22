// Drift backed implementation of the settings repository.

import 'package:sumizuri/core/theming/app_theme.dart' show AppColorScheme;
import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/models/backup_preferences.dart';
import 'package:sumizuri/features/settings/data/setting_rows.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/data/settings_repository.dart';

part 'settings_repository_kv_methods.dart';

class DriftSettingsRepository
    with DriftKvSettingsMethods
    implements SettingsRepository {
  DriftSettingsRepository(this._db, this._logger, {this.profileId = 1});

  @override
  final AppDatabase _db;
  @override
  final AppLogger _logger;
  @override
  final int profileId;

  static const _tag = 'settings';
}
