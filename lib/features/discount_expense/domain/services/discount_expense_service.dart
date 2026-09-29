import 'package:quiksee_vendor_app/features/discount_expense/domain/repositories/discount_expense_repository_interface.dart';
import 'package:quiksee_vendor_app/features/discount_expense/domain/services/discount_expense_service_interface.dart';

class DiscountExpenseService implements DiscountExpenseServiceInterface {
  final DiscountExpenseRepositoryInterface discountExpenseRepoInterface;
  DiscountExpenseService({required this.discountExpenseRepoInterface});

  @override
  Future getDiscountExpenseReport({
    String type = 'all',
    String? from,
    String? to,
  }) {
    return discountExpenseRepoInterface.getDiscountExpenseReport(
      type: type,
      from: from,
      to: to,
    );
  }
}
