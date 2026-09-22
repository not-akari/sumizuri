import 'fragments.graphql.dart';

import 'package:gql/ast.dart';

import 'schema.graphql.dart';

class Variables$Query$MediaWithEntry {
  factory Variables$Query$MediaWithEntry({required int id}) =>
      Variables$Query$MediaWithEntry._({r'id': id});

  Variables$Query$MediaWithEntry._(this._$data);

  factory Variables$Query$MediaWithEntry.fromJson(Map<String, dynamic> data) {
    final result$data = <String, dynamic>{};
    final l$id = data['id'];
    result$data['id'] = (l$id as int);
    return Variables$Query$MediaWithEntry._(result$data);
  }

  Map<String, dynamic> _$data;

  int get id => (_$data['id'] as int);

  Map<String, dynamic> toJson() {
    final result$data = <String, dynamic>{};
    final l$id = id;
    result$data['id'] = l$id;
    return result$data;
  }

  CopyWith$Variables$Query$MediaWithEntry<Variables$Query$MediaWithEntry>
  get copyWith => CopyWith$Variables$Query$MediaWithEntry(this, (i) => i);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Variables$Query$MediaWithEntry ||
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

abstract class CopyWith$Variables$Query$MediaWithEntry<TRes> {
  factory CopyWith$Variables$Query$MediaWithEntry(
    Variables$Query$MediaWithEntry instance,
    TRes Function(Variables$Query$MediaWithEntry) then,
  ) = _CopyWithImpl$Variables$Query$MediaWithEntry;

  factory CopyWith$Variables$Query$MediaWithEntry.stub(TRes res) =
      _CopyWithStubImpl$Variables$Query$MediaWithEntry;

  TRes call({int? id});
}

class _CopyWithImpl$Variables$Query$MediaWithEntry<TRes>
    implements CopyWith$Variables$Query$MediaWithEntry<TRes> {
  _CopyWithImpl$Variables$Query$MediaWithEntry(this._instance, this._then);

  final Variables$Query$MediaWithEntry _instance;

  final TRes Function(Variables$Query$MediaWithEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? id = _undefined}) => _then(
    Variables$Query$MediaWithEntry._({
      ..._instance._$data,
      if (id != _undefined && id != null) 'id': (id as int),
    }),
  );
}

class _CopyWithStubImpl$Variables$Query$MediaWithEntry<TRes>
    implements CopyWith$Variables$Query$MediaWithEntry<TRes> {
  _CopyWithStubImpl$Variables$Query$MediaWithEntry(this._res);

  TRes _res;

  call({int? id}) => _res;
}

class Query$MediaWithEntry {
  Query$MediaWithEntry({this.Media});

  factory Query$MediaWithEntry.fromJson(Map<String, dynamic> json) {
    final l$Media = json['Media'];
    return Query$MediaWithEntry(
      Media: l$Media == null
          ? null
          : Query$MediaWithEntry$Media.fromJson(
              (l$Media as Map<String, dynamic>),
            ),
    );
  }

  final Query$MediaWithEntry$Media? Media;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$Media = Media;
    _resultData['Media'] = l$Media?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$Media = Media;
    return Object.hashAll([l$Media]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaWithEntry || runtimeType != other.runtimeType) {
      return false;
    }
    final l$Media = Media;
    final lOther$Media = other.Media;
    if (l$Media != lOther$Media) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaWithEntry on Query$MediaWithEntry {
  CopyWith$Query$MediaWithEntry<Query$MediaWithEntry> get copyWith =>
      CopyWith$Query$MediaWithEntry(this, (i) => i);
}

abstract class CopyWith$Query$MediaWithEntry<TRes> {
  factory CopyWith$Query$MediaWithEntry(
    Query$MediaWithEntry instance,
    TRes Function(Query$MediaWithEntry) then,
  ) = _CopyWithImpl$Query$MediaWithEntry;

  factory CopyWith$Query$MediaWithEntry.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaWithEntry;

