import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';
import 'package:quiksee/features/assignment/domain/models/delivery_areas_model.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class ProfileActivationStatusWidget extends StatelessWidget {
  final UserInfoModel? profile;

  const ProfileActivationStatusWidget({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();

    final bool accountActive = profile!.isAccountActive;
    final bool isOnline = profile!.isOnline == 1;
    final bool autoAssign = profile!.autoAssignEnabled == true;

    return Container(
      margin: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeSmall,
        0,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
      ),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: accountActive
            ? Theme.of(context).primaryColor.withValues(alpha: .08)
            : Colors.orange.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(
          color: accountActive
              ? Theme.of(context).primaryColor.withValues(alpha: .25)
              : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'activation_status'.tr,
            style: rubikMedium.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          _row(
            context,
            'account_activation'.tr,
            accountActive ? 'account_activated'.tr : 'account_not_activated'.tr,
            accountActive ? Colors.green : Colors.orange,
          ),
          _row(
            context,
            'online_status'.tr,
            isOnline ? 'online'.tr : 'offline'.tr,
            isOnline ? Colors.green : Theme.of(context).hintColor,
          ),
          _row(
            context,
            'auto_assign_enabled'.tr,
            autoAssign ? 'enabled'.tr : 'disabled'.tr,
            autoAssign ? Colors.green : Theme.of(context).hintColor,
          ),
          if (Get.isRegistered<AssignmentController>())
            GetBuilder<AssignmentController>(
              builder: (assignmentController) {
                final areaText = _assignedAreaText(
                  assignmentController.deliveryAreas,
                  profile!.deliveryAreasSummary,
                );
                return _areaRow(
                  context,
                  'assigned_delivery_area'.tr,
                  areaText,
                  Theme.of(context).primaryColor,
                );
              },
            ),
          if (!accountActive)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Text(
                'account_activation_hint'.tr,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          if (accountActive && !isOnline)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Text(
                'go_online_for_orders'.tr,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _assignedAreaText(
    DeliveryAreasModel? areas,
    DeliveryAreasSummary? summary,
  ) {
    if (areas?.servesAllAreas == true) {
      return 'all_delivery_areas'.tr;
    }

    final labels = areas?.assignedAreaLabels ?? [];
    if (labels.isNotEmpty) {
      return labels.join(', ');
    }

    final radius = areas?.assignmentCircle?.radius;
    if (radius != null && radius > 0) {
      return 'assignment_radius_km'.trParams({
        'radius': radius % 1 == 0 ? '${radius.toInt()}' : radius.toStringAsFixed(1),
      });
    }

    if (summary != null) {
      if (summary.servesAllAreas == true) {
        return 'all_delivery_areas'.tr;
      }
      final zoneCount = summary.zoneCount ?? 0;
      if (zoneCount > 0) {
        return 'delivery_zones_count'.trParams({'count': '$zoneCount'});
      }
    }

    return 'not_assigned'.tr;
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        children: [
          Expanded(child: Text(label, style: rubikRegular)),
          Text(value, style: rubikMedium.copyWith(color: valueColor)),
        ],
      ),
    );
  }

  Widget _areaRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: rubikRegular)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: rubikMedium.copyWith(
                color: valueColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
