
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/onboard/controllers/onboarding_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/permissions/screens/app_permissions_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Get.find<OnBoardingController>().getOnBoardingList();

  }

  void _completeOnboarding() {
    Get.find<SplashController>().disableIntro();
    Get.offAll(() => const AppPermissionsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: SafeArea(
        child: GetBuilder<OnBoardingController>(
          builder: (onBoardingController) {
            final isLastPage =
                onBoardingController.selectedIndex == onBoardingController.onBoardingList.length - 1;

            return onBoardingController.onBoardingList.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        pageSnapping: true,
                        itemCount: onBoardingController.onBoardingList.length,
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) => onBoardingController.changeSelectIndex(index),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SizedBox.expand(
                              child: Image.asset(
                                onBoardingController.onBoardingList[index].imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).size.height * 0.035,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isLastPage
                                ? InkWell(
                                    key: const ValueKey('get_started_button'),
                                    onTap: _completeOnboarding,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: 162,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: .22),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'get_started'.tr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                : TextButton(
                                    key: const ValueKey('skip_button'),
                                    onPressed: _completeOnboarding,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).primaryColor,
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: Text('skip'.tr),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox();
          },
        ),
      ),
    );
  }
}