  TRes call({Query$MediaWithEntry$Media? Media});
  CopyWith$Query$MediaWithEntry$Media<TRes> get Media;
}

class _CopyWithImpl$Query$MediaWithEntry<TRes>
    implements CopyWith$Query$MediaWithEntry<TRes> {
  _CopyWithImpl$Query$MediaWithEntry(this._instance, this._then);

  final Query$MediaWithEntry _instance;

  final TRes Function(Query$MediaWithEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? Media = _undefined}) => _then(
    Query$MediaWithEntry(
      Media: Media == _undefined
          ? _instance.Media
          : (Media as Query$MediaWithEntry$Media?),
    ),
  );

  CopyWith$Query$MediaWithEntry$Media<TRes> get Media {
    final local$Media = _instance.Media;
    return local$Media == null
        ? CopyWith$Query$MediaWithEntry$Media.stub(_then(_instance))
        : CopyWith$Query$MediaWithEntry$Media(
            local$Media,
            (e) => call(Media: e),
          );
  }
}

class _CopyWithStubImpl$Query$MediaWithEntry<TRes>
    implements CopyWith$Query$MediaWithEntry<TRes> {
  _CopyWithStubImpl$Query$MediaWithEntry(this._res);

  TRes _res;

  call({Query$MediaWithEntry$Media? Media}) => _res;

  CopyWith$Query$MediaWithEntry$Media<TRes> get Media =>
      CopyWith$Query$MediaWithEntry$Media.stub(_res);
}

const documentNodeQueryMediaWithEntry = DocumentNode(
  definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: 'MediaWithEntry'),
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
            name: NameNode(value: 'Media'),
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
                FragmentSpreadNode(
                  name: NameNode(value: 'MediaCore'),
                  directives: [],
                ),
                FieldNode(
                  name: NameNode(value: 'mediaListEntry'),
                  alias: null,
                  arguments: [],
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
        ],
      ),
    ),
    fragmentDefinitionMediaCore,
    fragmentDefinitionListEntry,
  ],
);

class Query$MediaWithEntry$Media implements Fragment$MediaCore {
  Query$MediaWithEntry$Media({
    required this.id,
    this.type,
    this.format,
    this.status,
    this.title,
    this.coverImage,
    this.chapters,
    this.volumes,
    this.episodes,
    this.startDate,
    this.siteUrl,
    this.isAdult,
    this.synonyms,
    this.mediaListEntry,
  });

