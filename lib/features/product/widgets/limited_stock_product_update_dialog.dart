import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/addProduct/controllers/variation_controller.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/restock/controllers/restock_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';

class LimitedStockQuantityUpdateDialogWidget extends StatefulWidget {
  final String? title;
  final Function onYesPressed;
  final TextEditingController? note;
  final TextEditingController? stockQuantityController;
  final Product? product;
  const LimitedStockQuantityUpdateDialogWidget({super.key, this.title, required this.onYesPressed, this.note, this.product, this.stockQuantityController});

  @override
  State<LimitedStockQuantityUpdateDialogWidget> createState() => _LimitedStockQuantityUpdateDialogWidgetState();
}

class _LimitedStockQuantityUpdateDialogWidgetState extends State<LimitedStockQuantityUpdateDialogWidget> {
  int addColor = 0;

  void _load(){
    String languageCode = Provider.of<LocalizationController>(context, listen: false).locale.countryCode == 'US'?
    'en':Provider.of<LocalizationController>(context, listen: false).locale.countryCode!.toLowerCase();
    Provider.of<SplashController>(context,listen: false).getColorList();
    Provider.of<VariationController>(context,listen: false).getAttributeList(context, widget.product, languageCode);
  }

  @override
  void initState() {
    _load();
    Provider.of<RestockController>(context,listen: false).setCurrentStock(widget.product!.currentStock.toString());
    Provider.of<RestockController>(context,listen: false).initVariationController(widget.product!.variation ?? []);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Consumer<RestockController>(
            builder: (context, resProvider, child) {
              List<int> colors = [];
              colors.add(0);

              widget.stockQuantityController!.text = resProvider.totalQuantityController.text;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                child: Text(
                                  widget.title!, textAlign: TextAlign.center,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                                ),
                              ),

                              widget.product?.variation != null ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

                              widget.product?.variation != null?
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: widget.product?.variation?.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [

                                          Expanded(flex: 8, child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: widget.product?.variation![index].type ?? '', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                                                ],
                                              ),
                                            ),
                                          ])),
                                          const SizedBox(width: Dimensions.paddingSizeSmall),

                                          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            QuikseeTextFieldWidget(
                                              variant: true,
                                              border: true,
                                              hintText: 'Ex: 345',

                                              controller: resProvider.variationQuantityController[index],
                                              focusNode: resProvider.variationQuantityFocusnode[index],
                                              nextNode: index != widget.product!.variation!.length - 1 ? resProvider.variationQuantityFocusnode[index+1] : null,
                                              textInputAction: index != widget.product!.variation!.length - 1 ? TextInputAction.next : TextInputAction.done,
                                              isAmount: false,
                                              amountIcon: false,
                                              textInputType: TextInputType.number,
                                              isFullNumber : true,
                                              onChanged: (String cng){
                                                resProvider.calculateVariationQuantity();
                                              },
                                            ),
                                          ],
                                          )),

                                        ]),
                                  );
                                },
                              ):const SizedBox(),

                              Container(margin: const EdgeInsets.only(left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge,
                                  bottom: Dimensions.paddingSizeSmall),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(getTranslated('total_quantity', context)!,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                    QuikseeTextFieldWidget(
                                      idDate: widget.product!.variation!.isNotEmpty,
                                      border: true,
                                      textInputType: TextInputType.number,
                                      controller: widget.stockQuantityController,
                                      textInputAction: TextInputAction.next,
                                      isAmount: true,
                                      hintText: 'Ex: 500',
                                    ),
                                  ],)),

                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              Consumer<RestockController>(builder: (context, shippingProvider, child) {
                                return !shippingProvider.isLoading ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                  child: SizedBox(height: 40,
                                    child: QuikseeButtonWidget(
                                      borderRadius: 10,
                                      btnTxt: getTranslated('update_quantity',context),
                                      onTap: () =>  widget.onYesPressed(),
                                    ),
                                  ),
                                ) : const Center(child: CircularProgressIndicator());
                              }),
                            ]),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Padding(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                child: SizedBox(width: 18,child: Image.asset(Images.cross)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        ));
  }
}