import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/emergency_contact/domain/models/emergency_contact_model.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_action_button_widget.dart';
import 'package:quiksee/features/help_and_support/screens/help_and_support_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactCardWidget extends StatelessWidget {
  final ContactList? contactList;
  const EmergencyContactCardWidget({super.key, this.contactList});

  @override
  Widget build(BuildContext context) {
    return Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,Dimensions.paddingSizeDefault,0),
      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Get.find<ThemeController>().darkTheme ? Colors.black.withValues(alpha:0.10) : Colors.grey[100]!,
            blurRadius: 5, spreadRadius: 1, offset: const Offset(0,2))],),
        padding:  EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [

          Column(crossAxisAlignment: CrossAxisAlignment.start,children:  [
            Text(contactList!.name!, style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
            Padding(padding:  EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Row(children: [
                SizedBox(width: Dimensions.iconSizeMediumSmall, child: Image.asset(Images.phone)),
                 Padding(
                   padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                  child: Text(contactList?.phone ?? '', style: rubikRegular),
                 ),
              ]),
            )],
          ),

          GestureDetector(child: const QuikseeActionButtonWidget(title: 'call_now'),onTap: (){
          _launchUrl("tel:${contactList!.phone}",false);
        },),
      ],),),
    );
  }
}

Future<void> _launchUrl(String _url, bool isMail) async {
  if (!await launchUrl(Uri.parse(isMail? params.toString() :_url))) {
    throw 'Could not launch $_url';
  }
}
