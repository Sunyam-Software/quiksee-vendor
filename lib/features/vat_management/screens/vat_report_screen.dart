import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/common/basewidgets/paginated_list_view_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/controllers/vat_controller.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/gst_order_tax_breakdown_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/gst_report_stat_card_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/order_list_card_shimmer_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/order_list_card_widget.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/vat_filter_bottomsheet.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class VatReportScreen extends StatefulWidget {
  final String? orderType;
  const VatReportScreen({super.key, this.orderType});

  @override
  State<VatReportScreen> createState() => _VatReportScreenState();
}

class _VatReportScreenState extends State<VatReportScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isPosReport => widget.orderType?.toLowerCase() == 'pos';

  @override
  void initState() {
    super.initState();
    final vatController = Provider.of<VatController>(context, listen: false);
    vatController.resetReviewData(isUpdate: false);
    vatController.setOrderType(widget.orderType, isUpdate: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      vatController.getVatReportList(1, orderType: widget.orderType);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilter() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).cardColor,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) => const VatFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: QuikseeBrandColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: QuikseeAppBarWidget(
          title: _isPosReport
              ? (getTranslated('pos_sales_report', context) ?? 'POS Sales Report')
              : getGstTranslated('vat_report', context, fallback: 'GST Report'),
          useQuikseeBrandedHeader: true,
          isAction: true,
          isFilter: true,
          widget: InkWell(
            onTap: _openFilter,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: QuikseeBrandColors.logoGoldLight),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                Images.filterIcon,
                height: 18,
                width: 18,
                color: QuikseeBrandColors.logoGoldLight,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeMedium,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeMedium,
            Dimensions.paddingSizeLarge,
          ),
          child: Consumer<VatController>(
            builder: (context, vatController, _) {
              final model = vatController.vatReportModel;
              final hasTaxData = model?.typeWiseTaxesList?.isNotEmpty ?? false;

              if (vatController.isLoading == true && model == null) {
                return const VatReportShimmerWidget(isEnabled: true);
              }

              final emptyTitle = _isPosReport
                  ? 'no_pos_sales_found'
                  : 'no_tax_report_found';

              final orders = (model?.orderTransactions ?? []).where((tx) {
                if (_searchQuery.isEmpty) return true;
                return (tx.orderId?.toString() ?? '').contains(_searchQuery);
              }).toList();

              if (model == null) {
                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: Center(child: NoDataScreen(title: emptyTitle)),
                );
              }

              if (!hasTaxData && (model.orderTransactions?.isEmpty ?? true)) {
                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: Center(child: NoDataScreen(title: emptyTitle)),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTaxData) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GstReportStatCardWidget(
                              image: Images.totalOrderIcon,
                              amount: model.totalOrders?.toString() ?? '0',
                              label: getTranslated('total_orders', context) ?? 'Total Orders',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GstReportStatCardWidget(
                              image: Images.totalAmountIcon,
                              amount: PriceConverter.convertPrice(
                                context,
                                double.tryParse(model.totalOrderAmount.toString()) ?? 0,
                              ),
                              label: getTranslated('total_order_amount', context) ?? 'Total Order Amount',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GstReportStatCardWidget(
                              image: Images.vatReportIcon,
                              amount: PriceConverter.convertPrice(
                                context,
                                double.tryParse(model.totalTax.toString()) ?? 0,
                              ),
                              label: getGstTranslated('total_vat_amount', context, fallback: 'Total GST Amount')!,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    GstOrderTaxBreakdownWidget(
                      typeWiseTaxesList: model.typeWiseTaxesList,
                      totalTax: double.tryParse(model.totalTax.toString()),
                    ),
                  ],
                  if ((model.orderTransactions?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    Text(
                      '${getTranslated('all_gst', context) ?? 'All GST'} (${model.totalOrders ?? orders.length})',
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value.trim()),
                      decoration: InputDecoration(
                        hintText: getTranslated('search_by_order_id', context) ?? 'Search by order id',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    PaginatedListViewWidget(
                      scrollController: scrollController,
                      totalSize: model.totalOrders,
                      offset: model.offset,
                      onPaginate: (int? offset) async {
                        await vatController.getVatReportList(
                          offset ?? 1,
                          startDate: (vatController.isFilterActive ?? false)
                              ? vatController.startDate.toString()
                              : null,
                          endDate: (vatController.isFilterActive ?? false)
                              ? vatController.endDate.toString()
                              : null,
                        );
                      },
                      itemView: ListView.separated(
                        itemCount: orders.length,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          return OrderListCardWidget(orderModel: orders[index]);
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                      ),
                    ),
                  ] else if (hasTaxData)
                    const OrderListCardShimmer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class VatReportShimmerWidget extends StatelessWidget {
  final bool isEnabled;
  const VatReportShimmerWidget({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      enabled: isEnabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}
