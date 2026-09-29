abstract class DiscountExpenseServiceInterface {
  Future<dynamic> getDiscountExpenseReport({
    String type = 'all',
    String? from,
    String? to,
  });
}