  factory Query$MediaWithEntry$Media.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$type = json['type'];
    final l$format = json['format'];
    final l$status = json['status'];
    final l$title = json['title'];
    final l$coverImage = json['coverImage'];
    final l$chapters = json['chapters'];
    final l$volumes = json['volumes'];
    final l$episodes = json['episodes'];
    final l$startDate = json['startDate'];
    final l$siteUrl = json['siteUrl'];
    final l$isAdult = json['isAdult'];
    final l$synonyms = json['synonyms'];
    final l$mediaListEntry = json['mediaListEntry'];
    return Query$MediaWithEntry$Media(
      id: (l$id as int),
      type: l$type == null ? null : fromJson$Enum$MediaType((l$type as String)),
      format: l$format == null
          ? null
          : fromJson$Enum$MediaFormat((l$format as String)),
      status: l$status == null
          ? null
          : fromJson$Enum$MediaStatus((l$status as String)),
      title: l$title == null
          ? null
          : Query$MediaWithEntry$Media$title.fromJson(
              (l$title as Map<String, dynamic>),
            ),
      coverImage: l$coverImage == null
          ? null
          : Query$MediaWithEntry$Media$coverImage.fromJson(
              (l$coverImage as Map<String, dynamic>),
            ),
      chapters: (l$chapters as int?),
      volumes: (l$volumes as int?),
      episodes: (l$episodes as int?),
      startDate: l$startDate == null
          ? null
          : Query$MediaWithEntry$Media$startDate.fromJson(
              (l$startDate as Map<String, dynamic>),
            ),
      siteUrl: (l$siteUrl as String?),
      isAdult: (l$isAdult as bool?),
      synonyms: (l$synonyms as List<dynamic>?)
          ?.map((e) => (e as String?))
          .toList(),
      mediaListEntry: l$mediaListEntry == null
          ? null
          : Fragment$ListEntry.fromJson(
              (l$mediaListEntry as Map<String, dynamic>),
            ),
    );
  }

  final int id;

  final Enum$MediaType? type;

  final Enum$MediaFormat? format;

  final Enum$MediaStatus? status;

  final Query$MediaWithEntry$Media$title? title;

  final Query$MediaWithEntry$Media$coverImage? coverImage;

  final int? chapters;

  final int? volumes;

  final int? episodes;

  final Query$MediaWithEntry$Media$startDate? startDate;

  final String? siteUrl;

  final bool? isAdult;

  final List<String?>? synonyms;

  final Fragment$ListEntry? mediaListEntry;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$type = type;
    _resultData['type'] = l$type == null ? null : toJson$Enum$MediaType(l$type);
    final l$format = format;
    _resultData['format'] = l$format == null
        ? null
        : toJson$Enum$MediaFormat(l$format);
    final l$status = status;
    _resultData['status'] = l$status == null
        ? null
        : toJson$Enum$MediaStatus(l$status);
    final l$title = title;
    _resultData['title'] = l$title?.toJson();
    final l$coverImage = coverImage;
    _resultData['coverImage'] = l$coverImage?.toJson();
    final l$chapters = chapters;
    _resultData['chapters'] = l$chapters;
    final l$volumes = volumes;
    _resultData['volumes'] = l$volumes;
    final l$episodes = episodes;
    _resultData['episodes'] = l$episodes;
    final l$startDate = startDate;
    _resultData['startDate'] = l$startDate?.toJson();
    final l$siteUrl = siteUrl;
    _resultData['siteUrl'] = l$siteUrl;
    final l$isAdult = isAdult;
    _resultData['isAdult'] = l$isAdult;
    final l$synonyms = synonyms;
    _resultData['synonyms'] = l$synonyms?.map((e) => e).toList();
    final l$mediaListEntry = mediaListEntry;
    _resultData['mediaListEntry'] = l$mediaListEntry?.toJson();
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$type = type;
    final l$format = format;
    final l$status = status;
    final l$title = title;
    final l$coverImage = coverImage;
    final l$chapters = chapters;
    final l$volumes = volumes;
    final l$episodes = episodes;
    final l$startDate = startDate;
    final l$siteUrl = siteUrl;
    final l$isAdult = isAdult;
    final l$synonyms = synonyms;
    final l$mediaListEntry = mediaListEntry;
    return Object.hashAll([
      l$id,
      l$type,
      l$format,
      l$status,
      l$title,
      l$coverImage,
      l$chapters,
      l$volumes,
      l$episodes,
      l$startDate,
      l$siteUrl,
      l$isAdult,
      l$synonyms == null ? null : Object.hashAll(l$synonyms.map((v) => v)),
      l$mediaListEntry,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaWithEntry$Media ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$type = type;
    final lOther$type = other.type;
    if (l$type != lOther$type) {
      return false;
    }
    final l$format = format;
    final lOther$format = other.format;
    if (l$format != lOther$format) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$title = title;
    final lOther$title = other.title;
    if (l$title != lOther$title) {
      return false;
    }
    final l$coverImage = coverImage;
    final lOther$coverImage = other.coverImage;
    if (l$coverImage != lOther$coverImage) {
      return false;
    }
    final l$chapters = chapters;
    final lOther$chapters = other.chapters;
    if (l$chapters != lOther$chapters) {
      return false;
    }
    final l$volumes = volumes;
    final lOther$volumes = other.volumes;
    if (l$volumes != lOther$volumes) {
      return false;
    }
    final l$episodes = episodes;
    final lOther$episodes = other.episodes;
    if (l$episodes != lOther$episodes) {
      return false;
    }
    final l$startDate = startDate;
    final lOther$startDate = other.startDate;
    if (l$startDate != lOther$startDate) {
      return false;
    }
    final l$siteUrl = siteUrl;
    final lOther$siteUrl = other.siteUrl;
    if (l$siteUrl != lOther$siteUrl) {
      return false;
    }
    final l$isAdult = isAdult;
    final lOther$isAdult = other.isAdult;
    if (l$isAdult != lOther$isAdult) {
      return false;
    }
    final l$synonyms = synonyms;
    final lOther$synonyms = other.synonyms;
    if (l$synonyms != null && lOther$synonyms != null) {
      if (l$synonyms.length != lOther$synonyms.length) {
        return false;
      }
      for (int i = 0; i < l$synonyms.length; i++) {
        final l$synonyms$entry = l$synonyms[i];
        final lOther$synonyms$entry = lOther$synonyms[i];
        if (l$synonyms$entry != lOther$synonyms$entry) {
          return false;
        }
      }
    } else if (l$synonyms != lOther$synonyms) {
      return false;
    }
    final l$mediaListEntry = mediaListEntry;
    final lOther$mediaListEntry = other.mediaListEntry;
    if (l$mediaListEntry != lOther$mediaListEntry) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaWithEntry$Media
    on Query$MediaWithEntry$Media {
  CopyWith$Query$MediaWithEntry$Media<Query$MediaWithEntry$Media>
  get copyWith => CopyWith$Query$MediaWithEntry$Media(this, (i) => i);
}

abstract class CopyWith$Query$MediaWithEntry$Media<TRes> {
  factory CopyWith$Query$MediaWithEntry$Media(
    Query$MediaWithEntry$Media instance,
    TRes Function(Query$MediaWithEntry$Media) then,
  ) = _CopyWithImpl$Query$MediaWithEntry$Media;

  factory CopyWith$Query$MediaWithEntry$Media.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaWithEntry$Media;

  TRes call({
    int? id,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaStatus? status,
    Query$MediaWithEntry$Media$title? title,
    Query$MediaWithEntry$Media$coverImage? coverImage,
    int? chapters,
    int? volumes,
    int? episodes,
    Query$MediaWithEntry$Media$startDate? startDate,
    String? siteUrl,
    bool? isAdult,
    List<String?>? synonyms,
    Fragment$ListEntry? mediaListEntry,
  });
  CopyWith$Query$MediaWithEntry$Media$title<TRes> get title;
  CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> get coverImage;
  CopyWith$Query$MediaWithEntry$Media$startDate<TRes> get startDate;
  CopyWith$Fragment$ListEntry<TRes> get mediaListEntry;
}

class _CopyWithImpl$Query$MediaWithEntry$Media<TRes>
    implements CopyWith$Query$MediaWithEntry$Media<TRes> {
  _CopyWithImpl$Query$MediaWithEntry$Media(this._instance, this._then);

  final Query$MediaWithEntry$Media _instance;

  final TRes Function(Query$MediaWithEntry$Media) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? type = _undefined,
    Object? format = _undefined,
    Object? status = _undefined,
    Object? title = _undefined,
    Object? coverImage = _undefined,
    Object? chapters = _undefined,
    Object? volumes = _undefined,
    Object? episodes = _undefined,
    Object? startDate = _undefined,
    Object? siteUrl = _undefined,
    Object? isAdult = _undefined,
    Object? synonyms = _undefined,
    Object? mediaListEntry = _undefined,
  }) => _then(
    Query$MediaWithEntry$Media(
      id: id == _undefined || id == null ? _instance.id : (id as int),
      type: type == _undefined ? _instance.type : (type as Enum$MediaType?),
      format: format == _undefined
          ? _instance.format
          : (format as Enum$MediaFormat?),
      status: status == _undefined
          ? _instance.status
          : (status as Enum$MediaStatus?),
      title: title == _undefined
          ? _instance.title
          : (title as Query$MediaWithEntry$Media$title?),
      coverImage: coverImage == _undefined
          ? _instance.coverImage
          : (coverImage as Query$MediaWithEntry$Media$coverImage?),
      chapters: chapters == _undefined
          ? _instance.chapters
          : (chapters as int?),
      volumes: volumes == _undefined ? _instance.volumes : (volumes as int?),
      episodes: episodes == _undefined
          ? _instance.episodes
          : (episodes as int?),
      startDate: startDate == _undefined
          ? _instance.startDate
          : (startDate as Query$MediaWithEntry$Media$startDate?),
      siteUrl: siteUrl == _undefined ? _instance.siteUrl : (siteUrl as String?),
      isAdult: isAdult == _undefined ? _instance.isAdult : (isAdult as bool?),
      synonyms: synonyms == _undefined
          ? _instance.synonyms
          : (synonyms as List<String?>?),
      mediaListEntry: mediaListEntry == _undefined
          ? _instance.mediaListEntry
          : (mediaListEntry as Fragment$ListEntry?),
    ),
  );

  CopyWith$Query$MediaWithEntry$Media$title<TRes> get title {
    final local$title = _instance.title;
    return local$title == null
        ? CopyWith$Query$MediaWithEntry$Media$title.stub(_then(_instance))
        : CopyWith$Query$MediaWithEntry$Media$title(
            local$title,
            (e) => call(title: e),
          );
  }

  CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> get coverImage {
    final local$coverImage = _instance.coverImage;
    return local$coverImage == null
        ? CopyWith$Query$MediaWithEntry$Media$coverImage.stub(_then(_instance))
        : CopyWith$Query$MediaWithEntry$Media$coverImage(
            local$coverImage,
            (e) => call(coverImage: e),
          );
  }

  CopyWith$Query$MediaWithEntry$Media$startDate<TRes> get startDate {
    final local$startDate = _instance.startDate;
    return local$startDate == null
        ? CopyWith$Query$MediaWithEntry$Media$startDate.stub(_then(_instance))
        : CopyWith$Query$MediaWithEntry$Media$startDate(
            local$startDate,
            (e) => call(startDate: e),
          );
  }

  CopyWith$Fragment$ListEntry<TRes> get mediaListEntry {
    final local$mediaListEntry = _instance.mediaListEntry;
    return local$mediaListEntry == null
        ? CopyWith$Fragment$ListEntry.stub(_then(_instance))
        : CopyWith$Fragment$ListEntry(
            local$mediaListEntry,
            (e) => call(mediaListEntry: e),
          );
  }
}

