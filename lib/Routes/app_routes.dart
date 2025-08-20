import 'package:dartt_integraforwood/Pages/homescreen/binding/home_screen_binding.dart';
import 'package:dartt_integraforwood/Pages/homescreen/view/details_screen.dart';
import 'package:dartt_integraforwood/Pages/settings/binding/settings_binding.dart';
import 'package:dartt_integraforwood/Pages/settings/view/settings_screen.dart';
import 'package:dartt_integraforwood/Pages/imported_xmls/binding/imported_xmls_binding.dart';
import 'package:dartt_integraforwood/Pages/imported_xmls/view/imported_xmls_screen.dart';
import 'package:get/get.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: PageRoutes.home,
      page: () => DetailsScreen(),
      bindings: [HomeScreenBinding()],
    ),
    GetPage(
      name: PageRoutes.settings,
      page: () => SettingsScreen(),
      bindings: [SettingsBinding()],
    ),
    GetPage(
      name: PageRoutes.importedXmls,
      page: () => ImportedXmlsScreen(),
      bindings: [ImportedXmlsBinding()],
    ),
  ];
}

abstract class PageRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String importedXmls = '/imported-xmls';
}
