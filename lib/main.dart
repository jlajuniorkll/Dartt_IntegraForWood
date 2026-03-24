import 'dart:io';

import 'package:dartt_integraforwood/Routes/app_routes.dart';
import 'package:dartt_integraforwood/commom/commom_functions.dart';
import 'package:dartt_integraforwood/services/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Garantir que o Flutter esteja inicializado antes de qualquer operação
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SQLite para desktop (Windows/Linux/macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Garante pasta de logs ao iniciar o app
  await initLogsFolder();

  Get.put(AppLogger(), permanent: true);
  await Get.find<AppLogger>().prepare();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e(
      'Flutter',
      details.exceptionAsString(),
      stack: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Async', error.toString(), stack: stack);
    return true;
  };

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Integra3CadForWood',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: PageRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