class _CopyWithStubImpl$Query$MediaWithEntry$Media<TRes>
    implements CopyWith$Query$MediaWithEntry$Media<TRes> {
  _CopyWithStubImpl$Query$MediaWithEntry$Media(this._res);

  TRes _res;

  call({
    int? id,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaStatus? status,
    Query$MediaWithEntry$Media$title? title,
    Query$MediaWithEntry$Media$coverImage? coverImage,
    int? chapters,
    int? volumes,
    int? episodes,
    Query$MediaWithEntry$Media$startDate? startDate,
    String? siteUrl,
    bool? isAdult,
    List<String?>? synonyms,
    Fragment$ListEntry? mediaListEntry,
  }) => _res;

  CopyWith$Query$MediaWithEntry$Media$title<TRes> get title =>
      CopyWith$Query$MediaWithEntry$Media$title.stub(_res);

  CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> get coverImage =>
      CopyWith$Query$MediaWithEntry$Media$coverImage.stub(_res);

  CopyWith$Query$MediaWithEntry$Media$startDate<TRes> get startDate =>
      CopyWith$Query$MediaWithEntry$Media$startDate.stub(_res);

  CopyWith$Fragment$ListEntry<TRes> get mediaListEntry =>
      CopyWith$Fragment$ListEntry.stub(_res);
}

