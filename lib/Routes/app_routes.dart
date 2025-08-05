import 'package:dartt_integraforwood/Pages/homescreen/binding/home_screen_binding.dart';
import 'package:dartt_integraforwood/Pages/homescreen/view/details_screen.dart';
import 'package:get/get.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: PageRoutes.home,
      page: () => DetailsScreen(),
      bindings: [HomeScreenBinding()],
    ),
  ];
}

abstract class PageRoutes {
  static const String home = '/';
}
