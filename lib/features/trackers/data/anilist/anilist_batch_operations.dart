// Two operations whose shape depends on the batch size, so they are not .graphql files.
import 'package:gql/language.dart';

import 'package:sumizuri/features/trackers/data/anilist/graphql/fragments.graphql.dart';

const batchSize = 10;

// The list entry fields, from the same fragment the generated queries use.
String get _listEntry => printNode(fragmentDefinitionListEntry);

String entriesOperation(int count) {
  final vars = [for (var i = 0; i < count; i++) '\$m$i: Int!'].join(', ');
  final fields = [
    for (var i = 0; i < count; i++)
      '  m$i: Media(id: \$m$i) { id chapters mediaListEntry { ...ListEntry } }',
  ].join('\n');
  return 'query Entries($vars) {\n$fields\n}\n$_listEntry';
}

({String operation, Map<String, dynamic> variables}) saveEntriesOperation(
  List<Map<String, dynamic>> entries,
) {
  const types = {
    'mediaId': 'Int!',
    'status': 'MediaListStatus',
    'progress': 'Int',
    'progressVolumes': 'Int',
    'scoreRaw': 'Int',
    'repeat': 'Int',
    'startedAt': 'FuzzyDateInput',
    'completedAt': 'FuzzyDateInput',
  };
  final declarations = <String>[];
  final variables = <String, dynamic>{};
  final calls = <String>[];
  for (var i = 0; i < entries.length; i++) {
    final args = <String>[];
    for (final field in entries[i].entries) {
      final name = '${field.key}_$i';
      declarations.add('\$$name: ${types[field.key]}');
      variables[name] = field.value;
      args.add('${field.key}: \$$name');
    }
    calls.add('  e$i: SaveMediaListEntry(${args.join(', ')}) { ...ListEntry }');
  }
  return (
    operation:
        'mutation SaveEntries(${declarations.join(', ')}) {\n${calls.join('\n')}\n}\n$_listEntry',
    variables: variables,
  );
}
