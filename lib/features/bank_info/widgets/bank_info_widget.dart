import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class BankInfoWidget extends StatelessWidget {
  final String? name;
  final String? bank;
  final String? branch;
  final String? branchAddress;
  final String? ifscCode;
  final String? accountNo;
  final String? accountType;

  const BankInfoWidget({
    super.key,
    this.name,
    this.bank,
    this.branch,
    this.branchAddress,
    this.ifscCode,
    this.accountNo,
    this.accountType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(Images.bankInfoBg),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: Dimensions.paddingSizeDefault,
                        left: Dimensions.paddingSizeDefault,
                      ),
                      child: SizedBox(width: 40, child: Image.asset(Images.accountHolder)),
                    ),
                    Expanded(child: CardItem(title: 'ac_holder', value: name)),
                  ],
                ),
                Divider(color: Theme.of(context).cardColor.withValues(alpha: .5), thickness: 1.5),
                CardItem(title: 'bank', value: bank),
                CardItem(title: 'branch', value: branch),
                if (branchAddress != null && branchAddress!.trim().isNotEmpty)
                  CardItem(title: 'branch_address', value: branchAddress),
                if (ifscCode != null && ifscCode!.trim().isNotEmpty)
                  CardItem(title: 'ifsc_code', value: ifscCode),
                CardItem(title: 'account_no', value: accountNo),
                if (accountType != null && accountType!.trim().isNotEmpty)
                  CardItem(title: 'account_type', value: accountType),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          Text(
            '${getTranslated(title, context)} : ',
            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          Expanded(
            child: Text(
              value ?? getTranslated('no_data_found', context) ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
}
