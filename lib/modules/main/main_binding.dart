import 'package:get/get.dart';
import '../home/home_controller.dart';
import '../history/history_controller.dart';
import '../invite/invite_controller.dart';
import '../profile/profile_controller.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<InviteController>(() => InviteController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
