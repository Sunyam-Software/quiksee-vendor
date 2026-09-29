import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/review/controllers/revice_controller.dart';
import 'package:quiksee/features/review/widgets/review_card_shimmer_widget.dart';
import 'package:quiksee/features/review/widgets/review_filter_widget.dart';
import 'package:quiksee/features/review/widgets/review_list_widget.dart';

class ReviewScreen extends StatefulWidget {
  final OrderModel? orderModel;
  const ReviewScreen({super.key, this.orderModel});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ScrollController _scrollController = ScrollController();
   String? type;

  @override
  void initState() {
    super.initState();
    Get.find<ReviewController>().getReviewList(1);
    type = Get.find<ReviewController>().reviewTypeList.first;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReviewController>(builder: (reviewController){
      return Scaffold(
        appBar: QuikseeAppBarWidget(title: 'my_reviews'.tr,isBack: true,),

        body: Column(children: [
          ReviewFilterWidget(
            isBorder: true,
            items: reviewController.reviewTypeList,
            type: type,
            onSelected: (typeSelected){
              type = typeSelected;
              reviewController.update();
              reviewController.setSelectedReviewType = typeSelected;
              Get.find<ReviewController>().getReviewList(1);
            },),

          !reviewController.isLoading && reviewController.reviewModel != null?
          (reviewController.reviewModel!.review != null && reviewController.reviewModel!.review!.isNotEmpty) ?
          Expanded(child: ReviewListViewWidget(reviewController: reviewController, scrollController: _scrollController)) :
          const NoDataScreenWidget(): const Expanded(child: ReviewCardShimmerWidget()),
        ]),
      );
    });
  }
}
