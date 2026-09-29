import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/screens/bank_info_edit_screen.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';

class WalletBankInfoWidget extends StatelessWidget {
  const WalletBankInfoWidget({super.key});

  bool _hasBankInfo(ProfileController profileController) {
    final profile = profileController.profileModel;
    if (profile == null) return false;
    return [
      profile.holderName,
      profile.bankName,
      profile.branch,
      profile.branchAddress,
      profile.ifscCode,
      profile.accountNo,
    ].any((value) => value != null && value.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final profile = profileController.profileModel;
        final hasBankInfo = _hasBankInfo(profileController);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[Get.isDarkMode ? 900 : 200]!,
                  spreadRadius: 0.5,
                  blurRadius: 0.3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: Dimensions.iconSizeLarge,
                        height: Dimensions.iconSizeLarge,
                        child: Image.asset(Images.bankInfo),
                      ),
                      SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          'bank_info'.tr,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Get.to(() => const BankInfoEditScreen()),
                        child: Row(
                          children: [
                            Text(
                              hasBankInfo ? 'edit_info'.tr : 'add_bank_information'.tr,
                              style: rubikMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Icon(
                              hasBankInfo ? Icons.edit : Icons.add,
                              size: Dimensions.iconSizeDefault,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasBankInfo)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeDefault,
                      0,
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeDefault,
                    ),
                    child: Text(
                      'add_a_bank_account'.tr,
                      style: rubikRegular.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  )
                else ...[
                  _BankInfoRow(
                    label: 'ac_holder',
                    value: profile?.holderName,
                  ),
                  _BankInfoRow(
                    label: 'bank',
                    value: profile?.bankName,
                  ),
                  _BankInfoRow(
                    label: 'branch',
                    value: profile?.branch,
                  ),
                  if ((profile?.branchAddress ?? '').trim().isNotEmpty)
                    _BankInfoRow(
                      label: 'branch_address',
                      value: profile?.branchAddress,
                    ),
                  if ((profile?.ifscCode ?? '').trim().isNotEmpty)
                    _BankInfoRow(
                      label: 'ifsc_code',
                      value: profile?.ifscCode,
                    ),
                  _BankInfoRow(
                    label: 'account_no',
                    value: profile?.accountNo,
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BankInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLast;

  const _BankInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        (value == null || value!.trim().isEmpty) ? 'no_data_found'.tr : value!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeExtraSmall,
        Dimensions.paddingSizeDefault,
        isLast ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '${label.tr}:',
              style: rubikRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
