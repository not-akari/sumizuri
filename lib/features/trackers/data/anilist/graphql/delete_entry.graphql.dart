import 'package:gql/ast.dart';

class Variables$Mutation$DeleteEntry {
  factory Variables$Mutation$DeleteEntry({required int id}) =>
      Variables$Mutation$DeleteEntry._({r'id': id});

  Variables$Mutation$DeleteEntry._(this._$data);

  factory Variables$Mutation$DeleteEntry.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$id = data['id'];
    result$data['id'] = (l$id as int);
    return Variables$Mutation$DeleteEntry._(result$data);
  }

  Map<String, dynamic> _$data;

  int get id => (_$data['id'] as int);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$id = id;
    result$data['id'] = l$id;
    return result$data;
  }

  CopyWith$Variables$Mutation$DeleteEntry<Variables$Mutation$DeleteEntry>
  get copyWith => CopyWith$Variables$Mutation$DeleteEntry(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Mutation$DeleteEntry ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$id = id;
    return Object.hashAll([l$id]);
  }
}

abstract class CopyWith$Variables$Mutation$DeleteEntry<TRes> {
  factory CopyWith$Variables$Mutation$DeleteEntry(
    Variables$Mutation$DeleteEntry instance,
    TRes Function(Variables$Mutation$DeleteEntry) then,
  ) = _CopyWithImpl$Variables$Mutation$DeleteEntry;

  factory CopyWith$Variables$Mutation$DeleteEntry.stub(TRes res) =
      _CopyWithStubImpl$Variables$Mutation$DeleteEntry;

  TRes call({int? id});
}

class _CopyWithImpl$Variables$Mutation$DeleteEntry<TRes>
    implements CopyWith$Variables$Mutation$DeleteEntry<TRes> {
  _CopyWithImpl$Variables$Mutation$DeleteEntry(this._instance, this._then);

  final Variables$Mutation$DeleteEntry _instance;

  final TRes Function(Variables$Mutation$DeleteEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? id = _undefined}) => _then(
    Variables$Mutation$DeleteEntry._({
      ..._instance._$data,
      if (id != _undefined && id != null) 'id': (id as int),
    }),
  );
}

class _CopyWithStubImpl$Variables$Mutation$DeleteEntry<TRes>
    implements CopyWith$Variables$Mutation$DeleteEntry<TRes> {
  _CopyWithStubImpl$Variables$Mutation$DeleteEntry(this._res);

  TRes _res;

  call({int? id}) => _res;
}

class Mutation$DeleteEntry {
  Mutation$DeleteEntry({this.DeleteMediaListEntry});

  factory Mutation$DeleteEntry.fromJson(Map<String, dynamic> json) {
    final l$DeleteMediaListEntry = json['DeleteMediaListEntry'];
    return Mutation$DeleteEntry(
      DeleteMediaListEntry: l$DeleteMediaListEntry == null
          ? null
          : Mutation$DeleteEntry$DeleteMediaListEntry.fromJson(
              (l$DeleteMediaListEntry as Map<String, dynamic>),
            ),
    );
  }

  final Mutation$DeleteEntry$DeleteMediaListEntry? DeleteMediaListEntry;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$DeleteMediaListEntry = DeleteMediaListEntry;
    _resultData['DeleteMediaListEntry'] = l$DeleteMediaListEntry?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$DeleteMediaListEntry = DeleteMediaListEntry;
    return Object.hashAll([l$DeleteMediaListEntry]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$DeleteEntry || runtimeType != other.runtimeType) {
      return false;
    }
    final l$DeleteMediaListEntry = DeleteMediaListEntry;
    final lOther$DeleteMediaListEntry = other.DeleteMediaListEntry;
    if (l$DeleteMediaListEntry != lOther$DeleteMediaListEntry) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$DeleteEntry on Mutation$DeleteEntry {
  CopyWith$Mutation$DeleteEntry<Mutation$DeleteEntry> get copyWith =>
      CopyWith$Mutation$DeleteEntry(this, (i) => i);
}

abstract class CopyWith$Mutation$DeleteEntry<TRes> {
  factory CopyWith$Mutation$DeleteEntry(
    Mutation$DeleteEntry instance,
    TRes Function(Mutation$DeleteEntry) then,
  ) = _CopyWithImpl$Mutation$DeleteEntry;

  factory CopyWith$Mutation$DeleteEntry.stub(TRes res) =
      _CopyWithStubImpl$Mutation$DeleteEntry;

