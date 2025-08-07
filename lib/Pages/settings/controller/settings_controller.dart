import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartt_integraforwood/Pages/homescreen/controller/home_screen_controller.dart';

class SettingsController extends GetxController {
  // Variáveis de Informação
  final version = 'V1.0'.obs;
  final versionFvm = '3.2.1'.obs;
  final versionFlutter = '3.29.2'.obs;
  final versionDartSdk = '3.7.2'.obs;
  final versionDevTools = '2.42.3'.obs;

  // Variáveis de Configuração
  final nomecatalogoController = TextEditingController().obs;
  final databaseFWController = TextEditingController().obs;
  final hostFWController = TextEditingController().obs;
  final portFWController = TextEditingController().obs;
  final userNameFWController = TextEditingController().obs;
  final passwordFWController = TextEditingController().obs;
  final codbatismocorteController = TextEditingController().obs;
  final codbatismomoduloController = TextEditingController().obs;
  final codbatismopedidoController = TextEditingController().obs;
  final codUMM2Controller = TextEditingController().obs;
  final codUMM3Controller = TextEditingController().obs;
  final hostSQLController = TextEditingController().obs;
  final portSQLController = TextEditingController().obs;
  final databaseSQLController = TextEditingController().obs;
  final userNameSQLController = TextEditingController().obs;
  final passwordSQLController = TextEditingController().obs;
  final diretorioXMLController = TextEditingController().obs;
  final diretorioESPController = TextEditingController().obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    nomecatalogoController.value.text =
        prefs.getString('nomecatalogo') ?? 'Moveis3F1B';
    databaseFWController.value.text = prefs.getString('databaseFW') ?? '3F1B';
    hostFWController.value.text = prefs.getString('hostFW') ?? 'localhost';
    portFWController.value.text = (prefs.getInt('portFW') ?? 5432).toString();
    userNameFWController.value.text =
        prefs.getString('userNameFW') ?? 'postgres';
    passwordFWController.value.text =
        prefs.getString('passwordFW') ?? 'postgres';
    codbatismocorteController.value.text =
        prefs.getString('codbatismocorte') ?? '42';
    codbatismomoduloController.value.text =
        prefs.getString('codbatismomodulo') ?? '4.1';
    codbatismopedidoController.value.text =
        prefs.getString('codbatismopedido') ?? '5.3';
    codUMM2Controller.value.text = prefs.getString('codUMM2') ?? 'M2';
    codUMM3Controller.value.text = prefs.getString('codUMM3') ?? 'M3';
    hostSQLController.value.text =
        prefs.getString('hostSQL') ?? 'NOTEDARTT\\ECADPRO2019';
    portSQLController.value.text = (prefs.getInt('portSQL') ?? 1433).toString();
    databaseSQLController.value.text =
        prefs.getString('databaseSQL') ?? 'Moveis3F1B';
    userNameSQLController.value.text = prefs.getString('userNameSQL') ?? 'sa';
    passwordSQLController.value.text =
        prefs.getString('passwordSQL') ?? 'eCadPro2019';
    diretorioXMLController.value.text =
        prefs.getString('diretorioXML') ?? 'C:\\evolution\\xml';
    diretorioESPController.value.text =
        prefs.getString('diretorioESP') ?? 'C:\\industrial\\';
  }

  Future<void> saveSettings() async {
    try {
      // Salvar configurações primeiro
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomecatalogo', nomecatalogoController.value.text);
      await prefs.setString('databaseFW', databaseFWController.value.text);
      await prefs.setString('hostFW', hostFWController.value.text);
      await prefs.setInt(
        'portFW',
        int.tryParse(portFWController.value.text) ?? 5432,
      );
      await prefs.setString('userNameFW', userNameFWController.value.text);
      await prefs.setString('passwordFW', passwordFWController.value.text);
      await prefs.setString(
        'codbatismocorte',
        codbatismocorteController.value.text,
      );
      await prefs.setString(
        'codbatismomodulo',
        codbatismomoduloController.value.text,
      );
      await prefs.setString(
        'codbatismopedido',
        codbatismopedidoController.value.text,
      );
      await prefs.setString('codUMM2', codUMM2Controller.value.text);
      await prefs.setString('codUMM3', codUMM3Controller.value.text);
      await prefs.setString('hostSQL', hostSQLController.value.text);
      await prefs.setInt(
        'portSQL',
        int.tryParse(portSQLController.value.text) ?? 1433,
      );
      await prefs.setString('databaseSQL', databaseSQLController.value.text);
      await prefs.setString('userNameSQL', userNameSQLController.value.text);
      await prefs.setString('passwordSQL', passwordSQLController.value.text);
      await prefs.setString('diretorioXML', diretorioXMLController.value.text);
      await prefs.setString('diretorioESP', diretorioESPController.value.text);

      // Mostrar mensagem de sucesso imediatamente
      Get.snackbar(
        'Sucesso', 
        'Configurações salvas com sucesso!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      // Validar conexões em background (sem bloquear a UI)
      _validateConnectionsInBackground();
      
    } catch (e) {
      Get.snackbar(
        'Erro', 
        'Erro ao salvar configurações: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _validateConnectionsInBackground() async {
    try {
      // Tentar obter o HomeScreenController
      HomeScreenController? homeController;
      try {
        homeController = Get.find<HomeScreenController>();
      } catch (e) {
        // Se não encontrar o controller, não faz nada
        return;
      }
      
      // Validar conexões com timeout
      await Future.wait([
        Future.delayed(Duration.zero, () async {
          try {
            await homeController!.connectDatabase().timeout(Duration(seconds: 10));
          } catch (e) {
            print('Timeout ou erro na conexão PostgreSQL: $e');
          }
        }),
        Future.delayed(Duration.zero, () async {
          try {
            await homeController!.connectSqlServer().timeout(Duration(seconds: 10));
          } catch (e) {
            print('Timeout ou erro na conexão SQL Server: $e');
          }
        }),
      ]).timeout(Duration(seconds: 15));
      
      // Verificar resultados apenas se ainda estiver na tela de configurações
      if (Get.currentRoute.contains('settings')) {
        if (!homeController.databaseOn || !homeController.sqlServerConnected.value) {
          String errorMessage = 'Atenção: Problemas detectados nas conexões:\n';
          if (!homeController.databaseOn) {
            errorMessage += '• PostgreSQL: Falha na conexão\n';
          }
          if (!homeController.sqlServerConnected.value) {
            errorMessage += '• SQL Server: Falha na conexão';
          }
          
          Get.snackbar(
            'Atenção', 
            errorMessage,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            duration: Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      // Falha silenciosa na validação em background
      print('Erro na validação em background: $e');
    }
  }
}
