import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/addProduct/screens/add_product_tab_view_screen.dart';
import 'package:quiksee_vendor_app/features/barcode/controllers/barcode_controller.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/filter_model.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/product_details/enums/preview_type.dart';
import 'package:quiksee_vendor_app/features/product_details/widgets/audio_preview.dart';
import 'package:quiksee_vendor_app/features/product_details/widgets/download_preview_file.dart';
import 'package:quiksee_vendor_app/features/product_details/widgets/image_preview.dart';
import 'package:quiksee_vendor_app/features/product_details/widgets/pdf_preview_flutter.dart';
import 'package:quiksee_vendor_app/features/product_details/widgets/video_preview.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/helper/product_helper.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/product/screens/product_order_time_screen.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/features/product_details/screens/product_details_screen.dart';
import 'package:quiksee_vendor_app/features/barcode/screens/bar_code_generator_screen.dart';

import '../../../main.dart';

class ShopProductWidget extends StatefulWidget {
  final Product? productModel;
  final bool isDetails;
  const ShopProductWidget({super.key, required this.productModel, this.isDetails = false});

  @override
  State<ShopProductWidget> createState() => _ShopProductWidgetState();
}

class _ShopProductWidgetState extends State<ShopProductWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: GestureDetector(
            onTap: widget.isDetails ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productModel: widget.productModel))),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2)
                  )
                ]
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 50, width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          child: QuikseeImageWidget(
                            image: '${widget.productModel?.thumbnailFullUrl?.path}',
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      if ((widget.productModel?.clearanceSale?.discountAmount ?? 0) > 0)
                        const DiscountTagWidget()
                    ],
                  ),

                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: !widget.isDetails && isLtr ? 40.0 : 0,
                            left: !widget.isDetails && !isLtr ? 40.0 : 0,
                          ),
                          child: Text(
                            widget.productModel?.name ?? '',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodyLarge?.color
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Row(
                          children: [
                            Text(
                              PriceConverter.convertPrice(context, widget.productModel!.unitPrice,
                                discountType: (widget.productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                  ? widget.productModel?.clearanceSale?.discountType
                                  : widget.productModel?.discountType,
                                discount: (widget.productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                  ? widget.productModel?.clearanceSale?.discountAmount
                                  : widget.productModel?.discount
                              ),
                              style: robotoMedium.copyWith(fontSize: 18, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            if((widget.productModel?.discount ?? 0) > 0 || (widget.productModel?.clearanceSale?.discountAmount ?? 0) > 0)
                            Text(
                              PriceConverter.convertPrice(context, widget.productModel!.unitPrice),
                              style: robotoRegular.copyWith(
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${getTranslated('product_type', context)} : ',
                                    style: robotoRegular.copyWith(color: Theme.of(context).textTheme.headlineLarge?.color, fontSize: Dimensions.fontSizeSmall),
                                  ),
                                  TextSpan(
                                    text: getTranslated(widget.productModel?.productType, context),
                                    style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.productModel!.requestStatus == 1
                                    ? Theme.of(context).colorScheme.onTertiaryContainer
                                    : widget.productModel!.requestStatus == 2
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                ),
                                child: Text(
                                  widget.productModel!.requestStatus == 0 ? getTranslated('new_request', context)! :
                                  widget.productModel!.requestStatus == 1 ? getTranslated('approved', context)! :
                                  getTranslated('denied', context)!,
                                  style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                ),
                              ),
                          ],
                        ),

                        if(widget.isDetails && widget.productModel?.productType == 'digital' && widget.productModel?.previewFileFullUrl != null && widget.productModel?.previewFileFullUrl?.path != '')
                        Padding(
                          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap: () => _showPreview(widget.productModel?.previewFileFullUrl?.path ?? '', widget.productModel?.name ?? '', widget.productModel?.previewFileFullUrl?.key ?? ''),
                            child: Text(
                              getTranslated('see_preview', context)!,
                              style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline,
                                decorationColor: Theme.of(context).primaryColor),
                            ),
                          ),
                        ),

                        if(widget.isDetails && widget.productModel!.deniedNote != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                              Text('${getTranslated('note', context)}: ',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                              Expanded(child: Text( widget.productModel!.deniedNote!,overflow: TextOverflow.ellipsis,
                                maxLines: 50,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault))),
                            ],),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        !widget.isDetails
            ? Positioned(
                top: 0,
                right: isLtr ? 0 : null,
                left: isLtr ? null : 0,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(0, 40),
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).hintColor,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddProductTabView(
                          product: widget.productModel,
                          fromHome: false,
                        ),
                      ));
                    } else if (value == 'order_time') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductOrderTimeScreen(
                          productId: widget.productModel!.id!,
                          productName: widget.productModel?.name,
                        ),
                      ));
                    } else if (value == 'barcode') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            BarCodeGenerateScreen(product: widget.productModel),
                      ));
                      Provider.of<BarcodeController>(context, listen: false)
                          .setBarCodeQuantity(4);
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return ConfirmationDialogWidget(
                            icon: Images.deleteProduct,
                            refund: false,
                            description: getTranslated(
                              'are_you_sure_want_to_delete_this_product',
                              dialogContext,
                            ),
                            onYesPressed: () {
                              Provider.of<ProductController>(dialogContext,
                                      listen: false)
                                  .deleteProduct(
                                      dialogContext, widget.productModel!.id)
                                  .then((value) {
                                Provider.of<ProductController>(Get.context!,
                                        listen: false)
                                    .getStockOutProductList(1, 'en');
                                Provider.of<ProductController>(Get.context!,
                                        listen: false)
                                    .getSellerProductList(
                                  Provider.of<ProfileController>(Get.context!,
                                          listen: false)
                                      .userInfoModel!
                                      .id
                                      .toString(),
                                  1,
                                  'en',
                                  '',
                                  filterSearchModel:
                                      FilterModel(reload: true),
                                );
                              });
                            },
                          );
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(Images.editIcon),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('edit', context) ?? 'Edit',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'order_time',
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('product_order_time', context) ??
                                'Order time',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'barcode',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(Images.barCode),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('bar_code_generator', context) ??
                                'Barcode',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(Images.delete),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('delete', context) ?? 'Delete',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),

      ],
    );
  }

  void _showPreview(String url, String productName, String fileName) {
    PreviewType type = ProductHelper.getFileType(url);
    showDialog(context: context, builder: (BuildContext context){
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        insetPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: (type == PreviewType.pdf) ?
        PdfPreview(url: url, fileName: productName) : (type == PreviewType.image) ?
        ImagePreview(url: url, fileName: productName) : (type == PreviewType.video) ?
        VideoPreview(url: url, fileName: productName) : (type == PreviewType.audio)  ?
        AudioPreview(url: url, fileName: productName) : (type == PreviewType.others) ?
        DownloadPreview(url: url, fileName: fileName) :
        const SizedBox(),
      );
    });
  }
}

class DiscountTagWidget extends StatelessWidget {
  const DiscountTagWidget({
    super.key,
    this.positionedTop = 0,
    this.positionedLeft = 0,
    this.positionedRight = 0,
  });

  final double positionedTop;
  final double positionedLeft;
  final double positionedRight;

  @override
  Widget build(BuildContext context) {
    final bool isLtr  = Provider.of<LocalizationController>(context, listen: false).isLtr;
    return Positioned(
      top: positionedTop,
      left: isLtr ? positionedLeft : null,
      right: !isLtr ? positionedRight : null,
      child: Image.asset(Images.clearanceDiscountIcon, height: 25, width: 25),
    );
  }
}

