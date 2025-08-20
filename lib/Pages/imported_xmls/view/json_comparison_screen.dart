import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Models/xml_history.dart';
import '../../../services/xml_importado_service.dart';

class JsonComparisonScreen extends StatefulWidget {
  final String xmlNumero;

  const JsonComparisonScreen({Key? key, required this.xmlNumero}) : super(key: key);

  @override
  _JsonComparisonScreenState createState() => _JsonComparisonScreenState();
}

class _JsonComparisonScreenState extends State<JsonComparisonScreen> {
  final XmlImportadoService _xmlService = XmlImportadoService();
  
  List<XmlImportado> revisoes = [];
  XmlImportado? revisaoEsquerda;
  XmlImportado? revisaoDireita;
  String tipoJsonSelecionado = 'CADIREDI';
  bool isLoading = true;
  Map<String, dynamic>? jsonEsquerda;
  Map<String, dynamic>? jsonDireita;
  Set<String> chavesDiferentes = {};

  @override
  void initState() {
    super.initState();
    _carregarRevisoes();
  }

  Future<void> _carregarRevisoes() async {
    try {
      final xmls = await _xmlService.getXmlsByNumero(widget.xmlNumero);
      setState(() {
        revisoes = xmls..sort((a, b) => a.revisao.compareTo(b.revisao));
        if (revisoes.length >= 2) {
          revisaoEsquerda = revisoes[revisoes.length - 2]; // Penúltima revisão
          revisaoDireita = revisoes.last; // Última revisão
        } else if (revisoes.length == 1) {
          revisaoEsquerda = revisoes.first;
          revisaoDireita = revisoes.first;
        }
        isLoading = false;
        _compararJsons();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        'Erro',
        'Erro ao carregar revisões: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _compararJsons() {
    if (revisaoEsquerda != null && revisaoDireita != null) {
      try {
        final jsonStringEsquerda = _obterJsonPorTipo(revisaoEsquerda!, tipoJsonSelecionado);
        final jsonStringDireita = _obterJsonPorTipo(revisaoDireita!, tipoJsonSelecionado);
        
        final jsonObjEsquerda = jsonDecode(jsonStringEsquerda);
        final jsonObjDireita = jsonDecode(jsonStringDireita);
        
        // Verificar se os JSONs são mapas ou listas
        if (jsonObjEsquerda is Map<String, dynamic> && jsonObjDireita is Map<String, dynamic>) {
          jsonEsquerda = jsonObjEsquerda;
          jsonDireita = jsonObjDireita;
          chavesDiferentes = _encontrarDiferencias(jsonEsquerda!, jsonDireita!);
        } else if (jsonObjEsquerda is List && jsonObjDireita is List) {
          // Para listas, converter para mapa com índices
          jsonEsquerda = _converterListaParaMapa(jsonObjEsquerda);
          jsonDireita = _converterListaParaMapa(jsonObjDireita);
          chavesDiferentes = _encontrarDiferencias(jsonEsquerda!, jsonDireita!);
        } else {
          // Tipos diferentes entre esquerda e direita
          chavesDiferentes = {'root'};
          jsonEsquerda = {};
          jsonDireita = {};
        }
        
        // Debug: imprimir informações sobre a comparação
        print('Tipo JSON Esquerda: ${jsonObjEsquerda.runtimeType}');
        print('Tipo JSON Direita: ${jsonObjDireita.runtimeType}');
        print('Diferenças encontradas: $chavesDiferentes');
        print('Total de diferenças: ${chavesDiferentes.length}');
        
        setState(() {});
      } catch (e) {
        print('Erro ao comparar JSONs: $e');
        chavesDiferentes = {};
        setState(() {});
      }
    }
  }

  Map<String, dynamic> _converterListaParaMapa(List<dynamic> lista) {
    Map<String, dynamic> mapa = {};
    for (int i = 0; i < lista.length; i++) {
      mapa['[$i]'] = lista[i];
    }
    return mapa;
  }

  Set<String> _encontrarDiferencias(Map<String, dynamic> json1, Map<String, dynamic> json2, [String prefixo = '']) {
    Set<String> diferencias = {};
    
    // Verificar todas as chaves do primeiro JSON
    json1.forEach((chave, valor1) {
      final chaveCompleta = prefixo.isEmpty ? chave : '$prefixo.$chave';
      
      if (!json2.containsKey(chave)) {
        diferencias.add(chaveCompleta);
      } else {
        final valor2 = json2[chave];
        
        if (valor1 is Map<String, dynamic> && valor2 is Map<String, dynamic>) {
          diferencias.addAll(_encontrarDiferencias(valor1, valor2, chaveCompleta));
        } else if (valor1 is List && valor2 is List) {
          if (valor1.length != valor2.length) {
            diferencias.add(chaveCompleta);
          } else {
            for (int i = 0; i < valor1.length; i++) {
              if (valor1[i] is Map<String, dynamic> && valor2[i] is Map<String, dynamic>) {
                diferencias.addAll(_encontrarDiferencias(valor1[i], valor2[i], '$chaveCompleta[$i]'));
              } else if (valor1[i] != valor2[i]) {
                diferencias.add('$chaveCompleta[$i]');
              }
            }
          }
        } else if (valor1 != valor2) {
          diferencias.add(chaveCompleta);
        }
      }
    });
    
    // Verificar chaves que existem apenas no segundo JSON
    json2.forEach((chave, valor2) {
      final chaveCompleta = prefixo.isEmpty ? chave : '$prefixo.$chave';
      if (!json1.containsKey(chave)) {
        diferencias.add(chaveCompleta);
      }
    });
    
    return diferencias;
  }

  String _obterJsonPorTipo(XmlImportado xml, String tipo) {
    switch (tipo) {
      case 'CADIREDI':
        return xml.jsonCadiredi ?? '{}';
      case 'CADIRETA':
        return xml.jsonCadireta ?? '{}';
      case 'CADPROCE':
        return xml.jsonCadproce ?? '{}';
      default:
        return '{}';
    }
  }

  String _formatarJson(String jsonString) {
    try {
      final jsonObj = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObj);
    } catch (e) {
      return jsonString;
    }
  }

  Widget _buildJsonPanelComDestaque(XmlImportado? revisao, String lado) {
    if (revisao == null) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text('Selecione uma revisão'),
      );
    }

    final jsonString = _obterJsonPorTipo(revisao, tipoJsonSelecionado);
    final jsonFormatado = _formatarJson(jsonString);

    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Icon(Icons.description, size: 16),
                SizedBox(width: 8),
                Text(
                  'Revisão ${revisao.revisao} - $tipoJsonSelecionado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text(revisao.status),
                  backgroundColor: _getStatusColor(revisao.status),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: _buildJsonComDestaque(jsonFormatado, lado),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonComDestaque(String jsonText, String lado) {
    if (chavesDiferentes.isEmpty) {
      return SelectableText(
        jsonText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      );
    }

    List<TextSpan> spans = [];
    List<String> linhas = jsonText.split('\n');
    
    // Debug: imprimir as chaves diferentes encontradas
    print('Chaves diferentes encontradas: $chavesDiferentes');
    
    for (int i = 0; i < linhas.length; i++) {
      String linha = linhas[i];
      bool temDiferenca = false;
      
      // Se há diferença na raiz (tipos diferentes)
      if (chavesDiferentes.contains('root')) {
        temDiferenca = true;
      } else {
        // Lógica para detectar diferenças específicas
        for (String chaveDiferente in chavesDiferentes) {
          // Para arrays convertidos (chaves como [0], [1], etc.)
          if (chaveDiferente.startsWith('[') && chaveDiferente.endsWith(']')) {
            String indice = chaveDiferente.substring(1, chaveDiferente.length - 1);
            // Verificar se a linha contém o índice do array
            if (linha.trim().startsWith('{') || linha.trim().startsWith('[')) {
              // Verificar posição no array baseado na linha
              int linhaAtual = i;
              int contadorObjetos = 0;
              for (int j = 0; j <= i; j++) {
                if (linhas[j].trim().startsWith('{') || linhas[j].trim().startsWith('[')) {
                  if (contadorObjetos.toString() == indice) {
                    temDiferenca = true;
                    break;
                  }
                  contadorObjetos++;
                }
              }
            }
          } else {
            // Lógica original para chaves de objeto
            String nomeChave = chaveDiferente.split('.').last;
            
            // Remover índices de array se existirem
            if (nomeChave.contains('[')) {
              nomeChave = nomeChave.split('[')[0];
            }
            
            // Verificar se a linha contém a chave com aspas e dois pontos
            if (linha.contains('"$nomeChave"') && linha.contains(':')) {
              temDiferenca = true;
              print('Diferença encontrada na linha $i: $linha');
              break;
            }
          }
        }
      }
      
      Color? backgroundColor;
      Color textColor = Colors.black;
      
      if (temDiferenca) {
        if (lado == 'esquerda') {
          backgroundColor = Colors.red[200]!;
          textColor = Colors.red[800]!;
        } else {
          backgroundColor = Colors.green[200]!;
          textColor = Colors.green[800]!;
        }
      }
      
      spans.add(TextSpan(
        text: linha + (i < linhas.length - 1 ? '\n' : ''),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          backgroundColor: backgroundColor,
          color: textColor,
          fontWeight: temDiferenca ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildDropdownRevisao(String label, XmlImportado? revisaoSelecionada, Function(XmlImportado?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButton<XmlImportado>(
          value: revisaoSelecionada,
          isExpanded: true,
          items: revisoes.map((revisao) {
            return DropdownMenuItem<XmlImportado>(
              value: revisao,
              child: Text('Revisão ${revisao.revisao} - ${revisao.status}'),
            );
          }).toList(),
          onChanged: (XmlImportado? novaRevisao) {
            onChanged(novaRevisao);
            _compararJsons();
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'produzir':
        return Colors.orange[100]!;
      case 'em_producao':
        return Colors.blue[100]!;
      case 'finalizado':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comparação de JSONs - ${widget.xmlNumero}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _compararJsons,
            tooltip: 'Atualizar comparação',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Controles superiores
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      // Indicador de diferenças
                      if (chavesDiferentes.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[800]),
                              SizedBox(width: 8),
                              Text(
                                '${chavesDiferentes.length} diferença(s) encontrada(s)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Seletor de tipo de JSON
                      Row(
                        children: [
                          Text('Tipo de JSON: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 16),
                          DropdownButton<String>(
                            value: tipoJsonSelecionado,
                            items: ['CADIREDI', 'CADIRETA', 'CADPROCE'].map((tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                            onChanged: (String? novoTipo) {
                              if (novoTipo != null) {
                                setState(() {
                                  tipoJsonSelecionado = novoTipo;
                                });
                                _compararJsons();
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Seletores de revisão
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownRevisao(
                              'Revisão Esquerda',
                              revisaoEsquerda,
                              (XmlImportado? novaRevisao) {
                                setState(() {
                                  revisaoEsquerda = novaRevisao;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 32),
                          Expanded(
                            child: _buildDropdownRevisao(
                              'Revisão Direita',
                              revisaoDireita,
                              (XmlImportado? novaRevisao) {
                                setState(() {
                                  revisaoDireita = novaRevisao;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Legenda das cores
                      if (chavesDiferentes.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Removido/Alterado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Adicionado/Novo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Painéis de comparação
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildJsonPanelComDestaque(revisaoEsquerda, 'esquerda'),
                      ),
                      Container(
                        width: 2,
                        color: Colors.grey[400],
                      ),
                      Expanded(
                        child: _buildJsonPanelComDestaque(revisaoDireita, 'direita'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}