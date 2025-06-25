// lib/screens/debug_screen.dart - Actualizado con la nueva IP
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Importación explícita de dart:async para TimeoutException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/services/api_service.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ApiService _apiService = ApiService();
  String _logs = '';
  bool _isTesting = false;
  TextEditingController _urlController = TextEditingController();

  // Lista simplificada con únicamente la IP del servidor Debian
  List<String> _predefinedUrls = ['http://34.71.113.185/api/v1'];

  @override
  void initState() {
    super.initState();
    _urlController.text = _apiService.baseUrl;
  }

  // Agregar texto al log con timestamp
  void _log(String text) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs = '[$timestamp] $text\n$_logs';
    });
  }

  // Probar conexión al servidor
  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _logs = '';
    });

    try {
      // Actualizar la URL si fue modificada
      final newUrl = _urlController.text;
      if (newUrl != _apiService.baseUrl) {
        _apiService.updateBaseUrl(newUrl);
        _log('URL actualizada a: $newUrl');
      }

      final baseUrl = _apiService.baseUrl;
      _log('Probando conexión a: $baseUrl');

      // Primero probar con HTTP simple usando http package
      _log('Realizando prueba HTTP GET básica...');
      try {
        final response = await http
            .get(Uri.parse(baseUrl))
            .timeout(Duration(seconds: 30));
        _log('✅ Conexión HTTP básica exitosa: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          _log(
            'Cuerpo: ${response.body.substring(0, _min(100, response.body.length))}...',
          );
        }
      } catch (e) {
        _log('❌ Error en conexión HTTP básica: $e');

        // Si falla, comprobar si es un error de certificado SSL (común en desarrollo)
        if (e.toString().contains('certificate') ||
            e.toString().contains('SSL')) {
          _log(
            '⚠️ Posible problema con certificados SSL. En desarrollo, considera usar HTTP en lugar de HTTPS.',
          );
          _log(
            '⚠️ Si estás intentando usar HTTPS con una IP, necesitarás configurar certificados SSL válidos.',
          );
        }

        // Si es un error de socket o conexión rechazada
        if (e is SocketException) {
          _log('⚠️ Error de conexión: No se pudo conectar al servidor.');
          _log(
            '⚠️ Verifica que el servidor esté en ejecución y sea accesible desde tu red.',
          );
          _log(
            '⚠️ Si estás usando una IP externa, asegúrate de que los puertos estén abiertos y configurados correctamente.',
          );
        }

        // Continuar con el resto de las pruebas aún si esta falla
      }

      // Realizar prueba HTTP GET al endpoint /ping (debe ser implementado en el backend)
      _log('Probando endpoint de diagnóstico /ping...');
      final pingUrl =
          baseUrl.endsWith('/') ? '${baseUrl}ping' : '$baseUrl/ping';

      try {
        final response = await http
            .get(Uri.parse(pingUrl))
            .timeout(Duration(seconds: 30));
        _log('✅ Endpoint ping respondió: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          _log('Cuerpo: ${response.body}');
        }
      } catch (e) {
        _log('❌ Error al probar endpoint ping: $e');
        _log(
          'Es posible que este endpoint no esté implementado en el backend.',
        );
      }

      // Probar el endpoint específico de comprobantes
      _log('Probando endpoint de comprobantes...');

      final receiptsEndpoint =
          baseUrl.endsWith('/') ? '${baseUrl}receipts/' : '$baseUrl/receipts/';

      try {
        final response = await http
            .get(
              Uri.parse(receiptsEndpoint),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(
              Duration(seconds: 60),
            ); // Tiempo extendido para servidores con arranque en frío

        _log(
          '✅ Respuesta del endpoint de comprobantes: ${response.statusCode}',
        );

        if (response.body.isNotEmpty) {
          _log(
            'Cuerpo: ${response.body.substring(0, _min(100, response.body.length))}...',
          );

          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse.containsKey('data')) {
              final count = jsonResponse['count'] ?? 'no especificado';
              _log('Total de comprobantes: $count');
            } else {
              _log('⚠️ La respuesta no contiene la clave "data"');
            }
          } catch (e) {
            _log('⚠️ Error al decodificar JSON: $e');
          }
        } else {
          _log('⚠️ El cuerpo de la respuesta está vacío');
        }
      } catch (e) {
        _log('❌ Error al acceder al endpoint de comprobantes: $e');

        // Proporcionar sugerencias basadas en el tipo de error
        if (e is SocketException) {
          _log(
            'Parece un problema de conectividad de red o servidor no disponible.',
          );
          _log(
            'Verifica que la ruta del endpoint sea correcta: $receiptsEndpoint',
          );
        } else if (e.toString().contains('TimeoutException')) {
          _log(
            'Si el servidor está en la nube, puede ser un "cold start". Intenta de nuevo en unos momentos.',
          );
        } else if (e.toString().contains('HandshakeException')) {
          _log(
            'Problema de SSL/TLS. Verifica que la URL sea correcta (http vs https).',
          );
          _log(
            'Si estás intentando usar HTTPS con una IP, configura certificados SSL válidos o usa HTTP.',
          );
        }
      }

      _log('Diagnóstico finalizado');

      // Nota informativa sobre conexiones a servidores externos
      _log(
        '⚠️ NOTA: Cuando te conectas a un servidor externo por IP, asegúrate de:',
      );
      _log('1. Usar HTTP si no tienes un certificado SSL configurado.');
      _log(
        '2. Verificar que el puerto correcto esté abierto (80 para HTTP, 443 para HTTPS).',
      );
      _log(
        '3. Configurar el firewall del servidor para permitir conexiones entrantes.',
      );
    } catch (e) {
      _log('❌ Error en el diagnóstico: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  int _min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagnóstico de Conexión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entrada para la URL
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL del API',
                hintText: 'http://35.202.219.87/api/v1',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    _showUrlSelectionDialog();
                  },
                ),
              ),
            ),
            SizedBox(height: 16),

            // Botón de prueba
            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              child:
                  _isTesting
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Probando...'),
                        ],
                      )
                      : Text('Probar Conexión'),
            ),
            SizedBox(height: 16),

            // Botón para establecer como predeterminada
            OutlinedButton(
              onPressed:
                  _isTesting
                      ? null
                      : () {
                        // Guardar la URL como predeterminada (en la instancia actual)
                        _apiService.updateBaseUrl(_urlController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'URL establecida como predeterminada para esta sesión',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
              child: Text('Establecer como URL predeterminada'),
            ),
            SizedBox(height: 16),

            // Logs
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty
                        ? 'Inicie la prueba para ver los resultados...'
                        : _logs,
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seleccionar URL predefinida'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predefinedUrls.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _predefinedUrls[index],
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    setState(() {
                      _urlController.text = _predefinedUrls[index];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTestSection() {
    TextEditingController _dateController = TextEditingController(
      text: '02/05/2025',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prueba de Búsqueda por Fecha',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: 'Fecha (dd/MM/yyyy)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            try {
              _log(
                'Probando búsqueda directa por fecha: ${_dateController.text}',
              );

              // Probar la llamada directa a la API
              final url =
                  '${_apiService.baseUrl}/receipts/date/${_dateController.text}';
              _log('URL: $url');

              final response = await http
                  .get(
                    Uri.parse(url),
                    headers: {'Content-Type': 'application/json'},
                  )
                  .timeout(Duration(seconds: 30));

              _log('Código de respuesta: ${response.statusCode}');

              if (response.body.isNotEmpty) {
                try {
                  final jsonResponse = jsonDecode(response.body);
                  final count = jsonResponse['count'] ?? 0;
                  _log('Comprobantes encontrados: $count');
                  if (count > 0) {
                    _log(
                      'Primer comprobante: ${jsonResponse['data'][0]['nro_transaccion']}',
                    );
                  }
                } catch (e) {
                  _log('Error al analizar la respuesta: $e');
                }
              } else {
                _log('Respuesta vacía');
              }
            } catch (e) {
              _log('Error: $e');
            }
          },
          child: Text('Probar Búsqueda por Fecha'),
        ),
      ],
    );
  }
}
