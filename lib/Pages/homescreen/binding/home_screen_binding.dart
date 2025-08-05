import 'package:dartt_integraforwood/Pages/homescreen/controller/home_screen_controller.dart';
import 'package:get/get.dart';

class HomeScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeScreenController(), permanent: true);
  }
}
