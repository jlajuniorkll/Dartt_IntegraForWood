import 'package:dartt_integraforwood/Pages/system_log/controller/system_log_controller.dart';
import 'package:get/get.dart';

/// [AppLogger] é registrado em [main].
class SystemLogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SystemLogController());
  }
}
