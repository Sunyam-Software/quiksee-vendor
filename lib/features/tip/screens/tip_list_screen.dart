import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/tip/controllers/tip_controller.dart';
import 'package:quiksee/features/tip/widgets/tip_list_item_widget.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TipListScreen extends StatefulWidget {
  const TipListScreen({super.key});

  @override
  State<TipListScreen> createState() => _TipListScreenState();
}

class _TipListScreenState extends State<TipListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<TipController>().getTipList(reload: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Get.find<TipController>().getTipList(reload: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'tip_history'.tr, isBack: true),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: GetBuilder<TipController>(
              builder: (tipController) {
                if (tipController.isListLoading &&
                    tipController.tips.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tipController.tips.isEmpty) {
                  return const NoDataScreenWidget();
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      tipController.getTipList(reload: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    itemCount: tipController.tips.length +
                        (tipController.isListLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= tipController.tips.length) {
                        return Padding(
                          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: const Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      return TipListItemWidget(
                        tip: tipController.tips[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final labels = ['all_tips'.tr, 'tip_pending'.tr, 'tip_earned'.tr];
    return GetBuilder<TipController>(
      builder: (tipController) {
        return Container(
          height: 44,
          margin: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: labels.length,
            itemBuilder: (context, index) {
              final selected = tipController.tipStatusFilterIndex == index;
              return Padding(
                padding:
                    EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: InkWell(
                  onTap: () => tipController.setTipStatusFilter(index),
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeLarge),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                          Dimensions.paddingSizeLarge),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).hintColor
                                .withValues(alpha: .3),
                      ),
                    ),
                    child: Text(
                      labels[index],
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
