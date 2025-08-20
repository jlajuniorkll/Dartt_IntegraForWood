import 'package:get/get.dart';
import '../controller/imported_xmls_controller.dart';

class ImportedXmlsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImportedXmlsController>(
      () => ImportedXmlsController(),
    );
  }
}