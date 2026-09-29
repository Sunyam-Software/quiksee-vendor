import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/features/order/widgets/icon_with_text_row_widget.dart';
import 'package:quiksee_vendor_app/features/order_details/widgets/show_on_map_dialog_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/helper/map_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShippingAndBillingWidget extends StatefulWidget {
  final Order? orderModel;
  final bool? onlyDigital;
  final String orderType;
  const ShippingAndBillingWidget({super.key, this.orderModel, this.onlyDigital, required this.orderType});

  @override
  State<ShippingAndBillingWidget> createState() => _ShippingAndBillingWidgetState();
}

class _ShippingAndBillingWidgetState extends State<ShippingAndBillingWidget> {
  bool isExpand = false;

  @override
  Widget build(BuildContext context) {

    print(widget.onlyDigital);

    return  widget.orderModel?.orderType == 'POS' ? SizedBox() :
    CollapsibleAddressSection(
      onlyDigital: widget.onlyDigital,
      orderType: widget.orderType,
      orderModel: widget.orderModel,
      addressContent: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              widget.orderModel?.shippingAddressData != null  && !(widget.onlyDigital ?? false) ?
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated('shipping_address', context)!,
                      style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)
                    ),
                  ]
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  children: [
                    Expanded(
                      child: IconWithTextRowWidget(
                        isBold: true,
                        icon: Icons.person,
                        text: '${widget.orderModel?.shippingAddressData != null ?
                        widget.orderModel?.shippingAddressData!.contactPersonName : ''}',
                      ),
                    ),

                    Expanded(
                      child: IconWithTextRowWidget(
                        icon: Icons.call,
                        text: '${widget.orderModel?.shippingAddressData != null ?
                        widget.orderModel?.shippingAddressData!.phone : ''}',),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(children: [
                  Expanded(child: IconWithTextRowWidget(
                    imageIcon: Images.homeIconAddress,
                    text: '${widget.orderModel?.shippingAddressData?.addressType != null ?
                    widget.orderModel?.shippingAddressData!.addressType : ''}', icon: null,)),

                  Expanded(child: IconWithTextRowWidget(
                    imageIcon: Images.countryIconAddress,
                    text: widget.orderModel?.shippingAddressData?.country.toString().trim() == 'null' ? '' : widget.orderModel?.shippingAddressData?.country ?? '', icon: null,

                  ))]
                ),
                if(widget.orderModel?.shippingAddressData?.country != null || widget.orderModel?.shippingAddressData?.addressType != null )
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(children: [
                  Expanded(child: IconWithTextRowWidget(
                    imageIcon: Images.cityIconAddress,
                    icon: Icons.location_city,
                    text: '${widget.orderModel?.shippingAddressData?.city != null ?
                    widget.orderModel?.shippingAddressData!.city : ''}')
                  ),

                  Expanded(child: IconWithTextRowWidget(
                      imageIcon: Images.zipIconAddress,
                      icon: Icons.location_city,
                      text: widget.orderModel?.shippingAddressData?.zip ?? '')
                  )]
                ),
                if(widget.orderModel?.shippingAddressData?.city != null || widget.orderModel?.shippingAddressData?.zip != null )
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(mainAxisAlignment:MainAxisAlignment.start, crossAxisAlignment:CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                      Colors.white : Theme.of(context).hintColor.withValues(alpha: 0.5), size: 25),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text('${widget.orderModel?.shippingAddressData != null ?
                        widget.orderModel?.shippingAddressData!.address : ''}',
                            maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))
                      ))
                    ]
                ),
              ]):const SizedBox(),

              if(widget.orderModel?.billingAddressData != null &&  widget.orderModel?.shippingAddressData != null &&
                  widget.orderModel?.shippingAddressData?.contactPersonName != null && widget.orderModel!.shippingAddressData!.contactPersonName!.trim().isNotEmpty)
                Divider(thickness: .25, color: Theme.of(context).primaryColor.withValues(alpha:0.50)),

              widget.orderModel?.billingAddressData != null ?
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(getTranslated('billing_address', context)!,
                        style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  if(widget.orderModel?.shippingAddressData?.id == widget.orderModel?.billingAddressData?.id)...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('same_as_shipping_address', context)!,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)
                          )
                        ],
                      ),
                    )
                  ],

                  if(widget.orderModel?.shippingAddressData?.id != widget.orderModel?.billingAddressData?.id)...[
                    Row(
                      children: [
                        Expanded(
                          child: IconWithTextRowWidget(
                              isBold: true,
                              icon: Icons.person,
                              text: '${widget.orderModel?.billingAddressData != null ?
                              widget.orderModel?.billingAddressData!.contactPersonName : ''}'),
                        ),

                        Expanded(
                          child: IconWithTextRowWidget(icon: Icons.call,
                              text: '${widget.orderModel?.billingAddressData != null ?
                              widget.orderModel?.billingAddressData!.phone : ''}'),
                        )
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(children: [
                      Expanded(child: IconWithTextRowWidget(
                        imageIcon: Images.homeIconAddress,
                        text: '${widget.orderModel?.billingAddressData?.addressType != null ?
                        widget.orderModel?.billingAddressData!.addressType : ''}', icon: null,)),

                      Expanded(child: IconWithTextRowWidget(
                        imageIcon: Images.countryIconAddress,
                        text: widget.orderModel!.billingAddressData!.country ?? '',
                        icon: null,))]
                    ),
                    if(widget.orderModel?.billingAddressData?.country != null || widget.orderModel?.billingAddressData?.addressType != null )
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(children: [
                      Expanded(child: IconWithTextRowWidget(
                          imageIcon: Images.cityIconAddress,
                          icon: Icons.location_city,
                          text: '${widget.orderModel?.billingAddressData?.city != null ?
                          widget.orderModel?.billingAddressData!.city : ''}')),

                      Expanded(child: IconWithTextRowWidget(
                        imageIcon: Images.zipIconAddress,
                        icon: Icons.location_city,
                        text: widget.orderModel?.billingAddressData?.zip ?? '',))]
                    ),
                    if(widget.orderModel?.billingAddressData?.city != null || widget.orderModel?.billingAddressData?.zip != null )
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(mainAxisAlignment:MainAxisAlignment.start,
                      crossAxisAlignment:CrossAxisAlignment.start, children: [
                        Icon(Icons.location_on, color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                        Colors.white : Theme.of(context).hintColor.withValues(alpha: 0.5)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(' ${widget.orderModel?.billingAddressData != null ?
                          widget.orderModel?.billingAddressData!.address : ''}',
                              maxLines: 3, overflow: TextOverflow.ellipsis,
                              style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        )),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ]

                ]
                ),
              ):const SizedBox(),
            ],
            )
          )

        ],
      ),
    );
  }
}

