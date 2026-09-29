import 'package:flutter/material.dart';
import 'package:quiksee/features/emergency_contact/controllers/emergency_contruct_controller.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/emergency_contact/widgets/emergency_contact_card_widget.dart';

import 'emergency_card_shimmer_widget.dart';

class EmergencyContactListViewWidget extends StatelessWidget {
  final EmergencyContactController? emergencyContactController;
   const EmergencyContactListViewWidget({super.key, this.emergencyContactController});

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      !emergencyContactController!.isLoading ? emergencyContactController!.emergencyContactList!.isNotEmpty?
      ListView.builder(
          itemCount: emergencyContactController!.emergencyContactList!.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index){
            return EmergencyContactCardWidget(contactList: emergencyContactController!.emergencyContactList![index],);
          }):const NoDataScreenWidget() : const EmergencyContactCardShimmer()
    ],);
  }
}