class Query$MediaWithEntry$Media$title implements Fragment$MediaCore$title {
  Query$MediaWithEntry$Media$title({this.romaji, this.english, this.native});

  factory Query$MediaWithEntry$Media$title.fromJson(Map<String, dynamic> json) {
    final l$romaji = json['romaji'];
    final l$english = json['english'];
    final l$native = json['native'];
    return Query$MediaWithEntry$Media$title(
      romaji: (l$romaji as String?),
      english: (l$english as String?),
      native: (l$native as String?),
    );
  }

  final String? romaji;

  final String? english;

  final String? native;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$romaji = romaji;
    _resultData['romaji'] = l$romaji;
    final l$english = english;
    _resultData['english'] = l$english;
    final l$native = native;
    _resultData['native'] = l$native;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$romaji = romaji;
    final l$english = english;
    final l$native = native;
    return Object.hashAll([l$romaji, l$english, l$native]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaWithEntry$Media$title ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$romaji = romaji;
    final lOther$romaji = other.romaji;
    if (l$romaji != lOther$romaji) {
      return false;
    }
    final l$english = english;
    final lOther$english = other.english;
    if (l$english != lOther$english) {
      return false;
    }
    final l$native = native;
    final lOther$native = other.native;
    if (l$native != lOther$native) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaWithEntry$Media$title
    on Query$MediaWithEntry$Media$title {
  CopyWith$Query$MediaWithEntry$Media$title<Query$MediaWithEntry$Media$title>
  get copyWith => CopyWith$Query$MediaWithEntry$Media$title(this, (i) => i);
}

abstract class CopyWith$Query$MediaWithEntry$Media$title<TRes> {
  factory CopyWith$Query$MediaWithEntry$Media$title(
    Query$MediaWithEntry$Media$title instance,
    TRes Function(Query$MediaWithEntry$Media$title) then,
  ) = _CopyWithImpl$Query$MediaWithEntry$Media$title;

  factory CopyWith$Query$MediaWithEntry$Media$title.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaWithEntry$Media$title;

  TRes call({String? romaji, String? english, String? native});
}

class _CopyWithImpl$Query$MediaWithEntry$Media$title<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$title<TRes> {
  _CopyWithImpl$Query$MediaWithEntry$Media$title(this._instance, this._then);

  final Query$MediaWithEntry$Media$title _instance;

  final TRes Function(Query$MediaWithEntry$Media$title) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? romaji = _undefined,
    Object? english = _undefined,
    Object? native = _undefined,
  }) => _then(
    Query$MediaWithEntry$Media$title(
      romaji: romaji == _undefined ? _instance.romaji : (romaji as String?),
      english: english == _undefined ? _instance.english : (english as String?),
      native: native == _undefined ? _instance.native : (native as String?),
    ),
  );
}

