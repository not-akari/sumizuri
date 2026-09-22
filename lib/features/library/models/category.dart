import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.excludeFromUpdate,
    required this.mediaType,
    required this.useSmartRule,
    required this.sortField,
    required this.sortAscending,
    required this.statusFilter,
  });

  final int id;
  final String name;
  final int sortOrder;
  final bool excludeFromUpdate;
  final MediaType mediaType;

  final bool useSmartRule;
  final CategorySortField sortField;
  final bool sortAscending;
  final CategoryStatusFilter statusFilter;
}
