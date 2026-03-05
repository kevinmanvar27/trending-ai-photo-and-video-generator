import 'package:get/get.dart';
import '../home/home_controller.dart';
import '../history/history_controller.dart';
import '../invite/invite_controller.dart';
import '../profile/profile_controller.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put to make MainController permanent and prevent recreation
    Get.put<MainController>(MainController(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<InviteController>(() => InviteController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
