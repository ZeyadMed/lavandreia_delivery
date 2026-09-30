import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

/// صفحة من أي ليستة بالشكل اللي GenericPaginationCubit بيقراه
/// (items + pagination فيها currentPage / pagesCount / perPage / total)
class PagedModel<T> {
  final List<T> items;
  final PagedPagination pagination;

  const PagedModel({required this.items, required this.pagination});

  /// fetchResult بيبعت محتوى data لو كانت Map، أو الريسبونس كله لو data كانت List
  factory PagedModel.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) itemFromJson,
    required int pageIndex,
    required int pageSize,
  }) {
    final items = readList(json).map(itemFromJson).toList();
    return PagedModel(
      items: items,
      pagination: PagedPagination(
        currentPage: json.pickInt(['pageIndex', 'currentPage']) ?? pageIndex,
        pagesCount: json.pickInt(['totalPages', 'pagesCount']) ?? 0,
        perPage: json.pickInt(['pageSize', 'perPage']) ?? pageSize,
        total: json.pickInt(['totalCount', 'count', 'total']) ?? 0,
      ),
    );
  }
}

class PagedPagination {
  final int currentPage;
  final int pagesCount;
  final int perPage;
  final int total;

  const PagedPagination({
    required this.currentPage,
    required this.pagesCount,
    required this.perPage,
    required this.total,
  });
}
