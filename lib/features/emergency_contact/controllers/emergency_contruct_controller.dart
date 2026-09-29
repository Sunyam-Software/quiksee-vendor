
import 'package:get/get.dart';
import 'package:quiksee/features/emergency_contact/domain/models/emergency_contact_model.dart';
import 'package:quiksee/features/emergency_contact/domain/services/emergency_contruct_service_interface.dart';

class EmergencyContactController extends GetxController implements GetxService{
  final EmergencyContactServiceInterface emergencyContactServiceInterface;
  EmergencyContactController({required this.emergencyContactServiceInterface});

  List<ContactList>? _emergencyContactList =[];
  List<ContactList>? get emergencyContactList => _emergencyContactList;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> getEmergencyContactList() async {
    _isLoading = true;
    update();
    _emergencyContactList = await emergencyContactServiceInterface.getEmergencyContactList();
    _isLoading = false;
    update();
  }
}