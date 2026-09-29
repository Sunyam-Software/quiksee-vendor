
import 'package:get/get.dart';
import 'package:quiksee/features/onboard/domain/models/onboarding_model.dart';
import 'package:quiksee/features/onboard/domain/services/onboard_service_interface.dart';

class OnBoardingController extends GetxController implements GetxService {
  final OnboardServiceInterface onboardServiceInterface;
  OnBoardingController({required this.onboardServiceInterface});

  List<OnBoardingModel> _onBoardingList = [];
  int _selectedIndex = 0;

  List<OnBoardingModel> get onBoardingList => _onBoardingList;
  int get selectedIndex => _selectedIndex;

  void changeSelectIndex(int index) {
    _selectedIndex = index;
    update();
  }

  void getOnBoardingList() async {
    _onBoardingList = await onboardServiceInterface.getOnBoardingList();
    update();
  }
}
