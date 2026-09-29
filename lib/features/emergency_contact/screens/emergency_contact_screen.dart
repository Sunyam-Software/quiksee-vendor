import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/emergency_contact/controllers/emergency_contruct_controller.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/features/emergency_contact/widgets/emergency_contact_list_widget.dart';

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<EmergencyContactController>().getEmergencyContactList();
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'emergency_contact'.tr, isBack: true),
      body: RefreshIndicator(
        onRefresh: () async=> Get.find<EmergencyContactController>().getEmergencyContactList(),
        child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Column(children:  [
              GetBuilder<EmergencyContactController>(
                builder: (emergencyContactController) =>
                   EmergencyContactListViewWidget(emergencyContactController: emergencyContactController)
                )]))]),
      ),
    );
  }
}
