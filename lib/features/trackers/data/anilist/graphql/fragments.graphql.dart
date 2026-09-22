import 'package:gql/ast.dart';

import 'schema.graphql.dart';

class Fragment$MediaCore {
  Fragment$MediaCore({
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
  });

  factory Fragment$MediaCore.fromJson(Map<String, dynamic> json) {
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
    return Fragment$MediaCore(
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
          : Fragment$MediaCore$title.fromJson(
              (l$title as Map<String, dynamic>),
            ),
      coverImage: l$coverImage == null
          ? null
          : Fragment$MediaCore$coverImage.fromJson(
              (l$coverImage as Map<String, dynamic>),
            ),
      chapters: (l$chapters as int?),
      volumes: (l$volumes as int?),
      episodes: (l$episodes as int?),
      startDate: l$startDate == null
          ? null
          : Fragment$MediaCore$startDate.fromJson(
              (l$startDate as Map<String, dynamic>),
            ),
      siteUrl: (l$siteUrl as String?),
      isAdult: (l$isAdult as bool?),
      synonyms: (l$synonyms as List<dynamic>?)
          ?.map((e) => (e as String?))
          .toList(),
    );
  }

  final int id;

  final Enum$MediaType? type;

  final Enum$MediaFormat? format;

  final Enum$MediaStatus? status;

  final Fragment$MediaCore$title? title;

  final Fragment$MediaCore$coverImage? coverImage;

  final int? chapters;

  final int? volumes;

  final int? episodes;

  final Fragment$MediaCore$startDate? startDate;

  final String? siteUrl;

  final bool? isAdult;

  final List<String?>? synonyms;

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
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$MediaCore || runtimeType != other.runtimeType) {
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
    return true;
  }
}

extension UtilityExtension$Fragment$MediaCore on Fragment$MediaCore {
  CopyWith$Fragment$MediaCore<Fragment$MediaCore> get copyWith =>
      CopyWith$Fragment$MediaCore(this, (i) => i);
}

abstract class CopyWith$Fragment$MediaCore<TRes> {
  factory CopyWith$Fragment$MediaCore(
    Fragment$MediaCore instance,
    TRes Function(Fragment$MediaCore) then,
  ) = _CopyWithImpl$Fragment$MediaCore;

  factory CopyWith$Fragment$MediaCore.stub(TRes res) =
      _CopyWithStubImpl$Fragment$MediaCore;

  TRes call({
    int? id,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaStatus? status,
    Fragment$MediaCore$title? title,
    Fragment$MediaCore$coverImage? coverImage,
    int? chapters,
    int? volumes,
    int? episodes,
    Fragment$MediaCore$startDate? startDate,
    String? siteUrl,
    bool? isAdult,
    List<String?>? synonyms,
  });
  CopyWith$Fragment$MediaCore$title<TRes> get title;
  CopyWith$Fragment$MediaCore$coverImage<TRes> get coverImage;
  CopyWith$Fragment$MediaCore$startDate<TRes> get startDate;
}

class _CopyWithImpl$Fragment$MediaCore<TRes>
    implements CopyWith$Fragment$MediaCore<TRes> {
  _CopyWithImpl$Fragment$MediaCore(this._instance, this._then);

  final Fragment$MediaCore _instance;

  final TRes Function(Fragment$MediaCore) _then;

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
  }) => _then(
    Fragment$MediaCore(
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
          : (title as Fragment$MediaCore$title?),
      coverImage: coverImage == _undefined
          ? _instance.coverImage
          : (coverImage as Fragment$MediaCore$coverImage?),
      chapters: chapters == _undefined
          ? _instance.chapters
          : (chapters as int?),
      volumes: volumes == _undefined ? _instance.volumes : (volumes as int?),
      episodes: episodes == _undefined
          ? _instance.episodes
          : (episodes as int?),
      startDate: startDate == _undefined
          ? _instance.startDate
          : (startDate as Fragment$MediaCore$startDate?),
      siteUrl: siteUrl == _undefined ? _instance.siteUrl : (siteUrl as String?),
      isAdult: isAdult == _undefined ? _instance.isAdult : (isAdult as bool?),
      synonyms: synonyms == _undefined
          ? _instance.synonyms
          : (synonyms as List<String?>?),
    ),
  );

  CopyWith$Fragment$MediaCore$title<TRes> get title {
    final local$title = _instance.title;
    return local$title == null
        ? CopyWith$Fragment$MediaCore$title.stub(_then(_instance))
        : CopyWith$Fragment$MediaCore$title(local$title, (e) => call(title: e));
  }

  CopyWith$Fragment$MediaCore$coverImage<TRes> get coverImage {
    final local$coverImage = _instance.coverImage;
    return local$coverImage == null
        ? CopyWith$Fragment$MediaCore$coverImage.stub(_then(_instance))
        : CopyWith$Fragment$MediaCore$coverImage(
            local$coverImage,
            (e) => call(coverImage: e),
          );
  }

  CopyWith$Fragment$MediaCore$startDate<TRes> get startDate {
    final local$startDate = _instance.startDate;
    return local$startDate == null
        ? CopyWith$Fragment$MediaCore$startDate.stub(_then(_instance))
        : CopyWith$Fragment$MediaCore$startDate(
            local$startDate,
            (e) => call(startDate: e),
          );
  }
}

