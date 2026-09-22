import 'fragments.graphql.dart';

import 'package:gql/ast.dart';

import 'schema.graphql.dart';

class Variables$Query$SearchMedia {
  factory Variables$Query$SearchMedia({
    required String search,
    required Enum$MediaType type,
    Enum$MediaFormat? format,
    Enum$MediaFormat? formatNot,
    int? page,
    int? perPage,
  }) => Variables$Query$SearchMedia._({
    r'search': search,
    r'type': type,
    if (format != null) r'format': format,
    if (formatNot != null) r'formatNot': formatNot,
    if (page != null) r'page': page,
    if (perPage != null) r'perPage': perPage,
  });

  Variables$Query$SearchMedia._(this._$data);

  factory Variables$Query$SearchMedia.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$search = data['search'];
    result$data['search'] = (l$search as String);
    final l$type = data['type'];
    result$data['type'] = fromJson$Enum$MediaType((l$type as String));
    if (data.containsKey('format')) {
      final l$format = data['format'];
      result$data['format'] = l$format == null
          ? null
          : fromJson$Enum$MediaFormat((l$format as String));
    }
    if (data.containsKey('formatNot')) {
      final l$formatNot = data['formatNot'];
      result$data['formatNot'] = l$formatNot == null
          ? null
          : fromJson$Enum$MediaFormat((l$formatNot as String));
    }
    if (data.containsKey('page')) {
      final l$page = data['page'];
      result$data['page'] = (l$page as int?);
    }
    if (data.containsKey('perPage')) {
      final l$perPage = data['perPage'];
      result$data['perPage'] = (l$perPage as int?);
    }
    return Variables$Query$SearchMedia._(result$data);
  }

  Map<String, dynamic> _$data;

  String get search => (_$data['search'] as String);

  Enum$MediaType get type => (_$data['type'] as Enum$MediaType);

  Enum$MediaFormat? get format => (_$data['format'] as Enum$MediaFormat?);

  Enum$MediaFormat? get formatNot => (_$data['formatNot'] as Enum$MediaFormat?);

  int? get page => (_$data['page'] as int?);

  int? get perPage => (_$data['perPage'] as int?);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$search = search;
    result$data['search'] = l$search;
    final l$type = type;
    result$data['type'] = toJson$Enum$MediaType(l$type);
    if (_$data.containsKey('format')) {
      final l$format = format;
      result$data['format'] = l$format == null
          ? null
          : toJson$Enum$MediaFormat(l$format);
    }
    if (_$data.containsKey('formatNot')) {
      final l$formatNot = formatNot;
      result$data['formatNot'] = l$formatNot == null
          ? null
          : toJson$Enum$MediaFormat(l$formatNot);
    }
    if (_$data.containsKey('page')) {
      final l$page = page;
      result$data['page'] = l$page;
    }
    if (_$data.containsKey('perPage')) {
      final l$perPage = perPage;
      result$data['perPage'] = l$perPage;
    }
    return result$data;
  }

  CopyWith$Variables$Query$SearchMedia<Variables$Query$SearchMedia>
  get copyWith => CopyWith$Variables$Query$SearchMedia(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$SearchMedia ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$search = search;
    final lOther$search = other.search;
    if (l$search != lOther$search) {
      return false;
    }
    final l$type = type;
    final lOther$type = other.type;
    if (l$type != lOther$type) {
      return false;
    }
    final l$format = format;
    final lOther$format = other.format;
    if (_$data.containsKey('format') != other._$data.containsKey('format')) {
      return false;
    }
    if (l$format != lOther$format) {
      return false;
    }
    final l$formatNot = formatNot;
    final lOther$formatNot = other.formatNot;
    if (_$data.containsKey('formatNot') !=
        other._$data.containsKey('formatNot')) {
      return false;
    }
    if (l$formatNot != lOther$formatNot) {
      return false;
    }
    final l$page = page;
    final lOther$page = other.page;
    if (_$data.containsKey('page') != other._$data.containsKey('page')) {
      return false;
    }
    if (l$page != lOther$page) {
      return false;
    }
    final l$perPage = perPage;
    final lOther$perPage = other.perPage;
    if (_$data.containsKey('perPage') != other._$data.containsKey('perPage')) {
      return false;
    }
    if (l$perPage != lOther$perPage) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final l$search = search;
    final l$type = type;
    final l$format = format;
    final l$formatNot = formatNot;
    final l$page = page;
    final l$perPage = perPage;
    return Object.hashAll([
      l$search,
      l$type,
      _$data.containsKey('format') ? l$format : const {},
      _$data.containsKey('formatNot') ? l$formatNot : const {},
      _$data.containsKey('page') ? l$page : const {},
      _$data.containsKey('perPage') ? l$perPage : const {},
    ]);
  }
}

