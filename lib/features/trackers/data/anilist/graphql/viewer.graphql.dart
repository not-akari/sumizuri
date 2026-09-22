import 'package:gql/ast.dart';

class Query$Viewer {
  Query$Viewer({this.Viewer});

  factory Query$Viewer.fromJson(Map<String, dynamic> json) {
    final l$Viewer = json['Viewer'];
    return Query$Viewer(
      Viewer: l$Viewer == null
          ? null
          : Query$Viewer$Viewer.fromJson((l$Viewer as Map<String, dynamic>)),
    );
  }

  final Query$Viewer$Viewer? Viewer;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$Viewer = Viewer;
    _resultData['Viewer'] = l$Viewer?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$Viewer = Viewer;
    return Object.hashAll([l$Viewer]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Viewer || runtimeType != other.runtimeType) {
      return false;
    }
    final l$Viewer = Viewer;
    final lOther$Viewer = other.Viewer;
    if (l$Viewer != lOther$Viewer) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Viewer on Query$Viewer {
  CopyWith$Query$Viewer<Query$Viewer> get copyWith =>
      CopyWith$Query$Viewer(this, (i) => i);
}

abstract class CopyWith$Query$Viewer<TRes> {
  factory CopyWith$Query$Viewer(
    Query$Viewer instance,
    TRes Function(Query$Viewer) then,
  ) = _CopyWithImpl$Query$Viewer;

  factory CopyWith$Query$Viewer.stub(TRes res) = _CopyWithStubImpl$Query$Viewer;

  TRes call({Query$Viewer$Viewer? Viewer});
  CopyWith$Query$Viewer$Viewer<TRes> get Viewer;
}

class _CopyWithImpl$Query$Viewer<TRes> implements CopyWith$Query$Viewer<TRes> {
  _CopyWithImpl$Query$Viewer(this._instance, this._then);

  final Query$Viewer _instance;

  final TRes Function(Query$Viewer) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? Viewer = _undefined}) => _then(
    Query$Viewer(
      Viewer: Viewer == _undefined
          ? _instance.Viewer
          : (Viewer as Query$Viewer$Viewer?),
    ),
  );

  CopyWith$Query$Viewer$Viewer<TRes> get Viewer {
    final local$Viewer = _instance.Viewer;
    return local$Viewer == null
        ? CopyWith$Query$Viewer$Viewer.stub(_then(_instance))
        : CopyWith$Query$Viewer$Viewer(local$Viewer, (e) => call(Viewer: e));
  }
}

class _CopyWithStubImpl$Query$Viewer<TRes>
    implements CopyWith$Query$Viewer<TRes> {
  _CopyWithStubImpl$Query$Viewer(this._res);

  TRes _res;

  call({Query$Viewer$Viewer? Viewer}) => _res;

  CopyWith$Query$Viewer$Viewer<TRes> get Viewer =>
      CopyWith$Query$Viewer$Viewer.stub(_res);
}

const documentNodeQueryViewer = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'Viewer'),
      variableDefinitions: [],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'Viewer'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'id'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'name'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: null,
                ),
                FieldNode(
                  name: NameNode(value: 'avatar'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'medium'),
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
      ),
    ),
  ],
);

class Query$Viewer$Viewer {
  Query$Viewer$Viewer({required this.id, required this.name, this.avatar});