class _CopyWithStubImpl$Fragment$MediaCore<TRes>
    implements CopyWith$Fragment$MediaCore<TRes> {
  _CopyWithStubImpl$Fragment$MediaCore(this._res);

  TRes _res;

  call({
    int? id,
    Enum$MediaType? type,
    Enum$MediaFormat? format,
    Enum$MediaStatus? status,
    Fragment$MediaCore$title? title,
    Fragment$MediaCore$coverImage? coverImage,
    int? chapters,
    int? volumes,
    int? episodes,
    Fragment$MediaCore$startDate? startDate,
    String? siteUrl,
    bool? isAdult,
    List<String?>? synonyms,
  }) => _res;

  CopyWith$Fragment$MediaCore$title<TRes> get title =>
      CopyWith$Fragment$MediaCore$title.stub(_res);

  CopyWith$Fragment$MediaCore$coverImage<TRes> get coverImage =>
      CopyWith$Fragment$MediaCore$coverImage.stub(_res);

  CopyWith$Fragment$MediaCore$startDate<TRes> get startDate =>
      CopyWith$Fragment$MediaCore$startDate.stub(_res);
}

const fragmentDefinitionMediaCore = FragmentDefinitionNode(
  name: NameNode(value: 'MediaCore'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(name: NameNode(value: 'Media'), isNonNull: false),
  ),
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
        name: NameNode(value: 'type'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'format'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'status'),
        alias: null,
        arguments: [
          ArgumentNode(
            name: NameNode(value: 'version'),
            value: IntValueNode(value: '2'),
          ),
        ],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'title'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'romaji'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'english'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'native'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'coverImage'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'large'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
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
      FieldNode(
        name: NameNode(value: 'chapters'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'volumes'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'episodes'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'startDate'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'year'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'siteUrl'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'isAdult'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'synonyms'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentMediaCore = DocumentNode(
  definitions: [fragmentDefinitionMediaCore],
);

class Fragment$MediaCore$title {
  Fragment$MediaCore$title({this.romaji, this.english, this.native});

  factory Fragment$MediaCore$title.fromJson(Map<String, dynamic> json) {
    final l$romaji = json['romaji'];
    final l$english = json['english'];
    final l$native = json['native'];
    return Fragment$MediaCore$title(
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
    if (other is! Fragment$MediaCore$title ||
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

extension UtilityExtension$Fragment$MediaCore$title
    on Fragment$MediaCore$title {
  CopyWith$Fragment$MediaCore$title<Fragment$MediaCore$title> get copyWith =>
      CopyWith$Fragment$MediaCore$title(this, (i) => i);
}

abstract class CopyWith$Fragment$MediaCore$title<TRes> {
  factory CopyWith$Fragment$MediaCore$title(
    Fragment$MediaCore$title instance,
    TRes Function(Fragment$MediaCore$title) then,
  ) = _CopyWithImpl$Fragment$MediaCore$title;

  factory CopyWith$Fragment$MediaCore$title.stub(TRes res) =
      _CopyWithStubImpl$Fragment$MediaCore$title;

  TRes call({String? romaji, String? english, String? native});
}

class _CopyWithImpl$Fragment$MediaCore$title<TRes>
    implements CopyWith$Fragment$MediaCore$title<TRes> {
  _CopyWithImpl$Fragment$MediaCore$title(this._instance, this._then);

  final Fragment$MediaCore$title _instance;

  final TRes Function(Fragment$MediaCore$title) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? romaji = _undefined,
    Object? english = _undefined,
    Object? native = _undefined,
  }) => _then(
    Fragment$MediaCore$title(
      romaji: romaji == _undefined ? _instance.romaji : (romaji as String?),
      english: english == _undefined ? _instance.english : (english as String?),
      native: native == _undefined ? _instance.native : (native as String?),
    ),
  );
}

class _CopyWithStubImpl$Fragment$MediaCore$title<TRes>
    implements CopyWith$Fragment$MediaCore$title<TRes> {
  _CopyWithStubImpl$Fragment$MediaCore$title(this._res);

  TRes _res;

  call({String? romaji, String? english, String? native}) => _res;
}

class Fragment$MediaCore$coverImage {
  Fragment$MediaCore$coverImage({this.large, this.medium});

  factory Fragment$MediaCore$coverImage.fromJson(Map<String, dynamic> json) {
    final l$large = json['large'];
    final l$medium = json['medium'];
    return Fragment$MediaCore$coverImage(
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
    if (other is! Fragment$MediaCore$coverImage ||
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

extension UtilityExtension$Fragment$MediaCore$coverImage
    on Fragment$MediaCore$coverImage {
  CopyWith$Fragment$MediaCore$coverImage<Fragment$MediaCore$coverImage>
  get copyWith => CopyWith$Fragment$MediaCore$coverImage(this, (i) => i);
}

abstract class CopyWith$Fragment$MediaCore$coverImage<TRes> {
  factory CopyWith$Fragment$MediaCore$coverImage(
    Fragment$MediaCore$coverImage instance,
    TRes Function(Fragment$MediaCore$coverImage) then,
  ) = _CopyWithImpl$Fragment$MediaCore$coverImage;

  factory CopyWith$Fragment$MediaCore$coverImage.stub(TRes res) =
      _CopyWithStubImpl$Fragment$MediaCore$coverImage;

  TRes call({String? large, String? medium});
}

class _CopyWithImpl$Fragment$MediaCore$coverImage<TRes>
    implements CopyWith$Fragment$MediaCore$coverImage<TRes> {
  _CopyWithImpl$Fragment$MediaCore$coverImage(this._instance, this._then);

  final Fragment$MediaCore$coverImage _instance;

  final TRes Function(Fragment$MediaCore$coverImage) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? large = _undefined, Object? medium = _undefined}) => _then(
    Fragment$MediaCore$coverImage(
      large: large == _undefined ? _instance.large : (large as String?),
      medium: medium == _undefined ? _instance.medium : (medium as String?),
    ),
  );
}

class _CopyWithStubImpl$Fragment$MediaCore$coverImage<TRes>
    implements CopyWith$Fragment$MediaCore$coverImage<TRes> {
  _CopyWithStubImpl$Fragment$MediaCore$coverImage(this._res);

  TRes _res;

  call({String? large, String? medium}) => _res;
}

class Fragment$MediaCore$startDate {
  Fragment$MediaCore$startDate({this.year});

  factory Fragment$MediaCore$startDate.fromJson(Map<String, dynamic> json) {
    final l$year = json['year'];
    return Fragment$MediaCore$startDate(year: (l$year as int?));
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
    if (other is! Fragment$MediaCore$startDate ||
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

extension UtilityExtension$Fragment$MediaCore$startDate
    on Fragment$MediaCore$startDate {
  CopyWith$Fragment$MediaCore$startDate<Fragment$MediaCore$startDate>
  get copyWith => CopyWith$Fragment$MediaCore$startDate(this, (i) => i);
}

abstract class CopyWith$Fragment$MediaCore$startDate<TRes> {
  factory CopyWith$Fragment$MediaCore$startDate(
    Fragment$MediaCore$startDate instance,
    TRes Function(Fragment$MediaCore$startDate) then,
  ) = _CopyWithImpl$Fragment$MediaCore$startDate;

  factory CopyWith$Fragment$MediaCore$startDate.stub(TRes res) =
      _CopyWithStubImpl$Fragment$MediaCore$startDate;

  TRes call({int? year});
}

class _CopyWithImpl$Fragment$MediaCore$startDate<TRes>
    implements CopyWith$Fragment$MediaCore$startDate<TRes> {
  _CopyWithImpl$Fragment$MediaCore$startDate(this._instance, this._then);

  final Fragment$MediaCore$startDate _instance;

  final TRes Function(Fragment$MediaCore$startDate) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({Object? year = _undefined}) => _then(
    Fragment$MediaCore$startDate(
      year: year == _undefined ? _instance.year : (year as int?),
    ),
  );
}

class _CopyWithStubImpl$Fragment$MediaCore$startDate<TRes>
    implements CopyWith$Fragment$MediaCore$startDate<TRes> {
  _CopyWithStubImpl$Fragment$MediaCore$startDate(this._res);

  TRes _res;

  call({int? year}) => _res;
}

class Fragment$ListEntry {
  Fragment$ListEntry({
    required this.id,
    required this.mediaId,
    this.status,
    this.progress,
    this.progressVolumes,
    this.score,
    this.repeat,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
  });

  factory Fragment$ListEntry.fromJson(Map<String, dynamic> json) {
    final l$id = json['id'];
    final l$mediaId = json['mediaId'];
    final l$status = json['status'];
    final l$progress = json['progress'];
    final l$progressVolumes = json['progressVolumes'];
    final l$score = json['score'];
    final l$repeat = json['repeat'];
    final l$startedAt = json['startedAt'];
    final l$completedAt = json['completedAt'];
    final l$updatedAt = json['updatedAt'];
    return Fragment$ListEntry(
      id: (l$id as int),
      mediaId: (l$mediaId as int),
      status: l$status == null
          ? null
          : fromJson$Enum$MediaListStatus((l$status as String)),
      progress: (l$progress as int?),
      progressVolumes: (l$progressVolumes as int?),
      score: (l$score as num?)?.toDouble(),
      repeat: (l$repeat as int?),
      startedAt: l$startedAt == null
          ? null
          : Fragment$ListEntry$startedAt.fromJson(
              (l$startedAt as Map<String, dynamic>),
            ),
      completedAt: l$completedAt == null
          ? null
          : Fragment$ListEntry$completedAt.fromJson(
              (l$completedAt as Map<String, dynamic>),
            ),
      updatedAt: (l$updatedAt as int?),
    );
  }

  final int id;

  final int mediaId;

  final Enum$MediaListStatus? status;

  final int? progress;

  final int? progressVolumes;

  final double? score;

  final int? repeat;

  final Fragment$ListEntry$startedAt? startedAt;

  final Fragment$ListEntry$completedAt? completedAt;

  final int? updatedAt;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$id = id;
    _resultData['id'] = l$id;
    final l$mediaId = mediaId;
    _resultData['mediaId'] = l$mediaId;
    final l$status = status;
    _resultData['status'] = l$status == null
        ? null
        : toJson$Enum$MediaListStatus(l$status);
    final l$progress = progress;
    _resultData['progress'] = l$progress;
    final l$progressVolumes = progressVolumes;
    _resultData['progressVolumes'] = l$progressVolumes;
    final l$score = score;
    _resultData['score'] = l$score;
    final l$repeat = repeat;
    _resultData['repeat'] = l$repeat;
    final l$startedAt = startedAt;
    _resultData['startedAt'] = l$startedAt?.toJson();
    final l$completedAt = completedAt;
    _resultData['completedAt'] = l$completedAt?.toJson();
    final l$updatedAt = updatedAt;
    _resultData['updatedAt'] = l$updatedAt;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$id = id;
    final l$mediaId = mediaId;
    final l$status = status;
    final l$progress = progress;
    final l$progressVolumes = progressVolumes;
    final l$score = score;
    final l$repeat = repeat;
    final l$startedAt = startedAt;
    final l$completedAt = completedAt;
    final l$updatedAt = updatedAt;
    return Object.hashAll([
      l$id,
      l$mediaId,
      l$status,
      l$progress,
      l$progressVolumes,
      l$score,
      l$repeat,
      l$startedAt,
      l$completedAt,
      l$updatedAt,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$ListEntry || runtimeType != other.runtimeType) {
      return false;
    }
    final l$id = id;
    final lOther$id = other.id;
    if (l$id != lOther$id) {
      return false;
    }
    final l$mediaId = mediaId;
    final lOther$mediaId = other.mediaId;
    if (l$mediaId != lOther$mediaId) {
      return false;
    }
    final l$status = status;
    final lOther$status = other.status;
    if (l$status != lOther$status) {
      return false;
    }
    final l$progress = progress;
    final lOther$progress = other.progress;
    if (l$progress != lOther$progress) {
      return false;
    }
    final l$progressVolumes = progressVolumes;
    final lOther$progressVolumes = other.progressVolumes;
    if (l$progressVolumes != lOther$progressVolumes) {
      return false;
    }
    final l$score = score;
    final lOther$score = other.score;
    if (l$score != lOther$score) {
      return false;
    }
    final l$repeat = repeat;
    final lOther$repeat = other.repeat;
    if (l$repeat != lOther$repeat) {
      return false;
    }
    final l$startedAt = startedAt;
    final lOther$startedAt = other.startedAt;
    if (l$startedAt != lOther$startedAt) {
      return false;
    }
    final l$completedAt = completedAt;
    final lOther$completedAt = other.completedAt;
    if (l$completedAt != lOther$completedAt) {
      return false;
    }
    final l$updatedAt = updatedAt;
    final lOther$updatedAt = other.updatedAt;
    if (l$updatedAt != lOther$updatedAt) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$ListEntry on Fragment$ListEntry {
  CopyWith$Fragment$ListEntry<Fragment$ListEntry> get copyWith =>
      CopyWith$Fragment$ListEntry(this, (i) => i);
}

abstract class CopyWith$Fragment$ListEntry<TRes> {
  factory CopyWith$Fragment$ListEntry(
    Fragment$ListEntry instance,
    TRes Function(Fragment$ListEntry) then,
  ) = _CopyWithImpl$Fragment$ListEntry;

  factory CopyWith$Fragment$ListEntry.stub(TRes res) =
      _CopyWithStubImpl$Fragment$ListEntry;

  TRes call({
    int? id,
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    double? score,
    int? repeat,
    Fragment$ListEntry$startedAt? startedAt,
    Fragment$ListEntry$completedAt? completedAt,
    int? updatedAt,
  });
  CopyWith$Fragment$ListEntry$startedAt<TRes> get startedAt;
  CopyWith$Fragment$ListEntry$completedAt<TRes> get completedAt;
}

class _CopyWithImpl$Fragment$ListEntry<TRes>
    implements CopyWith$Fragment$ListEntry<TRes> {
  _CopyWithImpl$Fragment$ListEntry(this._instance, this._then);

  final Fragment$ListEntry _instance;

  final TRes Function(Fragment$ListEntry) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? id = _undefined,
    Object? mediaId = _undefined,
    Object? status = _undefined,
    Object? progress = _undefined,
    Object? progressVolumes = _undefined,
    Object? score = _undefined,
    Object? repeat = _undefined,
    Object? startedAt = _undefined,
    Object? completedAt = _undefined,
    Object? updatedAt = _undefined,
  }) => _then(
    Fragment$ListEntry(
      id: id == _undefined || id == null ? _instance.id : (id as int),
      mediaId: mediaId == _undefined || mediaId == null
          ? _instance.mediaId
          : (mediaId as int),
      status: status == _undefined
          ? _instance.status
          : (status as Enum$MediaListStatus?),
      progress: progress == _undefined
          ? _instance.progress
          : (progress as int?),
      progressVolumes: progressVolumes == _undefined
          ? _instance.progressVolumes
          : (progressVolumes as int?),
      score: score == _undefined ? _instance.score : (score as double?),
      repeat: repeat == _undefined ? _instance.repeat : (repeat as int?),
      startedAt: startedAt == _undefined
          ? _instance.startedAt
          : (startedAt as Fragment$ListEntry$startedAt?),
      completedAt: completedAt == _undefined
          ? _instance.completedAt
          : (completedAt as Fragment$ListEntry$completedAt?),
      updatedAt: updatedAt == _undefined
          ? _instance.updatedAt
          : (updatedAt as int?),
    ),
  );

  CopyWith$Fragment$ListEntry$startedAt<TRes> get startedAt {
    final local$startedAt = _instance.startedAt;
    return local$startedAt == null
        ? CopyWith$Fragment$ListEntry$startedAt.stub(_then(_instance))
        : CopyWith$Fragment$ListEntry$startedAt(
            local$startedAt,
            (e) => call(startedAt: e),
          );
  }

  CopyWith$Fragment$ListEntry$completedAt<TRes> get completedAt {
    final local$completedAt = _instance.completedAt;
    return local$completedAt == null
        ? CopyWith$Fragment$ListEntry$completedAt.stub(_then(_instance))
        : CopyWith$Fragment$ListEntry$completedAt(
            local$completedAt,
            (e) => call(completedAt: e),
          );
  }
}

class _CopyWithStubImpl$Fragment$ListEntry<TRes>
    implements CopyWith$Fragment$ListEntry<TRes> {
  _CopyWithStubImpl$Fragment$ListEntry(this._res);

  TRes _res;

  call({
    int? id,
    int? mediaId,
    Enum$MediaListStatus? status,
    int? progress,
    int? progressVolumes,
    double? score,
    int? repeat,
    Fragment$ListEntry$startedAt? startedAt,
    Fragment$ListEntry$completedAt? completedAt,
    int? updatedAt,
  }) => _res;

  CopyWith$Fragment$ListEntry$startedAt<TRes> get startedAt =>
      CopyWith$Fragment$ListEntry$startedAt.stub(_res);

  CopyWith$Fragment$ListEntry$completedAt<TRes> get completedAt =>
      CopyWith$Fragment$ListEntry$completedAt.stub(_res);
}

const fragmentDefinitionListEntry = FragmentDefinitionNode(
  name: NameNode(value: 'ListEntry'),
  typeCondition: TypeConditionNode(
    on: NamedTypeNode(name: NameNode(value: 'MediaList'), isNonNull: false),
  ),
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
        name: NameNode(value: 'mediaId'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'status'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'progress'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'progressVolumes'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'score'),
        alias: null,
        arguments: [
          ArgumentNode(
            name: NameNode(value: 'format'),
            value: EnumValueNode(name: NameNode(value: 'POINT_100')),
          ),
        ],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'repeat'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
      FieldNode(
        name: NameNode(value: 'startedAt'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'year'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'month'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'day'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'completedAt'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'year'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'month'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
            FieldNode(
              name: NameNode(value: 'day'),
              alias: null,
              arguments: [],
              directives: [],
              selectionSet: null,
            ),
          ],
        ),
      ),
      FieldNode(
        name: NameNode(value: 'updatedAt'),
        alias: null,
        arguments: [],
        directives: [],
        selectionSet: null,
      ),
    ],
  ),
);
const documentNodeFragmentListEntry = DocumentNode(
  definitions: [fragmentDefinitionListEntry],
);

class Fragment$ListEntry$startedAt {
  Fragment$ListEntry$startedAt({this.year, this.month, this.day});

  factory Fragment$ListEntry$startedAt.fromJson(Map<String, dynamic> json) {
    final l$year = json['year'];
    final l$month = json['month'];
    final l$day = json['day'];
    return Fragment$ListEntry$startedAt(
      year: (l$year as int?),
      month: (l$month as int?),
      day: (l$day as int?),
    );
  }

  final int? year;

  final int? month;

  final int? day;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$year = year;
    _resultData['year'] = l$year;
    final l$month = month;
    _resultData['month'] = l$month;
    final l$day = day;
    _resultData['day'] = l$day;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$year = year;
    final l$month = month;
    final l$day = day;
    return Object.hashAll([l$year, l$month, l$day]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$ListEntry$startedAt ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$year = year;
    final lOther$year = other.year;
    if (l$year != lOther$year) {
      return false;
    }
    final l$month = month;
    final lOther$month = other.month;
    if (l$month != lOther$month) {
      return false;
    }
    final l$day = day;
    final lOther$day = other.day;
    if (l$day != lOther$day) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$ListEntry$startedAt
    on Fragment$ListEntry$startedAt {
  CopyWith$Fragment$ListEntry$startedAt<Fragment$ListEntry$startedAt>
  get copyWith => CopyWith$Fragment$ListEntry$startedAt(this, (i) => i);
}

abstract class CopyWith$Fragment$ListEntry$startedAt<TRes> {
  factory CopyWith$Fragment$ListEntry$startedAt(
    Fragment$ListEntry$startedAt instance,
    TRes Function(Fragment$ListEntry$startedAt) then,
  ) = _CopyWithImpl$Fragment$ListEntry$startedAt;

  factory CopyWith$Fragment$ListEntry$startedAt.stub(TRes res) =
      _CopyWithStubImpl$Fragment$ListEntry$startedAt;

  TRes call({int? year, int? month, int? day});
}

class _CopyWithImpl$Fragment$ListEntry$startedAt<TRes>
    implements CopyWith$Fragment$ListEntry$startedAt<TRes> {
  _CopyWithImpl$Fragment$ListEntry$startedAt(this._instance, this._then);

  final Fragment$ListEntry$startedAt _instance;

  final TRes Function(Fragment$ListEntry$startedAt) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? year = _undefined,
    Object? month = _undefined,
    Object? day = _undefined,
  }) => _then(
    Fragment$ListEntry$startedAt(
      year: year == _undefined ? _instance.year : (year as int?),
      month: month == _undefined ? _instance.month : (month as int?),
      day: day == _undefined ? _instance.day : (day as int?),
    ),
  );
}

class _CopyWithStubImpl$Fragment$ListEntry$startedAt<TRes>
    implements CopyWith$Fragment$ListEntry$startedAt<TRes> {
  _CopyWithStubImpl$Fragment$ListEntry$startedAt(this._res);

  TRes _res;

  call({int? year, int? month, int? day}) => _res;
}

class Fragment$ListEntry$completedAt {
  Fragment$ListEntry$completedAt({this.year, this.month, this.day});

  factory Fragment$ListEntry$completedAt.fromJson(Map<String, dynamic> json) {
    final l$year = json['year'];
    final l$month = json['month'];
    final l$day = json['day'];
    return Fragment$ListEntry$completedAt(
      year: (l$year as int?),
      month: (l$month as int?),
      day: (l$day as int?),
    );
  }

  final int? year;

  final int? month;

  final int? day;

  Map<String, dynamic> toJson() {
    final _resultData = <String, dynamic>{};
    final l$year = year;
    _resultData['year'] = l$year;
    final l$month = month;
    _resultData['month'] = l$month;
    final l$day = day;
    _resultData['day'] = l$day;
    return _resultData;
  }

  @override
  int get hashCode {
    final l$year = year;
    final l$month = month;
    final l$day = day;
    return Object.hashAll([l$year, l$month, l$day]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Fragment$ListEntry$completedAt ||
        runtimeType != other.runtimeType) {
      return false;
    }
    final l$year = year;
    final lOther$year = other.year;
    if (l$year != lOther$year) {
      return false;
    }
    final l$month = month;
    final lOther$month = other.month;
    if (l$month != lOther$month) {
      return false;
    }
    final l$day = day;
    final lOther$day = other.day;
    if (l$day != lOther$day) {
      return false;
    }
    return true;
  }
}

extension UtilityExtension$Fragment$ListEntry$completedAt
    on Fragment$ListEntry$completedAt {
  CopyWith$Fragment$ListEntry$completedAt<Fragment$ListEntry$completedAt>
  get copyWith => CopyWith$Fragment$ListEntry$completedAt(this, (i) => i);
}

abstract class CopyWith$Fragment$ListEntry$completedAt<TRes> {
  factory CopyWith$Fragment$ListEntry$completedAt(
    Fragment$ListEntry$completedAt instance,
    TRes Function(Fragment$ListEntry$completedAt) then,
  ) = _CopyWithImpl$Fragment$ListEntry$completedAt;

  factory CopyWith$Fragment$ListEntry$completedAt.stub(TRes res) =
      _CopyWithStubImpl$Fragment$ListEntry$completedAt;

  TRes call({int? year, int? month, int? day});
}

class _CopyWithImpl$Fragment$ListEntry$completedAt<TRes>
    implements CopyWith$Fragment$ListEntry$completedAt<TRes> {
  _CopyWithImpl$Fragment$ListEntry$completedAt(this._instance, this._then);

  final Fragment$ListEntry$completedAt _instance;

  final TRes Function(Fragment$ListEntry$completedAt) _then;

  static const _undefined = <dynamic, dynamic>{};

  TRes call({
    Object? year = _undefined,
    Object? month = _undefined,
    Object? day = _undefined,
  }) => _then(
    Fragment$ListEntry$completedAt(
      year: year == _undefined ? _instance.year : (year as int?),
      month: month == _undefined ? _instance.month : (month as int?),
      day: day == _undefined ? _instance.day : (day as int?),
    ),
  );
}

class _CopyWithStubImpl$Fragment$ListEntry$completedAt<TRes>
    implements CopyWith$Fragment$ListEntry$completedAt<TRes> {
  _CopyWithStubImpl$Fragment$ListEntry$completedAt(this._res);

  TRes _res;

  call({int? year, int? month, int? day}) => _res;
}
