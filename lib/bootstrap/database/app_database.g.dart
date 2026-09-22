// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, avatarPath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final String? avatarPath;
  final DateTime createdAt;
  const Profile({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    Value<String?> avatarPath = const Value.absent(),
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, avatarPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.avatarPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? avatarPath,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EntryBranchesTable extends EntryBranches
    with TableInfo<$EntryBranchesTable, EntryBranche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryBranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _libraryEntryIdMeta = const VerificationMeta(
    'libraryEntryId',
  );
  @override
  late final GeneratedColumn<int> libraryEntryId = GeneratedColumn<int>(
    'library_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    libraryEntryId,
    name,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryBranche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('library_entry_id')) {
      context.handle(
        _libraryEntryIdMeta,
        libraryEntryId.isAcceptableOrUnknown(
          data['library_entry_id']!,
          _libraryEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryEntryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryBranche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryBranche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      libraryEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_entry_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntryBranchesTable createAlias(String alias) {
    return $EntryBranchesTable(attachedDatabase, alias);
  }
}

class EntryBranche extends DataClass implements Insertable<EntryBranche> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int libraryEntryId;
  final String name;
  final DateTime createdAt;
  const EntryBranche({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.libraryEntryId,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['library_entry_id'] = Variable<int>(libraryEntryId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntryBranchesCompanion toCompanion(bool nullToAbsent) {
    return EntryBranchesCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      libraryEntryId: Value(libraryEntryId),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory EntryBranche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryBranche(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      libraryEntryId: serializer.fromJson<int>(json['libraryEntryId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'libraryEntryId': serializer.toJson<int>(libraryEntryId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EntryBranche copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    int? libraryEntryId,
    String? name,
    DateTime? createdAt,
  }) => EntryBranche(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    libraryEntryId: libraryEntryId ?? this.libraryEntryId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  EntryBranche copyWithCompanion(EntryBranchesCompanion data) {
    return EntryBranche(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      libraryEntryId: data.libraryEntryId.present
          ? data.libraryEntryId.value
          : this.libraryEntryId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryBranche(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientId, updatedAt, libraryEntryId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryBranche &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.libraryEntryId == this.libraryEntryId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class EntryBranchesCompanion extends UpdateCompanion<EntryBranche> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int> libraryEntryId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const EntryBranchesCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.libraryEntryId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntryBranchesCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required int libraryEntryId,
    required String name,
    this.createdAt = const Value.absent(),
  }) : libraryEntryId = Value(libraryEntryId),
       name = Value(name);
  static Insertable<EntryBranche> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? libraryEntryId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (libraryEntryId != null) 'library_entry_id': libraryEntryId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntryBranchesCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int>? libraryEntryId,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return EntryBranchesCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      libraryEntryId: libraryEntryId ?? this.libraryEntryId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (libraryEntryId.present) {
      map['library_entry_id'] = Variable<int>(libraryEntryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryBranchesCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LibraryEntriesTable extends LibraryEntries
    with TableInfo<$LibraryEntriesTable, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeBranchIdMeta = const VerificationMeta(
    'activeBranchId',
  );
  @override
  late final GeneratedColumn<int> activeBranchId = GeneratedColumn<int>(
    'active_branch_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entry_branches (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, int> mediaType =
      GeneratedColumn<int>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($LibraryEntriesTable.$convertermediaType);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excludedScanlatorsMeta =
      const VerificationMeta('excludedScanlators');
  @override
  late final GeneratedColumn<String> excludedScanlators =
      GeneratedColumn<String>(
        'excluded_scanlators',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ReaderMode?, int> readerMode =
      GeneratedColumn<int>(
        'reader_mode',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ReaderMode?>($LibraryEntriesTable.$converterreaderModen);
  static const VerificationMeta _readerModeCheckedMeta = const VerificationMeta(
    'readerModeChecked',
  );
  @override
  late final GeneratedColumn<bool> readerModeChecked = GeneratedColumn<bool>(
    'reader_mode_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reader_mode_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReaderDualPageMode?, int>
  readerDualPageMode =
      GeneratedColumn<int>(
        'reader_dual_page_mode',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ReaderDualPageMode?>(
        $LibraryEntriesTable.$converterreaderDualPageModen,
      );
  static const VerificationMeta _settingsOverridesMeta = const VerificationMeta(
    'settingsOverrides',
  );
  @override
  late final GeneratedColumn<String> settingsOverrides =
      GeneratedColumn<String>(
        'settings_overrides',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customCoverPathMeta = const VerificationMeta(
    'customCoverPath',
  );
  @override
  late final GeneratedColumn<String> customCoverPath = GeneratedColumn<String>(
    'custom_cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    activeBranchId,
    profileId,
    title,
    coverUrl,
    mediaType,
    sourceId,
    excludedScanlators,
    sourceKey,
    externalId,
    favorite,
    addedAt,
    lastUpdatedAt,
    readerMode,
    readerModeChecked,
    readerDualPageMode,
    settingsOverrides,
    customCoverPath,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('active_branch_id')) {
      context.handle(
        _activeBranchIdMeta,
        activeBranchId.isAcceptableOrUnknown(
          data['active_branch_id']!,
          _activeBranchIdMeta,
        ),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('excluded_scanlators')) {
      context.handle(
        _excludedScanlatorsMeta,
        excludedScanlators.isAcceptableOrUnknown(
          data['excluded_scanlators']!,
          _excludedScanlatorsMeta,
        ),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('reader_mode_checked')) {
      context.handle(
        _readerModeCheckedMeta,
        readerModeChecked.isAcceptableOrUnknown(
          data['reader_mode_checked']!,
          _readerModeCheckedMeta,
        ),
      );
    }
    if (data.containsKey('settings_overrides')) {
      context.handle(
        _settingsOverridesMeta,
        settingsOverrides.isAcceptableOrUnknown(
          data['settings_overrides']!,
          _settingsOverridesMeta,
        ),
      );
    }
    if (data.containsKey('custom_cover_path')) {
      context.handle(
        _customCoverPathMeta,
        customCoverPath.isAcceptableOrUnknown(
          data['custom_cover_path']!,
          _customCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, sourceId, externalId},
  ];
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      activeBranchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_branch_id'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      mediaType: $LibraryEntriesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      excludedScanlators: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excluded_scanlators'],
      ),
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
      )!,
      readerMode: $LibraryEntriesTable.$converterreaderModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reader_mode'],
        ),
      ),
      readerModeChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reader_mode_checked'],
      )!,
      readerDualPageMode: $LibraryEntriesTable.$converterreaderDualPageModen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}reader_dual_page_mode'],
            ),
          ),
      settingsOverrides: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_overrides'],
      ),
      customCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_cover_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
    );
  }

  @override
  $LibraryEntriesTable createAlias(String alias) {
    return $LibraryEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, int, int> $convertermediaType =
      const EnumIndexConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<ReaderMode, int, int> $converterreaderMode =
      const EnumIndexConverter<ReaderMode>(ReaderMode.values);
  static JsonTypeConverter2<ReaderMode?, int?, int?> $converterreaderModen =
      JsonTypeConverter2.asNullable($converterreaderMode);
  static JsonTypeConverter2<ReaderDualPageMode, int, int>
  $converterreaderDualPageMode = const EnumIndexConverter<ReaderDualPageMode>(
    ReaderDualPageMode.values,
  );
  static JsonTypeConverter2<ReaderDualPageMode?, int?, int?>
  $converterreaderDualPageModen = JsonTypeConverter2.asNullable(
    $converterreaderDualPageMode,
  );
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int? activeBranchId;
  final int profileId;
  final String title;
  final String? coverUrl;
  final MediaType mediaType;
  final String sourceId;
  final String? excludedScanlators;
  final String? sourceKey;
  final String externalId;
  final bool favorite;
  final DateTime addedAt;
  final DateTime lastUpdatedAt;
  final ReaderMode? readerMode;

  /// Whether auto-detection has already run for this entry, so a normal
  /// (non-webtoon) series isn't re-probed on every chapter open forever.
  final bool readerModeChecked;

  /// Two-page layout chosen for this series alone. Null follows the app setting.
  final ReaderDualPageMode? readerDualPageMode;

  /// Settings this series keeps for itself as JSON. Null follows the app settings.
  final String? settingsOverrides;
  final String? customCoverPath;
  final String? status;
  const LibraryEntry({
    required this.id,
    this.clientId,
    required this.updatedAt,
    this.activeBranchId,
    required this.profileId,
    required this.title,
    this.coverUrl,
    required this.mediaType,
    required this.sourceId,
    this.excludedScanlators,
    this.sourceKey,
    required this.externalId,
    required this.favorite,
    required this.addedAt,
    required this.lastUpdatedAt,
    this.readerMode,
    required this.readerModeChecked,
    this.readerDualPageMode,
    this.settingsOverrides,
    this.customCoverPath,
    this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || activeBranchId != null) {
      map['active_branch_id'] = Variable<int>(activeBranchId);
    }
    map['profile_id'] = Variable<int>(profileId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    {
      map['media_type'] = Variable<int>(
        $LibraryEntriesTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || excludedScanlators != null) {
      map['excluded_scanlators'] = Variable<String>(excludedScanlators);
    }
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    map['external_id'] = Variable<String>(externalId);
    map['favorite'] = Variable<bool>(favorite);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    if (!nullToAbsent || readerMode != null) {
      map['reader_mode'] = Variable<int>(
        $LibraryEntriesTable.$converterreaderModen.toSql(readerMode),
      );
    }
    map['reader_mode_checked'] = Variable<bool>(readerModeChecked);
    if (!nullToAbsent || readerDualPageMode != null) {
      map['reader_dual_page_mode'] = Variable<int>(
        $LibraryEntriesTable.$converterreaderDualPageModen.toSql(
          readerDualPageMode,
        ),
      );
    }
    if (!nullToAbsent || settingsOverrides != null) {
      map['settings_overrides'] = Variable<String>(settingsOverrides);
    }
    if (!nullToAbsent || customCoverPath != null) {
      map['custom_cover_path'] = Variable<String>(customCoverPath);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      activeBranchId: activeBranchId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeBranchId),
      profileId: Value(profileId),
      title: Value(title),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      mediaType: Value(mediaType),
      sourceId: Value(sourceId),
      excludedScanlators: excludedScanlators == null && nullToAbsent
          ? const Value.absent()
          : Value(excludedScanlators),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      externalId: Value(externalId),
      favorite: Value(favorite),
      addedAt: Value(addedAt),
      lastUpdatedAt: Value(lastUpdatedAt),
      readerMode: readerMode == null && nullToAbsent
          ? const Value.absent()
          : Value(readerMode),
      readerModeChecked: Value(readerModeChecked),
      readerDualPageMode: readerDualPageMode == null && nullToAbsent
          ? const Value.absent()
          : Value(readerDualPageMode),
      settingsOverrides: settingsOverrides == null && nullToAbsent
          ? const Value.absent()
          : Value(settingsOverrides),
      customCoverPath: customCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(customCoverPath),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
    );
  }

  factory LibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      activeBranchId: serializer.fromJson<int?>(json['activeBranchId']),
      profileId: serializer.fromJson<int>(json['profileId']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      mediaType: $LibraryEntriesTable.$convertermediaType.fromJson(
        serializer.fromJson<int>(json['mediaType']),
      ),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      excludedScanlators: serializer.fromJson<String?>(
        json['excludedScanlators'],
      ),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      externalId: serializer.fromJson<String>(json['externalId']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
      readerMode: $LibraryEntriesTable.$converterreaderModen.fromJson(
        serializer.fromJson<int?>(json['readerMode']),
      ),
      readerModeChecked: serializer.fromJson<bool>(json['readerModeChecked']),
      readerDualPageMode: $LibraryEntriesTable.$converterreaderDualPageModen
          .fromJson(serializer.fromJson<int?>(json['readerDualPageMode'])),
      settingsOverrides: serializer.fromJson<String?>(
        json['settingsOverrides'],
      ),
      customCoverPath: serializer.fromJson<String?>(json['customCoverPath']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'activeBranchId': serializer.toJson<int?>(activeBranchId),
      'profileId': serializer.toJson<int>(profileId),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'mediaType': serializer.toJson<int>(
        $LibraryEntriesTable.$convertermediaType.toJson(mediaType),
      ),
      'sourceId': serializer.toJson<String>(sourceId),
      'excludedScanlators': serializer.toJson<String?>(excludedScanlators),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'externalId': serializer.toJson<String>(externalId),
      'favorite': serializer.toJson<bool>(favorite),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
      'readerMode': serializer.toJson<int?>(
        $LibraryEntriesTable.$converterreaderModen.toJson(readerMode),
      ),
      'readerModeChecked': serializer.toJson<bool>(readerModeChecked),
      'readerDualPageMode': serializer.toJson<int?>(
        $LibraryEntriesTable.$converterreaderDualPageModen.toJson(
          readerDualPageMode,
        ),
      ),
      'settingsOverrides': serializer.toJson<String?>(settingsOverrides),
      'customCoverPath': serializer.toJson<String?>(customCoverPath),
      'status': serializer.toJson<String?>(status),
    };
  }

  LibraryEntry copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    Value<int?> activeBranchId = const Value.absent(),
    int? profileId,
    String? title,
    Value<String?> coverUrl = const Value.absent(),
    MediaType? mediaType,
    String? sourceId,
    Value<String?> excludedScanlators = const Value.absent(),
    Value<String?> sourceKey = const Value.absent(),
    String? externalId,
    bool? favorite,
    DateTime? addedAt,
    DateTime? lastUpdatedAt,
    Value<ReaderMode?> readerMode = const Value.absent(),
    bool? readerModeChecked,
    Value<ReaderDualPageMode?> readerDualPageMode = const Value.absent(),
    Value<String?> settingsOverrides = const Value.absent(),
    Value<String?> customCoverPath = const Value.absent(),
    Value<String?> status = const Value.absent(),
  }) => LibraryEntry(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    activeBranchId: activeBranchId.present
        ? activeBranchId.value
        : this.activeBranchId,
    profileId: profileId ?? this.profileId,
    title: title ?? this.title,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    mediaType: mediaType ?? this.mediaType,
    sourceId: sourceId ?? this.sourceId,
    excludedScanlators: excludedScanlators.present
        ? excludedScanlators.value
        : this.excludedScanlators,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    externalId: externalId ?? this.externalId,
    favorite: favorite ?? this.favorite,
    addedAt: addedAt ?? this.addedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    readerMode: readerMode.present ? readerMode.value : this.readerMode,
    readerModeChecked: readerModeChecked ?? this.readerModeChecked,
    readerDualPageMode: readerDualPageMode.present
        ? readerDualPageMode.value
        : this.readerDualPageMode,
    settingsOverrides: settingsOverrides.present
        ? settingsOverrides.value
        : this.settingsOverrides,
    customCoverPath: customCoverPath.present
        ? customCoverPath.value
        : this.customCoverPath,
    status: status.present ? status.value : this.status,
  );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      activeBranchId: data.activeBranchId.present
          ? data.activeBranchId.value
          : this.activeBranchId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      title: data.title.present ? data.title.value : this.title,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      excludedScanlators: data.excludedScanlators.present
          ? data.excludedScanlators.value
          : this.excludedScanlators,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      readerMode: data.readerMode.present
          ? data.readerMode.value
          : this.readerMode,
      readerModeChecked: data.readerModeChecked.present
          ? data.readerModeChecked.value
          : this.readerModeChecked,
      readerDualPageMode: data.readerDualPageMode.present
          ? data.readerDualPageMode.value
          : this.readerDualPageMode,
      settingsOverrides: data.settingsOverrides.present
          ? data.settingsOverrides.value
          : this.settingsOverrides,
      customCoverPath: data.customCoverPath.present
          ? data.customCoverPath.value
          : this.customCoverPath,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('activeBranchId: $activeBranchId, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('sourceId: $sourceId, ')
          ..write('excludedScanlators: $excludedScanlators, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('externalId: $externalId, ')
          ..write('favorite: $favorite, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('readerMode: $readerMode, ')
          ..write('readerModeChecked: $readerModeChecked, ')
          ..write('readerDualPageMode: $readerDualPageMode, ')
          ..write('settingsOverrides: $settingsOverrides, ')
          ..write('customCoverPath: $customCoverPath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    clientId,
    updatedAt,
    activeBranchId,
    profileId,
    title,
    coverUrl,
    mediaType,
    sourceId,
    excludedScanlators,
    sourceKey,
    externalId,
    favorite,
    addedAt,
    lastUpdatedAt,
    readerMode,
    readerModeChecked,
    readerDualPageMode,
    settingsOverrides,
    customCoverPath,
    status,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.activeBranchId == this.activeBranchId &&
          other.profileId == this.profileId &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.mediaType == this.mediaType &&
          other.sourceId == this.sourceId &&
          other.excludedScanlators == this.excludedScanlators &&
          other.sourceKey == this.sourceKey &&
          other.externalId == this.externalId &&
          other.favorite == this.favorite &&
          other.addedAt == this.addedAt &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.readerMode == this.readerMode &&
          other.readerModeChecked == this.readerModeChecked &&
          other.readerDualPageMode == this.readerDualPageMode &&
          other.settingsOverrides == this.settingsOverrides &&
          other.customCoverPath == this.customCoverPath &&
          other.status == this.status);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int?> activeBranchId;
  final Value<int> profileId;
  final Value<String> title;
  final Value<String?> coverUrl;
  final Value<MediaType> mediaType;
  final Value<String> sourceId;
  final Value<String?> excludedScanlators;
  final Value<String?> sourceKey;
  final Value<String> externalId;
  final Value<bool> favorite;
  final Value<DateTime> addedAt;
  final Value<DateTime> lastUpdatedAt;
  final Value<ReaderMode?> readerMode;
  final Value<bool> readerModeChecked;
  final Value<ReaderDualPageMode?> readerDualPageMode;
  final Value<String?> settingsOverrides;
  final Value<String?> customCoverPath;
  final Value<String?> status;
  const LibraryEntriesCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.activeBranchId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.excludedScanlators = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.externalId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.readerMode = const Value.absent(),
    this.readerModeChecked = const Value.absent(),
    this.readerDualPageMode = const Value.absent(),
    this.settingsOverrides = const Value.absent(),
    this.customCoverPath = const Value.absent(),
    this.status = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.activeBranchId = const Value.absent(),
    this.profileId = const Value.absent(),
    required String title,
    this.coverUrl = const Value.absent(),
    required MediaType mediaType,
    required String sourceId,
    this.excludedScanlators = const Value.absent(),
    this.sourceKey = const Value.absent(),
    required String externalId,
    this.favorite = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.readerMode = const Value.absent(),
    this.readerModeChecked = const Value.absent(),
    this.readerDualPageMode = const Value.absent(),
    this.settingsOverrides = const Value.absent(),
    this.customCoverPath = const Value.absent(),
    this.status = const Value.absent(),
  }) : title = Value(title),
       mediaType = Value(mediaType),
       sourceId = Value(sourceId),
       externalId = Value(externalId);
  static Insertable<LibraryEntry> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? activeBranchId,
    Expression<int>? profileId,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<int>? mediaType,
    Expression<String>? sourceId,
    Expression<String>? excludedScanlators,
    Expression<String>? sourceKey,
    Expression<String>? externalId,
    Expression<bool>? favorite,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastUpdatedAt,
    Expression<int>? readerMode,
    Expression<bool>? readerModeChecked,
    Expression<int>? readerDualPageMode,
    Expression<String>? settingsOverrides,
    Expression<String>? customCoverPath,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (activeBranchId != null) 'active_branch_id': activeBranchId,
      if (profileId != null) 'profile_id': profileId,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (mediaType != null) 'media_type': mediaType,
      if (sourceId != null) 'source_id': sourceId,
      if (excludedScanlators != null) 'excluded_scanlators': excludedScanlators,
      if (sourceKey != null) 'source_key': sourceKey,
      if (externalId != null) 'external_id': externalId,
      if (favorite != null) 'favorite': favorite,
      if (addedAt != null) 'added_at': addedAt,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (readerMode != null) 'reader_mode': readerMode,
      if (readerModeChecked != null) 'reader_mode_checked': readerModeChecked,
      if (readerDualPageMode != null)
        'reader_dual_page_mode': readerDualPageMode,
      if (settingsOverrides != null) 'settings_overrides': settingsOverrides,
      if (customCoverPath != null) 'custom_cover_path': customCoverPath,
      if (status != null) 'status': status,
    });
  }

  LibraryEntriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int?>? activeBranchId,
    Value<int>? profileId,
    Value<String>? title,
    Value<String?>? coverUrl,
    Value<MediaType>? mediaType,
    Value<String>? sourceId,
    Value<String?>? excludedScanlators,
    Value<String?>? sourceKey,
    Value<String>? externalId,
    Value<bool>? favorite,
    Value<DateTime>? addedAt,
    Value<DateTime>? lastUpdatedAt,
    Value<ReaderMode?>? readerMode,
    Value<bool>? readerModeChecked,
    Value<ReaderDualPageMode?>? readerDualPageMode,
    Value<String?>? settingsOverrides,
    Value<String?>? customCoverPath,
    Value<String?>? status,
  }) {
    return LibraryEntriesCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      mediaType: mediaType ?? this.mediaType,
      sourceId: sourceId ?? this.sourceId,
      excludedScanlators: excludedScanlators ?? this.excludedScanlators,
      sourceKey: sourceKey ?? this.sourceKey,
      externalId: externalId ?? this.externalId,
      favorite: favorite ?? this.favorite,
      addedAt: addedAt ?? this.addedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      readerMode: readerMode ?? this.readerMode,
      readerModeChecked: readerModeChecked ?? this.readerModeChecked,
      readerDualPageMode: readerDualPageMode ?? this.readerDualPageMode,
      settingsOverrides: settingsOverrides ?? this.settingsOverrides,
      customCoverPath: customCoverPath ?? this.customCoverPath,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (activeBranchId.present) {
      map['active_branch_id'] = Variable<int>(activeBranchId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<int>(
        $LibraryEntriesTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (excludedScanlators.present) {
      map['excluded_scanlators'] = Variable<String>(excludedScanlators.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (readerMode.present) {
      map['reader_mode'] = Variable<int>(
        $LibraryEntriesTable.$converterreaderModen.toSql(readerMode.value),
      );
    }
    if (readerModeChecked.present) {
      map['reader_mode_checked'] = Variable<bool>(readerModeChecked.value);
    }
    if (readerDualPageMode.present) {
      map['reader_dual_page_mode'] = Variable<int>(
        $LibraryEntriesTable.$converterreaderDualPageModen.toSql(
          readerDualPageMode.value,
        ),
      );
    }
    if (settingsOverrides.present) {
      map['settings_overrides'] = Variable<String>(settingsOverrides.value);
    }
    if (customCoverPath.present) {
      map['custom_cover_path'] = Variable<String>(customCoverPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('activeBranchId: $activeBranchId, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('sourceId: $sourceId, ')
          ..write('excludedScanlators: $excludedScanlators, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('externalId: $externalId, ')
          ..write('favorite: $favorite, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('readerMode: $readerMode, ')
          ..write('readerModeChecked: $readerModeChecked, ')
          ..write('readerDualPageMode: $readerDualPageMode, ')
          ..write('settingsOverrides: $settingsOverrides, ')
          ..write('customCoverPath: $customCoverPath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $ContentUnitsTable extends ContentUnits
    with TableInfo<$ContentUnitsTable, ContentUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentUnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _libraryEntryIdMeta = const VerificationMeta(
    'libraryEntryId',
  );
  @override
  late final GeneratedColumn<int> libraryEntryId = GeneratedColumn<int>(
    'library_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<double> number = GeneratedColumn<double>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayTitleMeta = const VerificationMeta(
    'displayTitle',
  );
  @override
  late final GeneratedColumn<String> displayTitle = GeneratedColumn<String>(
    'display_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateUploadedMeta = const VerificationMeta(
    'dateUploaded',
  );
  @override
  late final GeneratedColumn<DateTime> dateUploaded = GeneratedColumn<DateTime>(
    'date_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _downloadedMeta = const VerificationMeta(
    'downloaded',
  );
  @override
  late final GeneratedColumn<bool> downloaded = GeneratedColumn<bool>(
    'downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scanlatorMeta = const VerificationMeta(
    'scanlator',
  );
  @override
  late final GeneratedColumn<String> scanlator = GeneratedColumn<String>(
    'scanlator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookmarkedMeta = const VerificationMeta(
    'bookmarked',
  );
  @override
  late final GeneratedColumn<bool> bookmarked = GeneratedColumn<bool>(
    'bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    libraryEntryId,
    number,
    displayTitle,
    url,
    dateUploaded,
    downloaded,
    scanlator,
    bookmarked,
    localPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_units';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentUnit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('library_entry_id')) {
      context.handle(
        _libraryEntryIdMeta,
        libraryEntryId.isAcceptableOrUnknown(
          data['library_entry_id']!,
          _libraryEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryEntryIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('display_title')) {
      context.handle(
        _displayTitleMeta,
        displayTitle.isAcceptableOrUnknown(
          data['display_title']!,
          _displayTitleMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('date_uploaded')) {
      context.handle(
        _dateUploadedMeta,
        dateUploaded.isAcceptableOrUnknown(
          data['date_uploaded']!,
          _dateUploadedMeta,
        ),
      );
    }
    if (data.containsKey('downloaded')) {
      context.handle(
        _downloadedMeta,
        downloaded.isAcceptableOrUnknown(data['downloaded']!, _downloadedMeta),
      );
    }
    if (data.containsKey('scanlator')) {
      context.handle(
        _scanlatorMeta,
        scanlator.isAcceptableOrUnknown(data['scanlator']!, _scanlatorMeta),
      );
    }
    if (data.containsKey('bookmarked')) {
      context.handle(
        _bookmarkedMeta,
        bookmarked.isAcceptableOrUnknown(data['bookmarked']!, _bookmarkedMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {libraryEntryId, url},
  ];
  @override
  ContentUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentUnit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      libraryEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_entry_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}number'],
      )!,
      displayTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_title'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      dateUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_uploaded'],
      )!,
      downloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}downloaded'],
      )!,
      scanlator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scanlator'],
      ),
      bookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bookmarked'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
    );
  }

  @override
  $ContentUnitsTable createAlias(String alias) {
    return $ContentUnitsTable(attachedDatabase, alias);
  }
}

class ContentUnit extends DataClass implements Insertable<ContentUnit> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int libraryEntryId;
  final double number;
  final String? displayTitle;
  final String url;
  final DateTime dateUploaded;
  final bool downloaded;
  final String? scanlator;
  final bool bookmarked;
  final String? localPath;
  const ContentUnit({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.libraryEntryId,
    required this.number,
    this.displayTitle,
    required this.url,
    required this.dateUploaded,
    required this.downloaded,
    this.scanlator,
    required this.bookmarked,
    this.localPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['library_entry_id'] = Variable<int>(libraryEntryId);
    map['number'] = Variable<double>(number);
    if (!nullToAbsent || displayTitle != null) {
      map['display_title'] = Variable<String>(displayTitle);
    }
    map['url'] = Variable<String>(url);
    map['date_uploaded'] = Variable<DateTime>(dateUploaded);
    map['downloaded'] = Variable<bool>(downloaded);
    if (!nullToAbsent || scanlator != null) {
      map['scanlator'] = Variable<String>(scanlator);
    }
    map['bookmarked'] = Variable<bool>(bookmarked);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    return map;
  }

  ContentUnitsCompanion toCompanion(bool nullToAbsent) {
    return ContentUnitsCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      libraryEntryId: Value(libraryEntryId),
      number: Value(number),
      displayTitle: displayTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(displayTitle),
      url: Value(url),
      dateUploaded: Value(dateUploaded),
      downloaded: Value(downloaded),
      scanlator: scanlator == null && nullToAbsent
          ? const Value.absent()
          : Value(scanlator),
      bookmarked: Value(bookmarked),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
    );
  }

  factory ContentUnit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentUnit(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      libraryEntryId: serializer.fromJson<int>(json['libraryEntryId']),
      number: serializer.fromJson<double>(json['number']),
      displayTitle: serializer.fromJson<String?>(json['displayTitle']),
      url: serializer.fromJson<String>(json['url']),
      dateUploaded: serializer.fromJson<DateTime>(json['dateUploaded']),
      downloaded: serializer.fromJson<bool>(json['downloaded']),
      scanlator: serializer.fromJson<String?>(json['scanlator']),
      bookmarked: serializer.fromJson<bool>(json['bookmarked']),
      localPath: serializer.fromJson<String?>(json['localPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'libraryEntryId': serializer.toJson<int>(libraryEntryId),
      'number': serializer.toJson<double>(number),
      'displayTitle': serializer.toJson<String?>(displayTitle),
      'url': serializer.toJson<String>(url),
      'dateUploaded': serializer.toJson<DateTime>(dateUploaded),
      'downloaded': serializer.toJson<bool>(downloaded),
      'scanlator': serializer.toJson<String?>(scanlator),
      'bookmarked': serializer.toJson<bool>(bookmarked),
      'localPath': serializer.toJson<String?>(localPath),
    };
  }

  ContentUnit copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    int? libraryEntryId,
    double? number,
    Value<String?> displayTitle = const Value.absent(),
    String? url,
    DateTime? dateUploaded,
    bool? downloaded,
    Value<String?> scanlator = const Value.absent(),
    bool? bookmarked,
    Value<String?> localPath = const Value.absent(),
  }) => ContentUnit(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    libraryEntryId: libraryEntryId ?? this.libraryEntryId,
    number: number ?? this.number,
    displayTitle: displayTitle.present ? displayTitle.value : this.displayTitle,
    url: url ?? this.url,
    dateUploaded: dateUploaded ?? this.dateUploaded,
    downloaded: downloaded ?? this.downloaded,
    scanlator: scanlator.present ? scanlator.value : this.scanlator,
    bookmarked: bookmarked ?? this.bookmarked,
    localPath: localPath.present ? localPath.value : this.localPath,
  );
  ContentUnit copyWithCompanion(ContentUnitsCompanion data) {
    return ContentUnit(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      libraryEntryId: data.libraryEntryId.present
          ? data.libraryEntryId.value
          : this.libraryEntryId,
      number: data.number.present ? data.number.value : this.number,
      displayTitle: data.displayTitle.present
          ? data.displayTitle.value
          : this.displayTitle,
      url: data.url.present ? data.url.value : this.url,
      dateUploaded: data.dateUploaded.present
          ? data.dateUploaded.value
          : this.dateUploaded,
      downloaded: data.downloaded.present
          ? data.downloaded.value
          : this.downloaded,
      scanlator: data.scanlator.present ? data.scanlator.value : this.scanlator,
      bookmarked: data.bookmarked.present
          ? data.bookmarked.value
          : this.bookmarked,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentUnit(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('number: $number, ')
          ..write('displayTitle: $displayTitle, ')
          ..write('url: $url, ')
          ..write('dateUploaded: $dateUploaded, ')
          ..write('downloaded: $downloaded, ')
          ..write('scanlator: $scanlator, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    updatedAt,
    libraryEntryId,
    number,
    displayTitle,
    url,
    dateUploaded,
    downloaded,
    scanlator,
    bookmarked,
    localPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentUnit &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.libraryEntryId == this.libraryEntryId &&
          other.number == this.number &&
          other.displayTitle == this.displayTitle &&
          other.url == this.url &&
          other.dateUploaded == this.dateUploaded &&
          other.downloaded == this.downloaded &&
          other.scanlator == this.scanlator &&
          other.bookmarked == this.bookmarked &&
          other.localPath == this.localPath);
}

class ContentUnitsCompanion extends UpdateCompanion<ContentUnit> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int> libraryEntryId;
  final Value<double> number;
  final Value<String?> displayTitle;
  final Value<String> url;
  final Value<DateTime> dateUploaded;
  final Value<bool> downloaded;
  final Value<String?> scanlator;
  final Value<bool> bookmarked;
  final Value<String?> localPath;
  const ContentUnitsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.libraryEntryId = const Value.absent(),
    this.number = const Value.absent(),
    this.displayTitle = const Value.absent(),
    this.url = const Value.absent(),
    this.dateUploaded = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.scanlator = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.localPath = const Value.absent(),
  });
  ContentUnitsCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required int libraryEntryId,
    required double number,
    this.displayTitle = const Value.absent(),
    required String url,
    this.dateUploaded = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.scanlator = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.localPath = const Value.absent(),
  }) : libraryEntryId = Value(libraryEntryId),
       number = Value(number),
       url = Value(url);
  static Insertable<ContentUnit> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? libraryEntryId,
    Expression<double>? number,
    Expression<String>? displayTitle,
    Expression<String>? url,
    Expression<DateTime>? dateUploaded,
    Expression<bool>? downloaded,
    Expression<String>? scanlator,
    Expression<bool>? bookmarked,
    Expression<String>? localPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (libraryEntryId != null) 'library_entry_id': libraryEntryId,
      if (number != null) 'number': number,
      if (displayTitle != null) 'display_title': displayTitle,
      if (url != null) 'url': url,
      if (dateUploaded != null) 'date_uploaded': dateUploaded,
      if (downloaded != null) 'downloaded': downloaded,
      if (scanlator != null) 'scanlator': scanlator,
      if (bookmarked != null) 'bookmarked': bookmarked,
      if (localPath != null) 'local_path': localPath,
    });
  }

  ContentUnitsCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int>? libraryEntryId,
    Value<double>? number,
    Value<String?>? displayTitle,
    Value<String>? url,
    Value<DateTime>? dateUploaded,
    Value<bool>? downloaded,
    Value<String?>? scanlator,
    Value<bool>? bookmarked,
    Value<String?>? localPath,
  }) {
    return ContentUnitsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      libraryEntryId: libraryEntryId ?? this.libraryEntryId,
      number: number ?? this.number,
      displayTitle: displayTitle ?? this.displayTitle,
      url: url ?? this.url,
      dateUploaded: dateUploaded ?? this.dateUploaded,
      downloaded: downloaded ?? this.downloaded,
      scanlator: scanlator ?? this.scanlator,
      bookmarked: bookmarked ?? this.bookmarked,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (libraryEntryId.present) {
      map['library_entry_id'] = Variable<int>(libraryEntryId.value);
    }
    if (number.present) {
      map['number'] = Variable<double>(number.value);
    }
    if (displayTitle.present) {
      map['display_title'] = Variable<String>(displayTitle.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (dateUploaded.present) {
      map['date_uploaded'] = Variable<DateTime>(dateUploaded.value);
    }
    if (downloaded.present) {
      map['downloaded'] = Variable<bool>(downloaded.value);
    }
    if (scanlator.present) {
      map['scanlator'] = Variable<String>(scanlator.value);
    }
    if (bookmarked.present) {
      map['bookmarked'] = Variable<bool>(bookmarked.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentUnitsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('number: $number, ')
          ..write('displayTitle: $displayTitle, ')
          ..write('url: $url, ')
          ..write('dateUploaded: $dateUploaded, ')
          ..write('downloaded: $downloaded, ')
          ..write('scanlator: $scanlator, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }
}

class $ChapterProgressTable extends ChapterProgress
    with TableInfo<$ChapterProgressTable, ChapterProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentUnitIdMeta = const VerificationMeta(
    'contentUnitId',
  );
  @override
  late final GeneratedColumn<int> contentUnitId = GeneratedColumn<int>(
    'content_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES content_units (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entry_branches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _consumedMeta = const VerificationMeta(
    'consumed',
  );
  @override
  late final GeneratedColumn<bool> consumed = GeneratedColumn<bool>(
    'consumed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consumed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressPositionMeta = const VerificationMeta(
    'progressPosition',
  );
  @override
  late final GeneratedColumn<double> progressPosition = GeneratedColumn<double>(
    'progress_position',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    contentUnitId,
    branchId,
    consumed,
    consumedAt,
    progressPosition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('content_unit_id')) {
      context.handle(
        _contentUnitIdMeta,
        contentUnitId.isAcceptableOrUnknown(
          data['content_unit_id']!,
          _contentUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentUnitIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('consumed')) {
      context.handle(
        _consumedMeta,
        consumed.isAcceptableOrUnknown(data['consumed']!, _consumedMeta),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    if (data.containsKey('progress_position')) {
      context.handle(
        _progressPositionMeta,
        progressPosition.isAcceptableOrUnknown(
          data['progress_position']!,
          _progressPositionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contentUnitId, branchId},
  ];
  @override
  ChapterProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      contentUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_unit_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
      consumed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consumed'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      ),
      progressPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_position'],
      ),
    );
  }

  @override
  $ChapterProgressTable createAlias(String alias) {
    return $ChapterProgressTable(attachedDatabase, alias);
  }
}

class ChapterProgressData extends DataClass
    implements Insertable<ChapterProgressData> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int contentUnitId;
  final int branchId;
  final bool consumed;
  final DateTime? consumedAt;
  final double? progressPosition;
  const ChapterProgressData({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.contentUnitId,
    required this.branchId,
    required this.consumed,
    this.consumedAt,
    this.progressPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['content_unit_id'] = Variable<int>(contentUnitId);
    map['branch_id'] = Variable<int>(branchId);
    map['consumed'] = Variable<bool>(consumed);
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<DateTime>(consumedAt);
    }
    if (!nullToAbsent || progressPosition != null) {
      map['progress_position'] = Variable<double>(progressPosition);
    }
    return map;
  }

  ChapterProgressCompanion toCompanion(bool nullToAbsent) {
    return ChapterProgressCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      contentUnitId: Value(contentUnitId),
      branchId: Value(branchId),
      consumed: Value(consumed),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
      progressPosition: progressPosition == null && nullToAbsent
          ? const Value.absent()
          : Value(progressPosition),
    );
  }

  factory ChapterProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterProgressData(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      contentUnitId: serializer.fromJson<int>(json['contentUnitId']),
      branchId: serializer.fromJson<int>(json['branchId']),
      consumed: serializer.fromJson<bool>(json['consumed']),
      consumedAt: serializer.fromJson<DateTime?>(json['consumedAt']),
      progressPosition: serializer.fromJson<double?>(json['progressPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'contentUnitId': serializer.toJson<int>(contentUnitId),
      'branchId': serializer.toJson<int>(branchId),
      'consumed': serializer.toJson<bool>(consumed),
      'consumedAt': serializer.toJson<DateTime?>(consumedAt),
      'progressPosition': serializer.toJson<double?>(progressPosition),
    };
  }

  ChapterProgressData copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    int? contentUnitId,
    int? branchId,
    bool? consumed,
    Value<DateTime?> consumedAt = const Value.absent(),
    Value<double?> progressPosition = const Value.absent(),
  }) => ChapterProgressData(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    contentUnitId: contentUnitId ?? this.contentUnitId,
    branchId: branchId ?? this.branchId,
    consumed: consumed ?? this.consumed,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
    progressPosition: progressPosition.present
        ? progressPosition.value
        : this.progressPosition,
  );
  ChapterProgressData copyWithCompanion(ChapterProgressCompanion data) {
    return ChapterProgressData(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      contentUnitId: data.contentUnitId.present
          ? data.contentUnitId.value
          : this.contentUnitId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      consumed: data.consumed.present ? data.consumed.value : this.consumed,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      progressPosition: data.progressPosition.present
          ? data.progressPosition.value
          : this.progressPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterProgressData(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentUnitId: $contentUnitId, ')
          ..write('branchId: $branchId, ')
          ..write('consumed: $consumed, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('progressPosition: $progressPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    updatedAt,
    contentUnitId,
    branchId,
    consumed,
    consumedAt,
    progressPosition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterProgressData &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.contentUnitId == this.contentUnitId &&
          other.branchId == this.branchId &&
          other.consumed == this.consumed &&
          other.consumedAt == this.consumedAt &&
          other.progressPosition == this.progressPosition);
}

class ChapterProgressCompanion extends UpdateCompanion<ChapterProgressData> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int> contentUnitId;
  final Value<int> branchId;
  final Value<bool> consumed;
  final Value<DateTime?> consumedAt;
  final Value<double?> progressPosition;
  const ChapterProgressCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.contentUnitId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.consumed = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.progressPosition = const Value.absent(),
  });
  ChapterProgressCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required int contentUnitId,
    required int branchId,
    this.consumed = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.progressPosition = const Value.absent(),
  }) : contentUnitId = Value(contentUnitId),
       branchId = Value(branchId);
  static Insertable<ChapterProgressData> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? contentUnitId,
    Expression<int>? branchId,
    Expression<bool>? consumed,
    Expression<DateTime>? consumedAt,
    Expression<double>? progressPosition,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (contentUnitId != null) 'content_unit_id': contentUnitId,
      if (branchId != null) 'branch_id': branchId,
      if (consumed != null) 'consumed': consumed,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (progressPosition != null) 'progress_position': progressPosition,
    });
  }

  ChapterProgressCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int>? contentUnitId,
    Value<int>? branchId,
    Value<bool>? consumed,
    Value<DateTime?>? consumedAt,
    Value<double?>? progressPosition,
  }) {
    return ChapterProgressCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      contentUnitId: contentUnitId ?? this.contentUnitId,
      branchId: branchId ?? this.branchId,
      consumed: consumed ?? this.consumed,
      consumedAt: consumedAt ?? this.consumedAt,
      progressPosition: progressPosition ?? this.progressPosition,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (contentUnitId.present) {
      map['content_unit_id'] = Variable<int>(contentUnitId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (consumed.present) {
      map['consumed'] = Variable<bool>(consumed.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (progressPosition.present) {
      map['progress_position'] = Variable<double>(progressPosition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterProgressCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('contentUnitId: $contentUnitId, ')
          ..write('branchId: $branchId, ')
          ..write('consumed: $consumed, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('progressPosition: $progressPosition')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _excludeFromUpdateMeta = const VerificationMeta(
    'excludeFromUpdate',
  );
  @override
  late final GeneratedColumn<bool> excludeFromUpdate = GeneratedColumn<bool>(
    'exclude_from_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exclude_from_update" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, int> mediaType =
      GeneratedColumn<int>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(MediaType.manga.index),
      ).withConverter<MediaType>($CategoriesTable.$convertermediaType);
  static const VerificationMeta _useSmartRuleMeta = const VerificationMeta(
    'useSmartRule',
  );
  @override
  late final GeneratedColumn<bool> useSmartRule = GeneratedColumn<bool>(
    'use_smart_rule',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_smart_rule" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategorySortField, int>
  sortField = GeneratedColumn<int>(
    'sort_field',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(CategorySortField.title.index),
  ).withConverter<CategorySortField>($CategoriesTable.$convertersortField);
  static const VerificationMeta _sortAscendingMeta = const VerificationMeta(
    'sortAscending',
  );
  @override
  late final GeneratedColumn<bool> sortAscending = GeneratedColumn<bool>(
    'sort_ascending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sort_ascending" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryStatusFilter, int>
  statusFilter =
      GeneratedColumn<int>(
        'status_filter',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(CategoryStatusFilter.any.index),
      ).withConverter<CategoryStatusFilter>(
        $CategoriesTable.$converterstatusFilter,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    profileId,
    name,
    sortOrder,
    excludeFromUpdate,
    mediaType,
    useSmartRule,
    sortField,
    sortAscending,
    statusFilter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('exclude_from_update')) {
      context.handle(
        _excludeFromUpdateMeta,
        excludeFromUpdate.isAcceptableOrUnknown(
          data['exclude_from_update']!,
          _excludeFromUpdateMeta,
        ),
      );
    }
    if (data.containsKey('use_smart_rule')) {
      context.handle(
        _useSmartRuleMeta,
        useSmartRule.isAcceptableOrUnknown(
          data['use_smart_rule']!,
          _useSmartRuleMeta,
        ),
      );
    }
    if (data.containsKey('sort_ascending')) {
      context.handle(
        _sortAscendingMeta,
        sortAscending.isAcceptableOrUnknown(
          data['sort_ascending']!,
          _sortAscendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      excludeFromUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_update'],
      )!,
      mediaType: $CategoriesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      useSmartRule: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_smart_rule'],
      )!,
      sortField: $CategoriesTable.$convertersortField.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sort_field'],
        )!,
      ),
      sortAscending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sort_ascending'],
      )!,
      statusFilter: $CategoriesTable.$converterstatusFilter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status_filter'],
        )!,
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, int, int> $convertermediaType =
      const EnumIndexConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<CategorySortField, int, int> $convertersortField =
      const EnumIndexConverter<CategorySortField>(CategorySortField.values);
  static JsonTypeConverter2<CategoryStatusFilter, int, int>
  $converterstatusFilter = const EnumIndexConverter<CategoryStatusFilter>(
    CategoryStatusFilter.values,
  );
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int profileId;
  final String name;
  final int sortOrder;
  final bool excludeFromUpdate;
  final MediaType mediaType;
  final bool useSmartRule;
  final CategorySortField sortField;
  final bool sortAscending;
  final CategoryStatusFilter statusFilter;
  const Category({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.profileId,
    required this.name,
    required this.sortOrder,
    required this.excludeFromUpdate,
    required this.mediaType,
    required this.useSmartRule,
    required this.sortField,
    required this.sortAscending,
    required this.statusFilter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['exclude_from_update'] = Variable<bool>(excludeFromUpdate);
    {
      map['media_type'] = Variable<int>(
        $CategoriesTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['use_smart_rule'] = Variable<bool>(useSmartRule);
    {
      map['sort_field'] = Variable<int>(
        $CategoriesTable.$convertersortField.toSql(sortField),
      );
    }
    map['sort_ascending'] = Variable<bool>(sortAscending);
    {
      map['status_filter'] = Variable<int>(
        $CategoriesTable.$converterstatusFilter.toSql(statusFilter),
      );
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      profileId: Value(profileId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      excludeFromUpdate: Value(excludeFromUpdate),
      mediaType: Value(mediaType),
      useSmartRule: Value(useSmartRule),
      sortField: Value(sortField),
      sortAscending: Value(sortAscending),
      statusFilter: Value(statusFilter),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      excludeFromUpdate: serializer.fromJson<bool>(json['excludeFromUpdate']),
      mediaType: $CategoriesTable.$convertermediaType.fromJson(
        serializer.fromJson<int>(json['mediaType']),
      ),
      useSmartRule: serializer.fromJson<bool>(json['useSmartRule']),
      sortField: $CategoriesTable.$convertersortField.fromJson(
        serializer.fromJson<int>(json['sortField']),
      ),
      sortAscending: serializer.fromJson<bool>(json['sortAscending']),
      statusFilter: $CategoriesTable.$converterstatusFilter.fromJson(
        serializer.fromJson<int>(json['statusFilter']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'excludeFromUpdate': serializer.toJson<bool>(excludeFromUpdate),
      'mediaType': serializer.toJson<int>(
        $CategoriesTable.$convertermediaType.toJson(mediaType),
      ),
      'useSmartRule': serializer.toJson<bool>(useSmartRule),
      'sortField': serializer.toJson<int>(
        $CategoriesTable.$convertersortField.toJson(sortField),
      ),
      'sortAscending': serializer.toJson<bool>(sortAscending),
      'statusFilter': serializer.toJson<int>(
        $CategoriesTable.$converterstatusFilter.toJson(statusFilter),
      ),
    };
  }

  Category copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    int? profileId,
    String? name,
    int? sortOrder,
    bool? excludeFromUpdate,
    MediaType? mediaType,
    bool? useSmartRule,
    CategorySortField? sortField,
    bool? sortAscending,
    CategoryStatusFilter? statusFilter,
  }) => Category(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    excludeFromUpdate: excludeFromUpdate ?? this.excludeFromUpdate,
    mediaType: mediaType ?? this.mediaType,
    useSmartRule: useSmartRule ?? this.useSmartRule,
    sortField: sortField ?? this.sortField,
    sortAscending: sortAscending ?? this.sortAscending,
    statusFilter: statusFilter ?? this.statusFilter,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      excludeFromUpdate: data.excludeFromUpdate.present
          ? data.excludeFromUpdate.value
          : this.excludeFromUpdate,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      useSmartRule: data.useSmartRule.present
          ? data.useSmartRule.value
          : this.useSmartRule,
      sortField: data.sortField.present ? data.sortField.value : this.sortField,
      sortAscending: data.sortAscending.present
          ? data.sortAscending.value
          : this.sortAscending,
      statusFilter: data.statusFilter.present
          ? data.statusFilter.value
          : this.statusFilter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('excludeFromUpdate: $excludeFromUpdate, ')
          ..write('mediaType: $mediaType, ')
          ..write('useSmartRule: $useSmartRule, ')
          ..write('sortField: $sortField, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('statusFilter: $statusFilter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    updatedAt,
    profileId,
    name,
    sortOrder,
    excludeFromUpdate,
    mediaType,
    useSmartRule,
    sortField,
    sortAscending,
    statusFilter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.excludeFromUpdate == this.excludeFromUpdate &&
          other.mediaType == this.mediaType &&
          other.useSmartRule == this.useSmartRule &&
          other.sortField == this.sortField &&
          other.sortAscending == this.sortAscending &&
          other.statusFilter == this.statusFilter);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int> profileId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> excludeFromUpdate;
  final Value<MediaType> mediaType;
  final Value<bool> useSmartRule;
  final Value<CategorySortField> sortField;
  final Value<bool> sortAscending;
  final Value<CategoryStatusFilter> statusFilter;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.excludeFromUpdate = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.useSmartRule = const Value.absent(),
    this.sortField = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.statusFilter = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.profileId = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.excludeFromUpdate = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.useSmartRule = const Value.absent(),
    this.sortField = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.statusFilter = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? excludeFromUpdate,
    Expression<int>? mediaType,
    Expression<bool>? useSmartRule,
    Expression<int>? sortField,
    Expression<bool>? sortAscending,
    Expression<int>? statusFilter,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (excludeFromUpdate != null) 'exclude_from_update': excludeFromUpdate,
      if (mediaType != null) 'media_type': mediaType,
      if (useSmartRule != null) 'use_smart_rule': useSmartRule,
      if (sortField != null) 'sort_field': sortField,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (statusFilter != null) 'status_filter': statusFilter,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int>? profileId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? excludeFromUpdate,
    Value<MediaType>? mediaType,
    Value<bool>? useSmartRule,
    Value<CategorySortField>? sortField,
    Value<bool>? sortAscending,
    Value<CategoryStatusFilter>? statusFilter,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      excludeFromUpdate: excludeFromUpdate ?? this.excludeFromUpdate,
      mediaType: mediaType ?? this.mediaType,
      useSmartRule: useSmartRule ?? this.useSmartRule,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (excludeFromUpdate.present) {
      map['exclude_from_update'] = Variable<bool>(excludeFromUpdate.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<int>(
        $CategoriesTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (useSmartRule.present) {
      map['use_smart_rule'] = Variable<bool>(useSmartRule.value);
    }
    if (sortField.present) {
      map['sort_field'] = Variable<int>(
        $CategoriesTable.$convertersortField.toSql(sortField.value),
      );
    }
    if (sortAscending.present) {
      map['sort_ascending'] = Variable<bool>(sortAscending.value);
    }
    if (statusFilter.present) {
      map['status_filter'] = Variable<int>(
        $CategoriesTable.$converterstatusFilter.toSql(statusFilter.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('excludeFromUpdate: $excludeFromUpdate, ')
          ..write('mediaType: $mediaType, ')
          ..write('useSmartRule: $useSmartRule, ')
          ..write('sortField: $sortField, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('statusFilter: $statusFilter')
          ..write(')'))
        .toString();
  }
}

class $EntryCategoriesTable extends EntryCategories
    with TableInfo<$EntryCategoriesTable, EntryCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _libraryEntryIdMeta = const VerificationMeta(
    'libraryEntryId',
  );
  @override
  late final GeneratedColumn<int> libraryEntryId = GeneratedColumn<int>(
    'library_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [libraryEntryId, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('library_entry_id')) {
      context.handle(
        _libraryEntryIdMeta,
        libraryEntryId.isAcceptableOrUnknown(
          data['library_entry_id']!,
          _libraryEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryEntryIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {libraryEntryId, categoryId};
  @override
  EntryCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryCategory(
      libraryEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_entry_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $EntryCategoriesTable createAlias(String alias) {
    return $EntryCategoriesTable(attachedDatabase, alias);
  }
}

class EntryCategory extends DataClass implements Insertable<EntryCategory> {
  final int libraryEntryId;
  final int categoryId;
  const EntryCategory({required this.libraryEntryId, required this.categoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['library_entry_id'] = Variable<int>(libraryEntryId);
    map['category_id'] = Variable<int>(categoryId);
    return map;
  }

  EntryCategoriesCompanion toCompanion(bool nullToAbsent) {
    return EntryCategoriesCompanion(
      libraryEntryId: Value(libraryEntryId),
      categoryId: Value(categoryId),
    );
  }

  factory EntryCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryCategory(
      libraryEntryId: serializer.fromJson<int>(json['libraryEntryId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'libraryEntryId': serializer.toJson<int>(libraryEntryId),
      'categoryId': serializer.toJson<int>(categoryId),
    };
  }

  EntryCategory copyWith({int? libraryEntryId, int? categoryId}) =>
      EntryCategory(
        libraryEntryId: libraryEntryId ?? this.libraryEntryId,
        categoryId: categoryId ?? this.categoryId,
      );
  EntryCategory copyWithCompanion(EntryCategoriesCompanion data) {
    return EntryCategory(
      libraryEntryId: data.libraryEntryId.present
          ? data.libraryEntryId.value
          : this.libraryEntryId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryCategory(')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(libraryEntryId, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryCategory &&
          other.libraryEntryId == this.libraryEntryId &&
          other.categoryId == this.categoryId);
}

class EntryCategoriesCompanion extends UpdateCompanion<EntryCategory> {
  final Value<int> libraryEntryId;
  final Value<int> categoryId;
  final Value<int> rowid;
  const EntryCategoriesCompanion({
    this.libraryEntryId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryCategoriesCompanion.insert({
    required int libraryEntryId,
    required int categoryId,
    this.rowid = const Value.absent(),
  }) : libraryEntryId = Value(libraryEntryId),
       categoryId = Value(categoryId);
  static Insertable<EntryCategory> custom({
    Expression<int>? libraryEntryId,
    Expression<int>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (libraryEntryId != null) 'library_entry_id': libraryEntryId,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryCategoriesCompanion copyWith({
    Value<int>? libraryEntryId,
    Value<int>? categoryId,
    Value<int>? rowid,
  }) {
    return EntryCategoriesCompanion(
      libraryEntryId: libraryEntryId ?? this.libraryEntryId,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (libraryEntryId.present) {
      map['library_entry_id'] = Variable<int>(libraryEntryId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryCategoriesCompanion(')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LogLevel, int> level =
      GeneratedColumn<int>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<LogLevel>($LogEntriesTable.$converterlevel);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackTraceMeta = const VerificationMeta(
    'stackTrace',
  );
  @override
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
    'stack_trace',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    level,
    tag,
    message,
    stackTrace,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('stack_trace')) {
      context.handle(
        _stackTraceMeta,
        stackTrace.isAcceptableOrUnknown(data['stack_trace']!, _stackTraceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      level: $LogEntriesTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}level'],
        )!,
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      stackTrace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stack_trace'],
      ),
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LogLevel, int, int> $converterlevel =
      const EnumIndexConverter<LogLevel>(LogLevel.values);
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final int id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;
  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    {
      map['level'] = Variable<int>(
        $LogEntriesTable.$converterlevel.toSql(level),
      );
    }
    map['tag'] = Variable<String>(tag);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || stackTrace != null) {
      map['stack_trace'] = Variable<String>(stackTrace);
    }
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      level: Value(level),
      tag: Value(tag),
      message: Value(message),
      stackTrace: stackTrace == null && nullToAbsent
          ? const Value.absent()
          : Value(stackTrace),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      level: $LogEntriesTable.$converterlevel.fromJson(
        serializer.fromJson<int>(json['level']),
      ),
      tag: serializer.fromJson<String>(json['tag']),
      message: serializer.fromJson<String>(json['message']),
      stackTrace: serializer.fromJson<String?>(json['stackTrace']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'level': serializer.toJson<int>(
        $LogEntriesTable.$converterlevel.toJson(level),
      ),
      'tag': serializer.toJson<String>(tag),
      'message': serializer.toJson<String>(message),
      'stackTrace': serializer.toJson<String?>(stackTrace),
    };
  }

  LogEntry copyWith({
    int? id,
    DateTime? timestamp,
    LogLevel? level,
    String? tag,
    String? message,
    Value<String?> stackTrace = const Value.absent(),
  }) => LogEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    level: level ?? this.level,
    tag: tag ?? this.tag,
    message: message ?? this.message,
    stackTrace: stackTrace.present ? stackTrace.value : this.stackTrace,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      level: data.level.present ? data.level.value : this.level,
      tag: data.tag.present ? data.tag.value : this.tag,
      message: data.message.present ? data.message.value : this.message,
      stackTrace: data.stackTrace.present
          ? data.stackTrace.value
          : this.stackTrace,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, level, tag, message, stackTrace);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.level == this.level &&
          other.tag == this.tag &&
          other.message == this.message &&
          other.stackTrace == this.stackTrace);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<LogLevel> level;
  final Value<String> tag;
  final Value<String> message;
  final Value<String?> stackTrace;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.level = const Value.absent(),
    this.tag = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required LogLevel level,
    required String tag,
    required String message,
    this.stackTrace = const Value.absent(),
  }) : level = Value(level),
       tag = Value(tag),
       message = Value(message);
  static Insertable<LogEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? level,
    Expression<String>? tag,
    Expression<String>? message,
    Expression<String>? stackTrace,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (level != null) 'level': level,
      if (tag != null) 'tag': tag,
      if (message != null) 'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<LogLevel>? level,
    Value<String>? tag,
    Value<String>? message,
    Value<String?>? stackTrace,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      tag: tag ?? this.tag,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(
        $LogEntriesTable.$converterlevel.toSql(level.value),
      );
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace')
          ..write(')'))
        .toString();
  }
}

class $InstalledSourcesTable extends InstalledSources
    with TableInfo<$InstalledSourcesTable, InstalledSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, int> mediaType =
      GeneratedColumn<int>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($InstalledSourcesTable.$convertermediaType);
  static const VerificationMeta _jsSourceMeta = const VerificationMeta(
    'jsSource',
  );
  @override
  late final GeneratedColumn<String> jsSource = GeneratedColumn<String>(
    'js_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _engineKindMeta = const VerificationMeta(
    'engineKind',
  );
  @override
  late final GeneratedColumn<String> engineKind = GeneratedColumn<String>(
    'engine_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('js'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _repoUrlMeta = const VerificationMeta(
    'repoUrl',
  );
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repoSourceIdMeta = const VerificationMeta(
    'repoSourceId',
  );
  @override
  late final GeneratedColumn<String> repoSourceId = GeneratedColumn<String>(
    'repo_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    name,
    lang,
    mediaType,
    jsSource,
    iconUrl,
    baseUrl,
    enabled,
    engineKind,
    addedAt,
    repoUrl,
    repoSourceId,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstalledSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('js_source')) {
      context.handle(
        _jsSourceMeta,
        jsSource.isAcceptableOrUnknown(data['js_source']!, _jsSourceMeta),
      );
    } else if (isInserting) {
      context.missing(_jsSourceMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('engine_kind')) {
      context.handle(
        _engineKindMeta,
        engineKind.isAcceptableOrUnknown(data['engine_kind']!, _engineKindMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    }
    if (data.containsKey('repo_source_id')) {
      context.handle(
        _repoSourceIdMeta,
        repoSourceId.isAcceptableOrUnknown(
          data['repo_source_id']!,
          _repoSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstalledSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      mediaType: $InstalledSourcesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      jsSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}js_source'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      engineKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_kind'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      ),
      repoSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_source_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $InstalledSourcesTable createAlias(String alias) {
    return $InstalledSourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, int, int> $convertermediaType =
      const EnumIndexConverter<MediaType>(MediaType.values);
}

class InstalledSource extends DataClass implements Insertable<InstalledSource> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final String name;
  final String lang;
  final MediaType mediaType;
  final String jsSource;
  final String iconUrl;
  final String baseUrl;
  final bool enabled;
  final String engineKind;
  final DateTime addedAt;
  final String? repoUrl;
  final String? repoSourceId;
  final int version;
  const InstalledSource({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.name,
    required this.lang,
    required this.mediaType,
    required this.jsSource,
    required this.iconUrl,
    required this.baseUrl,
    required this.enabled,
    required this.engineKind,
    required this.addedAt,
    this.repoUrl,
    this.repoSourceId,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['name'] = Variable<String>(name);
    map['lang'] = Variable<String>(lang);
    {
      map['media_type'] = Variable<int>(
        $InstalledSourcesTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['js_source'] = Variable<String>(jsSource);
    map['icon_url'] = Variable<String>(iconUrl);
    map['base_url'] = Variable<String>(baseUrl);
    map['enabled'] = Variable<bool>(enabled);
    map['engine_kind'] = Variable<String>(engineKind);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || repoUrl != null) {
      map['repo_url'] = Variable<String>(repoUrl);
    }
    if (!nullToAbsent || repoSourceId != null) {
      map['repo_source_id'] = Variable<String>(repoSourceId);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  InstalledSourcesCompanion toCompanion(bool nullToAbsent) {
    return InstalledSourcesCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      name: Value(name),
      lang: Value(lang),
      mediaType: Value(mediaType),
      jsSource: Value(jsSource),
      iconUrl: Value(iconUrl),
      baseUrl: Value(baseUrl),
      enabled: Value(enabled),
      engineKind: Value(engineKind),
      addedAt: Value(addedAt),
      repoUrl: repoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(repoUrl),
      repoSourceId: repoSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(repoSourceId),
      version: Value(version),
    );
  }

  factory InstalledSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledSource(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      lang: serializer.fromJson<String>(json['lang']),
      mediaType: $InstalledSourcesTable.$convertermediaType.fromJson(
        serializer.fromJson<int>(json['mediaType']),
      ),
      jsSource: serializer.fromJson<String>(json['jsSource']),
      iconUrl: serializer.fromJson<String>(json['iconUrl']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      engineKind: serializer.fromJson<String>(json['engineKind']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      repoUrl: serializer.fromJson<String?>(json['repoUrl']),
      repoSourceId: serializer.fromJson<String?>(json['repoSourceId']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'name': serializer.toJson<String>(name),
      'lang': serializer.toJson<String>(lang),
      'mediaType': serializer.toJson<int>(
        $InstalledSourcesTable.$convertermediaType.toJson(mediaType),
      ),
      'jsSource': serializer.toJson<String>(jsSource),
      'iconUrl': serializer.toJson<String>(iconUrl),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'enabled': serializer.toJson<bool>(enabled),
      'engineKind': serializer.toJson<String>(engineKind),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'repoUrl': serializer.toJson<String?>(repoUrl),
      'repoSourceId': serializer.toJson<String?>(repoSourceId),
      'version': serializer.toJson<int>(version),
    };
  }

  InstalledSource copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    String? name,
    String? lang,
    MediaType? mediaType,
    String? jsSource,
    String? iconUrl,
    String? baseUrl,
    bool? enabled,
    String? engineKind,
    DateTime? addedAt,
    Value<String?> repoUrl = const Value.absent(),
    Value<String?> repoSourceId = const Value.absent(),
    int? version,
  }) => InstalledSource(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    lang: lang ?? this.lang,
    mediaType: mediaType ?? this.mediaType,
    jsSource: jsSource ?? this.jsSource,
    iconUrl: iconUrl ?? this.iconUrl,
    baseUrl: baseUrl ?? this.baseUrl,
    enabled: enabled ?? this.enabled,
    engineKind: engineKind ?? this.engineKind,
    addedAt: addedAt ?? this.addedAt,
    repoUrl: repoUrl.present ? repoUrl.value : this.repoUrl,
    repoSourceId: repoSourceId.present ? repoSourceId.value : this.repoSourceId,
    version: version ?? this.version,
  );
  InstalledSource copyWithCompanion(InstalledSourcesCompanion data) {
    return InstalledSource(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      lang: data.lang.present ? data.lang.value : this.lang,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      jsSource: data.jsSource.present ? data.jsSource.value : this.jsSource,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      engineKind: data.engineKind.present
          ? data.engineKind.value
          : this.engineKind,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      repoSourceId: data.repoSourceId.present
          ? data.repoSourceId.value
          : this.repoSourceId,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledSource(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('lang: $lang, ')
          ..write('mediaType: $mediaType, ')
          ..write('jsSource: $jsSource, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('enabled: $enabled, ')
          ..write('engineKind: $engineKind, ')
          ..write('addedAt: $addedAt, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoSourceId: $repoSourceId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    updatedAt,
    name,
    lang,
    mediaType,
    jsSource,
    iconUrl,
    baseUrl,
    enabled,
    engineKind,
    addedAt,
    repoUrl,
    repoSourceId,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledSource &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.lang == this.lang &&
          other.mediaType == this.mediaType &&
          other.jsSource == this.jsSource &&
          other.iconUrl == this.iconUrl &&
          other.baseUrl == this.baseUrl &&
          other.enabled == this.enabled &&
          other.engineKind == this.engineKind &&
          other.addedAt == this.addedAt &&
          other.repoUrl == this.repoUrl &&
          other.repoSourceId == this.repoSourceId &&
          other.version == this.version);
}

class InstalledSourcesCompanion extends UpdateCompanion<InstalledSource> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<String> name;
  final Value<String> lang;
  final Value<MediaType> mediaType;
  final Value<String> jsSource;
  final Value<String> iconUrl;
  final Value<String> baseUrl;
  final Value<bool> enabled;
  final Value<String> engineKind;
  final Value<DateTime> addedAt;
  final Value<String?> repoUrl;
  final Value<String?> repoSourceId;
  final Value<int> version;
  const InstalledSourcesCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.lang = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.jsSource = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.enabled = const Value.absent(),
    this.engineKind = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.repoSourceId = const Value.absent(),
    this.version = const Value.absent(),
  });
  InstalledSourcesCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    this.lang = const Value.absent(),
    required MediaType mediaType,
    required String jsSource,
    this.iconUrl = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.enabled = const Value.absent(),
    this.engineKind = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.repoSourceId = const Value.absent(),
    this.version = const Value.absent(),
  }) : name = Value(name),
       mediaType = Value(mediaType),
       jsSource = Value(jsSource);
  static Insertable<InstalledSource> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<String>? name,
    Expression<String>? lang,
    Expression<int>? mediaType,
    Expression<String>? jsSource,
    Expression<String>? iconUrl,
    Expression<String>? baseUrl,
    Expression<bool>? enabled,
    Expression<String>? engineKind,
    Expression<DateTime>? addedAt,
    Expression<String>? repoUrl,
    Expression<String>? repoSourceId,
    Expression<int>? version,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (lang != null) 'lang': lang,
      if (mediaType != null) 'media_type': mediaType,
      if (jsSource != null) 'js_source': jsSource,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (baseUrl != null) 'base_url': baseUrl,
      if (enabled != null) 'enabled': enabled,
      if (engineKind != null) 'engine_kind': engineKind,
      if (addedAt != null) 'added_at': addedAt,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (repoSourceId != null) 'repo_source_id': repoSourceId,
      if (version != null) 'version': version,
    });
  }

  InstalledSourcesCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<String>? name,
    Value<String>? lang,
    Value<MediaType>? mediaType,
    Value<String>? jsSource,
    Value<String>? iconUrl,
    Value<String>? baseUrl,
    Value<bool>? enabled,
    Value<String>? engineKind,
    Value<DateTime>? addedAt,
    Value<String?>? repoUrl,
    Value<String?>? repoSourceId,
    Value<int>? version,
  }) {
    return InstalledSourcesCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      lang: lang ?? this.lang,
      mediaType: mediaType ?? this.mediaType,
      jsSource: jsSource ?? this.jsSource,
      iconUrl: iconUrl ?? this.iconUrl,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
      engineKind: engineKind ?? this.engineKind,
      addedAt: addedAt ?? this.addedAt,
      repoUrl: repoUrl ?? this.repoUrl,
      repoSourceId: repoSourceId ?? this.repoSourceId,
      version: version ?? this.version,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<int>(
        $InstalledSourcesTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (jsSource.present) {
      map['js_source'] = Variable<String>(jsSource.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (engineKind.present) {
      map['engine_kind'] = Variable<String>(engineKind.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (repoSourceId.present) {
      map['repo_source_id'] = Variable<String>(repoSourceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledSourcesCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('lang: $lang, ')
          ..write('mediaType: $mediaType, ')
          ..write('jsSource: $jsSource, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('enabled: $enabled, ')
          ..write('engineKind: $engineKind, ')
          ..write('addedAt: $addedAt, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoSourceId: $repoSourceId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }
}

class $ReposTable extends Repos with TableInfo<$ReposTable, Repo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReposTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    url,
    name,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Repo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Repo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Repo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $ReposTable createAlias(String alias) {
    return $ReposTable(attachedDatabase, alias);
  }
}

class Repo extends DataClass implements Insertable<Repo> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final String url;
  final String name;
  final DateTime addedAt;
  const Repo({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.url,
    required this.name,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['url'] = Variable<String>(url);
    map['name'] = Variable<String>(name);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  ReposCompanion toCompanion(bool nullToAbsent) {
    return ReposCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      url: Value(url),
      name: Value(name),
      addedAt: Value(addedAt),
    );
  }

  factory Repo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Repo(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Repo copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    String? url,
    String? name,
    DateTime? addedAt,
  }) => Repo(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    url: url ?? this.url,
    name: name ?? this.name,
    addedAt: addedAt ?? this.addedAt,
  );
  Repo copyWithCompanion(ReposCompanion data) {
    return Repo(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Repo(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientId, updatedAt, url, name, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Repo &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.url == this.url &&
          other.name == this.name &&
          other.addedAt == this.addedAt);
}

class ReposCompanion extends UpdateCompanion<Repo> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<String> url;
  final Value<String> name;
  final Value<DateTime> addedAt;
  const ReposCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.url = const Value.absent(),
    this.name = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  ReposCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String url,
    required String name,
    this.addedAt = const Value.absent(),
  }) : url = Value(url),
       name = Value(name);
  static Insertable<Repo> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<String>? url,
    Expression<String>? name,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  ReposCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<String>? url,
    Value<String>? name,
    Value<DateTime>? addedAt,
  }) {
    return ReposCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      url: url ?? this.url,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReposCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $ActiveProfileTableTable extends ActiveProfileTable
    with TableInfo<$ActiveProfileTableTable, ActiveProfileTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveProfileTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveProfileTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveProfileTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveProfileTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $ActiveProfileTableTable createAlias(String alias) {
    return $ActiveProfileTableTable(attachedDatabase, alias);
  }
}

class ActiveProfileTableData extends DataClass
    implements Insertable<ActiveProfileTableData> {
  final int id;
  final int profileId;
  const ActiveProfileTableData({required this.id, required this.profileId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    return map;
  }

  ActiveProfileTableCompanion toCompanion(bool nullToAbsent) {
    return ActiveProfileTableCompanion(
      id: Value(id),
      profileId: Value(profileId),
    );
  }

  factory ActiveProfileTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveProfileTableData(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
    };
  }

  ActiveProfileTableData copyWith({int? id, int? profileId}) =>
      ActiveProfileTableData(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
      );
  ActiveProfileTableData copyWithCompanion(ActiveProfileTableCompanion data) {
    return ActiveProfileTableData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveProfileTableData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveProfileTableData &&
          other.id == this.id &&
          other.profileId == this.profileId);
}

class ActiveProfileTableCompanion
    extends UpdateCompanion<ActiveProfileTableData> {
  final Value<int> id;
  final Value<int> profileId;
  const ActiveProfileTableCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
  });
  ActiveProfileTableCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
  }) : profileId = Value(profileId);
  static Insertable<ActiveProfileTableData> custom({
    Expression<int>? id,
    Expression<int>? profileId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
    });
  }

  ActiveProfileTableCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
  }) {
    return ActiveProfileTableCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveProfileTableCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }
}

class $SettingValuesTable extends SettingValues
    with TableInfo<$SettingValuesTable, SettingValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _settingIdMeta = const VerificationMeta(
    'settingId',
  );
  @override
  late final GeneratedColumn<String> settingId = GeneratedColumn<String>(
    'setting_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    settingId,
    value,
    updatedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('setting_id')) {
      context.handle(
        _settingIdMeta,
        settingId.isAcceptableOrUnknown(data['setting_id']!, _settingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_settingIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, settingId},
  ];
  @override
  SettingValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      settingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $SettingValuesTable createAlias(String alias) {
    return $SettingValuesTable(attachedDatabase, alias);
  }
}

class SettingValue extends DataClass implements Insertable<SettingValue> {
  final int id;
  final int profileId;
  final String settingId;
  final String value;
  final int updatedAt;
  final bool synced;
  const SettingValue({
    required this.id,
    required this.profileId,
    required this.settingId,
    required this.value,
    required this.updatedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['setting_id'] = Variable<String>(settingId);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  SettingValuesCompanion toCompanion(bool nullToAbsent) {
    return SettingValuesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      settingId: Value(settingId),
      value: Value(value),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory SettingValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingValue(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      settingId: serializer.fromJson<String>(json['settingId']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'settingId': serializer.toJson<String>(settingId),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  SettingValue copyWith({
    int? id,
    int? profileId,
    String? settingId,
    String? value,
    int? updatedAt,
    bool? synced,
  }) => SettingValue(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    settingId: settingId ?? this.settingId,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
    synced: synced ?? this.synced,
  );
  SettingValue copyWithCompanion(SettingValuesCompanion data) {
    return SettingValue(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      settingId: data.settingId.present ? data.settingId.value : this.settingId,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingValue(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('settingId: $settingId, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, settingId, value, updatedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingValue &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.settingId == this.settingId &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class SettingValuesCompanion extends UpdateCompanion<SettingValue> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> settingId;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<bool> synced;
  const SettingValuesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.settingId = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  SettingValuesCompanion.insert({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    required String settingId,
    required String value,
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
  }) : settingId = Value(settingId),
       value = Value(value);
  static Insertable<SettingValue> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? settingId,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (settingId != null) 'setting_id': settingId,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
    });
  }

  SettingValuesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? settingId,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<bool>? synced,
  }) {
    return SettingValuesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      settingId: settingId ?? this.settingId,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (settingId.present) {
      map['setting_id'] = Variable<String>(settingId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingValuesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('settingId: $settingId, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: generateClientId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _libraryEntryIdMeta = const VerificationMeta(
    'libraryEntryId',
  );
  @override
  late final GeneratedColumn<int> libraryEntryId = GeneratedColumn<int>(
    'library_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentUnitIdMeta = const VerificationMeta(
    'contentUnitId',
  );
  @override
  late final GeneratedColumn<int> contentUnitId = GeneratedColumn<int>(
    'content_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES content_units (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entry_branches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    updatedAt,
    libraryEntryId,
    contentUnitId,
    branchId,
    readAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('library_entry_id')) {
      context.handle(
        _libraryEntryIdMeta,
        libraryEntryId.isAcceptableOrUnknown(
          data['library_entry_id']!,
          _libraryEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryEntryIdMeta);
    }
    if (data.containsKey('content_unit_id')) {
      context.handle(
        _contentUnitIdMeta,
        contentUnitId.isAcceptableOrUnknown(
          data['content_unit_id']!,
          _contentUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentUnitIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      libraryEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_entry_id'],
      )!,
      contentUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_unit_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      ),
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      )!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final int id;
  final int? clientId;
  final int updatedAt;
  final int libraryEntryId;
  final int contentUnitId;
  final int? branchId;
  final DateTime readAt;
  const ReadingSession({
    required this.id,
    this.clientId,
    required this.updatedAt,
    required this.libraryEntryId,
    required this.contentUnitId,
    this.branchId,
    required this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['library_entry_id'] = Variable<int>(libraryEntryId);
    map['content_unit_id'] = Variable<int>(contentUnitId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<int>(branchId);
    }
    map['read_at'] = Variable<DateTime>(readAt);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      updatedAt: Value(updatedAt),
      libraryEntryId: Value(libraryEntryId),
      contentUnitId: Value(contentUnitId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      readAt: Value(readAt),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      libraryEntryId: serializer.fromJson<int>(json['libraryEntryId']),
      contentUnitId: serializer.fromJson<int>(json['contentUnitId']),
      branchId: serializer.fromJson<int?>(json['branchId']),
      readAt: serializer.fromJson<DateTime>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int?>(clientId),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'libraryEntryId': serializer.toJson<int>(libraryEntryId),
      'contentUnitId': serializer.toJson<int>(contentUnitId),
      'branchId': serializer.toJson<int?>(branchId),
      'readAt': serializer.toJson<DateTime>(readAt),
    };
  }

  ReadingSession copyWith({
    int? id,
    Value<int?> clientId = const Value.absent(),
    int? updatedAt,
    int? libraryEntryId,
    int? contentUnitId,
    Value<int?> branchId = const Value.absent(),
    DateTime? readAt,
  }) => ReadingSession(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    updatedAt: updatedAt ?? this.updatedAt,
    libraryEntryId: libraryEntryId ?? this.libraryEntryId,
    contentUnitId: contentUnitId ?? this.contentUnitId,
    branchId: branchId.present ? branchId.value : this.branchId,
    readAt: readAt ?? this.readAt,
  );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      libraryEntryId: data.libraryEntryId.present
          ? data.libraryEntryId.value
          : this.libraryEntryId,
      contentUnitId: data.contentUnitId.present
          ? data.contentUnitId.value
          : this.contentUnitId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('contentUnitId: $contentUnitId, ')
          ..write('branchId: $branchId, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    updatedAt,
    libraryEntryId,
    contentUnitId,
    branchId,
    readAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.updatedAt == this.updatedAt &&
          other.libraryEntryId == this.libraryEntryId &&
          other.contentUnitId == this.contentUnitId &&
          other.branchId == this.branchId &&
          other.readAt == this.readAt);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<int> id;
  final Value<int?> clientId;
  final Value<int> updatedAt;
  final Value<int> libraryEntryId;
  final Value<int> contentUnitId;
  final Value<int?> branchId;
  final Value<DateTime> readAt;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.libraryEntryId = const Value.absent(),
    this.contentUnitId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.readAt = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required int libraryEntryId,
    required int contentUnitId,
    this.branchId = const Value.absent(),
    this.readAt = const Value.absent(),
  }) : libraryEntryId = Value(libraryEntryId),
       contentUnitId = Value(contentUnitId);
  static Insertable<ReadingSession> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? updatedAt,
    Expression<int>? libraryEntryId,
    Expression<int>? contentUnitId,
    Expression<int>? branchId,
    Expression<DateTime>? readAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (libraryEntryId != null) 'library_entry_id': libraryEntryId,
      if (contentUnitId != null) 'content_unit_id': contentUnitId,
      if (branchId != null) 'branch_id': branchId,
      if (readAt != null) 'read_at': readAt,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? clientId,
    Value<int>? updatedAt,
    Value<int>? libraryEntryId,
    Value<int>? contentUnitId,
    Value<int?>? branchId,
    Value<DateTime>? readAt,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      libraryEntryId: libraryEntryId ?? this.libraryEntryId,
      contentUnitId: contentUnitId ?? this.contentUnitId,
      branchId: branchId ?? this.branchId,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (libraryEntryId.present) {
      map['library_entry_id'] = Variable<int>(libraryEntryId.value);
    }
    if (contentUnitId.present) {
      map['content_unit_id'] = Variable<int>(contentUnitId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('contentUnitId: $contentUnitId, ')
          ..write('branchId: $branchId, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }
}

class $SyncDeletionsTable extends SyncDeletions
    with TableInfo<$SyncDeletionsTable, SyncDeletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, profileId, entity, clientId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDeletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, entity, clientId},
  ];
  @override
  SyncDeletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDeletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_id'],
      )!,
    );
  }

  @override
  $SyncDeletionsTable createAlias(String alias) {
    return $SyncDeletionsTable(attachedDatabase, alias);
  }
}

class SyncDeletion extends DataClass implements Insertable<SyncDeletion> {
  final int id;
  final int profileId;
  final String entity;
  final int clientId;
  const SyncDeletion({
    required this.id,
    required this.profileId,
    required this.entity,
    required this.clientId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['entity'] = Variable<String>(entity);
    map['client_id'] = Variable<int>(clientId);
    return map;
  }

  SyncDeletionsCompanion toCompanion(bool nullToAbsent) {
    return SyncDeletionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      entity: Value(entity),
      clientId: Value(clientId),
    );
  }

  factory SyncDeletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDeletion(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      entity: serializer.fromJson<String>(json['entity']),
      clientId: serializer.fromJson<int>(json['clientId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'entity': serializer.toJson<String>(entity),
      'clientId': serializer.toJson<int>(clientId),
    };
  }

  SyncDeletion copyWith({
    int? id,
    int? profileId,
    String? entity,
    int? clientId,
  }) => SyncDeletion(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    entity: entity ?? this.entity,
    clientId: clientId ?? this.clientId,
  );
  SyncDeletion copyWithCompanion(SyncDeletionsCompanion data) {
    return SyncDeletion(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      entity: data.entity.present ? data.entity.value : this.entity,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('entity: $entity, ')
          ..write('clientId: $clientId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, entity, clientId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDeletion &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.entity == this.entity &&
          other.clientId == this.clientId);
}

class SyncDeletionsCompanion extends UpdateCompanion<SyncDeletion> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> entity;
  final Value<int> clientId;
  const SyncDeletionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.entity = const Value.absent(),
    this.clientId = const Value.absent(),
  });
  SyncDeletionsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String entity,
    required int clientId,
  }) : profileId = Value(profileId),
       entity = Value(entity),
       clientId = Value(clientId);
  static Insertable<SyncDeletion> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? entity,
    Expression<int>? clientId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (entity != null) 'entity': entity,
      if (clientId != null) 'client_id': clientId,
    });
  }

  SyncDeletionsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? entity,
    Value<int>? clientId,
  }) {
    return SyncDeletionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      entity: entity ?? this.entity,
      clientId: clientId ?? this.clientId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeletionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('entity: $entity, ')
          ..write('clientId: $clientId')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _applyingMeta = const VerificationMeta(
    'applying',
  );
  @override
  late final GeneratedColumn<int> applying = GeneratedColumn<int>(
    'applying',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, applying, installId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('applying')) {
      context.handle(
        _applyingMeta,
        applying.isAcceptableOrUnknown(data['applying']!, _applyingMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      applying: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applying'],
      )!,
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;
  final int applying;
  final String? installId;
  const SyncStateData({
    required this.id,
    required this.applying,
    this.installId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['applying'] = Variable<int>(applying);
    if (!nullToAbsent || installId != null) {
      map['install_id'] = Variable<String>(installId);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      applying: Value(applying),
      installId: installId == null && nullToAbsent
          ? const Value.absent()
          : Value(installId),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      applying: serializer.fromJson<int>(json['applying']),
      installId: serializer.fromJson<String?>(json['installId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'applying': serializer.toJson<int>(applying),
      'installId': serializer.toJson<String?>(installId),
    };
  }

  SyncStateData copyWith({
    int? id,
    int? applying,
    Value<String?> installId = const Value.absent(),
  }) => SyncStateData(
    id: id ?? this.id,
    applying: applying ?? this.applying,
    installId: installId.present ? installId.value : this.installId,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      applying: data.applying.present ? data.applying.value : this.applying,
      installId: data.installId.present ? data.installId.value : this.installId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('applying: $applying, ')
          ..write('installId: $installId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, applying, installId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.applying == this.applying &&
          other.installId == this.installId);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<int> applying;
  final Value<String?> installId;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.applying = const Value.absent(),
    this.installId = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.applying = const Value.absent(),
    this.installId = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<int>? applying,
    Expression<String>? installId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (applying != null) 'applying': applying,
      if (installId != null) 'install_id': installId,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<int>? applying,
    Value<String?>? installId,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      applying: applying ?? this.applying,
      installId: installId ?? this.installId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (applying.present) {
      map['applying'] = Variable<int>(applying.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('applying: $applying, ')
          ..write('installId: $installId')
          ..write(')'))
        .toString();
  }
}

class $SyncProfileStateTable extends SyncProfileState
    with TableInfo<$SyncProfileStateTable, SyncProfileStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncProfileStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _serverProfileIdMeta = const VerificationMeta(
    'serverProfileId',
  );
  @override
  late final GeneratedColumn<int> serverProfileId = GeneratedColumn<int>(
    'server_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverProfileNameMeta = const VerificationMeta(
    'serverProfileName',
  );
  @override
  late final GeneratedColumn<String> serverProfileName =
      GeneratedColumn<String>(
        'server_profile_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sinceMeta = const VerificationMeta('since');
  @override
  late final GeneratedColumn<int> since = GeneratedColumn<int>(
    'since',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localSinceMeta = const VerificationMeta(
    'localSince',
  );
  @override
  late final GeneratedColumn<int> localSince = GeneratedColumn<int>(
    'local_since',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoSyncIntervalMinutesMeta =
      const VerificationMeta('autoSyncIntervalMinutes');
  @override
  late final GeneratedColumn<int> autoSyncIntervalMinutes =
      GeneratedColumn<int>(
        'auto_sync_interval_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _syncOnLaunchMeta = const VerificationMeta(
    'syncOnLaunch',
  );
  @override
  late final GeneratedColumn<bool> syncOnLaunch = GeneratedColumn<bool>(
    'sync_on_launch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_on_launch" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _backgroundSyncMeta = const VerificationMeta(
    'backgroundSync',
  );
  @override
  late final GeneratedColumn<bool> backgroundSync = GeneratedColumn<bool>(
    'background_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("background_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    serverProfileId,
    serverProfileName,
    since,
    localSince,
    lastSyncAt,
    autoSyncIntervalMinutes,
    syncOnLaunch,
    backgroundSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_profile_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncProfileStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('server_profile_id')) {
      context.handle(
        _serverProfileIdMeta,
        serverProfileId.isAcceptableOrUnknown(
          data['server_profile_id']!,
          _serverProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('server_profile_name')) {
      context.handle(
        _serverProfileNameMeta,
        serverProfileName.isAcceptableOrUnknown(
          data['server_profile_name']!,
          _serverProfileNameMeta,
        ),
      );
    }
    if (data.containsKey('since')) {
      context.handle(
        _sinceMeta,
        since.isAcceptableOrUnknown(data['since']!, _sinceMeta),
      );
    }
    if (data.containsKey('local_since')) {
      context.handle(
        _localSinceMeta,
        localSince.isAcceptableOrUnknown(data['local_since']!, _localSinceMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('auto_sync_interval_minutes')) {
      context.handle(
        _autoSyncIntervalMinutesMeta,
        autoSyncIntervalMinutes.isAcceptableOrUnknown(
          data['auto_sync_interval_minutes']!,
          _autoSyncIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('sync_on_launch')) {
      context.handle(
        _syncOnLaunchMeta,
        syncOnLaunch.isAcceptableOrUnknown(
          data['sync_on_launch']!,
          _syncOnLaunchMeta,
        ),
      );
    }
    if (data.containsKey('background_sync')) {
      context.handle(
        _backgroundSyncMeta,
        backgroundSync.isAcceptableOrUnknown(
          data['background_sync']!,
          _backgroundSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  SyncProfileStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncProfileStateData(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      serverProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_profile_id'],
      ),
      serverProfileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_profile_name'],
      ),
      since: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}since'],
      )!,
      localSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_since'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      )!,
      autoSyncIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_sync_interval_minutes'],
      )!,
      syncOnLaunch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_on_launch'],
      )!,
      backgroundSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_sync'],
      )!,
    );
  }

  @override
  $SyncProfileStateTable createAlias(String alias) {
    return $SyncProfileStateTable(attachedDatabase, alias);
  }
}

class SyncProfileStateData extends DataClass
    implements Insertable<SyncProfileStateData> {
  final int profileId;
  final int? serverProfileId;
  final String? serverProfileName;
  final int since;
  final int localSince;
  final int lastSyncAt;
  final int autoSyncIntervalMinutes;
  final bool syncOnLaunch;
  final bool backgroundSync;
  const SyncProfileStateData({
    required this.profileId,
    this.serverProfileId,
    this.serverProfileName,
    required this.since,
    required this.localSince,
    required this.lastSyncAt,
    required this.autoSyncIntervalMinutes,
    required this.syncOnLaunch,
    required this.backgroundSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    if (!nullToAbsent || serverProfileId != null) {
      map['server_profile_id'] = Variable<int>(serverProfileId);
    }
    if (!nullToAbsent || serverProfileName != null) {
      map['server_profile_name'] = Variable<String>(serverProfileName);
    }
    map['since'] = Variable<int>(since);
    map['local_since'] = Variable<int>(localSince);
    map['last_sync_at'] = Variable<int>(lastSyncAt);
    map['auto_sync_interval_minutes'] = Variable<int>(autoSyncIntervalMinutes);
    map['sync_on_launch'] = Variable<bool>(syncOnLaunch);
    map['background_sync'] = Variable<bool>(backgroundSync);
    return map;
  }

  SyncProfileStateCompanion toCompanion(bool nullToAbsent) {
    return SyncProfileStateCompanion(
      profileId: Value(profileId),
      serverProfileId: serverProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverProfileId),
      serverProfileName: serverProfileName == null && nullToAbsent
          ? const Value.absent()
          : Value(serverProfileName),
      since: Value(since),
      localSince: Value(localSince),
      lastSyncAt: Value(lastSyncAt),
      autoSyncIntervalMinutes: Value(autoSyncIntervalMinutes),
      syncOnLaunch: Value(syncOnLaunch),
      backgroundSync: Value(backgroundSync),
    );
  }

  factory SyncProfileStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncProfileStateData(
      profileId: serializer.fromJson<int>(json['profileId']),
      serverProfileId: serializer.fromJson<int?>(json['serverProfileId']),
      serverProfileName: serializer.fromJson<String?>(
        json['serverProfileName'],
      ),
      since: serializer.fromJson<int>(json['since']),
      localSince: serializer.fromJson<int>(json['localSince']),
      lastSyncAt: serializer.fromJson<int>(json['lastSyncAt']),
      autoSyncIntervalMinutes: serializer.fromJson<int>(
        json['autoSyncIntervalMinutes'],
      ),
      syncOnLaunch: serializer.fromJson<bool>(json['syncOnLaunch']),
      backgroundSync: serializer.fromJson<bool>(json['backgroundSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'serverProfileId': serializer.toJson<int?>(serverProfileId),
      'serverProfileName': serializer.toJson<String?>(serverProfileName),
      'since': serializer.toJson<int>(since),
      'localSince': serializer.toJson<int>(localSince),
      'lastSyncAt': serializer.toJson<int>(lastSyncAt),
      'autoSyncIntervalMinutes': serializer.toJson<int>(
        autoSyncIntervalMinutes,
      ),
      'syncOnLaunch': serializer.toJson<bool>(syncOnLaunch),
      'backgroundSync': serializer.toJson<bool>(backgroundSync),
    };
  }

  SyncProfileStateData copyWith({
    int? profileId,
    Value<int?> serverProfileId = const Value.absent(),
    Value<String?> serverProfileName = const Value.absent(),
    int? since,
    int? localSince,
    int? lastSyncAt,
    int? autoSyncIntervalMinutes,
    bool? syncOnLaunch,
    bool? backgroundSync,
  }) => SyncProfileStateData(
    profileId: profileId ?? this.profileId,
    serverProfileId: serverProfileId.present
        ? serverProfileId.value
        : this.serverProfileId,
    serverProfileName: serverProfileName.present
        ? serverProfileName.value
        : this.serverProfileName,
    since: since ?? this.since,
    localSince: localSince ?? this.localSince,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    autoSyncIntervalMinutes:
        autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
    syncOnLaunch: syncOnLaunch ?? this.syncOnLaunch,
    backgroundSync: backgroundSync ?? this.backgroundSync,
  );
  SyncProfileStateData copyWithCompanion(SyncProfileStateCompanion data) {
    return SyncProfileStateData(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      serverProfileId: data.serverProfileId.present
          ? data.serverProfileId.value
          : this.serverProfileId,
      serverProfileName: data.serverProfileName.present
          ? data.serverProfileName.value
          : this.serverProfileName,
      since: data.since.present ? data.since.value : this.since,
      localSince: data.localSince.present
          ? data.localSince.value
          : this.localSince,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      autoSyncIntervalMinutes: data.autoSyncIntervalMinutes.present
          ? data.autoSyncIntervalMinutes.value
          : this.autoSyncIntervalMinutes,
      syncOnLaunch: data.syncOnLaunch.present
          ? data.syncOnLaunch.value
          : this.syncOnLaunch,
      backgroundSync: data.backgroundSync.present
          ? data.backgroundSync.value
          : this.backgroundSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncProfileStateData(')
          ..write('profileId: $profileId, ')
          ..write('serverProfileId: $serverProfileId, ')
          ..write('serverProfileName: $serverProfileName, ')
          ..write('since: $since, ')
          ..write('localSince: $localSince, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('autoSyncIntervalMinutes: $autoSyncIntervalMinutes, ')
          ..write('syncOnLaunch: $syncOnLaunch, ')
          ..write('backgroundSync: $backgroundSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    serverProfileId,
    serverProfileName,
    since,
    localSince,
    lastSyncAt,
    autoSyncIntervalMinutes,
    syncOnLaunch,
    backgroundSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncProfileStateData &&
          other.profileId == this.profileId &&
          other.serverProfileId == this.serverProfileId &&
          other.serverProfileName == this.serverProfileName &&
          other.since == this.since &&
          other.localSince == this.localSince &&
          other.lastSyncAt == this.lastSyncAt &&
          other.autoSyncIntervalMinutes == this.autoSyncIntervalMinutes &&
          other.syncOnLaunch == this.syncOnLaunch &&
          other.backgroundSync == this.backgroundSync);
}

class SyncProfileStateCompanion extends UpdateCompanion<SyncProfileStateData> {
  final Value<int> profileId;
  final Value<int?> serverProfileId;
  final Value<String?> serverProfileName;
  final Value<int> since;
  final Value<int> localSince;
  final Value<int> lastSyncAt;
  final Value<int> autoSyncIntervalMinutes;
  final Value<bool> syncOnLaunch;
  final Value<bool> backgroundSync;
  const SyncProfileStateCompanion({
    this.profileId = const Value.absent(),
    this.serverProfileId = const Value.absent(),
    this.serverProfileName = const Value.absent(),
    this.since = const Value.absent(),
    this.localSince = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.autoSyncIntervalMinutes = const Value.absent(),
    this.syncOnLaunch = const Value.absent(),
    this.backgroundSync = const Value.absent(),
  });
  SyncProfileStateCompanion.insert({
    this.profileId = const Value.absent(),
    this.serverProfileId = const Value.absent(),
    this.serverProfileName = const Value.absent(),
    this.since = const Value.absent(),
    this.localSince = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.autoSyncIntervalMinutes = const Value.absent(),
    this.syncOnLaunch = const Value.absent(),
    this.backgroundSync = const Value.absent(),
  });
  static Insertable<SyncProfileStateData> custom({
    Expression<int>? profileId,
    Expression<int>? serverProfileId,
    Expression<String>? serverProfileName,
    Expression<int>? since,
    Expression<int>? localSince,
    Expression<int>? lastSyncAt,
    Expression<int>? autoSyncIntervalMinutes,
    Expression<bool>? syncOnLaunch,
    Expression<bool>? backgroundSync,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (serverProfileId != null) 'server_profile_id': serverProfileId,
      if (serverProfileName != null) 'server_profile_name': serverProfileName,
      if (since != null) 'since': since,
      if (localSince != null) 'local_since': localSince,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (autoSyncIntervalMinutes != null)
        'auto_sync_interval_minutes': autoSyncIntervalMinutes,
      if (syncOnLaunch != null) 'sync_on_launch': syncOnLaunch,
      if (backgroundSync != null) 'background_sync': backgroundSync,
    });
  }

  SyncProfileStateCompanion copyWith({
    Value<int>? profileId,
    Value<int?>? serverProfileId,
    Value<String?>? serverProfileName,
    Value<int>? since,
    Value<int>? localSince,
    Value<int>? lastSyncAt,
    Value<int>? autoSyncIntervalMinutes,
    Value<bool>? syncOnLaunch,
    Value<bool>? backgroundSync,
  }) {
    return SyncProfileStateCompanion(
      profileId: profileId ?? this.profileId,
      serverProfileId: serverProfileId ?? this.serverProfileId,
      serverProfileName: serverProfileName ?? this.serverProfileName,
      since: since ?? this.since,
      localSince: localSince ?? this.localSince,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      autoSyncIntervalMinutes:
          autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
      syncOnLaunch: syncOnLaunch ?? this.syncOnLaunch,
      backgroundSync: backgroundSync ?? this.backgroundSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (serverProfileId.present) {
      map['server_profile_id'] = Variable<int>(serverProfileId.value);
    }
    if (serverProfileName.present) {
      map['server_profile_name'] = Variable<String>(serverProfileName.value);
    }
    if (since.present) {
      map['since'] = Variable<int>(since.value);
    }
    if (localSince.present) {
      map['local_since'] = Variable<int>(localSince.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (autoSyncIntervalMinutes.present) {
      map['auto_sync_interval_minutes'] = Variable<int>(
        autoSyncIntervalMinutes.value,
      );
    }
    if (syncOnLaunch.present) {
      map['sync_on_launch'] = Variable<bool>(syncOnLaunch.value);
    }
    if (backgroundSync.present) {
      map['background_sync'] = Variable<bool>(backgroundSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncProfileStateCompanion(')
          ..write('profileId: $profileId, ')
          ..write('serverProfileId: $serverProfileId, ')
          ..write('serverProfileName: $serverProfileName, ')
          ..write('since: $since, ')
          ..write('localSince: $localSince, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('autoSyncIntervalMinutes: $autoSyncIntervalMinutes, ')
          ..write('syncOnLaunch: $syncOnLaunch, ')
          ..write('backgroundSync: $backgroundSync')
          ..write(')'))
        .toString();
  }
}

class $SyncFilesTable extends SyncFiles
    with TableInfo<$SyncFilesTable, SyncFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    kind,
    name,
    sha256,
    sizeBytes,
    modifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, kind, name};
  @override
  SyncFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncFile(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
    );
  }

  @override
  $SyncFilesTable createAlias(String alias) {
    return $SyncFilesTable(attachedDatabase, alias);
  }
}

class SyncFile extends DataClass implements Insertable<SyncFile> {
  final int profileId;
  final String kind;
  final String name;
  final String sha256;
  final int sizeBytes;
  final int modifiedAt;
  const SyncFile({
    required this.profileId,
    required this.kind,
    required this.name,
    required this.sha256,
    required this.sizeBytes,
    required this.modifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['sha256'] = Variable<String>(sha256);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['modified_at'] = Variable<int>(modifiedAt);
    return map;
  }

  SyncFilesCompanion toCompanion(bool nullToAbsent) {
    return SyncFilesCompanion(
      profileId: Value(profileId),
      kind: Value(kind),
      name: Value(name),
      sha256: Value(sha256),
      sizeBytes: Value(sizeBytes),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory SyncFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncFile(
      profileId: serializer.fromJson<int>(json['profileId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      sha256: serializer.fromJson<String>(json['sha256']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'sha256': serializer.toJson<String>(sha256),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
    };
  }

  SyncFile copyWith({
    int? profileId,
    String? kind,
    String? name,
    String? sha256,
    int? sizeBytes,
    int? modifiedAt,
  }) => SyncFile(
    profileId: profileId ?? this.profileId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    sha256: sha256 ?? this.sha256,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
  SyncFile copyWithCompanion(SyncFilesCompanion data) {
    return SyncFile(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncFile(')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(profileId, kind, name, sha256, sizeBytes, modifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncFile &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.sha256 == this.sha256 &&
          other.sizeBytes == this.sizeBytes &&
          other.modifiedAt == this.modifiedAt);
}

class SyncFilesCompanion extends UpdateCompanion<SyncFile> {
  final Value<int> profileId;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> sha256;
  final Value<int> sizeBytes;
  final Value<int> modifiedAt;
  final Value<int> rowid;
  const SyncFilesCompanion({
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncFilesCompanion.insert({
    required int profileId,
    required String kind,
    required String name,
    required String sha256,
    required int sizeBytes,
    required int modifiedAt,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       kind = Value(kind),
       name = Value(name),
       sha256 = Value(sha256),
       sizeBytes = Value(sizeBytes),
       modifiedAt = Value(modifiedAt);
  static Insertable<SyncFile> custom({
    Expression<int>? profileId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? sha256,
    Expression<int>? sizeBytes,
    Expression<int>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (sha256 != null) 'sha256': sha256,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncFilesCompanion copyWith({
    Value<int>? profileId,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? sha256,
    Value<int>? sizeBytes,
    Value<int>? modifiedAt,
    Value<int>? rowid,
  }) {
    return SyncFilesCompanion(
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncFilesCompanion(')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackerLinksTable extends TrackerLinks
    with TableInfo<$TrackerLinksTable, TrackerLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackerLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _libraryEntryIdMeta = const VerificationMeta(
    'libraryEntryId',
  );
  @override
  late final GeneratedColumn<int> libraryEntryId = GeneratedColumn<int>(
    'library_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackerMeta = const VerificationMeta(
    'tracker',
  );
  @override
  late final GeneratedColumn<String> tracker = GeneratedColumn<String>(
    'tracker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('anilist'),
  );
  static const VerificationMeta _remoteMediaIdMeta = const VerificationMeta(
    'remoteMediaId',
  );
  @override
  late final GeneratedColumn<int> remoteMediaId = GeneratedColumn<int>(
    'remote_media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteTitleMeta = const VerificationMeta(
    'remoteTitle',
  );
  @override
  late final GeneratedColumn<String> remoteTitle = GeneratedColumn<String>(
    'remote_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteChaptersMeta = const VerificationMeta(
    'remoteChapters',
  );
  @override
  late final GeneratedColumn<int> remoteChapters = GeneratedColumn<int>(
    'remote_chapters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAtMeta = const VerificationMeta(
    'linkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> linkedAt = GeneratedColumn<DateTime>(
    'linked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryEntryId,
    tracker,
    remoteMediaId,
    remoteTitle,
    remoteChapters,
    linkedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracker_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackerLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('library_entry_id')) {
      context.handle(
        _libraryEntryIdMeta,
        libraryEntryId.isAcceptableOrUnknown(
          data['library_entry_id']!,
          _libraryEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryEntryIdMeta);
    }
    if (data.containsKey('tracker')) {
      context.handle(
        _trackerMeta,
        tracker.isAcceptableOrUnknown(data['tracker']!, _trackerMeta),
      );
    }
    if (data.containsKey('remote_media_id')) {
      context.handle(
        _remoteMediaIdMeta,
        remoteMediaId.isAcceptableOrUnknown(
          data['remote_media_id']!,
          _remoteMediaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteMediaIdMeta);
    }
    if (data.containsKey('remote_title')) {
      context.handle(
        _remoteTitleMeta,
        remoteTitle.isAcceptableOrUnknown(
          data['remote_title']!,
          _remoteTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteTitleMeta);
    }
    if (data.containsKey('remote_chapters')) {
      context.handle(
        _remoteChaptersMeta,
        remoteChapters.isAcceptableOrUnknown(
          data['remote_chapters']!,
          _remoteChaptersMeta,
        ),
      );
    }
    if (data.containsKey('linked_at')) {
      context.handle(
        _linkedAtMeta,
        linkedAt.isAcceptableOrUnknown(data['linked_at']!, _linkedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {libraryEntryId, tracker},
  ];
  @override
  TrackerLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackerLinkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      libraryEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}library_entry_id'],
      )!,
      tracker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracker'],
      )!,
      remoteMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_media_id'],
      )!,
      remoteTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_title'],
      )!,
      remoteChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_chapters'],
      ),
      linkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}linked_at'],
      )!,
    );
  }

  @override
  $TrackerLinksTable createAlias(String alias) {
    return $TrackerLinksTable(attachedDatabase, alias);
  }
}

class TrackerLinkRow extends DataClass implements Insertable<TrackerLinkRow> {
  final int id;
  final int libraryEntryId;
  final String tracker;
  final int remoteMediaId;
  final String remoteTitle;
  final int? remoteChapters;
  final DateTime linkedAt;
  const TrackerLinkRow({
    required this.id,
    required this.libraryEntryId,
    required this.tracker,
    required this.remoteMediaId,
    required this.remoteTitle,
    this.remoteChapters,
    required this.linkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['library_entry_id'] = Variable<int>(libraryEntryId);
    map['tracker'] = Variable<String>(tracker);
    map['remote_media_id'] = Variable<int>(remoteMediaId);
    map['remote_title'] = Variable<String>(remoteTitle);
    if (!nullToAbsent || remoteChapters != null) {
      map['remote_chapters'] = Variable<int>(remoteChapters);
    }
    map['linked_at'] = Variable<DateTime>(linkedAt);
    return map;
  }

  TrackerLinksCompanion toCompanion(bool nullToAbsent) {
    return TrackerLinksCompanion(
      id: Value(id),
      libraryEntryId: Value(libraryEntryId),
      tracker: Value(tracker),
      remoteMediaId: Value(remoteMediaId),
      remoteTitle: Value(remoteTitle),
      remoteChapters: remoteChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteChapters),
      linkedAt: Value(linkedAt),
    );
  }

  factory TrackerLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackerLinkRow(
      id: serializer.fromJson<int>(json['id']),
      libraryEntryId: serializer.fromJson<int>(json['libraryEntryId']),
      tracker: serializer.fromJson<String>(json['tracker']),
      remoteMediaId: serializer.fromJson<int>(json['remoteMediaId']),
      remoteTitle: serializer.fromJson<String>(json['remoteTitle']),
      remoteChapters: serializer.fromJson<int?>(json['remoteChapters']),
      linkedAt: serializer.fromJson<DateTime>(json['linkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'libraryEntryId': serializer.toJson<int>(libraryEntryId),
      'tracker': serializer.toJson<String>(tracker),
      'remoteMediaId': serializer.toJson<int>(remoteMediaId),
      'remoteTitle': serializer.toJson<String>(remoteTitle),
      'remoteChapters': serializer.toJson<int?>(remoteChapters),
      'linkedAt': serializer.toJson<DateTime>(linkedAt),
    };
  }

  TrackerLinkRow copyWith({
    int? id,
    int? libraryEntryId,
    String? tracker,
    int? remoteMediaId,
    String? remoteTitle,
    Value<int?> remoteChapters = const Value.absent(),
    DateTime? linkedAt,
  }) => TrackerLinkRow(
    id: id ?? this.id,
    libraryEntryId: libraryEntryId ?? this.libraryEntryId,
    tracker: tracker ?? this.tracker,
    remoteMediaId: remoteMediaId ?? this.remoteMediaId,
    remoteTitle: remoteTitle ?? this.remoteTitle,
    remoteChapters: remoteChapters.present
        ? remoteChapters.value
        : this.remoteChapters,
    linkedAt: linkedAt ?? this.linkedAt,
  );
  TrackerLinkRow copyWithCompanion(TrackerLinksCompanion data) {
    return TrackerLinkRow(
      id: data.id.present ? data.id.value : this.id,
      libraryEntryId: data.libraryEntryId.present
          ? data.libraryEntryId.value
          : this.libraryEntryId,
      tracker: data.tracker.present ? data.tracker.value : this.tracker,
      remoteMediaId: data.remoteMediaId.present
          ? data.remoteMediaId.value
          : this.remoteMediaId,
      remoteTitle: data.remoteTitle.present
          ? data.remoteTitle.value
          : this.remoteTitle,
      remoteChapters: data.remoteChapters.present
          ? data.remoteChapters.value
          : this.remoteChapters,
      linkedAt: data.linkedAt.present ? data.linkedAt.value : this.linkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackerLinkRow(')
          ..write('id: $id, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('tracker: $tracker, ')
          ..write('remoteMediaId: $remoteMediaId, ')
          ..write('remoteTitle: $remoteTitle, ')
          ..write('remoteChapters: $remoteChapters, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    libraryEntryId,
    tracker,
    remoteMediaId,
    remoteTitle,
    remoteChapters,
    linkedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackerLinkRow &&
          other.id == this.id &&
          other.libraryEntryId == this.libraryEntryId &&
          other.tracker == this.tracker &&
          other.remoteMediaId == this.remoteMediaId &&
          other.remoteTitle == this.remoteTitle &&
          other.remoteChapters == this.remoteChapters &&
          other.linkedAt == this.linkedAt);
}

class TrackerLinksCompanion extends UpdateCompanion<TrackerLinkRow> {
  final Value<int> id;
  final Value<int> libraryEntryId;
  final Value<String> tracker;
  final Value<int> remoteMediaId;
  final Value<String> remoteTitle;
  final Value<int?> remoteChapters;
  final Value<DateTime> linkedAt;
  const TrackerLinksCompanion({
    this.id = const Value.absent(),
    this.libraryEntryId = const Value.absent(),
    this.tracker = const Value.absent(),
    this.remoteMediaId = const Value.absent(),
    this.remoteTitle = const Value.absent(),
    this.remoteChapters = const Value.absent(),
    this.linkedAt = const Value.absent(),
  });
  TrackerLinksCompanion.insert({
    this.id = const Value.absent(),
    required int libraryEntryId,
    this.tracker = const Value.absent(),
    required int remoteMediaId,
    required String remoteTitle,
    this.remoteChapters = const Value.absent(),
    this.linkedAt = const Value.absent(),
  }) : libraryEntryId = Value(libraryEntryId),
       remoteMediaId = Value(remoteMediaId),
       remoteTitle = Value(remoteTitle);
  static Insertable<TrackerLinkRow> custom({
    Expression<int>? id,
    Expression<int>? libraryEntryId,
    Expression<String>? tracker,
    Expression<int>? remoteMediaId,
    Expression<String>? remoteTitle,
    Expression<int>? remoteChapters,
    Expression<DateTime>? linkedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryEntryId != null) 'library_entry_id': libraryEntryId,
      if (tracker != null) 'tracker': tracker,
      if (remoteMediaId != null) 'remote_media_id': remoteMediaId,
      if (remoteTitle != null) 'remote_title': remoteTitle,
      if (remoteChapters != null) 'remote_chapters': remoteChapters,
      if (linkedAt != null) 'linked_at': linkedAt,
    });
  }

  TrackerLinksCompanion copyWith({
    Value<int>? id,
    Value<int>? libraryEntryId,
    Value<String>? tracker,
    Value<int>? remoteMediaId,
    Value<String>? remoteTitle,
    Value<int?>? remoteChapters,
    Value<DateTime>? linkedAt,
  }) {
    return TrackerLinksCompanion(
      id: id ?? this.id,
      libraryEntryId: libraryEntryId ?? this.libraryEntryId,
      tracker: tracker ?? this.tracker,
      remoteMediaId: remoteMediaId ?? this.remoteMediaId,
      remoteTitle: remoteTitle ?? this.remoteTitle,
      remoteChapters: remoteChapters ?? this.remoteChapters,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (libraryEntryId.present) {
      map['library_entry_id'] = Variable<int>(libraryEntryId.value);
    }
    if (tracker.present) {
      map['tracker'] = Variable<String>(tracker.value);
    }
    if (remoteMediaId.present) {
      map['remote_media_id'] = Variable<int>(remoteMediaId.value);
    }
    if (remoteTitle.present) {
      map['remote_title'] = Variable<String>(remoteTitle.value);
    }
    if (remoteChapters.present) {
      map['remote_chapters'] = Variable<int>(remoteChapters.value);
    }
    if (linkedAt.present) {
      map['linked_at'] = Variable<DateTime>(linkedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackerLinksCompanion(')
          ..write('id: $id, ')
          ..write('libraryEntryId: $libraryEntryId, ')
          ..write('tracker: $tracker, ')
          ..write('remoteMediaId: $remoteMediaId, ')
          ..write('remoteTitle: $remoteTitle, ')
          ..write('remoteChapters: $remoteChapters, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackerOutboxTable extends TrackerOutbox
    with TableInfo<$TrackerOutboxTable, TrackerOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackerOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _linkIdMeta = const VerificationMeta('linkId');
  @override
  late final GeneratedColumn<int> linkId = GeneratedColumn<int>(
    'link_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracker_links (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _firstQueuedAtMeta = const VerificationMeta(
    'firstQueuedAt',
  );
  @override
  late final GeneratedColumn<int> firstQueuedAt = GeneratedColumn<int>(
    'first_queued_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextTryAtMeta = const VerificationMeta(
    'nextTryAt',
  );
  @override
  late final GeneratedColumn<int> nextTryAt = GeneratedColumn<int>(
    'next_try_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    linkId,
    firstQueuedAt,
    version,
    attempts,
    lastError,
    nextTryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracker_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackerOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('link_id')) {
      context.handle(
        _linkIdMeta,
        linkId.isAcceptableOrUnknown(data['link_id']!, _linkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_linkIdMeta);
    }
    if (data.containsKey('first_queued_at')) {
      context.handle(
        _firstQueuedAtMeta,
        firstQueuedAt.isAcceptableOrUnknown(
          data['first_queued_at']!,
          _firstQueuedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstQueuedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_try_at')) {
      context.handle(
        _nextTryAtMeta,
        nextTryAt.isAcceptableOrUnknown(data['next_try_at']!, _nextTryAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {linkId},
  ];
  @override
  TrackerOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackerOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      linkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}link_id'],
      )!,
      firstQueuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_queued_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextTryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_try_at'],
      )!,
    );
  }

  @override
  $TrackerOutboxTable createAlias(String alias) {
    return $TrackerOutboxTable(attachedDatabase, alias);
  }
}

class TrackerOutboxRow extends DataClass
    implements Insertable<TrackerOutboxRow> {
  final int id;
  final int linkId;
  final int firstQueuedAt;
  final int version;
  final int attempts;
  final String? lastError;
  final int nextTryAt;
  const TrackerOutboxRow({
    required this.id,
    required this.linkId,
    required this.firstQueuedAt,
    required this.version,
    required this.attempts,
    this.lastError,
    required this.nextTryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['link_id'] = Variable<int>(linkId);
    map['first_queued_at'] = Variable<int>(firstQueuedAt);
    map['version'] = Variable<int>(version);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['next_try_at'] = Variable<int>(nextTryAt);
    return map;
  }

  TrackerOutboxCompanion toCompanion(bool nullToAbsent) {
    return TrackerOutboxCompanion(
      id: Value(id),
      linkId: Value(linkId),
      firstQueuedAt: Value(firstQueuedAt),
      version: Value(version),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextTryAt: Value(nextTryAt),
    );
  }

  factory TrackerOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackerOutboxRow(
      id: serializer.fromJson<int>(json['id']),
      linkId: serializer.fromJson<int>(json['linkId']),
      firstQueuedAt: serializer.fromJson<int>(json['firstQueuedAt']),
      version: serializer.fromJson<int>(json['version']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextTryAt: serializer.fromJson<int>(json['nextTryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'linkId': serializer.toJson<int>(linkId),
      'firstQueuedAt': serializer.toJson<int>(firstQueuedAt),
      'version': serializer.toJson<int>(version),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextTryAt': serializer.toJson<int>(nextTryAt),
    };
  }

  TrackerOutboxRow copyWith({
    int? id,
    int? linkId,
    int? firstQueuedAt,
    int? version,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    int? nextTryAt,
  }) => TrackerOutboxRow(
    id: id ?? this.id,
    linkId: linkId ?? this.linkId,
    firstQueuedAt: firstQueuedAt ?? this.firstQueuedAt,
    version: version ?? this.version,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextTryAt: nextTryAt ?? this.nextTryAt,
  );
  TrackerOutboxRow copyWithCompanion(TrackerOutboxCompanion data) {
    return TrackerOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      linkId: data.linkId.present ? data.linkId.value : this.linkId,
      firstQueuedAt: data.firstQueuedAt.present
          ? data.firstQueuedAt.value
          : this.firstQueuedAt,
      version: data.version.present ? data.version.value : this.version,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextTryAt: data.nextTryAt.present ? data.nextTryAt.value : this.nextTryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackerOutboxRow(')
          ..write('id: $id, ')
          ..write('linkId: $linkId, ')
          ..write('firstQueuedAt: $firstQueuedAt, ')
          ..write('version: $version, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextTryAt: $nextTryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    linkId,
    firstQueuedAt,
    version,
    attempts,
    lastError,
    nextTryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackerOutboxRow &&
          other.id == this.id &&
          other.linkId == this.linkId &&
          other.firstQueuedAt == this.firstQueuedAt &&
          other.version == this.version &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextTryAt == this.nextTryAt);
}

class TrackerOutboxCompanion extends UpdateCompanion<TrackerOutboxRow> {
  final Value<int> id;
  final Value<int> linkId;
  final Value<int> firstQueuedAt;
  final Value<int> version;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> nextTryAt;
  const TrackerOutboxCompanion({
    this.id = const Value.absent(),
    this.linkId = const Value.absent(),
    this.firstQueuedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextTryAt = const Value.absent(),
  });
  TrackerOutboxCompanion.insert({
    this.id = const Value.absent(),
    required int linkId,
    required int firstQueuedAt,
    this.version = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextTryAt = const Value.absent(),
  }) : linkId = Value(linkId),
       firstQueuedAt = Value(firstQueuedAt);
  static Insertable<TrackerOutboxRow> custom({
    Expression<int>? id,
    Expression<int>? linkId,
    Expression<int>? firstQueuedAt,
    Expression<int>? version,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? nextTryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (linkId != null) 'link_id': linkId,
      if (firstQueuedAt != null) 'first_queued_at': firstQueuedAt,
      if (version != null) 'version': version,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextTryAt != null) 'next_try_at': nextTryAt,
    });
  }

  TrackerOutboxCompanion copyWith({
    Value<int>? id,
    Value<int>? linkId,
    Value<int>? firstQueuedAt,
    Value<int>? version,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? nextTryAt,
  }) {
    return TrackerOutboxCompanion(
      id: id ?? this.id,
      linkId: linkId ?? this.linkId,
      firstQueuedAt: firstQueuedAt ?? this.firstQueuedAt,
      version: version ?? this.version,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextTryAt: nextTryAt ?? this.nextTryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (linkId.present) {
      map['link_id'] = Variable<int>(linkId.value);
    }
    if (firstQueuedAt.present) {
      map['first_queued_at'] = Variable<int>(firstQueuedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextTryAt.present) {
      map['next_try_at'] = Variable<int>(nextTryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackerOutboxCompanion(')
          ..write('id: $id, ')
          ..write('linkId: $linkId, ')
          ..write('firstQueuedAt: $firstQueuedAt, ')
          ..write('version: $version, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextTryAt: $nextTryAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $EntryBranchesTable entryBranches = $EntryBranchesTable(this);
  late final $LibraryEntriesTable libraryEntries = $LibraryEntriesTable(this);
  late final $ContentUnitsTable contentUnits = $ContentUnitsTable(this);
  late final $ChapterProgressTable chapterProgress = $ChapterProgressTable(
    this,
  );
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $EntryCategoriesTable entryCategories = $EntryCategoriesTable(
    this,
  );
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $InstalledSourcesTable installedSources = $InstalledSourcesTable(
    this,
  );
  late final $ReposTable repos = $ReposTable(this);
  late final $ActiveProfileTableTable activeProfileTable =
      $ActiveProfileTableTable(this);
  late final $SettingValuesTable settingValues = $SettingValuesTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $SyncDeletionsTable syncDeletions = $SyncDeletionsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SyncProfileStateTable syncProfileState = $SyncProfileStateTable(
    this,
  );
  late final $SyncFilesTable syncFiles = $SyncFilesTable(this);
  late final $TrackerLinksTable trackerLinks = $TrackerLinksTable(this);
  late final $TrackerOutboxTable trackerOutbox = $TrackerOutboxTable(this);
  late final Index idxLibraryEntriesSource = Index(
    'idx_library_entries_source',
    'CREATE INDEX idx_library_entries_source ON library_entries (source_id)',
  );
  late final Index idxLibraryEntriesClientId = Index(
    'idx_library_entries_client_id',
    'CREATE UNIQUE INDEX idx_library_entries_client_id ON library_entries (client_id)',
  );
  late final Index idxLibraryEntriesUpdatedAt = Index(
    'idx_library_entries_updated_at',
    'CREATE INDEX idx_library_entries_updated_at ON library_entries (updated_at)',
  );
  late final Index idxEntryBranchesEntry = Index(
    'idx_entry_branches_entry',
    'CREATE INDEX idx_entry_branches_entry ON entry_branches (library_entry_id)',
  );
  late final Index idxEntryBranchesClientId = Index(
    'idx_entry_branches_client_id',
    'CREATE UNIQUE INDEX idx_entry_branches_client_id ON entry_branches (client_id)',
  );
  late final Index idxEntryBranchesUpdatedAt = Index(
    'idx_entry_branches_updated_at',
    'CREATE INDEX idx_entry_branches_updated_at ON entry_branches (updated_at)',
  );
  late final Index idxContentUnitsEntry = Index(
    'idx_content_units_entry',
    'CREATE INDEX idx_content_units_entry ON content_units (library_entry_id)',
  );
  late final Index idxContentUnitsUpdates = Index(
    'idx_content_units_updates',
    'CREATE INDEX idx_content_units_updates ON content_units (date_uploaded)',
  );
  late final Index idxContentUnitsClientId = Index(
    'idx_content_units_client_id',
    'CREATE UNIQUE INDEX idx_content_units_client_id ON content_units (client_id)',
  );
  late final Index idxContentUnitsUpdatedAt = Index(
    'idx_content_units_updated_at',
    'CREATE INDEX idx_content_units_updated_at ON content_units (updated_at)',
  );
  late final Index idxChapterProgressBranch = Index(
    'idx_chapter_progress_branch',
    'CREATE INDEX idx_chapter_progress_branch ON chapter_progress (branch_id, consumed, consumed_at)',
  );
  late final Index idxChapterProgressClientId = Index(
    'idx_chapter_progress_client_id',
    'CREATE UNIQUE INDEX idx_chapter_progress_client_id ON chapter_progress (client_id)',
  );
  late final Index idxChapterProgressUpdatedAt = Index(
    'idx_chapter_progress_updated_at',
    'CREATE INDEX idx_chapter_progress_updated_at ON chapter_progress (updated_at)',
  );
  late final Index idxCategoriesClientId = Index(
    'idx_categories_client_id',
    'CREATE UNIQUE INDEX idx_categories_client_id ON categories (client_id)',
  );
  late final Index idxCategoriesUpdatedAt = Index(
    'idx_categories_updated_at',
    'CREATE INDEX idx_categories_updated_at ON categories (updated_at)',
  );
  late final Index idxEntryCategoriesCategory = Index(
    'idx_entry_categories_category',
    'CREATE INDEX idx_entry_categories_category ON entry_categories (category_id)',
  );
  late final Index idxLogEntriesTime = Index(
    'idx_log_entries_time',
    'CREATE INDEX idx_log_entries_time ON log_entries (timestamp)',
  );
  late final Index idxInstalledSourcesClientId = Index(
    'idx_installed_sources_client_id',
    'CREATE UNIQUE INDEX idx_installed_sources_client_id ON installed_sources (client_id)',
  );
  late final Index idxInstalledSourcesUpdatedAt = Index(
    'idx_installed_sources_updated_at',
    'CREATE INDEX idx_installed_sources_updated_at ON installed_sources (updated_at)',
  );
  late final Index idxReposClientId = Index(
    'idx_repos_client_id',
    'CREATE UNIQUE INDEX idx_repos_client_id ON repos (client_id)',
  );
  late final Index idxReposUpdatedAt = Index(
    'idx_repos_updated_at',
    'CREATE INDEX idx_repos_updated_at ON repos (updated_at)',
  );
  late final Index idxSettingValuesSetting = Index(
    'idx_setting_values_setting',
    'CREATE INDEX idx_setting_values_setting ON setting_values (setting_id)',
  );
  late final Index idxReadingSessionsEntryTime = Index(
    'idx_reading_sessions_entry_time',
    'CREATE INDEX idx_reading_sessions_entry_time ON reading_sessions (library_entry_id, read_at)',
  );
  late final Index idxReadingSessionsTime = Index(
    'idx_reading_sessions_time',
    'CREATE INDEX idx_reading_sessions_time ON reading_sessions (read_at)',
  );
  late final Index idxReadingSessionsClientId = Index(
    'idx_reading_sessions_client_id',
    'CREATE UNIQUE INDEX idx_reading_sessions_client_id ON reading_sessions (client_id)',
  );
  late final Index idxReadingSessionsUpdatedAt = Index(
    'idx_reading_sessions_updated_at',
    'CREATE INDEX idx_reading_sessions_updated_at ON reading_sessions (updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    entryBranches,
    libraryEntries,
    contentUnits,
    chapterProgress,
    categories,
    entryCategories,
    logEntries,
    installedSources,
    repos,
    activeProfileTable,
    settingValues,
    readingSessions,
    syncDeletions,
    syncState,
    syncProfileState,
    syncFiles,
    trackerLinks,
    trackerOutbox,
    idxLibraryEntriesSource,
    idxLibraryEntriesClientId,
    idxLibraryEntriesUpdatedAt,
    idxEntryBranchesEntry,
    idxEntryBranchesClientId,
    idxEntryBranchesUpdatedAt,
    idxContentUnitsEntry,
    idxContentUnitsUpdates,
    idxContentUnitsClientId,
    idxContentUnitsUpdatedAt,
    idxChapterProgressBranch,
    idxChapterProgressClientId,
    idxChapterProgressUpdatedAt,
    idxCategoriesClientId,
    idxCategoriesUpdatedAt,
    idxEntryCategoriesCategory,
    idxLogEntriesTime,
    idxInstalledSourcesClientId,
    idxInstalledSourcesUpdatedAt,
    idxReposClientId,
    idxReposUpdatedAt,
    idxSettingValuesSetting,
    idxReadingSessionsEntryTime,
    idxReadingSessionsTime,
    idxReadingSessionsClientId,
    idxReadingSessionsUpdatedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_branches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_branches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('content_units', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_units',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapter_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_branches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapter_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('active_profile', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'content_units',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_branches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_profile_state', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracker_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracker_links',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracker_outbox', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> avatarPath,
  Value<DateTime> createdAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> avatarPath,
  Value<DateTime> createdAt,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LibraryEntriesTable, List<LibraryEntry>>
  _libraryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.libraryEntries,
    aliasName: 'profiles__id__library_entries__profile_id',
  );

  $$LibraryEntriesTableProcessedTableManager get libraryEntriesRefs {
    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_libraryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'profiles__id__categories__profile_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ActiveProfileTableTable,
    List<ActiveProfileTableData>
  >
  _activeProfileTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.activeProfileTable,
        aliasName: 'profiles__id__active_profile__profile_id',
      );

  $$ActiveProfileTableTableProcessedTableManager get activeProfileTableRefs {
    final manager = $$ActiveProfileTableTableTableManager(
      $_db,
      $_db.activeProfileTable,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activeProfileTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncProfileStateTable, List<SyncProfileStateData>>
  _syncProfileStateRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncProfileState,
    aliasName: 'profiles__id__sync_profile_state__profile_id',
  );

  $$SyncProfileStateTableProcessedTableManager get syncProfileStateRefs {
    final manager = $$SyncProfileStateTableTableManager(
      $_db,
      $_db.syncProfileState,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncProfileStateRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> libraryEntriesRefs(
    Expression<bool> Function($$LibraryEntriesTableFilterComposer f) f,
  ) {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> activeProfileTableRefs(
    Expression<bool> Function($$ActiveProfileTableTableFilterComposer f) f,
  ) {
    final $$ActiveProfileTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activeProfileTable,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveProfileTableTableFilterComposer(
            $db: $db,
            $table: $db.activeProfileTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncProfileStateRefs(
    Expression<bool> Function($$SyncProfileStateTableFilterComposer f) f,
  ) {
    final $$SyncProfileStateTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncProfileState,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncProfileStateTableFilterComposer(
            $db: $db,
            $table: $db.syncProfileState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> libraryEntriesRefs<T extends Object>(
    Expression<T> Function($$LibraryEntriesTableAnnotationComposer a) f,
  ) {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> activeProfileTableRefs<T extends Object>(
    Expression<T> Function($$ActiveProfileTableTableAnnotationComposer a) f,
  ) {
    final $$ActiveProfileTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.activeProfileTable,
          getReferencedColumn: (t) => t.profileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ActiveProfileTableTableAnnotationComposer(
                $db: $db,
                $table: $db.activeProfileTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> syncProfileStateRefs<T extends Object>(
    Expression<T> Function($$SyncProfileStateTableAnnotationComposer a) f,
  ) {
    final $$SyncProfileStateTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncProfileState,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncProfileStateTableAnnotationComposer(
            $db: $db,
            $table: $db.syncProfileState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({
            bool libraryEntriesRefs,
            bool categoriesRefs,
            bool activeProfileTableRefs,
            bool syncProfileStateRefs,
          })
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                avatarPath: avatarPath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> avatarPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                avatarPath: avatarPath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryEntriesRefs = false,
                categoriesRefs = false,
                activeProfileTableRefs = false,
                syncProfileStateRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (libraryEntriesRefs) db.libraryEntries,
                    if (categoriesRefs) db.categories,
                    if (activeProfileTableRefs) db.activeProfileTable,
                    if (syncProfileStateRefs) db.syncProfileState,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (libraryEntriesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          LibraryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._libraryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).libraryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Category
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (activeProfileTableRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          ActiveProfileTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._activeProfileTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).activeProfileTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncProfileStateRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          SyncProfileStateData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._syncProfileStateRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).syncProfileStateRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({
        bool libraryEntriesRefs,
        bool categoriesRefs,
        bool activeProfileTableRefs,
        bool syncProfileStateRefs,
      })
    >;
typedef $$EntryBranchesTableCreateCompanionBuilder =
    EntryBranchesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      required int libraryEntryId,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$EntryBranchesTableUpdateCompanionBuilder =
    EntryBranchesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int> libraryEntryId,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$EntryBranchesTableReferences
    extends BaseReferences<_$AppDatabase, $EntryBranchesTable, EntryBranche> {
  $$EntryBranchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryEntriesTable _libraryEntryIdTable(_$AppDatabase db) => db
      .libraryEntries
      .createAlias('entry_branches__library_entry_id__library_entries__id');

  $$LibraryEntriesTableProcessedTableManager get libraryEntryId {
    final $_column = $_itemColumn<int>('library_entry_id')!;

    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LibraryEntriesTable, List<LibraryEntry>>
  _libraryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.libraryEntries,
    aliasName: 'entry_branches__id__library_entries__active_branch_id',
  );

  $$LibraryEntriesTableProcessedTableManager get libraryEntriesRefs {
    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.activeBranchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_libraryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChapterProgressTable, List<ChapterProgressData>>
  _chapterProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chapterProgress,
    aliasName: 'entry_branches__id__chapter_progress__branch_id',
  );

  $$ChapterProgressTableProcessedTableManager get chapterProgressRefs {
    final manager = $$ChapterProgressTableTableManager(
      $_db,
      $_db.chapterProgress,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chapterProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: 'entry_branches__id__reading_sessions__branch_id',
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntryBranchesTableFilterComposer
    extends Composer<_$AppDatabase, $EntryBranchesTable> {
  $$EntryBranchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryEntriesTableFilterComposer get libraryEntryId {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> libraryEntriesRefs(
    Expression<bool> Function($$LibraryEntriesTableFilterComposer f) f,
  ) {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.activeBranchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chapterProgressRefs(
    Expression<bool> Function($$ChapterProgressTableFilterComposer f) f,
  ) {
    final $$ChapterProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterProgress,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterProgressTableFilterComposer(
            $db: $db,
            $table: $db.chapterProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntryBranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryBranchesTable> {
  $$EntryBranchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryEntriesTableOrderingComposer get libraryEntryId {
    final $$LibraryEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryBranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryBranchesTable> {
  $$EntryBranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LibraryEntriesTableAnnotationComposer get libraryEntryId {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> libraryEntriesRefs<T extends Object>(
    Expression<T> Function($$LibraryEntriesTableAnnotationComposer a) f,
  ) {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.activeBranchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chapterProgressRefs<T extends Object>(
    Expression<T> Function($$ChapterProgressTableAnnotationComposer a) f,
  ) {
    final $$ChapterProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterProgress,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.chapterProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntryBranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryBranchesTable,
          EntryBranche,
          $$EntryBranchesTableFilterComposer,
          $$EntryBranchesTableOrderingComposer,
          $$EntryBranchesTableAnnotationComposer,
          $$EntryBranchesTableCreateCompanionBuilder,
          $$EntryBranchesTableUpdateCompanionBuilder,
          (EntryBranche, $$EntryBranchesTableReferences),
          EntryBranche,
          PrefetchHooks Function({
            bool libraryEntryId,
            bool libraryEntriesRefs,
            bool chapterProgressRefs,
            bool readingSessionsRefs,
          })
        > {
  $$EntryBranchesTableTableManager(_$AppDatabase db, $EntryBranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryBranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryBranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryBranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> libraryEntryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntryBranchesCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required int libraryEntryId,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntryBranchesCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryBranchesTable, EntryBranche>(table),
                  $$EntryBranchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryEntryId = false,
                libraryEntriesRefs = false,
                chapterProgressRefs = false,
                readingSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (libraryEntriesRefs) db.libraryEntries,
                    if (chapterProgressRefs) db.chapterProgress,
                    if (readingSessionsRefs) db.readingSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (libraryEntryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryEntryId,
                            referencedTable: $$EntryBranchesTableReferences
                                ._libraryEntryIdTable(db),
                            referencedColumn: $$EntryBranchesTableReferences
                                ._libraryEntryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (libraryEntriesRefs)
                        await $_getPrefetchedData<
                          EntryBranche,
                          $EntryBranchesTable,
                          LibraryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$EntryBranchesTableReferences
                              ._libraryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntryBranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).libraryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.activeBranchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chapterProgressRefs)
                        await $_getPrefetchedData<
                          EntryBranche,
                          $EntryBranchesTable,
                          ChapterProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$EntryBranchesTableReferences
                              ._chapterProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntryBranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).chapterProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.branchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          EntryBranche,
                          $EntryBranchesTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$EntryBranchesTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntryBranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.branchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EntryBranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryBranchesTable,
      EntryBranche,
      $$EntryBranchesTableFilterComposer,
      $$EntryBranchesTableOrderingComposer,
      $$EntryBranchesTableAnnotationComposer,
      $$EntryBranchesTableCreateCompanionBuilder,
      $$EntryBranchesTableUpdateCompanionBuilder,
      (EntryBranche, $$EntryBranchesTableReferences),
      EntryBranche,
      PrefetchHooks Function({
        bool libraryEntryId,
        bool libraryEntriesRefs,
        bool chapterProgressRefs,
        bool readingSessionsRefs,
      })
    >;
typedef $$LibraryEntriesTableCreateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int?> activeBranchId,
      Value<int> profileId,
      required String title,
      Value<String?> coverUrl,
      required MediaType mediaType,
      required String sourceId,
      Value<String?> excludedScanlators,
      Value<String?> sourceKey,
      required String externalId,
      Value<bool> favorite,
      Value<DateTime> addedAt,
      Value<DateTime> lastUpdatedAt,
      Value<ReaderMode?> readerMode,
      Value<bool> readerModeChecked,
      Value<ReaderDualPageMode?> readerDualPageMode,
      Value<String?> settingsOverrides,
      Value<String?> customCoverPath,
      Value<String?> status,
    });
typedef $$LibraryEntriesTableUpdateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int?> activeBranchId,
      Value<int> profileId,
      Value<String> title,
      Value<String?> coverUrl,
      Value<MediaType> mediaType,
      Value<String> sourceId,
      Value<String?> excludedScanlators,
      Value<String?> sourceKey,
      Value<String> externalId,
      Value<bool> favorite,
      Value<DateTime> addedAt,
      Value<DateTime> lastUpdatedAt,
      Value<ReaderMode?> readerMode,
      Value<bool> readerModeChecked,
      Value<ReaderDualPageMode?> readerDualPageMode,
      Value<String?> settingsOverrides,
      Value<String?> customCoverPath,
      Value<String?> status,
    });

final class $$LibraryEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LibraryEntriesTable, LibraryEntry> {
  $$LibraryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntryBranchesTable _activeBranchIdTable(_$AppDatabase db) => db
      .entryBranches
      .createAlias('library_entries__active_branch_id__entry_branches__id');

  $$EntryBranchesTableProcessedTableManager? get activeBranchId {
    final $_column = $_itemColumn<int>('active_branch_id');
    if ($_column == null) return null;
    final manager = $$EntryBranchesTableTableManager(
      $_db,
      $_db.entryBranches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activeBranchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('library_entries__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntryBranchesTable, List<EntryBranche>>
  _entryBranchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryBranches,
    aliasName: 'library_entries__id__entry_branches__library_entry_id',
  );

  $$EntryBranchesTableProcessedTableManager get entryBranchesRefs {
    final manager = $$EntryBranchesTableTableManager(
      $_db,
      $_db.entryBranches,
    ).filter((f) => f.libraryEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryBranchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ContentUnitsTable, List<ContentUnit>>
  _contentUnitsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contentUnits,
    aliasName: 'library_entries__id__content_units__library_entry_id',
  );

  $$ContentUnitsTableProcessedTableManager get contentUnitsRefs {
    final manager = $$ContentUnitsTableTableManager(
      $_db,
      $_db.contentUnits,
    ).filter((f) => f.libraryEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contentUnitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntryCategoriesTable, List<EntryCategory>>
  _entryCategoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryCategories,
    aliasName: 'library_entries__id__entry_categories__library_entry_id',
  );

  $$EntryCategoriesTableProcessedTableManager get entryCategoriesRefs {
    final manager = $$EntryCategoriesTableTableManager(
      $_db,
      $_db.entryCategories,
    ).filter((f) => f.libraryEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _entryCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: 'library_entries__id__reading_sessions__library_entry_id',
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.libraryEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrackerLinksTable, List<TrackerLinkRow>>
  _trackerLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackerLinks,
    aliasName: 'library_entries__id__tracker_links__library_entry_id',
  );

  $$TrackerLinksTableProcessedTableManager get trackerLinksRefs {
    final manager = $$TrackerLinksTableTableManager(
      $_db,
      $_db.trackerLinks,
    ).filter((f) => f.libraryEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackerLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, int> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excludedScanlators => $composableBuilder(
    column: $table.excludedScanlators,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReaderMode?, ReaderMode, int> get readerMode =>
      $composableBuilder(
        column: $table.readerMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get readerModeChecked => $composableBuilder(
    column: $table.readerModeChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReaderDualPageMode?, ReaderDualPageMode, int>
  get readerDualPageMode => $composableBuilder(
    column: $table.readerDualPageMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get settingsOverrides => $composableBuilder(
    column: $table.settingsOverrides,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customCoverPath => $composableBuilder(
    column: $table.customCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$EntryBranchesTableFilterComposer get activeBranchId {
    final $$EntryBranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeBranchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableFilterComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entryBranchesRefs(
    Expression<bool> Function($$EntryBranchesTableFilterComposer f) f,
  ) {
    final $$EntryBranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableFilterComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contentUnitsRefs(
    Expression<bool> Function($$ContentUnitsTableFilterComposer f) f,
  ) {
    final $$ContentUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableFilterComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entryCategoriesRefs(
    Expression<bool> Function($$EntryCategoriesTableFilterComposer f) f,
  ) {
    final $$EntryCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryCategories,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.entryCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trackerLinksRefs(
    Expression<bool> Function($$TrackerLinksTableFilterComposer f) f,
  ) {
    final $$TrackerLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerLinks,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerLinksTableFilterComposer(
            $db: $db,
            $table: $db.trackerLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excludedScanlators => $composableBuilder(
    column: $table.excludedScanlators,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readerMode => $composableBuilder(
    column: $table.readerMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readerModeChecked => $composableBuilder(
    column: $table.readerModeChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readerDualPageMode => $composableBuilder(
    column: $table.readerDualPageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsOverrides => $composableBuilder(
    column: $table.settingsOverrides,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customCoverPath => $composableBuilder(
    column: $table.customCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntryBranchesTableOrderingComposer get activeBranchId {
    final $$EntryBranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeBranchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableOrderingComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, int> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get excludedScanlators => $composableBuilder(
    column: $table.excludedScanlators,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReaderMode?, int> get readerMode =>
      $composableBuilder(
        column: $table.readerMode,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get readerModeChecked => $composableBuilder(
    column: $table.readerModeChecked,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReaderDualPageMode?, int>
  get readerDualPageMode => $composableBuilder(
    column: $table.readerDualPageMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingsOverrides => $composableBuilder(
    column: $table.settingsOverrides,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customCoverPath => $composableBuilder(
    column: $table.customCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$EntryBranchesTableAnnotationComposer get activeBranchId {
    final $$EntryBranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeBranchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entryBranchesRefs<T extends Object>(
    Expression<T> Function($$EntryBranchesTableAnnotationComposer a) f,
  ) {
    final $$EntryBranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contentUnitsRefs<T extends Object>(
    Expression<T> Function($$ContentUnitsTableAnnotationComposer a) f,
  ) {
    final $$ContentUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entryCategoriesRefs<T extends Object>(
    Expression<T> Function($$EntryCategoriesTableAnnotationComposer a) f,
  ) {
    final $$EntryCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryCategories,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trackerLinksRefs<T extends Object>(
    Expression<T> Function($$TrackerLinksTableAnnotationComposer a) f,
  ) {
    final $$TrackerLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerLinks,
      getReferencedColumn: (t) => t.libraryEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryEntriesTable,
          LibraryEntry,
          $$LibraryEntriesTableFilterComposer,
          $$LibraryEntriesTableOrderingComposer,
          $$LibraryEntriesTableAnnotationComposer,
          $$LibraryEntriesTableCreateCompanionBuilder,
          $$LibraryEntriesTableUpdateCompanionBuilder,
          (LibraryEntry, $$LibraryEntriesTableReferences),
          LibraryEntry,
          PrefetchHooks Function({
            bool activeBranchId,
            bool profileId,
            bool entryBranchesRefs,
            bool contentUnitsRefs,
            bool entryCategoriesRefs,
            bool readingSessionsRefs,
            bool trackerLinksRefs,
          })
        > {
  $$LibraryEntriesTableTableManager(
    _$AppDatabase db,
    $LibraryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> activeBranchId = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> excludedScanlators = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<ReaderMode?> readerMode = const Value.absent(),
                Value<bool> readerModeChecked = const Value.absent(),
                Value<ReaderDualPageMode?> readerDualPageMode =
                    const Value.absent(),
                Value<String?> settingsOverrides = const Value.absent(),
                Value<String?> customCoverPath = const Value.absent(),
                Value<String?> status = const Value.absent(),
              }) => LibraryEntriesCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                activeBranchId: activeBranchId,
                profileId: profileId,
                title: title,
                coverUrl: coverUrl,
                mediaType: mediaType,
                sourceId: sourceId,
                excludedScanlators: excludedScanlators,
                sourceKey: sourceKey,
                externalId: externalId,
                favorite: favorite,
                addedAt: addedAt,
                lastUpdatedAt: lastUpdatedAt,
                readerMode: readerMode,
                readerModeChecked: readerModeChecked,
                readerDualPageMode: readerDualPageMode,
                settingsOverrides: settingsOverrides,
                customCoverPath: customCoverPath,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> activeBranchId = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                required String title,
                Value<String?> coverUrl = const Value.absent(),
                required MediaType mediaType,
                required String sourceId,
                Value<String?> excludedScanlators = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                required String externalId,
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<ReaderMode?> readerMode = const Value.absent(),
                Value<bool> readerModeChecked = const Value.absent(),
                Value<ReaderDualPageMode?> readerDualPageMode =
                    const Value.absent(),
                Value<String?> settingsOverrides = const Value.absent(),
                Value<String?> customCoverPath = const Value.absent(),
                Value<String?> status = const Value.absent(),
              }) => LibraryEntriesCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                activeBranchId: activeBranchId,
                profileId: profileId,
                title: title,
                coverUrl: coverUrl,
                mediaType: mediaType,
                sourceId: sourceId,
                excludedScanlators: excludedScanlators,
                sourceKey: sourceKey,
                externalId: externalId,
                favorite: favorite,
                addedAt: addedAt,
                lastUpdatedAt: lastUpdatedAt,
                readerMode: readerMode,
                readerModeChecked: readerModeChecked,
                readerDualPageMode: readerDualPageMode,
                settingsOverrides: settingsOverrides,
                customCoverPath: customCoverPath,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryEntriesTable, LibraryEntry>(table),
                  $$LibraryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                activeBranchId = false,
                profileId = false,
                entryBranchesRefs = false,
                contentUnitsRefs = false,
                entryCategoriesRefs = false,
                readingSessionsRefs = false,
                trackerLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entryBranchesRefs) db.entryBranches,
                    if (contentUnitsRefs) db.contentUnits,
                    if (entryCategoriesRefs) db.entryCategories,
                    if (readingSessionsRefs) db.readingSessions,
                    if (trackerLinksRefs) db.trackerLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (activeBranchId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.activeBranchId,
                            referencedTable: $$LibraryEntriesTableReferences
                                ._activeBranchIdTable(db),
                            referencedColumn: $$LibraryEntriesTableReferences
                                ._activeBranchIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (profileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.profileId,
                            referencedTable: $$LibraryEntriesTableReferences
                                ._profileIdTable(db),
                            referencedColumn: $$LibraryEntriesTableReferences
                                ._profileIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryBranchesRefs)
                        await $_getPrefetchedData<
                          LibraryEntry,
                          $LibraryEntriesTable,
                          EntryBranche
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryEntriesTableReferences
                              ._entryBranchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entryBranchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contentUnitsRefs)
                        await $_getPrefetchedData<
                          LibraryEntry,
                          $LibraryEntriesTable,
                          ContentUnit
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryEntriesTableReferences
                              ._contentUnitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).contentUnitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entryCategoriesRefs)
                        await $_getPrefetchedData<
                          LibraryEntry,
                          $LibraryEntriesTable,
                          EntryCategory
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryEntriesTableReferences
                              ._entryCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entryCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          LibraryEntry,
                          $LibraryEntriesTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryEntriesTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trackerLinksRefs)
                        await $_getPrefetchedData<
                          LibraryEntry,
                          $LibraryEntriesTable,
                          TrackerLinkRow
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryEntriesTableReferences
                              ._trackerLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).trackerLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LibraryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryEntriesTable,
      LibraryEntry,
      $$LibraryEntriesTableFilterComposer,
      $$LibraryEntriesTableOrderingComposer,
      $$LibraryEntriesTableAnnotationComposer,
      $$LibraryEntriesTableCreateCompanionBuilder,
      $$LibraryEntriesTableUpdateCompanionBuilder,
      (LibraryEntry, $$LibraryEntriesTableReferences),
      LibraryEntry,
      PrefetchHooks Function({
        bool activeBranchId,
        bool profileId,
        bool entryBranchesRefs,
        bool contentUnitsRefs,
        bool entryCategoriesRefs,
        bool readingSessionsRefs,
        bool trackerLinksRefs,
      })
    >;
typedef $$ContentUnitsTableCreateCompanionBuilder =
    ContentUnitsCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      required int libraryEntryId,
      required double number,
      Value<String?> displayTitle,
      required String url,
      Value<DateTime> dateUploaded,
      Value<bool> downloaded,
      Value<String?> scanlator,
      Value<bool> bookmarked,
      Value<String?> localPath,
    });
typedef $$ContentUnitsTableUpdateCompanionBuilder =
    ContentUnitsCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int> libraryEntryId,
      Value<double> number,
      Value<String?> displayTitle,
      Value<String> url,
      Value<DateTime> dateUploaded,
      Value<bool> downloaded,
      Value<String?> scanlator,
      Value<bool> bookmarked,
      Value<String?> localPath,
    });

final class $$ContentUnitsTableReferences
    extends BaseReferences<_$AppDatabase, $ContentUnitsTable, ContentUnit> {
  $$ContentUnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryEntriesTable _libraryEntryIdTable(_$AppDatabase db) => db
      .libraryEntries
      .createAlias('content_units__library_entry_id__library_entries__id');

  $$LibraryEntriesTableProcessedTableManager get libraryEntryId {
    final $_column = $_itemColumn<int>('library_entry_id')!;

    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChapterProgressTable, List<ChapterProgressData>>
  _chapterProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chapterProgress,
    aliasName: 'content_units__id__chapter_progress__content_unit_id',
  );

  $$ChapterProgressTableProcessedTableManager get chapterProgressRefs {
    final manager = $$ChapterProgressTableTableManager(
      $_db,
      $_db.chapterProgress,
    ).filter((f) => f.contentUnitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chapterProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: 'content_units__id__reading_sessions__content_unit_id',
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.contentUnitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContentUnitsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentUnitsTable> {
  $$ContentUnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateUploaded => $composableBuilder(
    column: $table.dateUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scanlator => $composableBuilder(
    column: $table.scanlator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryEntriesTableFilterComposer get libraryEntryId {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chapterProgressRefs(
    Expression<bool> Function($$ChapterProgressTableFilterComposer f) f,
  ) {
    final $$ChapterProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterProgress,
      getReferencedColumn: (t) => t.contentUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterProgressTableFilterComposer(
            $db: $db,
            $table: $db.chapterProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.contentUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContentUnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentUnitsTable> {
  $$ContentUnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateUploaded => $composableBuilder(
    column: $table.dateUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scanlator => $composableBuilder(
    column: $table.scanlator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryEntriesTableOrderingComposer get libraryEntryId {
    final $$LibraryEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentUnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentUnitsTable> {
  $$ContentUnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<DateTime> get dateUploaded => $composableBuilder(
    column: $table.dateUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scanlator =>
      $composableBuilder(column: $table.scanlator, builder: (column) => column);

  GeneratedColumn<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  $$LibraryEntriesTableAnnotationComposer get libraryEntryId {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chapterProgressRefs<T extends Object>(
    Expression<T> Function($$ChapterProgressTableAnnotationComposer a) f,
  ) {
    final $$ChapterProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterProgress,
      getReferencedColumn: (t) => t.contentUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.chapterProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.contentUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContentUnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentUnitsTable,
          ContentUnit,
          $$ContentUnitsTableFilterComposer,
          $$ContentUnitsTableOrderingComposer,
          $$ContentUnitsTableAnnotationComposer,
          $$ContentUnitsTableCreateCompanionBuilder,
          $$ContentUnitsTableUpdateCompanionBuilder,
          (ContentUnit, $$ContentUnitsTableReferences),
          ContentUnit,
          PrefetchHooks Function({
            bool libraryEntryId,
            bool chapterProgressRefs,
            bool readingSessionsRefs,
          })
        > {
  $$ContentUnitsTableTableManager(_$AppDatabase db, $ContentUnitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentUnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentUnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentUnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> libraryEntryId = const Value.absent(),
                Value<double> number = const Value.absent(),
                Value<String?> displayTitle = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<DateTime> dateUploaded = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<String?> scanlator = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
              }) => ContentUnitsCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                number: number,
                displayTitle: displayTitle,
                url: url,
                dateUploaded: dateUploaded,
                downloaded: downloaded,
                scanlator: scanlator,
                bookmarked: bookmarked,
                localPath: localPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required int libraryEntryId,
                required double number,
                Value<String?> displayTitle = const Value.absent(),
                required String url,
                Value<DateTime> dateUploaded = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<String?> scanlator = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
              }) => ContentUnitsCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                number: number,
                displayTitle: displayTitle,
                url: url,
                dateUploaded: dateUploaded,
                downloaded: downloaded,
                scanlator: scanlator,
                bookmarked: bookmarked,
                localPath: localPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentUnitsTable, ContentUnit>(table),
                  $$ContentUnitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryEntryId = false,
                chapterProgressRefs = false,
                readingSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chapterProgressRefs) db.chapterProgress,
                    if (readingSessionsRefs) db.readingSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (libraryEntryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryEntryId,
                            referencedTable: $$ContentUnitsTableReferences
                                ._libraryEntryIdTable(db),
                            referencedColumn: $$ContentUnitsTableReferences
                                ._libraryEntryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chapterProgressRefs)
                        await $_getPrefetchedData<
                          ContentUnit,
                          $ContentUnitsTable,
                          ChapterProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$ContentUnitsTableReferences
                              ._chapterProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentUnitsTableReferences(
                                db,
                                table,
                                p0,
                              ).chapterProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contentUnitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          ContentUnit,
                          $ContentUnitsTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$ContentUnitsTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContentUnitsTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contentUnitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContentUnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentUnitsTable,
      ContentUnit,
      $$ContentUnitsTableFilterComposer,
      $$ContentUnitsTableOrderingComposer,
      $$ContentUnitsTableAnnotationComposer,
      $$ContentUnitsTableCreateCompanionBuilder,
      $$ContentUnitsTableUpdateCompanionBuilder,
      (ContentUnit, $$ContentUnitsTableReferences),
      ContentUnit,
      PrefetchHooks Function({
        bool libraryEntryId,
        bool chapterProgressRefs,
        bool readingSessionsRefs,
      })
    >;
typedef $$ChapterProgressTableCreateCompanionBuilder =
    ChapterProgressCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      required int contentUnitId,
      required int branchId,
      Value<bool> consumed,
      Value<DateTime?> consumedAt,
      Value<double?> progressPosition,
    });
typedef $$ChapterProgressTableUpdateCompanionBuilder =
    ChapterProgressCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int> contentUnitId,
      Value<int> branchId,
      Value<bool> consumed,
      Value<DateTime?> consumedAt,
      Value<double?> progressPosition,
    });

final class $$ChapterProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ChapterProgressTable,
          ChapterProgressData
        > {
  $$ChapterProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContentUnitsTable _contentUnitIdTable(_$AppDatabase db) => db
      .contentUnits
      .createAlias('chapter_progress__content_unit_id__content_units__id');

  $$ContentUnitsTableProcessedTableManager get contentUnitId {
    final $_column = $_itemColumn<int>('content_unit_id')!;

    final manager = $$ContentUnitsTableTableManager(
      $_db,
      $_db.contentUnits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntryBranchesTable _branchIdTable(_$AppDatabase db) => db
      .entryBranches
      .createAlias('chapter_progress__branch_id__entry_branches__id');

  $$EntryBranchesTableProcessedTableManager get branchId {
    final $_column = $_itemColumn<int>('branch_id')!;

    final manager = $$EntryBranchesTableTableManager(
      $_db,
      $_db.entryBranches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChapterProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ChapterProgressTable> {
  $$ChapterProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consumed => $composableBuilder(
    column: $table.consumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPosition => $composableBuilder(
    column: $table.progressPosition,
    builder: (column) => ColumnFilters(column),
  );

  $$ContentUnitsTableFilterComposer get contentUnitId {
    final $$ContentUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableFilterComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableFilterComposer get branchId {
    final $$EntryBranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableFilterComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ChapterProgressTable> {
  $$ChapterProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consumed => $composableBuilder(
    column: $table.consumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPosition => $composableBuilder(
    column: $table.progressPosition,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContentUnitsTableOrderingComposer get contentUnitId {
    final $$ContentUnitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableOrderingComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableOrderingComposer get branchId {
    final $$EntryBranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableOrderingComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChapterProgressTable> {
  $$ChapterProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get consumed =>
      $composableBuilder(column: $table.consumed, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressPosition => $composableBuilder(
    column: $table.progressPosition,
    builder: (column) => column,
  );

  $$ContentUnitsTableAnnotationComposer get contentUnitId {
    final $$ContentUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableAnnotationComposer get branchId {
    final $$EntryBranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChapterProgressTable,
          ChapterProgressData,
          $$ChapterProgressTableFilterComposer,
          $$ChapterProgressTableOrderingComposer,
          $$ChapterProgressTableAnnotationComposer,
          $$ChapterProgressTableCreateCompanionBuilder,
          $$ChapterProgressTableUpdateCompanionBuilder,
          (ChapterProgressData, $$ChapterProgressTableReferences),
          ChapterProgressData,
          PrefetchHooks Function({bool contentUnitId, bool branchId})
        > {
  $$ChapterProgressTableTableManager(
    _$AppDatabase db,
    $ChapterProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> contentUnitId = const Value.absent(),
                Value<int> branchId = const Value.absent(),
                Value<bool> consumed = const Value.absent(),
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<double?> progressPosition = const Value.absent(),
              }) => ChapterProgressCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                contentUnitId: contentUnitId,
                branchId: branchId,
                consumed: consumed,
                consumedAt: consumedAt,
                progressPosition: progressPosition,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required int contentUnitId,
                required int branchId,
                Value<bool> consumed = const Value.absent(),
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<double?> progressPosition = const Value.absent(),
              }) => ChapterProgressCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                contentUnitId: contentUnitId,
                branchId: branchId,
                consumed: consumed,
                consumedAt: consumedAt,
                progressPosition: progressPosition,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChapterProgressTable, ChapterProgressData>(
                    table,
                  ),
                  $$ChapterProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contentUnitId = false, branchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contentUnitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contentUnitId,
                        referencedTable: $$ChapterProgressTableReferences
                            ._contentUnitIdTable(db),
                        referencedColumn: $$ChapterProgressTableReferences
                            ._contentUnitIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (branchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.branchId,
                        referencedTable: $$ChapterProgressTableReferences
                            ._branchIdTable(db),
                        referencedColumn: $$ChapterProgressTableReferences
                            ._branchIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChapterProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChapterProgressTable,
      ChapterProgressData,
      $$ChapterProgressTableFilterComposer,
      $$ChapterProgressTableOrderingComposer,
      $$ChapterProgressTableAnnotationComposer,
      $$ChapterProgressTableCreateCompanionBuilder,
      $$ChapterProgressTableUpdateCompanionBuilder,
      (ChapterProgressData, $$ChapterProgressTableReferences),
      ChapterProgressData,
      PrefetchHooks Function({bool contentUnitId, bool branchId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<int?> clientId,
  Value<int> updatedAt,
  Value<int> profileId,
  required String name,
  Value<int> sortOrder,
  Value<bool> excludeFromUpdate,
  Value<MediaType> mediaType,
  Value<bool> useSmartRule,
  Value<CategorySortField> sortField,
  Value<bool> sortAscending,
  Value<CategoryStatusFilter> statusFilter,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<int?> clientId,
  Value<int> updatedAt,
  Value<int> profileId,
  Value<String> name,
  Value<int> sortOrder,
  Value<bool> excludeFromUpdate,
  Value<MediaType> mediaType,
  Value<bool> useSmartRule,
  Value<CategorySortField> sortField,
  Value<bool> sortAscending,
  Value<CategoryStatusFilter> statusFilter,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('categories__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntryCategoriesTable, List<EntryCategory>>
  _entryCategoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryCategories,
    aliasName: 'categories__id__entry_categories__category_id',
  );

  $$EntryCategoriesTableProcessedTableManager get entryCategoriesRefs {
    final manager = $$EntryCategoriesTableTableManager(
      $_db,
      $_db.entryCategories,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _entryCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromUpdate => $composableBuilder(
    column: $table.excludeFromUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, int> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get useSmartRule => $composableBuilder(
    column: $table.useSmartRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategorySortField, CategorySortField, int>
  get sortField => $composableBuilder(
    column: $table.sortField,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    CategoryStatusFilter,
    CategoryStatusFilter,
    int
  >
  get statusFilter => $composableBuilder(
    column: $table.statusFilter,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entryCategoriesRefs(
    Expression<bool> Function($$EntryCategoriesTableFilterComposer f) f,
  ) {
    final $$EntryCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryCategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.entryCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromUpdate => $composableBuilder(
    column: $table.excludeFromUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useSmartRule => $composableBuilder(
    column: $table.useSmartRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortField => $composableBuilder(
    column: $table.sortField,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusFilter => $composableBuilder(
    column: $table.statusFilter,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get excludeFromUpdate => $composableBuilder(
    column: $table.excludeFromUpdate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MediaType, int> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<bool> get useSmartRule => $composableBuilder(
    column: $table.useSmartRule,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CategorySortField, int> get sortField =>
      $composableBuilder(column: $table.sortField, builder: (column) => column);

  GeneratedColumn<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CategoryStatusFilter, int>
  get statusFilter => $composableBuilder(
    column: $table.statusFilter,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entryCategoriesRefs<T extends Object>(
    Expression<T> Function($$EntryCategoriesTableAnnotationComposer a) f,
  ) {
    final $$EntryCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryCategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool profileId, bool entryCategoriesRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> excludeFromUpdate = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<bool> useSmartRule = const Value.absent(),
                Value<CategorySortField> sortField = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<CategoryStatusFilter> statusFilter = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                profileId: profileId,
                name: name,
                sortOrder: sortOrder,
                excludeFromUpdate: excludeFromUpdate,
                mediaType: mediaType,
                useSmartRule: useSmartRule,
                sortField: sortField,
                sortAscending: sortAscending,
                statusFilter: statusFilter,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> excludeFromUpdate = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<bool> useSmartRule = const Value.absent(),
                Value<CategorySortField> sortField = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<CategoryStatusFilter> statusFilter = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                profileId: profileId,
                name: name,
                sortOrder: sortOrder,
                excludeFromUpdate: excludeFromUpdate,
                mediaType: mediaType,
                useSmartRule: useSmartRule,
                sortField: sortField,
                sortAscending: sortAscending,
                statusFilter: statusFilter,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({profileId = false, entryCategoriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entryCategoriesRefs) db.entryCategories,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (profileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.profileId,
                            referencedTable: $$CategoriesTableReferences
                                ._profileIdTable(db),
                            referencedColumn: $$CategoriesTableReferences
                                ._profileIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryCategoriesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          EntryCategory
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._entryCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entryCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool profileId, bool entryCategoriesRefs})
    >;
typedef $$EntryCategoriesTableCreateCompanionBuilder =
    EntryCategoriesCompanion Function({
      required int libraryEntryId,
      required int categoryId,
      Value<int> rowid,
    });
typedef $$EntryCategoriesTableUpdateCompanionBuilder =
    EntryCategoriesCompanion Function({
      Value<int> libraryEntryId,
      Value<int> categoryId,
      Value<int> rowid,
    });

final class $$EntryCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $EntryCategoriesTable, EntryCategory> {
  $$EntryCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryEntriesTable _libraryEntryIdTable(_$AppDatabase db) => db
      .libraryEntries
      .createAlias('entry_categories__library_entry_id__library_entries__id');

  $$LibraryEntriesTableProcessedTableManager get libraryEntryId {
    final $_column = $_itemColumn<int>('library_entry_id')!;

    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('entry_categories__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntryCategoriesTable> {
  $$EntryCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LibraryEntriesTableFilterComposer get libraryEntryId {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryCategoriesTable> {
  $$EntryCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LibraryEntriesTableOrderingComposer get libraryEntryId {
    final $$LibraryEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryCategoriesTable> {
  $$EntryCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LibraryEntriesTableAnnotationComposer get libraryEntryId {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryCategoriesTable,
          EntryCategory,
          $$EntryCategoriesTableFilterComposer,
          $$EntryCategoriesTableOrderingComposer,
          $$EntryCategoriesTableAnnotationComposer,
          $$EntryCategoriesTableCreateCompanionBuilder,
          $$EntryCategoriesTableUpdateCompanionBuilder,
          (EntryCategory, $$EntryCategoriesTableReferences),
          EntryCategory,
          PrefetchHooks Function({bool libraryEntryId, bool categoryId})
        > {
  $$EntryCategoriesTableTableManager(
    _$AppDatabase db,
    $EntryCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> libraryEntryId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryCategoriesCompanion(
                libraryEntryId: libraryEntryId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int libraryEntryId,
                required int categoryId,
                Value<int> rowid = const Value.absent(),
              }) => EntryCategoriesCompanion.insert(
                libraryEntryId: libraryEntryId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryCategoriesTable, EntryCategory>(table),
                  $$EntryCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({libraryEntryId = false, categoryId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (libraryEntryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryEntryId,
                            referencedTable: $$EntryCategoriesTableReferences
                                ._libraryEntryIdTable(db),
                            referencedColumn: $$EntryCategoriesTableReferences
                                ._libraryEntryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$EntryCategoriesTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$EntryCategoriesTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$EntryCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryCategoriesTable,
      EntryCategory,
      $$EntryCategoriesTableFilterComposer,
      $$EntryCategoriesTableOrderingComposer,
      $$EntryCategoriesTableAnnotationComposer,
      $$EntryCategoriesTableCreateCompanionBuilder,
      $$EntryCategoriesTableUpdateCompanionBuilder,
      (EntryCategory, $$EntryCategoriesTableReferences),
      EntryCategory,
      PrefetchHooks Function({bool libraryEntryId, bool categoryId})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> timestamp,
  required LogLevel level,
  required String tag,
  required String message,
  Value<String?> stackTrace,
});
typedef $$LogEntriesTableUpdateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> timestamp,
  Value<LogLevel> level,
  Value<String> tag,
  Value<String> message,
  Value<String?> stackTrace,
});

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LogLevel, LogLevel, int> get level =>
      $composableBuilder(
        column: $table.level,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LogLevel, int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => column,
  );
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
          LogEntry,
          PrefetchHooks Function()
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<LogLevel> level = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> stackTrace = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                timestamp: timestamp,
                level: level,
                tag: tag,
                message: message,
                stackTrace: stackTrace,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required LogLevel level,
                required String tag,
                required String message,
                Value<String?> stackTrace = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                timestamp: timestamp,
                level: level,
                tag: tag,
                message: message,
                stackTrace: stackTrace,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogEntriesTable, LogEntry>(table),
                  BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
      LogEntry,
      PrefetchHooks Function()
    >;
typedef $$InstalledSourcesTableCreateCompanionBuilder =
    InstalledSourcesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      required String name,
      Value<String> lang,
      required MediaType mediaType,
      required String jsSource,
      Value<String> iconUrl,
      Value<String> baseUrl,
      Value<bool> enabled,
      Value<String> engineKind,
      Value<DateTime> addedAt,
      Value<String?> repoUrl,
      Value<String?> repoSourceId,
      Value<int> version,
    });
typedef $$InstalledSourcesTableUpdateCompanionBuilder =
    InstalledSourcesCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<String> name,
      Value<String> lang,
      Value<MediaType> mediaType,
      Value<String> jsSource,
      Value<String> iconUrl,
      Value<String> baseUrl,
      Value<bool> enabled,
      Value<String> engineKind,
      Value<DateTime> addedAt,
      Value<String?> repoUrl,
      Value<String?> repoSourceId,
      Value<int> version,
    });

class $$InstalledSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledSourcesTable> {
  $$InstalledSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, int> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get jsSource => $composableBuilder(
    column: $table.jsSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineKind => $composableBuilder(
    column: $table.engineKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoSourceId => $composableBuilder(
    column: $table.repoSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstalledSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledSourcesTable> {
  $$InstalledSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsSource => $composableBuilder(
    column: $table.jsSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineKind => $composableBuilder(
    column: $table.engineKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoSourceId => $composableBuilder(
    column: $table.repoSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstalledSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledSourcesTable> {
  $$InstalledSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, int> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get jsSource =>
      $composableBuilder(column: $table.jsSource, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get engineKind => $composableBuilder(
    column: $table.engineKind,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<String> get repoSourceId => $composableBuilder(
    column: $table.repoSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$InstalledSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledSourcesTable,
          InstalledSource,
          $$InstalledSourcesTableFilterComposer,
          $$InstalledSourcesTableOrderingComposer,
          $$InstalledSourcesTableAnnotationComposer,
          $$InstalledSourcesTableCreateCompanionBuilder,
          $$InstalledSourcesTableUpdateCompanionBuilder,
          (
            InstalledSource,
            BaseReferences<
              _$AppDatabase,
              $InstalledSourcesTable,
              InstalledSource
            >,
          ),
          InstalledSource,
          PrefetchHooks Function()
        > {
  $$InstalledSourcesTableTableManager(
    _$AppDatabase db,
    $InstalledSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalledSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstalledSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> jsSource = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> engineKind = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String?> repoUrl = const Value.absent(),
                Value<String?> repoSourceId = const Value.absent(),
                Value<int> version = const Value.absent(),
              }) => InstalledSourcesCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                name: name,
                lang: lang,
                mediaType: mediaType,
                jsSource: jsSource,
                iconUrl: iconUrl,
                baseUrl: baseUrl,
                enabled: enabled,
                engineKind: engineKind,
                addedAt: addedAt,
                repoUrl: repoUrl,
                repoSourceId: repoSourceId,
                version: version,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required String name,
                Value<String> lang = const Value.absent(),
                required MediaType mediaType,
                required String jsSource,
                Value<String> iconUrl = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> engineKind = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String?> repoUrl = const Value.absent(),
                Value<String?> repoSourceId = const Value.absent(),
                Value<int> version = const Value.absent(),
              }) => InstalledSourcesCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                name: name,
                lang: lang,
                mediaType: mediaType,
                jsSource: jsSource,
                iconUrl: iconUrl,
                baseUrl: baseUrl,
                enabled: enabled,
                engineKind: engineKind,
                addedAt: addedAt,
                repoUrl: repoUrl,
                repoSourceId: repoSourceId,
                version: version,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstalledSourcesTable, InstalledSource>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InstalledSourcesTable,
                    InstalledSource
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstalledSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledSourcesTable,
      InstalledSource,
      $$InstalledSourcesTableFilterComposer,
      $$InstalledSourcesTableOrderingComposer,
      $$InstalledSourcesTableAnnotationComposer,
      $$InstalledSourcesTableCreateCompanionBuilder,
      $$InstalledSourcesTableUpdateCompanionBuilder,
      (
        InstalledSource,
        BaseReferences<_$AppDatabase, $InstalledSourcesTable, InstalledSource>,
      ),
      InstalledSource,
      PrefetchHooks Function()
    >;
typedef $$ReposTableCreateCompanionBuilder = ReposCompanion Function({
  Value<int> id,
  Value<int?> clientId,
  Value<int> updatedAt,
  required String url,
  required String name,
  Value<DateTime> addedAt,
});
typedef $$ReposTableUpdateCompanionBuilder = ReposCompanion Function({
  Value<int> id,
  Value<int?> clientId,
  Value<int> updatedAt,
  Value<String> url,
  Value<String> name,
  Value<DateTime> addedAt,
});

class $$ReposTableFilterComposer extends Composer<_$AppDatabase, $ReposTable> {
  $$ReposTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReposTableOrderingComposer
    extends Composer<_$AppDatabase, $ReposTable> {
  $$ReposTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReposTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReposTable> {
  $$ReposTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$ReposTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReposTable,
          Repo,
          $$ReposTableFilterComposer,
          $$ReposTableOrderingComposer,
          $$ReposTableAnnotationComposer,
          $$ReposTableCreateCompanionBuilder,
          $$ReposTableUpdateCompanionBuilder,
          (Repo, BaseReferences<_$AppDatabase, $ReposTable, Repo>),
          Repo,
          PrefetchHooks Function()
        > {
  $$ReposTableTableManager(_$AppDatabase db, $ReposTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReposTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReposTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReposTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => ReposCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                url: url,
                name: name,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required String url,
                required String name,
                Value<DateTime> addedAt = const Value.absent(),
              }) => ReposCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                url: url,
                name: name,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReposTable, Repo>(table),
                  BaseReferences<_$AppDatabase, $ReposTable, Repo>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReposTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReposTable,
      Repo,
      $$ReposTableFilterComposer,
      $$ReposTableOrderingComposer,
      $$ReposTableAnnotationComposer,
      $$ReposTableCreateCompanionBuilder,
      $$ReposTableUpdateCompanionBuilder,
      (Repo, BaseReferences<_$AppDatabase, $ReposTable, Repo>),
      Repo,
      PrefetchHooks Function()
    >;
typedef $$ActiveProfileTableTableCreateCompanionBuilder =
    ActiveProfileTableCompanion Function({
      Value<int> id,
      required int profileId,
    });
typedef $$ActiveProfileTableTableUpdateCompanionBuilder =
    ActiveProfileTableCompanion Function({Value<int> id, Value<int> profileId});

final class $$ActiveProfileTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ActiveProfileTableTable,
          ActiveProfileTableData
        > {
  $$ActiveProfileTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('active_profile__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActiveProfileTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveProfileTableTable> {
  $$ActiveProfileTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActiveProfileTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveProfileTableTable> {
  $$ActiveProfileTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActiveProfileTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveProfileTableTable> {
  $$ActiveProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActiveProfileTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActiveProfileTableTable,
          ActiveProfileTableData,
          $$ActiveProfileTableTableFilterComposer,
          $$ActiveProfileTableTableOrderingComposer,
          $$ActiveProfileTableTableAnnotationComposer,
          $$ActiveProfileTableTableCreateCompanionBuilder,
          $$ActiveProfileTableTableUpdateCompanionBuilder,
          (ActiveProfileTableData, $$ActiveProfileTableTableReferences),
          ActiveProfileTableData,
          PrefetchHooks Function({bool profileId})
        > {
  $$ActiveProfileTableTableTableManager(
    _$AppDatabase db,
    $ActiveProfileTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveProfileTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
          }) => ActiveProfileTableCompanion(id: id, profileId: profileId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
              }) => ActiveProfileTableCompanion.insert(
                id: id,
                profileId: profileId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActiveProfileTableTable, ActiveProfileTableData>(
                    table,
                  ),
                  $$ActiveProfileTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$ActiveProfileTableTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$ActiveProfileTableTableReferences
                            ._profileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ActiveProfileTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActiveProfileTableTable,
      ActiveProfileTableData,
      $$ActiveProfileTableTableFilterComposer,
      $$ActiveProfileTableTableOrderingComposer,
      $$ActiveProfileTableTableAnnotationComposer,
      $$ActiveProfileTableTableCreateCompanionBuilder,
      $$ActiveProfileTableTableUpdateCompanionBuilder,
      (ActiveProfileTableData, $$ActiveProfileTableTableReferences),
      ActiveProfileTableData,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$SettingValuesTableCreateCompanionBuilder =
    SettingValuesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      required String settingId,
      required String value,
      Value<int> updatedAt,
      Value<bool> synced,
    });
typedef $$SettingValuesTableUpdateCompanionBuilder =
    SettingValuesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> settingId,
      Value<String> value,
      Value<int> updatedAt,
      Value<bool> synced,
    });

class $$SettingValuesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingValuesTable> {
  $$SettingValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingId => $composableBuilder(
    column: $table.settingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingValuesTable> {
  $$SettingValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingId => $composableBuilder(
    column: $table.settingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingValuesTable> {
  $$SettingValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get settingId =>
      $composableBuilder(column: $table.settingId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SettingValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingValuesTable,
          SettingValue,
          $$SettingValuesTableFilterComposer,
          $$SettingValuesTableOrderingComposer,
          $$SettingValuesTableAnnotationComposer,
          $$SettingValuesTableCreateCompanionBuilder,
          $$SettingValuesTableUpdateCompanionBuilder,
          (
            SettingValue,
            BaseReferences<_$AppDatabase, $SettingValuesTable, SettingValue>,
          ),
          SettingValue,
          PrefetchHooks Function()
        > {
  $$SettingValuesTableTableManager(_$AppDatabase db, $SettingValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> settingId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => SettingValuesCompanion(
                id: id,
                profileId: profileId,
                settingId: settingId,
                value: value,
                updatedAt: updatedAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                required String settingId,
                required String value,
                Value<int> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => SettingValuesCompanion.insert(
                id: id,
                profileId: profileId,
                settingId: settingId,
                value: value,
                updatedAt: updatedAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingValuesTable, SettingValue>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingValuesTable,
                    SettingValue
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingValuesTable,
      SettingValue,
      $$SettingValuesTableFilterComposer,
      $$SettingValuesTableOrderingComposer,
      $$SettingValuesTableAnnotationComposer,
      $$SettingValuesTableCreateCompanionBuilder,
      $$SettingValuesTableUpdateCompanionBuilder,
      (
        SettingValue,
        BaseReferences<_$AppDatabase, $SettingValuesTable, SettingValue>,
      ),
      SettingValue,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      required int libraryEntryId,
      required int contentUnitId,
      Value<int?> branchId,
      Value<DateTime> readAt,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      Value<int?> clientId,
      Value<int> updatedAt,
      Value<int> libraryEntryId,
      Value<int> contentUnitId,
      Value<int?> branchId,
      Value<DateTime> readAt,
    });

final class $$ReadingSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSession> {
  $$ReadingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryEntriesTable _libraryEntryIdTable(_$AppDatabase db) => db
      .libraryEntries
      .createAlias('reading_sessions__library_entry_id__library_entries__id');

  $$LibraryEntriesTableProcessedTableManager get libraryEntryId {
    final $_column = $_itemColumn<int>('library_entry_id')!;

    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContentUnitsTable _contentUnitIdTable(_$AppDatabase db) => db
      .contentUnits
      .createAlias('reading_sessions__content_unit_id__content_units__id');

  $$ContentUnitsTableProcessedTableManager get contentUnitId {
    final $_column = $_itemColumn<int>('content_unit_id')!;

    final manager = $$ContentUnitsTableTableManager(
      $_db,
      $_db.contentUnits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntryBranchesTable _branchIdTable(_$AppDatabase db) => db
      .entryBranches
      .createAlias('reading_sessions__branch_id__entry_branches__id');

  $$EntryBranchesTableProcessedTableManager? get branchId {
    final $_column = $_itemColumn<int>('branch_id');
    if ($_column == null) return null;
    final manager = $$EntryBranchesTableTableManager(
      $_db,
      $_db.entryBranches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryEntriesTableFilterComposer get libraryEntryId {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContentUnitsTableFilterComposer get contentUnitId {
    final $$ContentUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableFilterComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableFilterComposer get branchId {
    final $$EntryBranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableFilterComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryEntriesTableOrderingComposer get libraryEntryId {
    final $$LibraryEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContentUnitsTableOrderingComposer get contentUnitId {
    final $$ContentUnitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableOrderingComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableOrderingComposer get branchId {
    final $$EntryBranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableOrderingComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  $$LibraryEntriesTableAnnotationComposer get libraryEntryId {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContentUnitsTableAnnotationComposer get contentUnitId {
    final $$ContentUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentUnitId,
      referencedTable: $db.contentUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.contentUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntryBranchesTableAnnotationComposer get branchId {
    final $$EntryBranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.entryBranches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryBranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.entryBranches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSessionsTable,
          ReadingSession,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (ReadingSession, $$ReadingSessionsTableReferences),
          ReadingSession,
          PrefetchHooks Function({
            bool libraryEntryId,
            bool contentUnitId,
            bool branchId,
          })
        > {
  $$ReadingSessionsTableTableManager(
    _$AppDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> libraryEntryId = const Value.absent(),
                Value<int> contentUnitId = const Value.absent(),
                Value<int?> branchId = const Value.absent(),
                Value<DateTime> readAt = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                contentUnitId: contentUnitId,
                branchId: branchId,
                readAt: readAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> clientId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                required int libraryEntryId,
                required int contentUnitId,
                Value<int?> branchId = const Value.absent(),
                Value<DateTime> readAt = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                clientId: clientId,
                updatedAt: updatedAt,
                libraryEntryId: libraryEntryId,
                contentUnitId: contentUnitId,
                branchId: branchId,
                readAt: readAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingSessionsTable, ReadingSession>(table),
                  $$ReadingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryEntryId = false,
                contentUnitId = false,
                branchId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (libraryEntryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryEntryId,
                            referencedTable: $$ReadingSessionsTableReferences
                                ._libraryEntryIdTable(db),
                            referencedColumn: $$ReadingSessionsTableReferences
                                ._libraryEntryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contentUnitId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contentUnitId,
                            referencedTable: $$ReadingSessionsTableReferences
                                ._contentUnitIdTable(db),
                            referencedColumn: $$ReadingSessionsTableReferences
                                ._contentUnitIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (branchId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.branchId,
                            referencedTable: $$ReadingSessionsTableReferences
                                ._branchIdTable(db),
                            referencedColumn: $$ReadingSessionsTableReferences
                                ._branchIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSessionsTable,
      ReadingSession,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (ReadingSession, $$ReadingSessionsTableReferences),
      ReadingSession,
      PrefetchHooks Function({
        bool libraryEntryId,
        bool contentUnitId,
        bool branchId,
      })
    >;
typedef $$SyncDeletionsTableCreateCompanionBuilder =
    SyncDeletionsCompanion Function({
      Value<int> id,
      required int profileId,
      required String entity,
      required int clientId,
    });
typedef $$SyncDeletionsTableUpdateCompanionBuilder =
    SyncDeletionsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> entity,
      Value<int> clientId,
    });

class $$SyncDeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncDeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncDeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDeletionsTable> {
  $$SyncDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<int> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);
}

class $$SyncDeletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncDeletionsTable,
          SyncDeletion,
          $$SyncDeletionsTableFilterComposer,
          $$SyncDeletionsTableOrderingComposer,
          $$SyncDeletionsTableAnnotationComposer,
          $$SyncDeletionsTableCreateCompanionBuilder,
          $$SyncDeletionsTableUpdateCompanionBuilder,
          (
            SyncDeletion,
            BaseReferences<_$AppDatabase, $SyncDeletionsTable, SyncDeletion>,
          ),
          SyncDeletion,
          PrefetchHooks Function()
        > {
  $$SyncDeletionsTableTableManager(_$AppDatabase db, $SyncDeletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<int> clientId = const Value.absent(),
              }) => SyncDeletionsCompanion(
                id: id,
                profileId: profileId,
                entity: entity,
                clientId: clientId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String entity,
                required int clientId,
              }) => SyncDeletionsCompanion.insert(
                id: id,
                profileId: profileId,
                entity: entity,
                clientId: clientId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncDeletionsTable, SyncDeletion>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncDeletionsTable,
                    SyncDeletion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncDeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncDeletionsTable,
      SyncDeletion,
      $$SyncDeletionsTableFilterComposer,
      $$SyncDeletionsTableOrderingComposer,
      $$SyncDeletionsTableAnnotationComposer,
      $$SyncDeletionsTableCreateCompanionBuilder,
      $$SyncDeletionsTableUpdateCompanionBuilder,
      (
        SyncDeletion,
        BaseReferences<_$AppDatabase, $SyncDeletionsTable, SyncDeletion>,
      ),
      SyncDeletion,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<int> applying,
  Value<String?> installId,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<int> applying,
  Value<String?> installId,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get applying => $composableBuilder(
    column: $table.applying,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get applying => $composableBuilder(
    column: $table.applying,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get applying =>
      $composableBuilder(column: $table.applying, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> applying = const Value.absent(),
                Value<String?> installId = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                applying: applying,
                installId: installId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> applying = const Value.absent(),
                Value<String?> installId = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                applying: applying,
                installId: installId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$SyncProfileStateTableCreateCompanionBuilder =
    SyncProfileStateCompanion Function({
      Value<int> profileId,
      Value<int?> serverProfileId,
      Value<String?> serverProfileName,
      Value<int> since,
      Value<int> localSince,
      Value<int> lastSyncAt,
      Value<int> autoSyncIntervalMinutes,
      Value<bool> syncOnLaunch,
      Value<bool> backgroundSync,
    });
typedef $$SyncProfileStateTableUpdateCompanionBuilder =
    SyncProfileStateCompanion Function({
      Value<int> profileId,
      Value<int?> serverProfileId,
      Value<String?> serverProfileName,
      Value<int> since,
      Value<int> localSince,
      Value<int> lastSyncAt,
      Value<int> autoSyncIntervalMinutes,
      Value<bool> syncOnLaunch,
      Value<bool> backgroundSync,
    });

final class $$SyncProfileStateTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyncProfileStateTable,
          SyncProfileStateData
        > {
  $$SyncProfileStateTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('sync_profile_state__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncProfileStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncProfileStateTable> {
  $$SyncProfileStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverProfileId => $composableBuilder(
    column: $table.serverProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverProfileName => $composableBuilder(
    column: $table.serverProfileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get since => $composableBuilder(
    column: $table.since,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSince => $composableBuilder(
    column: $table.localSince,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoSyncIntervalMinutes => $composableBuilder(
    column: $table.autoSyncIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncOnLaunch => $composableBuilder(
    column: $table.syncOnLaunch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backgroundSync => $composableBuilder(
    column: $table.backgroundSync,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncProfileStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncProfileStateTable> {
  $$SyncProfileStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverProfileId => $composableBuilder(
    column: $table.serverProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverProfileName => $composableBuilder(
    column: $table.serverProfileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get since => $composableBuilder(
    column: $table.since,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSince => $composableBuilder(
    column: $table.localSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoSyncIntervalMinutes => $composableBuilder(
    column: $table.autoSyncIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncOnLaunch => $composableBuilder(
    column: $table.syncOnLaunch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backgroundSync => $composableBuilder(
    column: $table.backgroundSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncProfileStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncProfileStateTable> {
  $$SyncProfileStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverProfileId => $composableBuilder(
    column: $table.serverProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverProfileName => $composableBuilder(
    column: $table.serverProfileName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get since =>
      $composableBuilder(column: $table.since, builder: (column) => column);

  GeneratedColumn<int> get localSince => $composableBuilder(
    column: $table.localSince,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoSyncIntervalMinutes => $composableBuilder(
    column: $table.autoSyncIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncOnLaunch => $composableBuilder(
    column: $table.syncOnLaunch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backgroundSync => $composableBuilder(
    column: $table.backgroundSync,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncProfileStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncProfileStateTable,
          SyncProfileStateData,
          $$SyncProfileStateTableFilterComposer,
          $$SyncProfileStateTableOrderingComposer,
          $$SyncProfileStateTableAnnotationComposer,
          $$SyncProfileStateTableCreateCompanionBuilder,
          $$SyncProfileStateTableUpdateCompanionBuilder,
          (SyncProfileStateData, $$SyncProfileStateTableReferences),
          SyncProfileStateData,
          PrefetchHooks Function({bool profileId})
        > {
  $$SyncProfileStateTableTableManager(
    _$AppDatabase db,
    $SyncProfileStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncProfileStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncProfileStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncProfileStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<int?> serverProfileId = const Value.absent(),
                Value<String?> serverProfileName = const Value.absent(),
                Value<int> since = const Value.absent(),
                Value<int> localSince = const Value.absent(),
                Value<int> lastSyncAt = const Value.absent(),
                Value<int> autoSyncIntervalMinutes = const Value.absent(),
                Value<bool> syncOnLaunch = const Value.absent(),
                Value<bool> backgroundSync = const Value.absent(),
              }) => SyncProfileStateCompanion(
                profileId: profileId,
                serverProfileId: serverProfileId,
                serverProfileName: serverProfileName,
                since: since,
                localSince: localSince,
                lastSyncAt: lastSyncAt,
                autoSyncIntervalMinutes: autoSyncIntervalMinutes,
                syncOnLaunch: syncOnLaunch,
                backgroundSync: backgroundSync,
              ),
          createCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<int?> serverProfileId = const Value.absent(),
                Value<String?> serverProfileName = const Value.absent(),
                Value<int> since = const Value.absent(),
                Value<int> localSince = const Value.absent(),
                Value<int> lastSyncAt = const Value.absent(),
                Value<int> autoSyncIntervalMinutes = const Value.absent(),
                Value<bool> syncOnLaunch = const Value.absent(),
                Value<bool> backgroundSync = const Value.absent(),
              }) => SyncProfileStateCompanion.insert(
                profileId: profileId,
                serverProfileId: serverProfileId,
                serverProfileName: serverProfileName,
                since: since,
                localSince: localSince,
                lastSyncAt: lastSyncAt,
                autoSyncIntervalMinutes: autoSyncIntervalMinutes,
                syncOnLaunch: syncOnLaunch,
                backgroundSync: backgroundSync,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncProfileStateTable, SyncProfileStateData>(
                    table,
                  ),
                  $$SyncProfileStateTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$SyncProfileStateTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$SyncProfileStateTableReferences
                            ._profileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncProfileStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncProfileStateTable,
      SyncProfileStateData,
      $$SyncProfileStateTableFilterComposer,
      $$SyncProfileStateTableOrderingComposer,
      $$SyncProfileStateTableAnnotationComposer,
      $$SyncProfileStateTableCreateCompanionBuilder,
      $$SyncProfileStateTableUpdateCompanionBuilder,
      (SyncProfileStateData, $$SyncProfileStateTableReferences),
      SyncProfileStateData,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$SyncFilesTableCreateCompanionBuilder = SyncFilesCompanion Function({
  required int profileId,
  required String kind,
  required String name,
  required String sha256,
  required int sizeBytes,
  required int modifiedAt,
  Value<int> rowid,
});
typedef $$SyncFilesTableUpdateCompanionBuilder = SyncFilesCompanion Function({
  Value<int> profileId,
  Value<String> kind,
  Value<String> name,
  Value<String> sha256,
  Value<int> sizeBytes,
  Value<int> modifiedAt,
  Value<int> rowid,
});

class $$SyncFilesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncFilesTable> {
  $$SyncFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncFilesTable> {
  $$SyncFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncFilesTable> {
  $$SyncFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );
}

class $$SyncFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncFilesTable,
          SyncFile,
          $$SyncFilesTableFilterComposer,
          $$SyncFilesTableOrderingComposer,
          $$SyncFilesTableAnnotationComposer,
          $$SyncFilesTableCreateCompanionBuilder,
          $$SyncFilesTableUpdateCompanionBuilder,
          (SyncFile, BaseReferences<_$AppDatabase, $SyncFilesTable, SyncFile>),
          SyncFile,
          PrefetchHooks Function()
        > {
  $$SyncFilesTableTableManager(_$AppDatabase db, $SyncFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncFilesCompanion(
                profileId: profileId,
                kind: kind,
                name: name,
                sha256: sha256,
                sizeBytes: sizeBytes,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String kind,
                required String name,
                required String sha256,
                required int sizeBytes,
                required int modifiedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncFilesCompanion.insert(
                profileId: profileId,
                kind: kind,
                name: name,
                sha256: sha256,
                sizeBytes: sizeBytes,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncFilesTable, SyncFile>(table),
                  BaseReferences<_$AppDatabase, $SyncFilesTable, SyncFile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncFilesTable,
      SyncFile,
      $$SyncFilesTableFilterComposer,
      $$SyncFilesTableOrderingComposer,
      $$SyncFilesTableAnnotationComposer,
      $$SyncFilesTableCreateCompanionBuilder,
      $$SyncFilesTableUpdateCompanionBuilder,
      (SyncFile, BaseReferences<_$AppDatabase, $SyncFilesTable, SyncFile>),
      SyncFile,
      PrefetchHooks Function()
    >;
typedef $$TrackerLinksTableCreateCompanionBuilder =
    TrackerLinksCompanion Function({
      Value<int> id,
      required int libraryEntryId,
      Value<String> tracker,
      required int remoteMediaId,
      required String remoteTitle,
      Value<int?> remoteChapters,
      Value<DateTime> linkedAt,
    });
typedef $$TrackerLinksTableUpdateCompanionBuilder =
    TrackerLinksCompanion Function({
      Value<int> id,
      Value<int> libraryEntryId,
      Value<String> tracker,
      Value<int> remoteMediaId,
      Value<String> remoteTitle,
      Value<int?> remoteChapters,
      Value<DateTime> linkedAt,
    });

final class $$TrackerLinksTableReferences
    extends BaseReferences<_$AppDatabase, $TrackerLinksTable, TrackerLinkRow> {
  $$TrackerLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryEntriesTable _libraryEntryIdTable(_$AppDatabase db) => db
      .libraryEntries
      .createAlias('tracker_links__library_entry_id__library_entries__id');

  $$LibraryEntriesTableProcessedTableManager get libraryEntryId {
    final $_column = $_itemColumn<int>('library_entry_id')!;

    final manager = $$LibraryEntriesTableTableManager(
      $_db,
      $_db.libraryEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TrackerOutboxTable, List<TrackerOutboxRow>>
  _trackerOutboxRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackerOutbox,
    aliasName: 'tracker_links__id__tracker_outbox__link_id',
  );

  $$TrackerOutboxTableProcessedTableManager get trackerOutboxRefs {
    final manager = $$TrackerOutboxTableTableManager(
      $_db,
      $_db.trackerOutbox,
    ).filter((f) => f.linkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackerOutboxRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrackerLinksTableFilterComposer
    extends Composer<_$AppDatabase, $TrackerLinksTable> {
  $$TrackerLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tracker => $composableBuilder(
    column: $table.tracker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteMediaId => $composableBuilder(
    column: $table.remoteMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteTitle => $composableBuilder(
    column: $table.remoteTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteChapters => $composableBuilder(
    column: $table.remoteChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get linkedAt => $composableBuilder(
    column: $table.linkedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryEntriesTableFilterComposer get libraryEntryId {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> trackerOutboxRefs(
    Expression<bool> Function($$TrackerOutboxTableFilterComposer f) f,
  ) {
    final $$TrackerOutboxTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerOutbox,
      getReferencedColumn: (t) => t.linkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerOutboxTableFilterComposer(
            $db: $db,
            $table: $db.trackerOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrackerLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackerLinksTable> {
  $$TrackerLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracker => $composableBuilder(
    column: $table.tracker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteMediaId => $composableBuilder(
    column: $table.remoteMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteTitle => $composableBuilder(
    column: $table.remoteTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteChapters => $composableBuilder(
    column: $table.remoteChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get linkedAt => $composableBuilder(
    column: $table.linkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryEntriesTableOrderingComposer get libraryEntryId {
    final $$LibraryEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackerLinksTable> {
  $$TrackerLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tracker =>
      $composableBuilder(column: $table.tracker, builder: (column) => column);

  GeneratedColumn<int> get remoteMediaId => $composableBuilder(
    column: $table.remoteMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteTitle => $composableBuilder(
    column: $table.remoteTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteChapters => $composableBuilder(
    column: $table.remoteChapters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get linkedAt =>
      $composableBuilder(column: $table.linkedAt, builder: (column) => column);

  $$LibraryEntriesTableAnnotationComposer get libraryEntryId {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryEntryId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> trackerOutboxRefs<T extends Object>(
    Expression<T> Function($$TrackerOutboxTableAnnotationComposer a) f,
  ) {
    final $$TrackerOutboxTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerOutbox,
      getReferencedColumn: (t) => t.linkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerOutboxTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrackerLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackerLinksTable,
          TrackerLinkRow,
          $$TrackerLinksTableFilterComposer,
          $$TrackerLinksTableOrderingComposer,
          $$TrackerLinksTableAnnotationComposer,
          $$TrackerLinksTableCreateCompanionBuilder,
          $$TrackerLinksTableUpdateCompanionBuilder,
          (TrackerLinkRow, $$TrackerLinksTableReferences),
          TrackerLinkRow,
          PrefetchHooks Function({bool libraryEntryId, bool trackerOutboxRefs})
        > {
  $$TrackerLinksTableTableManager(_$AppDatabase db, $TrackerLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackerLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackerLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackerLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> libraryEntryId = const Value.absent(),
                Value<String> tracker = const Value.absent(),
                Value<int> remoteMediaId = const Value.absent(),
                Value<String> remoteTitle = const Value.absent(),
                Value<int?> remoteChapters = const Value.absent(),
                Value<DateTime> linkedAt = const Value.absent(),
              }) => TrackerLinksCompanion(
                id: id,
                libraryEntryId: libraryEntryId,
                tracker: tracker,
                remoteMediaId: remoteMediaId,
                remoteTitle: remoteTitle,
                remoteChapters: remoteChapters,
                linkedAt: linkedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int libraryEntryId,
                Value<String> tracker = const Value.absent(),
                required int remoteMediaId,
                required String remoteTitle,
                Value<int?> remoteChapters = const Value.absent(),
                Value<DateTime> linkedAt = const Value.absent(),
              }) => TrackerLinksCompanion.insert(
                id: id,
                libraryEntryId: libraryEntryId,
                tracker: tracker,
                remoteMediaId: remoteMediaId,
                remoteTitle: remoteTitle,
                remoteChapters: remoteChapters,
                linkedAt: linkedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackerLinksTable, TrackerLinkRow>(table),
                  $$TrackerLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({libraryEntryId = false, trackerOutboxRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackerOutboxRefs) db.trackerOutbox,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (libraryEntryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryEntryId,
                            referencedTable: $$TrackerLinksTableReferences
                                ._libraryEntryIdTable(db),
                            referencedColumn: $$TrackerLinksTableReferences
                                ._libraryEntryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackerOutboxRefs)
                        await $_getPrefetchedData<
                          TrackerLinkRow,
                          $TrackerLinksTable,
                          TrackerOutboxRow
                        >(
                          currentTable: table,
                          referencedTable: $$TrackerLinksTableReferences
                              ._trackerOutboxRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrackerLinksTableReferences(
                                db,
                                table,
                                p0,
                              ).trackerOutboxRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.linkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TrackerLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackerLinksTable,
      TrackerLinkRow,
      $$TrackerLinksTableFilterComposer,
      $$TrackerLinksTableOrderingComposer,
      $$TrackerLinksTableAnnotationComposer,
      $$TrackerLinksTableCreateCompanionBuilder,
      $$TrackerLinksTableUpdateCompanionBuilder,
      (TrackerLinkRow, $$TrackerLinksTableReferences),
      TrackerLinkRow,
      PrefetchHooks Function({bool libraryEntryId, bool trackerOutboxRefs})
    >;
typedef $$TrackerOutboxTableCreateCompanionBuilder =
    TrackerOutboxCompanion Function({
      Value<int> id,
      required int linkId,
      required int firstQueuedAt,
      Value<int> version,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> nextTryAt,
    });
typedef $$TrackerOutboxTableUpdateCompanionBuilder =
    TrackerOutboxCompanion Function({
      Value<int> id,
      Value<int> linkId,
      Value<int> firstQueuedAt,
      Value<int> version,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> nextTryAt,
    });

final class $$TrackerOutboxTableReferences
    extends
        BaseReferences<_$AppDatabase, $TrackerOutboxTable, TrackerOutboxRow> {
  $$TrackerOutboxTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrackerLinksTable _linkIdTable(_$AppDatabase db) =>
      db.trackerLinks.createAlias('tracker_outbox__link_id__tracker_links__id');

  $$TrackerLinksTableProcessedTableManager get linkId {
    final $_column = $_itemColumn<int>('link_id')!;

    final manager = $$TrackerLinksTableTableManager(
      $_db,
      $_db.trackerLinks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackerOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $TrackerOutboxTable> {
  $$TrackerOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstQueuedAt => $composableBuilder(
    column: $table.firstQueuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextTryAt => $composableBuilder(
    column: $table.nextTryAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TrackerLinksTableFilterComposer get linkId {
    final $$TrackerLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkId,
      referencedTable: $db.trackerLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerLinksTableFilterComposer(
            $db: $db,
            $table: $db.trackerLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackerOutboxTable> {
  $$TrackerOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstQueuedAt => $composableBuilder(
    column: $table.firstQueuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextTryAt => $composableBuilder(
    column: $table.nextTryAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrackerLinksTableOrderingComposer get linkId {
    final $$TrackerLinksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkId,
      referencedTable: $db.trackerLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerLinksTableOrderingComposer(
            $db: $db,
            $table: $db.trackerLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackerOutboxTable> {
  $$TrackerOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get firstQueuedAt => $composableBuilder(
    column: $table.firstQueuedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get nextTryAt =>
      $composableBuilder(column: $table.nextTryAt, builder: (column) => column);

  $$TrackerLinksTableAnnotationComposer get linkId {
    final $$TrackerLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkId,
      referencedTable: $db.trackerLinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackerOutboxTable,
          TrackerOutboxRow,
          $$TrackerOutboxTableFilterComposer,
          $$TrackerOutboxTableOrderingComposer,
          $$TrackerOutboxTableAnnotationComposer,
          $$TrackerOutboxTableCreateCompanionBuilder,
          $$TrackerOutboxTableUpdateCompanionBuilder,
          (TrackerOutboxRow, $$TrackerOutboxTableReferences),
          TrackerOutboxRow,
          PrefetchHooks Function({bool linkId})
        > {
  $$TrackerOutboxTableTableManager(_$AppDatabase db, $TrackerOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackerOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackerOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackerOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> linkId = const Value.absent(),
                Value<int> firstQueuedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> nextTryAt = const Value.absent(),
              }) => TrackerOutboxCompanion(
                id: id,
                linkId: linkId,
                firstQueuedAt: firstQueuedAt,
                version: version,
                attempts: attempts,
                lastError: lastError,
                nextTryAt: nextTryAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int linkId,
                required int firstQueuedAt,
                Value<int> version = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> nextTryAt = const Value.absent(),
              }) => TrackerOutboxCompanion.insert(
                id: id,
                linkId: linkId,
                firstQueuedAt: firstQueuedAt,
                version: version,
                attempts: attempts,
                lastError: lastError,
                nextTryAt: nextTryAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackerOutboxTable, TrackerOutboxRow>(table),
                  $$TrackerOutboxTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({linkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (linkId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.linkId,
                        referencedTable: $$TrackerOutboxTableReferences
                            ._linkIdTable(db),
                        referencedColumn: $$TrackerOutboxTableReferences
                            ._linkIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackerOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackerOutboxTable,
      TrackerOutboxRow,
      $$TrackerOutboxTableFilterComposer,
      $$TrackerOutboxTableOrderingComposer,
      $$TrackerOutboxTableAnnotationComposer,
      $$TrackerOutboxTableCreateCompanionBuilder,
      $$TrackerOutboxTableUpdateCompanionBuilder,
      (TrackerOutboxRow, $$TrackerOutboxTableReferences),
      TrackerOutboxRow,
      PrefetchHooks Function({bool linkId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$EntryBranchesTableTableManager get entryBranches =>
      $$EntryBranchesTableTableManager(_db, _db.entryBranches);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(_db, _db.libraryEntries);
  $$ContentUnitsTableTableManager get contentUnits =>
      $$ContentUnitsTableTableManager(_db, _db.contentUnits);
  $$ChapterProgressTableTableManager get chapterProgress =>
      $$ChapterProgressTableTableManager(_db, _db.chapterProgress);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$EntryCategoriesTableTableManager get entryCategories =>
      $$EntryCategoriesTableTableManager(_db, _db.entryCategories);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$InstalledSourcesTableTableManager get installedSources =>
      $$InstalledSourcesTableTableManager(_db, _db.installedSources);
  $$ReposTableTableManager get repos =>
      $$ReposTableTableManager(_db, _db.repos);
  $$ActiveProfileTableTableTableManager get activeProfileTable =>
      $$ActiveProfileTableTableTableManager(_db, _db.activeProfileTable);
  $$SettingValuesTableTableManager get settingValues =>
      $$SettingValuesTableTableManager(_db, _db.settingValues);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$SyncDeletionsTableTableManager get syncDeletions =>
      $$SyncDeletionsTableTableManager(_db, _db.syncDeletions);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$SyncProfileStateTableTableManager get syncProfileState =>
      $$SyncProfileStateTableTableManager(_db, _db.syncProfileState);
  $$SyncFilesTableTableManager get syncFiles =>
      $$SyncFilesTableTableManager(_db, _db.syncFiles);
  $$TrackerLinksTableTableManager get trackerLinks =>
      $$TrackerLinksTableTableManager(_db, _db.trackerLinks);
  $$TrackerOutboxTableTableManager get trackerOutbox =>
      $$TrackerOutboxTableTableManager(_db, _db.trackerOutbox);
}