  factory Query$Viewer$Viewer.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$name = json['name'];
    final l$avatar = json['avatar'];
    return Query$Viewer$Viewer(
      id: (l$id as int),
      name: (l$name as String),
      avatar: l$avatar == null
          ? null
          : Query$Viewer$Viewer$avatar.fromJson(
              (l$avatar as Map<String, dynamic>),
            ),
    );
  }

  final int id;

  final String name;

  final Query$Viewer$Viewer$avatar? avatar;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$name = name;
    _resultData['name'] = l$name;
    final l$avatar = avatar;
    _resultData['avatar'] = l$avatar?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$name = name;
    final l$avatar = avatar;
    return Object.hashAll([l$id, l$name, l$avatar]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Viewer$Viewer || runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$name = name;
    final lOther$name = other.name;
    if (l$name != lOther$name) {
      return false;
    }
    final l$avatar = avatar;
    final lOther$avatar = other.avatar;
    if (l$avatar != lOther$avatar) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Viewer$Viewer on Query$Viewer$Viewer {
  CopyWith$Query$Viewer$Viewer<Query$Viewer$Viewer> get copyWith =>
      CopyWith$Query$Viewer$Viewer(this, (i) => i);
}

abstract class CopyWith$Query$Viewer$Viewer<TRes> {
  factory CopyWith$Query$Viewer$Viewer(
    Query$Viewer$Viewer instance,
    TRes Function(Query$Viewer$Viewer) then,
  ) = _CopyWithImpl$Query$Viewer$Viewer;

  factory CopyWith$Query$Viewer$Viewer.stub(TRes res) =
      _CopyWithStubImpl$Query$Viewer$Viewer;

  TRes call({int? id, String? name, Query$Viewer$Viewer$avatar? avatar});
  CopyWith$Query$Viewer$Viewer$avatar<TRes> get avatar;
}

class _CopyWithImpl$Query$Viewer$Viewer<TRes>
    implements CopyWith$Query$Viewer$Viewer<TRes> {
  _CopyWithImpl$Query$Viewer$Viewer(this._instance, this._then);

  final Query$Viewer$Viewer _instance;

  final TRes Function(Query$Viewer$Viewer) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? avatar = _undefined,
  }) => _then(
    Query$Viewer$Viewer(
      id: id == _undefined || id == null ? _instance.id : (id as int),
      name: name == _undefined || name == null
          ? _instance.name
          : (name as String),
      avatar: avatar == _undefined
          ? _instance.avatar
          : (avatar as Query$Viewer$Viewer$avatar?),
    ),
  );

  CopyWith$Query$Viewer$Viewer$avatar<TRes> get avatar {
    final local$avatar = _instance.avatar;
    return local$avatar == null
        ? CopyWith$Query$Viewer$Viewer$avatar.stub(_then(_instance))
        : CopyWith$Query$Viewer$Viewer$avatar(
            local$avatar,
            (e) => call(avatar: e),
          );
  }
}

class _CopyWithStubImpl$Query$Viewer$Viewer<TRes>
    implements CopyWith$Query$Viewer$Viewer<TRes> {
  _CopyWithStubImpl$Query$Viewer$Viewer(this._res);

  TRes _res;

  call({int? id, String? name, Query$Viewer$Viewer$avatar? avatar}) => _res;

  CopyWith$Query$Viewer$Viewer$avatar<TRes> get avatar =>
      CopyWith$Query$Viewer$Viewer$avatar.stub(_res);
}

class Query$Viewer$Viewer$avatar {
  Query$Viewer$Viewer$avatar({this.medium});

  factory Query$Viewer$Viewer$avatar.fromJson(Map<String, dynamic> json) {
    final l$medium = json['medium'];
    return Query$Viewer$Viewer$avatar(medium: (l$medium as String?));
  }

  final String? medium;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$medium = medium;
    _resultData['medium'] = l$medium;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$medium = medium;
    return Object.hashAll([l$medium]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$Viewer$Viewer$avatar ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$medium = medium;
    final lOther$medium = other.medium;
    if (l$medium != lOther$medium) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$Viewer$Viewer$avatar
    on Query$Viewer$Viewer$avatar {
  CopyWith$Query$Viewer$Viewer$avatar<Query$Viewer$Viewer$avatar>
  get copyWith => CopyWith$Query$Viewer$Viewer$avatar(this, (i) => i);
}

abstract class CopyWith$Query$Viewer$Viewer$avatar<TRes> {
  factory CopyWith$Query$Viewer$Viewer$avatar(
    Query$Viewer$Viewer$avatar instance,
    TRes Function(Query$Viewer$Viewer$avatar) then,
  ) = _CopyWithImpl$Query$Viewer$Viewer$avatar;

  factory CopyWith$Query$Viewer$Viewer$avatar.stub(TRes res) =
      _CopyWithStubImpl$Query$Viewer$Viewer$avatar;

  TRes call({String? medium});
}

class _CopyWithImpl$Query$Viewer$Viewer$avatar<TRes>
    implements CopyWith$Query$Viewer$Viewer$avatar<TRes> {
  _CopyWithImpl$Query$Viewer$Viewer$avatar(this._instance, this._then);

  final Query$Viewer$Viewer$avatar _instance;

  final TRes Function(Query$Viewer$Viewer$avatar) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? medium = _undefined}) => _then(
    Query$Viewer$Viewer$avatar(
      medium: medium == _undefined ? _instance.medium : (medium as String?),
    ),
  );
}

class _CopyWithStubImpl$Query$Viewer$Viewer$avatar<TRes>
    implements CopyWith$Query$Viewer$Viewer$avatar<TRes> {
  _CopyWithStubImpl$Query$Viewer$Viewer$avatar(this._res);

  TRes _res;

  call({String? medium}) => _res;
}
