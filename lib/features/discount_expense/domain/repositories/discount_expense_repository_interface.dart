abstract class DiscountExpenseRepositoryInterface {
  Future<dynamic> getDiscountExpenseReport({
    String type = 'all',
    String? from,
    String? to,
  });

  Future add(dynamic value);
  Future update(Map<String, dynamic> body, int id);
  Future delete(int id);
  Future getList({int? offset = 1});
  Future get(String id);
}
