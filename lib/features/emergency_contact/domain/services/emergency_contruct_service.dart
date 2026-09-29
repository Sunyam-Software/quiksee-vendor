

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/emergency_contact/domain/models/emergency_contact_model.dart';
import 'package:quiksee/features/emergency_contact/domain/repositories/emergency_contruct_repository_interface.dart';
import 'package:quiksee/features/emergency_contact/domain/services/emergency_contruct_service_interface.dart';

class EmergencyContactService implements EmergencyContactServiceInterface{
  EmergencyContactRepositoryInterface emergencyContactRepoInterface;
  EmergencyContactService({required this.emergencyContactRepoInterface});

  @override
  Future getEmergencyContactList() async {
    Response response = await emergencyContactRepoInterface.getList();
    if (response.statusCode == 200) {
      return EmergencyContactModel.fromJson(response.body).contactList;
    } else {
      ApiChecker.checkApi(response);
    }
  }
}