  TRes call({Mutation$DeleteEntry$DeleteMediaListEntry? DeleteMediaListEntry});
  CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes>
  get DeleteMediaListEntry;
}

class _CopyWithImpl$Mutation$DeleteEntry<TRes>
    implements CopyWith$Mutation$DeleteEntry<TRes> {
  _CopyWithImpl$Mutation$DeleteEntry(this._instance, this._then);

  final Mutation$DeleteEntry _instance;

  final TRes Function(Mutation$DeleteEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? DeleteMediaListEntry = _undefined}) => _then(
    Mutation$DeleteEntry(
      DeleteMediaListEntry: DeleteMediaListEntry == _undefined
          ? _instance.DeleteMediaListEntry
          : (DeleteMediaListEntry
                as Mutation$DeleteEntry$DeleteMediaListEntry?),
    ),
  );

  CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes>
  get DeleteMediaListEntry {
    final local$DeleteMediaListEntry = _instance.DeleteMediaListEntry;
    return local$DeleteMediaListEntry == null
        ? CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry.stub(
            _then(_instance),
          )
        : CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry(
            local$DeleteMediaListEntry,
            (e) => call(DeleteMediaListEntry: e),
          );
  }
}

class _CopyWithStubImpl$Mutation$DeleteEntry<TRes>
    implements CopyWith$Mutation$DeleteEntry<TRes> {
  _CopyWithStubImpl$Mutation$DeleteEntry(this._res);

  TRes _res;

  call({Mutation$DeleteEntry$DeleteMediaListEntry? DeleteMediaListEntry}) =>
      _res;

  CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes>
  get DeleteMediaListEntry =>
      CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry.stub(_res);
}

const documentNodeMutationDeleteEntry = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.mutation,
      name: NameNode(value: 'DeleteEntry'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'id')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'DeleteMediaListEntry'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'id'),
                value: VariableNode(name: NameNode(value: 'id')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'deleted'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
);

class Mutation$DeleteEntry$DeleteMediaListEntry {
  Mutation$DeleteEntry$DeleteMediaListEntry({this.deleted});

  factory Mutation$DeleteEntry$DeleteMediaListEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$deleted = json['deleted'];
    return Mutation$DeleteEntry$DeleteMediaListEntry(
      deleted: (l$deleted as bool?),
    );
  }

  final bool? deleted;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$deleted = deleted;
    _resultData['deleted'] = l$deleted;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$deleted = deleted;
    return Object.hashAll([l$deleted]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Mutation$DeleteEntry$DeleteMediaListEntry ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$deleted = deleted;
    final lOther$deleted = other.deleted;
    if (l$deleted != lOther$deleted) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Mutation$DeleteEntry$DeleteMediaListEntry
    on Mutation$DeleteEntry$DeleteMediaListEntry {
  CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<
    Mutation$DeleteEntry$DeleteMediaListEntry
  >
  get copyWith =>
      CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry(this, (i) => i);
}

abstract class CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes> {
  factory CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry(
    Mutation$DeleteEntry$DeleteMediaListEntry instance,
    TRes Function(Mutation$DeleteEntry$DeleteMediaListEntry) then,
  ) = _CopyWithImpl$Mutation$DeleteEntry$DeleteMediaListEntry;

  factory CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry.stub(TRes res) =
      _CopyWithStubImpl$Mutation$DeleteEntry$DeleteMediaListEntry;

  TRes call({bool? deleted});
}

class _CopyWithImpl$Mutation$DeleteEntry$DeleteMediaListEntry<TRes>
    implements CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes> {
  _CopyWithImpl$Mutation$DeleteEntry$DeleteMediaListEntry(
    this._instance,
    this._then,
  );

  final Mutation$DeleteEntry$DeleteMediaListEntry _instance;

  final TRes Function(Mutation$DeleteEntry$DeleteMediaListEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? deleted = _undefined}) => _then(
    Mutation$DeleteEntry$DeleteMediaListEntry(
      deleted: deleted == _undefined ? _instance.deleted : (deleted as bool?),
    ),
  );
}

class _CopyWithStubImpl$Mutation$DeleteEntry$DeleteMediaListEntry<TRes>
    implements CopyWith$Mutation$DeleteEntry$DeleteMediaListEntry<TRes> {
  _CopyWithStubImpl$Mutation$DeleteEntry$DeleteMediaListEntry(this._res);

  TRes _res;

  call({bool? deleted}) => _res;
}
