
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/features/profile/screens/bank_info_edit_screen.dart';


class BankInfoScreen extends StatelessWidget {
  const BankInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'bank_info'.tr, isBack: true),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          final profile = profileController.profileModel;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final String name = profile.holderName ?? '';
          final String bank = profile.bankName ?? '';
          final String branch = profile.branch ?? '';
          final String branchAddress = profile.branchAddress ?? '';
          final String ifscCode = profile.ifscCode ?? '';
          final String accountNo = profile.accountNo ?? '';
          final bool hasBankDetails = name.isNotEmpty ||
              bank.isNotEmpty ||
              branch.isNotEmpty ||
              accountNo.isNotEmpty;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => const BankInfoEditScreen()),
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          hasBankDetails ? 'edit_info'.tr : 'add_bank_information'.tr,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Get.isDarkMode
                                ? Theme.of(context).hintColor
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        Icon(
                          hasBankDetails ? Icons.edit : Icons.add,
                          color: Get.isDarkMode
                              ? Theme.of(context).hintColor
                              : Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: Get.width / 3,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor.withValues(alpha: .05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(100),
                                  bottomLeft: Radius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: Get.width / 4,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor.withValues(alpha: .05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(100),
                                  bottomLeft: Radius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            SizedBox(height: Dimensions.paddingSizeDefault),
                            Row(
                              children: [
                                Expanded(
                                  child: CardItem(title: 'ac_holder', value: name),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                                  child: SizedBox(
                                    width: 40,
                                    child: Image.asset(Images.bankInfo),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: Theme.of(context).cardColor.withValues(alpha: .5),
                              thickness: 1.5,
                            ),
                            CardItem(title: 'bank', value: bank),
                            CardItem(title: 'branch', value: branch),
                            CardItem(title: 'branch_address', value: branchAddress),
                            CardItem(title: 'ifsc_code', value: ifscCode),
                            CardItem(title: 'account_no', value: accountNo),
                            SizedBox(height: Dimensions.paddingSizeDefault),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final String? title;
  final String? value;
  const CardItem({super.key, this.title, this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue =
        (value == null || value!.trim().isEmpty) ? 'no_data_found'.tr : value!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${title!.tr} : ',
            style: rubikRegular.copyWith(
              color: Get.isDarkMode
                  ? Theme.of(context).hintColor
                  : Theme.of(context).cardColor,
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: rubikRegular.copyWith(
                color: Get.isDarkMode
                    ? Theme.of(context).hintColor
                    : Theme.of(context).cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
