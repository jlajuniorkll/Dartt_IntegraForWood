import 'package:dartt_integraforwood/Pages/system_log/controller/system_log_controller.dart';
import 'package:dartt_integraforwood/debug_agent_log.dart';
import 'package:get/get.dart';

/// [AppLogger] é registrado em [main].
class SystemLogBinding extends Bindings {
  @override
  void dependencies() {
    // #region agent log
    agentDebugLog(
      location: 'system_log_binding.dart:dependencies',
      message: 'SystemLogBinding.dependencies enter',
      hypothesisId: 'H2',
    );
    // #endregion
    Get.lazyPut(() {
      // #region agent log
      agentDebugLog(
        location: 'system_log_binding.dart:lazyPut',
        message: 'creating SystemLogController',
        hypothesisId: 'H2',
      );
      try {
        return SystemLogController();
      } catch (e, st) {
        agentDebugLog(
          location: 'system_log_binding.dart:lazyPut',
          message: 'SystemLogController ctor failed',
          hypothesisId: 'H3',
          data: {'error': e.toString(), 'stack': st.toString()},
        );
        rethrow;
      }
      // #endregion
    });
    // #region agent log
    agentDebugLog(
      location: 'system_log_binding.dart:dependencies',
      message: 'SystemLogBinding.dependencies done',
      hypothesisId: 'H2',
    );
    // #endregion
  }
}
