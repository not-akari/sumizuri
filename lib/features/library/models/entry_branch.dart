class EntryBranch {
  const EntryBranch({
    required this.id,
    required this.libraryEntryId,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final int libraryEntryId;
  final String name;
  final DateTime createdAt;
}