class _CopyWithStubImpl$Query$MediaWithEntry$Media$title<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$title<TRes> {
  _CopyWithStubImpl$Query$MediaWithEntry$Media$title(this._res);

  TRes _res;

  call({String? romaji, String? english, String? native}) => _res;
}

class Query$MediaWithEntry$Media$coverImage
    implements Fragment$MediaCore$coverImage {
  Query$MediaWithEntry$Media$coverImage({this.large, this.medium});

  factory Query$MediaWithEntry$Media$coverImage.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$large = json['large'];
    final l$medium = json['medium'];
    return Query$MediaWithEntry$Media$coverImage(
      large: (l$large as String?),
      medium: (l$medium as String?),
    );
  }

  final String? large;

  final String? medium;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$large = large;
    _resultData['large'] = l$large;
    final l$medium = medium;
    _resultData['medium'] = l$medium;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$large = large;
    final l$medium = medium;
    return Object.hashAll([l$large, l$medium]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaWithEntry$Media$coverImage ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$large = large;
    final lOther$large = other.large;
    if (l$large != lOther$large) {
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

extension UtilityExtension$Query$MediaWithEntry$Media$coverImage
    on Query$MediaWithEntry$Media$coverImage {
  CopyWith$Query$MediaWithEntry$Media$coverImage<
    Query$MediaWithEntry$Media$coverImage
  >
  get copyWith =>
      CopyWith$Query$MediaWithEntry$Media$coverImage(this, (i) => i);
}

abstract class CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> {
  factory CopyWith$Query$MediaWithEntry$Media$coverImage(
    Query$MediaWithEntry$Media$coverImage instance,
    TRes Function(Query$MediaWithEntry$Media$coverImage) then,
  ) = _CopyWithImpl$Query$MediaWithEntry$Media$coverImage;

  factory CopyWith$Query$MediaWithEntry$Media$coverImage.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaWithEntry$Media$coverImage;

  TRes call({String? large, String? medium});
}

class _CopyWithImpl$Query$MediaWithEntry$Media$coverImage<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> {
  _CopyWithImpl$Query$MediaWithEntry$Media$coverImage(
    this._instance,
    this._then,
  );

  final Query$MediaWithEntry$Media$coverImage _instance;

  final TRes Function(Query$MediaWithEntry$Media$coverImage) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? large = _undefined, Object? medium = _undefined}) => _then(
    Query$MediaWithEntry$Media$coverImage(
      large: large == _undefined ? _instance.large : (large as String?),
      medium: medium == _undefined ? _instance.medium : (medium as String?),
    ),
  );
}