class CollapsibleAddressSection extends StatefulWidget {
  final Widget addressContent;
  final bool? onlyDigital;
  final String orderType;
  final Order? orderModel;
  const CollapsibleAddressSection({super.key, required this.addressContent, this.onlyDigital, required this.orderType, this.orderModel});

  @override
  State<CollapsibleAddressSection> createState() => _CollapsibleAddressSectionState();
}

class _CollapsibleAddressSectionState extends State<CollapsibleAddressSection>
    with SingleTickerProviderStateMixin {
  bool isExpand = true;

  Future<void> _openOrderAddressMap(
    BuildContext context,
    OrderDetailsController resProvider,
  ) async {
    final shipping = widget.orderModel?.shippingAddressData;
    if (shipping == null) {
      showQuikseeSnackBarWidget(
        getTranslated('address_not_found', context) ?? 'Address not found',
        context,
        sanckBarType: SnackBarType.warning,
      );
      return;
    }

    final BillingAddressData address = resProvider.getAddressForMap(
      shipping,
      widget.orderModel?.billingAddressData,
    );
    final LatLng? position = MapHelper.latLngFromAddress(address);

    if (position != null) {
      final opened = await MapHelper.openExternalMap(position);
      if (opened) return;
    }

    final openedByAddress = await MapHelper.openExternalMapForAddress(address);
    if (openedByAddress) return;

    if (!context.mounted) return;

    final bool mapEnabled = Provider.of<SplashController>(context, listen: false)
            .configModel
            ?.mapApiStatus ==
        1;

    if (position != null && mapEnabled) {
      await resProvider.setMarker(address);
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => ShowOnMapDialogWidget(
          billingAddressData: address,
          position: position,
        ),
      );
      return;
    }

    showQuikseeSnackBarWidget(
      getTranslated('location_not_available', context) ??
          'Location not available for this address',
      context,
      sanckBarType: SnackBarType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:0.2), spreadRadius:1.5, blurRadius: 3)],
        color: Theme.of(context).cardColor,
      ),

      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Address',
                  style: robotoBold.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),

                widget.orderType != 'POS' || !widget.onlyDigital!?
                Provider.of<SplashController>(context, listen: false).configModel!.mapApiStatus == 1 ?
                Consumer<OrderDetailsController>(
                  builder: (context, resProvider, child) {
                    return InkWell(
                      onTap: () => _openOrderAddressMap(context, resProvider),
                      child: Row(children: [
                        Text('${getTranslated('show_on_map', context)}', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                          child: Image.asset(Images.showOnMap, width: Dimensions.iconSizeDefault)
                        ),
                      ]),
                    );
                  }
                ) : const SizedBox() : const SizedBox(),

              ],
            ),
          ),

          Divider(
            thickness: 0.2,
            height: 1,
            color: Theme.of(context).hintColor.withValues(alpha: 0.65),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpand ? Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.only(
               top: Dimensions.paddingSizeSmall,
               left: Dimensions.paddingSizeDefault,
               right: Dimensions.paddingSizeDefault,
               bottom: Dimensions.paddingSizeDefault,
              ),
              child: widget.addressContent,
            ) : const SizedBox(),

          ),
        ],
      ),
    );
  }
}

