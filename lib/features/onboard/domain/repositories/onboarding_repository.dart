import 'package:get/get.dart';
import 'package:quiksee/features/onboard/domain/models/onboarding_model.dart';
import 'package:quiksee/features/onboard/domain/repositories/onbording_repository_interface.dart';
import 'package:quiksee/utill/images.dart';

class OnBoardingRepository implements OnboardRepositoryInterface {


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
    try {
      List<OnBoardingModel> onBoardingList = [
        OnBoardingModel(Images.onboard_1, 'on_boarding_1_title'.tr, 'on_boarding_1_description'.tr),
        OnBoardingModel(Images.onboard_2, 'on_boarding_2_title'.tr, 'on_boarding_2_description'.tr),
        OnBoardingModel(Images.onboard_3, 'on_boarding_3_title'.tr, 'on_boarding_3_description'.tr),
      ];

      Response response = Response(body: onBoardingList, statusCode: 200);
      return response;
    } catch (e) {
      return const Response(statusCode: 404, statusText: 'Onboarding data not found');
    }
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
