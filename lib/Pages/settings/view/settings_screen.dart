import 'package:dartt_integraforwood/Pages/settings/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: use_key_in_widget_constructors
class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações Editáveis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildTextField(
                controller.nomecatalogoController.value,
                'Nome do Catálogo',
              ),
              _buildTextField(
                controller.databaseFWController.value,
                'Banco de Dados ForWood',
              ),
              _buildTextField(
                controller.hostFWController.value,
                'Host ForWood',
              ),
              _buildTextField(
                controller.portFWController.value,
                'Porta ForWood',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller.userNameFWController.value,
                'Usuário ForWood',
              ),
              _buildTextField(
                controller.passwordFWController.value,
                'Senha ForWood',
                obscureText: true,
              ),
              _buildTextField(
                controller.codbatismocorteController.value,
                'Cód. Batismo Corte',
              ),
              _buildTextField(
                controller.codbatismomoduloController.value,
                'Cód. Batismo Módulo',
              ),
              _buildTextField(
                controller.codbatismopedidoController.value,
                'Cód. Batismo Pedido',
              ),
              _buildTextField(controller.codUMM2Controller.value, 'Cód. UM M2'),
              _buildTextField(controller.codUMM3Controller.value, 'Cód. UM M3'),
              _buildTextField(controller.hostSQLController.value, 'Host SQL'),
              _buildTextField(
                controller.portSQLController.value,
                'Porta SQL',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller.databaseSQLController.value,
                'Banco de Dados SQL',
              ),
              _buildTextField(
                controller.userNameSQLController.value,
                'Usuário SQL',
              ),
              _buildTextField(
                controller.passwordSQLController.value,
                'Senha SQL',
                obscureText: true,
              ),
              _buildTextField(
                controller.diretorioXMLController.value,
                'Diretório XML',
              ),
              _buildTextField(
                controller.diretorioESPController.value,
                'Diretório ESP',
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.saveSettings();
                },
                child: Text('Salvar'),
              ),
              SizedBox(height: 20),
              Text(
                'Informações',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildInfoTile('Versão', controller.version.value),
              _buildInfoTile('Versão FVM', controller.versionFvm.value),
              _buildInfoTile('Versão Flutter', controller.versionFlutter.value),
              _buildInfoTile(
                'Versão Dart SDK',
                controller.versionDartSdk.value,
              ),
              _buildInfoTile(
                'Versão DevTools',
                controller.versionDevTools.value,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(title: Text(title), subtitle: Text(value));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
  }
}