abstract class CopyWith$Variables$Query$SearchMedia<TRes> {
  factory CopyWith$Variables$Query$SearchMedia(
    Variables$Query$SearchMedia instance,
    TRes Function(Variables$Query$SearchMedia) then,
  ) = _CopyWithImpl$Variables$Query$SearchMedia;

  factory CopyWith$Variables$Query$SearchMedia.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$SearchMedia;

  TRes call({
    String? search,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaFormat? formatNot,
    int? page,
    int? perPage,
  });
}

class _CopyWithImpl$Variables$Query$SearchMedia<TRes>
    implements CopyWith$Variables$Query$SearchMedia<TRes> {
  _CopyWithImpl$Variables$Query$SearchMedia(this._instance, this._then);

  final Variables$Query$SearchMedia _instance;

  final TRes Function(Variables$Query$SearchMedia) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? search = _undefined,
    Object? type = _undefined,
    Object? format = _undefined,
    Object? formatNot = _undefined,
    Object? page = _undefined,
    Object? perPage = _undefined,
  }) => _then(
    Variables$Query$SearchMedia._({
      ..._instance._$data,
      if (search != _undefined && search != null) 'search': (search as String),
      if (type != _undefined && type != null) 'type': (type as Enum$MediaType),
      if (format != _undefined) 'format': (format as Enum$MediaFormat?),
      if (formatNot != _undefined)
        'formatNot': (formatNot as Enum$MediaFormat?),
      if (page != _undefined) 'page': (page as int?),
      if (perPage != _undefined) 'perPage': (perPage as int?),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$SearchMedia<TRes>
    implements CopyWith$Variables$Query$SearchMedia<TRes> {
  _CopyWithStubImpl$Variables$Query$SearchMedia(this._res);

  TRes _res;

  call({
    String? search,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaFormat? formatNot,
    int? page,
    int? perPage,
  }) => _res;
}

class Query$SearchMedia {
  Query$SearchMedia({this.Page});

  factory Query$SearchMedia.fromJson(Map<String, dynamic> json) {
    final l$Page = json['Page'];
    return Query$SearchMedia(
      Page: l$Page == null
          ? null
          : Query$SearchMedia$Page.fromJson((l$Page as Map<String, dynamic>)),
    );
  }

  final Query$SearchMedia$Page? Page;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$Page = Page;
    _resultData['Page'] = l$Page?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$Page = Page;
    return Object.hashAll([l$Page]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SearchMedia || runtimeType != other.runtimeType) {
      return false;
    }
    final l$Page = Page;
    final lOther$Page = other.Page;
    if (l$Page != lOther$Page) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SearchMedia on Query$SearchMedia {
  CopyWith$Query$SearchMedia<Query$SearchMedia> get copyWith =>
      CopyWith$Query$SearchMedia(this, (i) => i);
}

abstract class CopyWith$Query$SearchMedia<TRes> {
  factory CopyWith$Query$SearchMedia(
    Query$SearchMedia instance,
    TRes Function(Query$SearchMedia) then,
  ) = _CopyWithImpl$Query$SearchMedia;

  factory CopyWith$Query$SearchMedia.stub(TRes res) =
      _CopyWithStubImpl$Query$SearchMedia;

  TRes call({Query$SearchMedia$Page? Page});
  CopyWith$Query$SearchMedia$Page<TRes> get Page;
}

class _CopyWithImpl$Query$SearchMedia<TRes>
    implements CopyWith$Query$SearchMedia<TRes> {
  _CopyWithImpl$Query$SearchMedia(this._instance, this._then);

  final Query$SearchMedia _instance;

  final TRes Function(Query$SearchMedia) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? Page = _undefined}) => _then(
    Query$SearchMedia(
      Page: Page == _undefined
          ? _instance.Page
          : (Page as Query$SearchMedia$Page?),
    ),
  );

  CopyWith$Query$SearchMedia$Page<TRes> get Page {
    final local$Page = _instance.Page;
    return local$Page == null
        ? CopyWith$Query$SearchMedia$Page.stub(_then(_instance))
        : CopyWith$Query$SearchMedia$Page(local$Page, (e) => call(Page: e));
  }
}

class _CopyWithStubImpl$Query$SearchMedia<TRes>
    implements CopyWith$Query$SearchMedia<TRes> {
  _CopyWithStubImpl$Query$SearchMedia(this._res);

  TRes _res;

  call({Query$SearchMedia$Page? Page}) => _res;

  CopyWith$Query$SearchMedia$Page<TRes> get Page =>
      CopyWith$Query$SearchMedia$Page.stub(_res);
}

const documentNodeQuerySearchMedia = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'SearchMedia'),
      variableDefinitions: [
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'search')),
          type: NamedTypeNode(name: NameNode(value: 'String'), isNonNull: true),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'type')),
          type: NamedTypeNode(
            name: NameNode(value: 'MediaType'),
            isNonNull: true,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'format')),
          type: NamedTypeNode(
            name: NameNode(value: 'MediaFormat'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'formatNot')),
          type: NamedTypeNode(
            name: NameNode(value: 'MediaFormat'),
            isNonNull: false,
          ),
          defaultValue: DefaultValueNode(value: null),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'page')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: IntValueNode(value: '1')),
          directives: [],
        ),
        VariableDefinitionNode(
          variable: VariableNode(name: NameNode(value: 'perPage')),
          type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: false),
          defaultValue: DefaultValueNode(value: IntValueNode(value: '20')),
          directives: [],
        ),
      ],
      directives: [],
      selectionSet: SelectionSetNode(
        selections: [
          FieldNode(
            name: NameNode(value: 'Page'),
            alias: null,
            arguments: [
              ArgumentNode(
                name: NameNode(value: 'page'),
                value: VariableNode(name: NameNode(value: 'page')),
              ),
              ArgumentNode(
                name: NameNode(value: 'perPage'),
                value: VariableNode(name: NameNode(value: 'perPage')),
              ),
            ],
            directives: [],
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'pageInfo'),
                  alias: null,
                  arguments: [],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(
                        name: NameNode(value: 'hasNextPage'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ],
                  ),
                ),
                FieldNode(
                  name: NameNode(value: 'media'),
                  alias: null,
                  arguments: [
                    ArgumentNode(
                      name: NameNode(value: 'search'),
                      value: VariableNode(name: NameNode(value: 'search')),
                    ),
                    ArgumentNode(
                      name: NameNode(value: 'type'),
                      value: VariableNode(name: NameNode(value: 'type')),
                    ),
                    ArgumentNode(
                      name: NameNode(value: 'format'),
                      value: VariableNode(name: NameNode(value: 'format')),
                    ),
                    ArgumentNode(
                      name: NameNode(value: 'format_not'),
                      value: VariableNode(name: NameNode(value: 'formatNot')),
                    ),
                    ArgumentNode(
                      name: NameNode(value: 'sort'),
                      value: EnumValueNode(
                        name: NameNode(value: 'SEARCH_MATCH'),
                      ),
                    ),
                  ],
                  directives: [],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FragmentSpreadNode(
                        name: NameNode(value: 'MediaCore'),
                        directives: [],
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
    fragmentDefinitionMediaCore,
  ],
);

class Query$SearchMedia$Page {
  Query$SearchMedia$Page({this.pageInfo, this.media});

  factory Query$SearchMedia$Page.fromJson(Map<String, dynamic> json) {
    final l$pageInfo = json['pageInfo'];
    final l$media = json['media'];
    return Query$SearchMedia$Page(
      pageInfo: l$pageInfo == null
          ? null
          : Query$SearchMedia$Page$pageInfo.fromJson(
              (l$pageInfo as Map<String, dynamic>),
            ),
      media: (l$media as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : Fragment$MediaCore.fromJson((e as Map<String, dynamic>)),
          )
          .toList(),
    );
  }

  final Query$SearchMedia$Page$pageInfo? pageInfo;

  final List<Fragment$MediaCore?>? media;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$pageInfo = pageInfo;
    _resultData['pageInfo'] = l$pageInfo?.toJson();
    final l$media = media;
    _resultData['media'] = l$media?.map((e) => e?.toJson()).toList();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$pageInfo = pageInfo;
    final l$media = media;
    return Object.hashAll([
      l$pageInfo,
      l$media == null ? null : Object.hashAll(l$media.map((v) => v)),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SearchMedia$Page || runtimeType != other.runtimeType) {
      return false;
    }
    final l$pageInfo = pageInfo;
    final lOther$pageInfo = other.pageInfo;
    if (l$pageInfo != lOther$pageInfo) {
      return false;
    }
    final l$media = media;
    final lOther$media = other.media;
    if (l$media != null && lOther$media != null) {
      if (l$media.length != lOther$media.length) {
        return false;
      }
      for (int i = 0; i < l$media.length; i++) {
        final l$media$entry = l$media[i];
        final lOther$media$entry = lOther$media[i];
        if (l$media$entry != lOther$media$entry) {
          return false;
        }
      }
    } else if (l$media != lOther$media) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SearchMedia$Page on Query$SearchMedia$Page {
  CopyWith$Query$SearchMedia$Page<Query$SearchMedia$Page> get copyWith =>
      CopyWith$Query$SearchMedia$Page(this, (i) => i);
}

abstract class CopyWith$Query$SearchMedia$Page<TRes> {
  factory CopyWith$Query$SearchMedia$Page(
    Query$SearchMedia$Page instance,
    TRes Function(Query$SearchMedia$Page) then,
  ) = _CopyWithImpl$Query$SearchMedia$Page;

  factory CopyWith$Query$SearchMedia$Page.stub(TRes res) =
      _CopyWithStubImpl$Query$SearchMedia$Page;

  TRes call({
    Query$SearchMedia$Page$pageInfo? pageInfo,
    List<Fragment$MediaCore?>? media,
  });
  CopyWith$Query$SearchMedia$Page$pageInfo<TRes> get pageInfo;
  TRes media(
    Iterable<Fragment$MediaCore?>? Function(
      Iterable<CopyWith$Fragment$MediaCore<Fragment$MediaCore>?>?,
    )
    _fn,
  );
}

class _CopyWithImpl$Query$SearchMedia$Page<TRes>
    implements CopyWith$Query$SearchMedia$Page<TRes> {
  _CopyWithImpl$Query$SearchMedia$Page(this._instance, this._then);

  final Query$SearchMedia$Page _instance;

  final TRes Function(Query$SearchMedia$Page) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? pageInfo = _undefined, Object? media = _undefined}) =>
      _then(
        Query$SearchMedia$Page(
          pageInfo: pageInfo == _undefined
              ? _instance.pageInfo
              : (pageInfo as Query$SearchMedia$Page$pageInfo?),
          media: media == _undefined
              ? _instance.media
              : (media as List<Fragment$MediaCore?>?),
        ),
      );

  CopyWith$Query$SearchMedia$Page$pageInfo<TRes> get pageInfo {
    final local$pageInfo = _instance.pageInfo;
    return local$pageInfo == null
        ? CopyWith$Query$SearchMedia$Page$pageInfo.stub(_then(_instance))
        : CopyWith$Query$SearchMedia$Page$pageInfo(
            local$pageInfo,
            (e) => call(pageInfo: e),
          );
  }

  TRes media(
    Iterable<Fragment$MediaCore?>? Function(
      Iterable<CopyWith$Fragment$MediaCore<Fragment$MediaCore>?>?,
    )
    _fn,
  ) => call(
    media: _fn(
      _instance.media?.map(
        (e) => e == null ? null : CopyWith$Fragment$MediaCore(e, (i) => i),
      ),
    )?.toList(),
  );
}

class _CopyWithStubImpl$Query$SearchMedia$Page<TRes>
    implements CopyWith$Query$SearchMedia$Page<TRes> {
  _CopyWithStubImpl$Query$SearchMedia$Page(this._res);

  TRes _res;

  call({
    Query$SearchMedia$Page$pageInfo? pageInfo,
    List<Fragment$MediaCore?>? media,
  }) => _res;

  CopyWith$Query$SearchMedia$Page$pageInfo<TRes> get pageInfo =>
      CopyWith$Query$SearchMedia$Page$pageInfo.stub(_res);

  media(_fn) => _res;
}

class Query$SearchMedia$Page$pageInfo {
  Query$SearchMedia$Page$pageInfo({this.hasNextPage});

  factory Query$SearchMedia$Page$pageInfo.fromJson(Map<String, dynamic> json) {
    final l$hasNextPage = json['hasNextPage'];
    return Query$SearchMedia$Page$pageInfo(
      hasNextPage: (l$hasNextPage as bool?),
    );
  }

  final bool? hasNextPage;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$hasNextPage = hasNextPage;
    _resultData['hasNextPage'] = l$hasNextPage;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$hasNextPage = hasNextPage;
    return Object.hashAll([l$hasNextPage]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$SearchMedia$Page$pageInfo ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$hasNextPage = hasNextPage;
    final lOther$hasNextPage = other.hasNextPage;
    if (l$hasNextPage != lOther$hasNextPage) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$SearchMedia$Page$pageInfo
    on Query$SearchMedia$Page$pageInfo {
  CopyWith$Query$SearchMedia$Page$pageInfo<Query$SearchMedia$Page$pageInfo>
  get copyWith => CopyWith$Query$SearchMedia$Page$pageInfo(this, (i) => i);
}

abstract class CopyWith$Query$SearchMedia$Page$pageInfo<TRes> {
  factory CopyWith$Query$SearchMedia$Page$pageInfo(
    Query$SearchMedia$Page$pageInfo instance,
    TRes Function(Query$SearchMedia$Page$pageInfo) then,
  ) = _CopyWithImpl$Query$SearchMedia$Page$pageInfo;

  factory CopyWith$Query$SearchMedia$Page$pageInfo.stub(TRes res) =
      _CopyWithStubImpl$Query$SearchMedia$Page$pageInfo;

  TRes call({bool? hasNextPage});
}

class _CopyWithImpl$Query$SearchMedia$Page$pageInfo<TRes>
    implements CopyWith$Query$SearchMedia$Page$pageInfo<TRes> {
  _CopyWithImpl$Query$SearchMedia$Page$pageInfo(this._instance, this._then);

  final Query$SearchMedia$Page$pageInfo _instance;

  final TRes Function(Query$SearchMedia$Page$pageInfo) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? hasNextPage = _undefined}) => _then(
    Query$SearchMedia$Page$pageInfo(
      hasNextPage: hasNextPage == _undefined
          ? _instance.hasNextPage
          : (hasNextPage as bool?),
    ),
  );
}

class _CopyWithStubImpl$Query$SearchMedia$Page$pageInfo<TRes>
    implements CopyWith$Query$SearchMedia$Page$pageInfo<TRes> {
  _CopyWithStubImpl$Query$SearchMedia$Page$pageInfo(this._res);

  TRes _res;

  call({bool? hasNextPage}) => _res;
}
