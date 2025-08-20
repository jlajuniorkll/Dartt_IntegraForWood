import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/imported_xmls_controller.dart';
import '../../../Models/xml_history.dart';

class ImportedXmlsScreen extends StatelessWidget {
  final ImportedXmlsController controller = Get.find<ImportedXmlsController>();
  final ScrollController _scrollController = ScrollController();

  ImportedXmlsScreen() {
    // Adicionar listener para scroll infinito
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('XMLs Importados'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadXmlsImportados(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndSort(),
          _buildStatusSummary(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.xmlsImportados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'Nenhum XML encontrado para "${controller.searchQuery.value}"'
                            : 'Nenhum XML importado encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: controller.xmlsImportados.length + 
                    (controller.hasMoreItems.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // Se é o último item e há mais itens para carregar
                  if (index == controller.xmlsImportados.length) {
                    return Obx(() => controller.isLoadingMore.value
                        ? Container(
                            padding: EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          )
                        : SizedBox.shrink());
                  }
                  
                  final xml = controller.xmlsImportados[index];
                  return _buildXmlCard(xml);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Obx(() {
      final count = controller.statusCount;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: [
            _buildStatusChip(
              'Aguardando',
              'aguardando',
              count['aguardando'] ?? 0,
              Colors.orange,
            ),
            _buildStatusChip(
              'Orçado',
              'orcado',
              count['orcado'] ?? 0,
              Colors.blue,
            ),
            _buildStatusChip(
              'Produzir',
              'produzir',
              count['produzir'] ?? 0,
              Colors.green,
            ),
            _buildStatusChip(
              'Em produção',
              'em_producao',
              count['em_producao'] ?? 0,
              Colors.purple,
            ),
            _buildStatusChip(
              'Finalizado',
              'finalizado',
              count['finalizado'] ?? 0,
              Colors.teal,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusChip(
    String label,
    String statusValue,
    int count,
    Color color,
  ) {
    return Obx(() {
      final isSelected = controller.selectedStatusFilter.value == statusValue;
      return GestureDetector(
        onTap: () {
          // Se já está selecionado, volta para 'todos', senão filtra pelo status
          final newFilter = isSelected ? 'todos' : statusValue;
          controller.filterByStatus(newFilter);
        },
        child: Chip(
          label: Text('$label: $count'),
          backgroundColor:
              isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
          labelStyle: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          side:
              isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
      );
    });
  }

  Widget _buildXmlCard(XmlImportado xml) {
    return Card(
      margin: EdgeInsets.only(bottom: 8), // Reduzido de 16 para 8
      elevation: 2, // Reduzido de 4 para 2
      child: Padding(
        padding: EdgeInsets.all(12), // Reduzido de 16 para 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho mais compacto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'XML ${xml.numero} (Rev. ${xml.revisao})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Reduzido de 18 para 16
                  ),
                ),
                _buildStatusBadge(xml.status),
              ],
            ),
            SizedBox(height: 8), // Reduzido de 12 para 8
            
            // Informações principais em layout mais compacto
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRowCompact('RIF:', xml.rif),
                      _buildInfoRowCompact('Pai:', xml.pai),
                      _buildInfoRowCompact('Data:', xml.data),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRowCompact(
                        'Criado:',
                        DateFormat('dd/MM/yy HH:mm').format(xml.createdAt), // Formato mais curto
                      ),
                      if (xml.updatedAt != null)
                        _buildInfoRowCompact(
                          'Atualizado:',
                          DateFormat('dd/MM/yy HH:mm').format(xml.updatedAt!), // Formato mais curto
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8), // Reduzido de 12 para 8
            
            // Número de fabricação mais compacto
            _buildNumeroFabricacaoFieldCompact(xml),
            SizedBox(height: 8), // Reduzido de 12 para 8
            
            // Status dropdown mais compacto
            _buildStatusDropdownCompact(xml),
            SizedBox(height: 8), // Reduzido de 16 para 8
            
            // Botões de ação mais compactos
            _buildActionButtonsCompact(xml),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowCompact(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1), // Reduzido de 2 para 1
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60, // Reduzido de 120 para 60
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12, // Fonte menor
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12), // Fonte menor
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumeroFabricacaoFieldCompact(XmlImportado xml) {
    final TextEditingController textController = TextEditingController(
      text: xml.numeroFabricacao ?? '',
    );

    return Row(
      children: [
        SizedBox(
          width: 80, // Reduzido de 120 para 80
          child: Text(
            'Nº Fab:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12, // Fonte menor
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: textController,
            style: TextStyle(fontSize: 12), // Fonte menor
            decoration: InputDecoration(
              hintText: 'Número de fabricação',
              hintStyle: TextStyle(fontSize: 11),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding reduzido
              isDense: true, // Campo mais compacto
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                controller.updateNumeroFabricacao(xml.id!, value.trim());
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdownCompact(XmlImportado xml) {
    return Row(
      children: [
        SizedBox(
          width: 80, // Reduzido de 120 para 80
          child: Text(
            'Status:', 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12, // Fonte menor
            ),
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: xml.status,
            isExpanded: true,
            isDense: true, // Dropdown mais compacto
            style: TextStyle(fontSize: 12, color: Colors.black), // Fonte menor
            items: StatusXml.values
                .map((status) {
                  if (xml.status == 'em_producao' &&
                      status.value != 'em_producao' &&
                      status.value != 'finalizado') {
                    return null;
                  }
                  return DropdownMenuItem(
                    value: status.value,
                    child: Text(status.label),
                  );
                })
                .where((item) => item != null)
                .cast<DropdownMenuItem<String>>()
                .toList(),
            onChanged: (newStatus) {
              if (newStatus != null && newStatus != xml.status) {
                controller.updateXmlStatus(xml.id!, newStatus);
              }
            }
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsCompact(XmlImportado xml) {
    // Verificar se pode enviar para produção
    bool podeEnviarProducao = xml.status == 'produzir' && 
                           xml.numeroFabricacao != null && 
                           xml.numeroFabricacao!.trim().isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Grupo de botões do lado esquerdo
        Row(
          children: [
            // Botão Produção com validação
            SizedBox(
              width: 90,
              child: ElevatedButton.icon(
                icon: Icon(Icons.send, size: 14),
                label: Text(
                  'Produção',
                  style: TextStyle(fontSize: 10),
                ),
                onPressed: podeEnviarProducao
                    ? () => controller.enviarParaProducao(xml)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: podeEnviarProducao ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  minimumSize: Size(0, 28),
                ),
              ),
            ),
            // Mostrar tooltip quando não pode enviar
            if (xml.status == 'produzir' && !podeEnviarProducao)
              Tooltip(
                message: 'Número de fabricação deve estar preenchido',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
            SizedBox(width: 8), // Espaçamento entre botões do grupo esquerdo
            // Botão JSONs
            SizedBox(
              width: 70,
              child: ElevatedButton.icon(
                icon: Icon(Icons.code, size: 14),
                label: Text(
                  'JSONs',
                  style: TextStyle(fontSize: 10),
                ),
                onPressed: () => controller.visualizarJsons(xml),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  minimumSize: Size(0, 28),
                ),
              ),
            ),
          ],
        ),
        // Botão Delete isolado no lado direito
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red, size: 16),
          onPressed: () => controller.confirmDelete(xml),
          padding: EdgeInsets.all(3),
          constraints: BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'aguardando':
        color = Colors.orange;
        break;
      case 'orcado':
        color = Colors.blue;
        break;
      case 'produzir':
        color = Colors.green;
        break;
      case 'em_producao':
        color = Colors.purple;
        break;
      case 'finalizado':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Padding reduzido
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), // Raio reduzido
        border: Border.all(color: color),
      ),
      child: Text(
        StatusXml.fromValue(status).label,
        style: TextStyle(
          color: color, 
          fontWeight: FontWeight.bold,
          fontSize: 11, // Fonte menor
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por número, RIF ou pai...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => controller.searchXmls(value),
            ),
          ),
          SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            tooltip: 'Ordenar por',
            onSelected: (value) => controller.changeSortBy(value),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'createdAt',
                    child: Text('Data de criação'),
                  ),
                  PopupMenuItem(value: 'numero', child: Text('Número')),
                  PopupMenuItem(value: 'rif', child: Text('RIF')),
                  PopupMenuItem(value: 'pai', child: Text('Pai')),
                ],
          ),
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isAscending.value
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              tooltip:
                  controller.isAscending.value
                      ? 'Ordem crescente'
                      : 'Ordem decrescente',
              onPressed: () => controller.toggleSortOrder(),
            ),
          ),
        ],
      ),
    );
  }
}
