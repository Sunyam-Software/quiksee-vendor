import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/coupon/domain/models/coupon_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/pos/controllers/cart_controller.dart';
import 'package:quiksee_vendor_app/features/coupon/controllers/coupon_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_date_picker_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_drop_down_item_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_field_with_title_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
class AddNewCouponScreen extends StatefulWidget {
  final Coupons? coupons;
  const AddNewCouponScreen({super.key, this.coupons});

  @override
  State<AddNewCouponScreen> createState() => _AddNewCouponScreenState();
}

class _AddNewCouponScreenState extends State<AddNewCouponScreen> {

  TextEditingController couponTitleController = TextEditingController();
  TextEditingController limitController = TextEditingController();
  TextEditingController couponCodeController = TextEditingController();
  TextEditingController discountAmountController = TextEditingController();
  TextEditingController minimumPurchaseController = TextEditingController();
  TextEditingController maximumDiscountController = TextEditingController();

  bool update = false;

  @override
  void initState() {
    update = widget.coupons != null ? true: false;

    if(update){
      couponTitleController.text = widget.coupons!.title!;
      couponCodeController.text = widget.coupons!.code!;
      discountAmountController.text =  widget.coupons?.discountType == 'amount' ?  PriceConverter.convertPriceWithoutSymbol(Get.context!, widget.coupons!.discount) : widget.coupons!.discount.toString();
      minimumPurchaseController.text =  PriceConverter.convertPriceWithoutSymbol(Get.context!, widget.coupons!.minPurchase);
      limitController.text = widget.coupons!.limit.toString();
      maximumDiscountController.text =   PriceConverter.convertPriceWithoutSymbol(Get.context!, widget.coupons!.maxDiscount);
      Provider.of<CouponController>(context, listen: false).startDate = DateTime.parse(widget.coupons!.startDate!);
      Provider.of<CouponController>(context, listen: false).endDate = DateTime.parse(widget.coupons!.expireDate!);
    } else {
      Provider.of<CouponController>(context, listen: false).clearCouponData();
    }
    Provider.of<CouponController>(context, listen: false).setCustomerInfo(0, 'All Customer', false);
    Provider.of<CouponController>(context, listen: false).setCouponCustomerIndex(0, 0, false);
    Provider.of<CouponController>(context, listen: false).searchCustomerController.text =
        getTranslated('all_customer', context) ?? 'All Customer';
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: getTranslated('coupon_setup', context)),
      body: Consumer<CouponController>(
        builder: (context, coupon,_) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    QuikseeDropDownItemWidget(
                      title: 'coupon_type',
                      widget: DropdownButtonFormField<String>(
                        initialValue: coupon.selectedCouponType,
                        isExpanded: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                        iconSize: 24, elevation: 16, style: robotoRegular,
                        onChanged: (value) {
                          coupon.setSelectedCouponType(value);
                        },
                        items: coupon.couponTypeList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(getTranslated(value, context)!,
                                style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                          );
                        }).toList(),
                      ),
                    ),

                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
                        child: Text(getTranslated('select_customer', context)!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color))
                      ),
                    ),

                    Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Container(width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(border: Border.all(width: .25, color: Theme.of(context).hintColor.withValues(alpha:.75)),
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                        child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: Text(
                            getTranslated('all_customer', context) ?? 'All Customer',
                            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        )),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeMedium,),
                    QuikseeFieldWithTitleWidget(
                      isCoupon: true,
                      title: getTranslated('coupon_title', context),
                      quikseeTextField: QuikseeTextFieldWidget(
                        border: true,
                        controller: couponTitleController,
                        hintText: getTranslated('coupon_title_hint', context),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        Row(children: [
                          Text(getTranslated('coupon_code', context)!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),

                          const Spacer(),
                          InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
                              Random rnd = Random();

                              String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
                                  length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
                              var code = getRandomString(10);
                              couponCodeController.text = code.toString();
                            },
                            child: Text(getTranslated('generate_code', context)!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor))),
                        ],
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        QuikseeTextFieldWidget(
                          controller: couponCodeController,
                          border: true,
                          textInputAction: TextInputAction.next,
                          textInputType: TextInputType.text,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                          hintText: 'Ex: ze5uzkyu0s',
                        ),
                      ],),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    QuikseeFieldWithTitleWidget(
                      isCoupon: true,
                      title: getTranslated('limit_for_same_user', context),
                      quikseeTextField: QuikseeTextFieldWidget(
                        border: true,
                        isAmount: true,
                        controller: limitController,
                        hintText: getTranslated('limit_user_hint', context),
                        textInputType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),

                    ),

                    coupon.selectedCouponType == 'discount_on_purchase'?
                    const SizedBox(height: Dimensions.paddingSizeMedium):const SizedBox.shrink(),
                    coupon.selectedCouponType == 'discount_on_purchase'?
                    QuikseeDropDownItemWidget(
                      title: 'discount_type',
                      widget: DropdownButtonFormField<String>(
                        initialValue: coupon.discountTypeName,
                        isExpanded: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                        iconSize: 24, elevation: 16, style: robotoRegular,
                        onChanged: (value) {
                          coupon.setSelectedDiscountNameType(value);
                        },
                        items: coupon.discountTypeList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(getTranslated(value, context)!,
                                style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                          );
                        }).toList(),
                      ),
                    ):const SizedBox.shrink(),

                    coupon.selectedCouponType == 'discount_on_purchase'?
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall): const SizedBox.shrink(),
                    coupon.selectedCouponType == 'discount_on_purchase'?
                    QuikseeFieldWithTitleWidget(
                      isCoupon: true,
                      title: getTranslated('discount_amount', context),
                      quikseeTextField: QuikseeTextFieldWidget(
                        border: true,
                        isAmount: true,
                        controller: discountAmountController,
                        hintText: getTranslated('discount_amount_hint', context),
                      ),

                    ):const SizedBox.shrink(),
                    const SizedBox(height: Dimensions.paddingSizeMedium),

                    QuikseeFieldWithTitleWidget(
                      isCoupon: true,
                      title: getTranslated('minimum_purchase', context),
                      quikseeTextField: QuikseeTextFieldWidget(
                        border: true,
                        isAmount: true,
                        textInputAction: TextInputAction.done,
                        controller: minimumPurchaseController,
                        hintText: getTranslated('minimum_purchase_hint', context),
                      ),
                    ),

                    if(coupon.discountTypeName == 'percentage')
                      const SizedBox(height: Dimensions.paddingSizeMedium),
                    if(coupon.selectedCouponType != 'free_delivery' && coupon.discountTypeName == 'percentage')
                      QuikseeFieldWithTitleWidget(
                          isCoupon: true,
                          title: getTranslated('maximum_discount', context),
                          quikseeTextField: QuikseeTextFieldWidget(
                              border: true,
                              isAmount: true,
                              textInputAction: TextInputAction.done,
                              controller: maximumDiscountController,
                              hintText: getTranslated('minimum_purchase_hint', context))),

                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Row(children: [
                      Expanded(child: QuikseeDatePickerWidget(
                        title: getTranslated('start_date', context),
                        image: Images.calenderIcon,
                        text: coupon.startDate != null ?
                        coupon.dateFormat.format(coupon.startDate!).toString() : getTranslated('select_date', context),
                        selectDate: () => coupon.selectDate("start", context),
                      )),

                      Expanded(child: QuikseeDatePickerWidget(
                        title: getTranslated('expire_date', context),
                        image: Images.calenderIcon,
                        text: coupon.endDate != null ?
                        coupon.dateFormat.format(coupon.endDate!).toString() : getTranslated('select_date', context),
                        selectDate: () => coupon.selectDate("end", context),
                      )),
                    ],),
                    const SizedBox(height: Dimensions.paddingSizeMedium),
                  ],
                ),
              ),
            ),

            Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: ThemeShadow.getShadow(context)
                ),
                child: Consumer<CouponController>(
                    builder: (context, coupon,_) {
                      return Consumer<CartController>(
                          builder: (context, customer,_) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraLarge),
                              child: coupon.isAdd?
                              const Center(
                                child: SizedBox(width: 40,height: 40,
                                    child: CircularProgressIndicator()),
                              ):
                              QuikseeButtonWidget(btnTxt:update? getTranslated('update', context) : getTranslated('submit', context),
                                onTap: () {
                                  String? couponType = coupon.selectedCouponType;
                                  int? customerId = 0;
                                  String couponTitle = couponTitleController.text.trim();
                                  String couponCode = couponCodeController.text.trim();
                                  String limit = limitController.text.trim();
                                  String? discountType = coupon.discountTypeName;
                                  String discountAmount = discountAmountController.text.trim();
                                  String minimumPurchase = minimumPurchaseController.text.trim();
                                  String maxDiscount = maximumDiscountController.text.trim();
                                  String? startDate =  coupon.dateFormat.format(coupon.startDate?? DateTime.now()).toString();
                                  String? endDate =  coupon.dateFormat.format(coupon.endDate?? DateTime.now()).toString();

                                  if(couponTitle.isEmpty){
                                    showQuikseeSnackBarWidget(getTranslated('coupon_title_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(couponCode.isEmpty){
                                    showQuikseeSnackBarWidget(getTranslated('coupon_code_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(limit.isEmpty){
                                    showQuikseeSnackBarWidget(getTranslated('limit_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(discountAmount.isEmpty && coupon.selectedCouponType == 'discount_on_purchase'){
                                    showQuikseeSnackBarWidget(getTranslated('amount_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(minimumPurchase.isEmpty){
                                    showQuikseeSnackBarWidget(getTranslated('minimum_purchase_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(couponType != 'free_delivery' && maxDiscount.isEmpty && coupon.discountTypeName == 'percentage'){
                                    showQuikseeSnackBarWidget(getTranslated('max_discount_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(coupon.startDate == null && !update){
                                    showQuikseeSnackBarWidget(getTranslated('start_date_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if(coupon.endDate == null && !update){
                                    showQuikseeSnackBarWidget(getTranslated('end_date_is_required', context), context, sanckBarType: SnackBarType.warning);
                                  }else if( couponType != 'free_delivery' && coupon.discountTypeName == 'percentage' && double.parse(discountAmount) > 100){
                                    showQuikseeSnackBarWidget(getTranslated('discount_amount_should_be_less_then', context), context, sanckBarType: SnackBarType.warning);
                                  }else if (couponType != 'free_delivery' && coupon.discountTypeName == 'amount' && double.parse(discountAmountController.text) > double.parse(minimumPurchaseController.text)) {
                                    showQuikseeSnackBarWidget(getTranslated('minimum_purchase_amount_should_be_greater_than_the_discount_amount', context), context, sanckBarType: SnackBarType.warning);
                                  } else{
                                    Coupons coupons = Coupons(
                                      id: update? widget.coupons!.id: null,
                                      title: couponTitle,
                                      couponType: couponType,
                                      customerId: customerId,
                                      code: couponCode,
                                      limit: double.parse(limit),
                                      discountType: discountType,
                                      discount: coupon.selectedCouponType == 'discount_on_purchase'?double.parse(discountAmount):0,
                                      minPurchase: double.parse(minimumPurchase),
                                      maxDiscount: maxDiscount.isNotEmpty? double.parse(maxDiscount) : 0,
                                      startDate: startDate,
                                      expireDate: endDate
                                    );
                                    coupon.addNewCoupon(context, coupons, update);
                                  }
                                }
                              ),
                            );
                          }
                      );
                    }
                ))
          ]);
        }
      ),
    );
  }
}
