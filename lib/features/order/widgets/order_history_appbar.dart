import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_calender_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/date_type.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class OrderHistoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const OrderHistoryAppBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  State<OrderHistoryAppBar> createState() => _OrderHistoryAppBarState();
}

class _OrderHistoryAppBarState extends State<OrderHistoryAppBar> with SingleTickerProviderStateMixin {
  static const Color _appBarLightGreen = Color(0xFFD2E7D7);
  static const Color _appBarGold = Color(0xFFD4A62A);

  int toggle = 0;
  late AnimationController _con;
  final FocusNode _focusNode = FocusNode();
  String result = 'all_time';

  @override
  void initState() {
    super.initState();
    _con = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 375),
    );
  }

  void _handleToggle() {
    setState(() {
      if (toggle == 0) {
        toggle = 1;
        _con.forward();
        FocusScope.of(context).requestFocus(_focusNode);
      } else {
        toggle = 0;
        _con.reverse();
        _focusNode.unfocus();
        widget.searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return AppBar(
      surfaceTintColor: Get.isDarkMode ? Theme.of(context).cardColor : _appBarLightGreen,
      backgroundColor: Get.isDarkMode ? Theme.of(context).cardColor : _appBarLightGreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedOpacity(
              opacity: toggle == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  const BrandLogoWidget(),
                  const Spacer(),

                  Text(widget.title.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikMedium.copyWith(
                    color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : _appBarGold, fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w700)
                  ),
                  const Spacer(),

                  CircularSearchTrigger(onTap: _handleToggle),
                  const SizedBox(width: 10),
                  // --- Refactored Filter Menu Component ---
                  const RefundFilterAction(),
                ],
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 375),
              left: toggle == 1 ? 0 : width,
              right: 0,
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: toggle == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: SearchBarExpandedWidget(
                  controller: widget.searchController,
                  focusNode: _focusNode,
                  onChanged: widget.onSearchChanged,
                  onBack: _handleToggle,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


class BrandLogoWidget extends StatelessWidget {
  const BrandLogoWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Image.asset(
        Images.quikseeLogo,
        height: 28,
        width: 72,
        fit: BoxFit.contain,
      ),
    );
  }
}

class CircularSearchTrigger extends StatelessWidget {
  final VoidCallback onTap;
  const CircularSearchTrigger({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingSizeMin),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.20)),
        ),
        child: Icon(Icons.search, color: Theme.of(context).primaryColor, size: 20),
      ),
    );
  }
}

class RefundFilterAction extends StatefulWidget {
  const RefundFilterAction({super.key});

  @override
  State<RefundFilterAction> createState() => _RefundFilterActionState();
}

class _RefundFilterActionState extends State<RefundFilterAction> {
  String result = 'all_time';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (result != 'all_time')
          Positioned(
            top: 1,
            right: 0,
            child: Container(
              height: 7,
              width: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),

        SizedBox(
          height: 32,
          width: 32,
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              return PopupMenuButton<DateType>(
                offset: const Offset(0, 40),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                icon: Container(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.20)),
                  ),
                  child: QuikseeAssetImageWidget(
                    Images.filterIcon,
                    color: Theme.of(context).colorScheme.primary,
                    height: Dimensions.rememberMeSizeDefault,
                    width: Dimensions.rememberMeSizeDefault,
                  ),
                ),


                onSelected: (DateType selected) async {
                  setState(() => result = selected.key);

                  if (selected.key != 'custom_date') {
                    orderController.setDateType(selected);

                    orderController.setOrderTypeIndex(orderController.orderTypeIndex,
                      startDate: '' , endDate: '', search: '',
                      reload: false, isUpdate: true
                    );
                  } else if (selected.key == 'custom_date') {
                    Get.dialog(QuikseeCalendarWidget(
                      //initDateRange: PickerDateRange(null, null),
                      onSubmit: (PickerDateRange? range) {
                      if(range?.startDate == null) {
                        showQuikseeSnackBarWidget('select_start_date_first'.tr);
                      }else if(range?.endDate == null) {
                        showQuikseeSnackBarWidget('select_end_date_first'.tr);
                      } else {
                        orderController.setDateType(selected);
                        orderController.selectDate(
                          startDate: range!.startDate!.toString(),
                          endDate: range.endDate!.toString()
                        );

                        orderController.setOrderTypeIndex(orderController.orderTypeIndex,
                          startDate: orderController.startDate ?? '' , endDate: orderController.endDate ?? '', search: '',
                          reload: false, isUpdate: true
                        );
                      }
                    }));
                  }
                },

                itemBuilder: (BuildContext context) => [
                  _buildPopupItem(context, DateType.overall, orderController),
                  _buildPopupItem(context, DateType.today, orderController),
                  _buildPopupItem(context, DateType.thisWeek,orderController),
                  _buildPopupItem(context, DateType.thisMonth, orderController),
                  _buildPopupItem(context, DateType.custom, orderController),
                ],

              );
            }
          ),
        ),

      ],
    );
  }

  PopupMenuItem<DateType> _buildPopupItem(BuildContext context, DateType value, OrderController orderController) {
    return PopupMenuItem<DateType>(
      value: value,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            value.key.tr,
            style: robotoRegular.copyWith(
              color: orderController.dateType == value.key
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          if (value == 'all_time')  SizedBox(width: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}

class SearchBarExpandedWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onBack;

  const SearchBarExpandedWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 45,
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                onPressed: () {
                  if(controller.text.trim().isNotEmpty && orderController.isSearchActive) {
                    controller.text = '';
                    orderController.setOrderTypeIndex(
                      orderController.orderTypeIndex,
                      startDate: orderController.startDate ?? '' , endDate: orderController.endDate ?? '', search: '',
                      reload: true, isUpdate: true
                    );
                  }
                  orderController.setSearchStatus(false);
                  onBack();
                },
              ),

              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) {
                        showQuikseeSnackBarWidget('please_enter_order_id'.tr);
                      } else {
                        orderController.setOrderTypeIndex(
                          orderController.orderTypeIndex,
                          startDate: orderController.startDate ?? '' , endDate: orderController.endDate ?? '', search: controller.text,
                          reload: false, isUpdate: true
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                      suffixIcon: InkWell(
                        child: Icon(orderController.isSearchActive ? Icons.close : Icons.search, color: Theme.of(context).primaryColor),
                        onTap: () {
                          if(orderController.isSearchActive) {
                            orderController.setSearchStatus(!orderController.isSearchActive, isUpdate: true);
                            controller.text = '';
                            orderController.setOrderTypeIndex(
                              orderController.orderTypeIndex,
                              startDate: orderController.startDate ?? '' , endDate: orderController.endDate ?? '', search: '',
                              reload: true, isUpdate: true
                            );
                          } else if (controller.text.trim().isEmpty) {
                            showQuikseeSnackBarWidget('please_enter_order_id'.tr);
                          } else {
                            orderController.setOrderTypeIndex(
                              orderController.orderTypeIndex,
                              startDate: orderController.startDate ?? '' , endDate: orderController.endDate ?? '', search: controller.text,
                              reload: false, isUpdate: true
                            );
                          }
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}