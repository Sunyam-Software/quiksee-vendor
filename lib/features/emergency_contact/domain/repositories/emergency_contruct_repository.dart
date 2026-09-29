import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/emergency_contact/domain/repositories/emergency_contruct_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class EmergencyContactRepository implements EmergencyContactRepositoryInterface{
  final ApiClient apiClient;
  EmergencyContactRepository({required this.apiClient});

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() async{
    return await apiClient.getData(AppConstants.emergencyContactList);
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}