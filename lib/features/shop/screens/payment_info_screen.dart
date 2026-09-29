import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/paginated_list_view_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/guideline_warning_widget.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/bank_info/screens/bank_editing_screen.dart';
import 'package:quiksee_vendor_app/features/bank_info/widgets/bank_info_widget.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/features/shop/screens/add_payment_info_screen.dart';
import 'package:quiksee_vendor_app/features/shop/widgets/status_change_botomsheet_widget.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

import '../../../main.dart' show Get;

class PaymentInfoScreen extends StatefulWidget {
  const PaymentInfoScreen({super.key});

  @override
  State<PaymentInfoScreen> createState() => _PaymentInfoScreenState();
}

class _PaymentInfoScreenState extends State<PaymentInfoScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final shop = Provider.of<ShopController>(context, listen: false);
    shop.getPaymentInfoList(1);
    shop.getPaymentWithdrawalMethodList();
    Provider.of<BankInfoController>(context, listen: false).getBankInfo(context);
  }

  ProfileInfoModel? _bankModel(BankInfoController bank, ProfileController profile) {
    return bank.bankInfo ?? profile.userInfoModel;
  }

  bool _hasBankDetails(ProfileInfoModel? bank) {
    if (bank == null) return false;
    return (bank.accountNo ?? '').trim().isNotEmpty ||
        (bank.bankName ?? '').trim().isNotEmpty ||
        (bank.holderName ?? '').trim().isNotEmpty;
  }

  Future<void> _openBankEditor() async {
    final bankController = Provider.of<BankInfoController>(context, listen: false);
    ProfileInfoModel? model = bankController.bankInfo;
    if (model == null) {
      await bankController.getBankInfo(context);
      if (!mounted) return;
      model = bankController.bankInfo;
    }
    model ??= Provider.of<ProfileController>(context, listen: false).userInfoModel;
    if (model == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BankEditingScreen(sellerModel: model)),
    );
    if (!mounted) return;
    await bankController.getBankInfo(context);
    if (!mounted) return;
    await Provider.of<ProfileController>(context, listen: false).getSellerInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
        child: Consumer<ShopController>(
          builder: (context, shopController, child) {
            return Consumer<BankInfoController>(
              builder: (context, bankController, _) {
                return Consumer<ProfileController>(
                  builder: (context, profile, _) {
                    final bank = _bankModel(bankController, profile);
                    final hasBank = _hasBankDetails(bank);
                    final paymentMethods = shopController.paymentInformationModel?.data ?? [];
                    final loadingPayments = shopController.paymentInformationModel == null;

                    if (loadingPayments && !hasBank) {
                      return const PaymentMethodListShimmer();
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                GuidelineWarningWidget(
                                  guidelineStatus: GuidelineStatus.warning,
                                  content: RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style.copyWith(
                                        color: Theme.of(context).textTheme.headlineLarge?.color,
                                      ),
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: getTranslated('please_verify_your_payment', context) ??
                                              'Add your bank account to receive payouts from your wallet.',
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                  showCrossButton: false,
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                Container(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(Dimensions.paddingSizeDefault),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getTranslated('bank_info', context) ?? 'Bank account',
                                        style: robotoBold.copyWith(
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: Dimensions.paddingSizeDefault,
                                        ),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      Text(
                                        getTranslated('you_should_fill_up', context) ??
                                            'This bank account is used to send your order earnings.',
                                        style: robotoRegular.copyWith(
                                          color: Theme.of(context).hintColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      if (hasBank && bank != null)
                                        BankInfoWidget(
                                          name: bank.holderName ?? '',
                                          bank: bank.bankName ?? '',
                                          branch: bank.branch ?? '',
                                          branchAddress: bank.branchAddress ?? '',
                                          ifscCode: bank.ifscCode ?? '',
                                          accountNo: bank.accountNo ?? '',
                                          accountType: bank.displayAccountType(),
                                        )
                                      else
                                        PaymentMethodEmptyWidget(onAdd: _openBankEditor),
                                    ],
                                  ),
                                ),
                                if (paymentMethods.isNotEmpty) ...[
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Container(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(Dimensions.paddingSizeDefault),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated('payment_method_list', context) ?? '',
                                          style: robotoBold.copyWith(
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                            fontSize: Dimensions.paddingSizeDefault,
                                          ),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeSmall),
                                        PaginatedListViewWidget(
                                          reverse: false,
                                          scrollController: scrollController,
                                          totalSize: shopController.paymentInformationModel?.totalSize ?? 0,
                                          offset: shopController.paymentInformationModel?.offset ?? 0,
                                          onPaginate: (int? offset) async {
                                            await shopController.getPaymentInfoList(offset ?? 0);
                                          },
                                          itemView: ListView.separated(
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: paymentMethods.length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index) {
                                              return PaymentInfoWidget(index: index);
                                            },
                                            separatorBuilder: (context, index) {
                                              return const SizedBox(height: Dimensions.paddingSizeSmall);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                              ],
                            ),
                          ),
                        ),
                        QuikseeButtonWidget(
                          btnTxt: hasBank
                              ? (getTranslated('edit_info', context) ?? 'Edit bank account')
                              : (getTranslated('add_payment_info', context) ?? 'Add bank account'),
                          onTap: _openBankEditor,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

TableRow _buildTableRow(String label, String value) {
  return TableRow(
    children: [
      Text(
        formatField(label),
        style: robotoMedium.copyWith(color: Theme.of(Get.context!).textTheme.headlineLarge?.color, fontSize: Dimensions.fontSizeDefault)
      ),

      Text(
        ': $value',
        style: robotoMedium.copyWith(color: Theme.of(Get.context!).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeDefault)
      ),
    ],
  );
}

String formatField(String input) {
  return input.split('_').where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
}

class PaymentMethodEmptyWidget extends StatelessWidget {
  final VoidCallback? onAdd;
  const PaymentMethodEmptyWidget({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height*0.5,
      decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha: 0.15) ,
          borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault))
      ),

      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(children: []),

          const QuikseeAssetImageWidget(Images.paymentMethodWarningIcon, width: 45, height: 45),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            getTranslated('no_payment_info', context) ?? 'No bank account added yet',
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          InkWell(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault))
              ),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 20, width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor
                    ),
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).primaryColor,
                      size: 15
                    )
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    getTranslated('add_payment_info', context) ?? 'Add bank account',
                    style: robotoRegular.copyWith(color: Theme.of(context).highlightColor, fontSize: Dimensions.fontSizeDefault),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentInfoWidget extends StatelessWidget {
  final int index;
  const PaymentInfoWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return  Consumer<ShopController>(
      builder: (context, shopController, child) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha: 0.07) ,
            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(shopController.paymentInformationModel?.data?[index].methodName ?? '', style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.paddingSizeDefault),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        if(shopController.paymentInformationModel?.data?[index].isDefault ?? false)
                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: 0.10) ,
                              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                            ),
                            child: Text(getTranslated('default', context) ?? '', style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: Dimensions.fontSizeDefault)),
                          ),
                      ],
                    ),
                  ),

                  PopupMenuButton<int>(
                    icon: Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        border: Border.all(color: Theme.of(context).primaryColor)
                      ),
                      child: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
                    ),
                    offset: const Offset(0, 40),
                    onSelected: (value) {
                      if(value == 2) {
                        shopController.setDefaultPaymentMethod(shopController.paymentInformationModel?.data?[index].id ?? 0);
                      } else if (value == 3) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddPaymentInfoScreen(formUpdate: true, paymentInfoData: shopController.paymentInformationModel?.data?[index])));
                      } else if (value == 4 && shopController.paymentInformationModel?.data?[index].isDefault == false) {
                        shopController.deletePaymentMethodStatus(shopController.paymentInformationModel?.data?[index].id ?? 0, index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(getTranslated('statuss', context)!,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 2,
                            ),
                            const SizedBox(width: 25),

                            Consumer<ShopController>(
                              builder: (context, shopController, child) {
                                return FlutterSwitch(width: 40.0, height: 20.0, toggleSize: 18.0,
                                  value: shopController.paymentInformationModel?.data?[index].isActive ?? false,
                                  borderRadius: 20.0,
                                  activeColor: Theme.of(context).primaryColor,
                                  padding: 1.0,
                                  onToggle:(bool isActive) {
                                    showModalBottomSheet(context: context, isScrollControlled: true,
                                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0),
                                      builder: (con) => StatusChangeBottomSheetWidget(
                                        title: (shopController.paymentInformationModel?.data?[index].isActive ?? false) ?
                                        ((getTranslated('do_you_want_to_to_disable_the', context) ?? '') + (shopController.paymentInformationModel?.data?[index].methodName ?? ''))
                                        : (getTranslated('do_you_want_to_to_enable_the', context) ?? '') + (shopController.paymentInformationModel?.data?[index].methodName ?? ''),
                                        subtitle: getTranslated('turning_on_this_status_will_make', context),
                                        onNoPressed: () {},
                                        onYesPressed: () {
                                          shopController.updatePaymentMethodStatus(isActive, index, shopController.paymentInformationModel?.data?[index].id ?? 0);
                                          Navigator.pop(Get.context!);
                                        } ,
                                      )
                                    );
                                  },
                                );
                              }
                            )

                          ],
                        ),
                      ),

                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(getTranslated('mark_as_default', context)!,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 2,
                            ),
                            const SizedBox(width: 10),

                            const QuikseeAssetImageWidget(Images.defaultMarkIcon, width: 20, height: 20)
                          ],
                        ),
                      ),

                      if ('flat' == 'flat' )...[
                        PopupMenuItem(
                          value: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(getTranslated('edit', context)!,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 2,
                              ),
                              const SizedBox(width: 10),

                              QuikseeAssetImageWidget(Images.myShopEditIcon, width: 20, height: 20, color: Theme.of(context).colorScheme.onPrimary)
                            ],
                          ),
                        )
                      ],

                      PopupMenuItem(
                        value: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(getTranslated('delete', context)!,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                color: (shopController.paymentInformationModel?.data![index].isDefault ?? false) ?
                                Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color
                              ), maxLines: 2,
                            ),
                            const SizedBox(width: 10),

                            Opacity(
                              opacity: (shopController.paymentInformationModel?.data![index].isDefault ?? false) ? 0.5 : 1.0,
                              child: const QuikseeAssetImageWidget(Images.trashIcon, width: 20, height: 20),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration:  BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                    color: Theme.of(context).cardColor
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(100),
                    },
                    children: [

                      for (var methodInfo in shopController.paymentInformationModel?.data?[index].methodInfo?.entries ?? {}.entries)...[
                        _buildTableRow(
                          getTranslated(methodInfo.key, context) ?? '',
                          methodInfo.value ?? '',
                        ),

                        const TableRow(children: [
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        ]),
                      ]

                    ],
                  )
              ),

            ],
          ),
        );
      }
    );
  }
}

class PaymentMethodListShimmer extends StatelessWidget {
  const PaymentMethodListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 3,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          enabled: true,
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
              border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
            ),

            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 85,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                        color: Theme.of(context).colorScheme.secondaryContainer
                      ),
                    ),
                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                        color: Theme.of(context).colorScheme.secondaryContainer
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 85,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 105,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 75,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 83,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      ],
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 85,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                              border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                              color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 75,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                              border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                              color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Container(
                          width: 97,
                          padding: const EdgeInsets.all(Dimensions.paddingEye),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeVeryTiny)),
                            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                            color: Theme.of(context).colorScheme.secondaryContainer
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: Dimensions.paddingSizeMedium);
      },
    );
  }
}