class _CopyWithStubImpl$Query$MediaWithEntry$Media$coverImage<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$coverImage<TRes> {
  _CopyWithStubImpl$Query$MediaWithEntry$Media$coverImage(this._res);

  TRes _res;

  call({String? large, String? medium}) => _res;
}

class Query$MediaWithEntry$Media$startDate
    implements Fragment$MediaCore$startDate {
  Query$MediaWithEntry$Media$startDate({this.year});

  factory Query$MediaWithEntry$Media$startDate.fromJson(
    Map<String, dynamic> json,
  ) {
    final l$year = json['year'];
    return Query$MediaWithEntry$Media$startDate(year: (l$year as int?));
  }

  final int? year;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$year = year;
    _resultData['year'] = l$year;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$year = year;
    return Object.hashAll([l$year]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Query$MediaWithEntry$Media$startDate ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$year = year;
    final lOther$year = other.year;
    if (l$year != lOther$year) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Query$MediaWithEntry$Media$startDate
    on Query$MediaWithEntry$Media$startDate {
  CopyWith$Query$MediaWithEntry$Media$startDate<
    Query$MediaWithEntry$Media$startDate
  >
  get copyWith => CopyWith$Query$MediaWithEntry$Media$startDate(this, (i) => i);
}

abstract class CopyWith$Query$MediaWithEntry$Media$startDate<TRes> {
  factory CopyWith$Query$MediaWithEntry$Media$startDate(
    Query$MediaWithEntry$Media$startDate instance,
    TRes Function(Query$MediaWithEntry$Media$startDate) then,
  ) = _CopyWithImpl$Query$MediaWithEntry$Media$startDate;

  factory CopyWith$Query$MediaWithEntry$Media$startDate.stub(TRes res) =
      _CopyWithStubImpl$Query$MediaWithEntry$Media$startDate;

  TRes call({int? year});
}

class _CopyWithImpl$Query$MediaWithEntry$Media$startDate<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$startDate<TRes> {
  _CopyWithImpl$Query$MediaWithEntry$Media$startDate(
    this._instance,
    this._then,
  );

  final Query$MediaWithEntry$Media$startDate _instance;

  final TRes Function(Query$MediaWithEntry$Media$startDate) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? year = _undefined}) => _then(
    Query$MediaWithEntry$Media$startDate(
      year: year == _undefined ? _instance.year : (year as int?),
    ),
  );
}

class _CopyWithStubImpl$Query$MediaWithEntry$Media$startDate<TRes>
    implements CopyWith$Query$MediaWithEntry$Media$startDate<TRes> {
  _CopyWithStubImpl$Query$MediaWithEntry$Media$startDate(this._res);

  TRes _res;

  call({int? year}) => _res;
}
