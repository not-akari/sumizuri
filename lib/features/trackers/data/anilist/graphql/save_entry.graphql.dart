import 'fragments.graphql.dart';

import 'package:gql/ast.dart';

import 'schema.graphql.dart';

class Variables$Mutation$SaveEntry {
  factory Variables$Mutation$SaveEntry({
    required int mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    int? scoreRaw,
    int? repeat,
    Input$FuzzyDateInput? startedAt,
    Input$FuzzyDateInput? completedAt,
  }) => Variables$Mutation$SaveEntry._({
    r'mediaId': mediaId,
    if (status != null) r'status': status,
    if (progress != null) r'progress': progress,
    if (progressVolumes != null) r'progressVolumes': progressVolumes,
    if (scoreRaw != null) r'scoreRaw': scoreRaw,
    if (repeat != null) r'repeat': repeat,
    if (startedAt != null) r'startedAt': startedAt,
    if (completedAt != null) r'completedAt': completedAt,
  });

  Variables$Mutation$SaveEntry._(this._$data);

  factory Variables$Mutation$SaveEntry.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$mediaId = data['mediaId'];
    result$data['mediaId'] = (l$mediaId as int);
    if (data.containsKey('status')) {
      final l$status = data['status'];
      result$data['status'] = l$status == null
          ? null
          : fromJson$Enum$MediaListStatus((l$status as String));
    }
    if (data.containsKey('progress')) {
      final l$progress = data['progress'];
      result$data['progress'] = (l$progress as int?);
    }
    if (data.containsKey('progressVolumes')) {
      final l$progressVolumes = data['progressVolumes'];
      result$data['progressVolumes'] = (l$progressVolumes as int?);
    }
    if (data.containsKey('scoreRaw')) {
      final l$scoreRaw = data['scoreRaw'];
      result$data['scoreRaw'] = (l$scoreRaw as int?);
    }
    if (data.containsKey('repeat')) {
      final l$repeat = data['repeat'];
      result$data['repeat'] = (l$repeat as int?);
    }
    if (data.containsKey('startedAt')) {
      final l$startedAt = data['startedAt'];
      result$data['startedAt'] = l$startedAt == null
          ? null
          : Input$FuzzyDateInput.fromJson(
              (l$startedAt as Map<String, dynamic>),
            );
    }
    if (data.containsKey('completedAt')) {
      final l$completedAt = data['completedAt'];
      result$data['completedAt'] = l$completedAt == null
          ? null
          : Input$FuzzyDateInput.fromJson(
              (l$completedAt as Map<String, dynamic>),
            );
    }
    return Variables$Mutation$SaveEntry._(result$data);
  }

  Map<String, dynamic> _$data;

  int get mediaId => (_$data['mediaId'] as int);

  Enum$MediaListStatus? get status =>
      (_$data['status'] as Enum$MediaListStatus?);

  int? get progress => (_$data['progress'] as int?);

  int? get progressVolumes => (_$data['progressVolumes'] as int?);

  int? get scoreRaw => (_$data['scoreRaw'] as int?);

  int? get repeat => (_$data['repeat'] as int?);

  Input$FuzzyDateInput? get startedAt =>
      (_$data['startedAt'] as Input$FuzzyDateInput?);

  Input$FuzzyDateInput? get completedAt =>
      (_$data['completedAt'] as Input$FuzzyDateInput?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$mediaId = mediaId;
    result$data['mediaId'] = l$mediaId;
    if (_$data.containsKey('status')) {
      final l$status = status;
      result$data['status'] = l$status == null
          ? null
          : toJson$Enum$MediaListStatus(l$status);
    }
    if (_$data.containsKey('progress')) {
      final l$progress = progress;
      result$data['progress'] = l$progress;
    }
    if (_$data.containsKey('progressVolumes')) {
      final l$progressVolumes = progressVolumes;
      result$data['progressVolumes'] = l$progressVolumes;
    }
    if (_$data.containsKey('scoreRaw')) {
      final l$scoreRaw = scoreRaw;
      result$data['scoreRaw'] = l$scoreRaw;
    }
    if (_$data.containsKey('repeat')) {
      final l$repeat = repeat;
      result$data['repeat'] = l$repeat;
    }
    if (_$data.containsKey('startedAt')) {
      final l$startedAt = startedAt;
      result$data['startedAt'] = l$startedAt?.toJson();
    }
    if (_$data.containsKey('completedAt')) {
      final l$completedAt = completedAt;
      result$data['completedAt'] = l$completedAt?.toJson();
    }
    return result$data;
  }

  CopyWith$Variables$Mutation$SaveEntry<Variables$Mutation$SaveEntry>
  get copyWith => CopyWith$Variables$Mutation$SaveEntry(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$SaveEntry ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$mediaId = mediaId;
    final lOther$mediaId = other.mediaId;
    if (l$mediaId != lOther$mediaId) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (_$data.containsKey('status') != other._$data.containsKey('status')) {
      return false;
    }
    if (l$status != lOther$status) {
      return false;
    }
    final l$progress = progress;
    final lOther$progress = other.progress;
    if (_$data.containsKey('progress') !=
        other._$data.containsKey('progress')) {
      return false;
    }
    if (l$progress != lOther$progress) {
      return false;
    }
    final l$progressVolumes = progressVolumes;
    final lOther$progressVolumes = other.progressVolumes;
    if (_$data.containsKey('progressVolumes') !=
        other._$data.containsKey('progressVolumes')) {
      return false;
    }
    if (l$progressVolumes != lOther$progressVolumes) {
      return false;
    }
    final l$scoreRaw = scoreRaw;
    final lOther$scoreRaw = other.scoreRaw;
    if (_$data.containsKey('scoreRaw') !=
        other._$data.containsKey('scoreRaw')) {
      return false;
    }
    if (l$scoreRaw != lOther$scoreRaw) {
      return false;
    }
    final l$repeat = repeat;
    final lOther$repeat = other.repeat;
    if (_$data.containsKey('repeat') != other._$data.containsKey('repeat')) {
      return false;
    }
    if (l$repeat != lOther$repeat) {
      return false;
    }
    final l$startedAt = startedAt;
    final lOther$startedAt = other.startedAt;
    if (_$data.containsKey('startedAt') !=
        other._$data.containsKey('startedAt')) {
      return false;
    }
    if (l$startedAt != lOther$startedAt) {
      return false;
    }
    final l$completedAt = completedAt;
    final lOther$completedAt = other.completedAt;
    if (_$data.containsKey('completedAt') !=
        other._$data.containsKey('completedAt')) {
      return false;
    }
    if (l$completedAt != lOther$completedAt) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$mediaId = mediaId;
    final l$status = status;
    final l$progress = progress;
    final l$progressVolumes = progressVolumes;
    final l$scoreRaw = scoreRaw;
    final l$repeat = repeat;
    final l$startedAt = startedAt;
    final l$completedAt = completedAt;
    return Object.hashAll([
      l$mediaId,
      _$data.containsKey('status') ? l$status : const {},
      _$data.containsKey('progress') ? l$progress : const {},
      _$data.containsKey('progressVolumes') ? l$progressVolumes : const {},
      _$data.containsKey('scoreRaw') ? l$scoreRaw : const {},
      _$data.containsKey('repeat') ? l$repeat : const {},
      _$data.containsKey('startedAt') ? l$startedAt : const {},
      _$data.containsKey('completedAt') ? l$completedAt : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Mutation$SaveEntry<TRes> {
  factory CopyWith$Variables$Mutation$SaveEntry(
    Variables$Mutation$SaveEntry instance,
    TRes Function(Variables$Mutation$SaveEntry) then,
  ) = _CopyWithImpl$Variables$Mutation$SaveEntry;

  factory CopyWith$Variables$Mutation$SaveEntry.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$SaveEntry;

  TRes call({
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    int? scoreRaw,
    int? repeat,
    Input$FuzzyDateInput? startedAt,
    Input$FuzzyDateInput? completedAt,
  });
}

class _CopyWithImpl$Variables$Mutation$SaveEntry<TRes>
    implements CopyWith$Variables$Mutation$SaveEntry<TRes> {
  _CopyWithImpl$Variables$Mutation$SaveEntry(this._instance, this._then);

  final Variables$Mutation$SaveEntry _instance;

  final TRes Function(Variables$Mutation$SaveEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? mediaId = _undefined,
    Object? status = _undefined,
    Object? progress = _undefined,
    Object? progressVolumes = _undefined,
    Object? scoreRaw = _undefined,
    Object? repeat = _undefined,
    Object? startedAt = _undefined,
    Object? completedAt = _undefined,
  }) => _then(
    Variables$Mutation$SaveEntry._({
      ..._instance._$data,
      if (mediaId != _undefined && mediaId != null) 'mediaId': (mediaId as int),
      if (status != _undefined) 'status': (status as Enum$MediaListStatus?),
      if (progress != _undefined) 'progress': (progress as int?),
      if (progressVolumes != _undefined)
        'progressVolumes': (progressVolumes as int?),
      if (scoreRaw != _undefined) 'scoreRaw': (scoreRaw as int?),
      if (repeat != _undefined) 'repeat': (repeat as int?),
      if (startedAt != _undefined)
        'startedAt': (startedAt as Input$FuzzyDateInput?),
      if (completedAt != _undefined)
        'completedAt': (completedAt as Input$FuzzyDateInput?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$SaveEntry<TRes>
    implements CopyWith$Variables$Mutation$SaveEntry<TRes> {
  _CopyWithStubImpl$Variables$Mutation$SaveEntry(this._res);

  TRes _res;

  call({
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    int? scoreRaw,
    int? repeat,
    Input$FuzzyDateInput? startedAt,
    Input$FuzzyDateInput? completedAt,
  }) => _res;
}

class Mutation$SaveEntry {
  Mutation$SaveEntry({this.SaveMediaListEntry});

  factory Mutation$SaveEntry.fromJson(Map<String, dynamic> json) {
    final l$SaveMediaListEntry = json['SaveMediaListEntry'];
    return Mutation$SaveEntry(
      SaveMediaListEntry: l$SaveMediaListEntry == null
          ? null
          : Fragment$ListEntry.fromJson(
              (l$SaveMediaListEntry as Map<String, dynamic>),
            ),
    );
  }

  final Fragment$ListEntry? SaveMediaListEntry;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$SaveMediaListEntry = SaveMediaListEntry;
    _resultData['SaveMediaListEntry'] = l$SaveMediaListEntry?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$SaveMediaListEntry = SaveMediaListEntry;
    return Object.hashAll([l$SaveMediaListEntry]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$SaveEntry || runtimeType != other.runtimeType) {
      return false;
    }
    final l$SaveMediaListEntry = SaveMediaListEntry;
    final lOther$SaveMediaListEntry = other.SaveMediaListEntry;
    if (l$SaveMediaListEntry != lOther$SaveMediaListEntry) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$SaveEntry on Mutation$SaveEntry {
  CopyWith$Mutation$SaveEntry<Mutation$SaveEntry> get copyWith =>
      CopyWith$Mutation$SaveEntry(this, (i) => i);
}

abstract class CopyWith$Mutation$SaveEntry<TRes> {
  factory CopyWith$Mutation$SaveEntry(
    Mutation$SaveEntry instance,
    TRes Function(Mutation$SaveEntry) then,
  ) = _CopyWithImpl$Mutation$SaveEntry;

  factory CopyWith$Mutation$SaveEntry.stub(TRes res) =
      _CopyWithStubImpl$Mutation$SaveEntry;

  TRes call({Fragment$ListEntry? SaveMediaListEntry});
  CopyWith$Fragment$ListEntry<TRes> get SaveMediaListEntry;
}

class _CopyWithImpl$Mutation$SaveEntry<TRes>
    implements CopyWith$Mutation$SaveEntry<TRes> {
  _CopyWithImpl$Mutation$SaveEntry(this._instance, this._then);

  final Mutation$SaveEntry _instance;

  final TRes Function(Mutation$SaveEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? SaveMediaListEntry = _undefined}) => _then(
    Mutation$SaveEntry(
      SaveMediaListEntry: SaveMediaListEntry == _undefined
          ? _instance.SaveMediaListEntry
          : (SaveMediaListEntry as Fragment$ListEntry?),
    ),
  );

  CopyWith$Fragment$ListEntry<TRes> get SaveMediaListEntry {
    final local$SaveMediaListEntry = _instance.SaveMediaListEntry;
    return local$SaveMediaListEntry == null
        ? CopyWith$Fragment$ListEntry.stub(_then(_instance))
        : CopyWith$Fragment$ListEntry(
            local$SaveMediaListEntry,
            (e) => call(SaveMediaListEntry: e),
          );
  }
}

class _CopyWithStubImpl$Mutation$SaveEntry<TRes>
    implements CopyWith$Mutation$SaveEntry<TRes> {
  _CopyWithStubImpl$Mutation$SaveEntry(this._res);

  TRes _res;

  call({Fragment$ListEntry? SaveMediaListEntry}) => _res;

  CopyWith$Fragment$ListEntry<TRes> get SaveMediaListEntry =>
      CopyWith$Fragment$ListEntry.stub(_res);
}

const documentNodeMutationSaveEntry = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'SaveEntry'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'mediaId')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'status')),
          type: NamedTypeNode(
            name: NameNode(value: 'MediaListStatus'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'progress')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'progressVolumes')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'scoreRaw')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'repeat')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'startedAt')),
          type: NamedTypeNode(
            name: NameNode(value: 'FuzzyDateInput'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'completedAt')),
          type: NamedTypeNode(
            name: NameNode(value: 'FuzzyDateInput'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'SaveMediaListEntry'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'mediaId'),
                value: VariableNode(name: NameNode(value: 'mediaId')),
              ),
              ArgumentNode(
                name: NameNode(value: 'status'),
                value: VariableNode(name: NameNode(value: 'status')),
              ),
              ArgumentNode(
                name: NameNode(value: 'progress'),
                value: VariableNode(name: NameNode(value: 'progress')),
              ),
              ArgumentNode(
                name: NameNode(value: 'progressVolumes'),
                value: VariableNode(name: NameNode(value: 'progressVolumes')),
              ),
              ArgumentNode(
                name: NameNode(value: 'scoreRaw'),
                value: VariableNode(name: NameNode(value: 'scoreRaw')),
              ),
              ArgumentNode(
                name: NameNode(value: 'repeat'),
                value: VariableNode(name: NameNode(value: 'repeat')),
              ),
              ArgumentNode(
                name: NameNode(value: 'startedAt'),
                value: VariableNode(name: NameNode(value: 'startedAt')),
              ),
              ArgumentNode(
                name: NameNode(value: 'completedAt'),
                value: VariableNode(name: NameNode(value: 'completedAt')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FragmentSpreadNode(
                  name: NameNode(value: 'ListEntry'),
                  directives: [],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    fragmentDefinitionListEntry,
  ],
);
