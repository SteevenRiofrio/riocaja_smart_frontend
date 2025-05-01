// lib/screens/debug_screen.dart - Completamente corregido
import 'dart:convert';
import 'dart:io';
import 'dart:async';  // Importación explícita de dart:async para TimeoutException
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
  List<String> _predefinedUrls = [
    'https://riocaja-smart-backend.onrender.com/api/v1', // Render (producción)
    'http://10.41.1.251:8000/api/v1',                    // IP local original
    'http://10.0.2.2:8000/api/v1',                       // Emulador Android
    'http://localhost:8000/api/v1'                       // Local iOS/desarrollo
  ];

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
        final response = await http.get(Uri.parse(baseUrl))
            .timeout(Duration(seconds: 30));
        _log('✅ Conexión HTTP básica exitosa: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          _log('Cuerpo: ${response.body.substring(0, _min(100, response.body.length))}...');
        }
      } catch (e) {
        _log('❌ Error en conexión HTTP básica: $e');
        
        // Si falla, comprobar si es un error de certificado SSL (común en desarrollo)
        if (e.toString().contains('certificate') || e.toString().contains('SSL')) {
          _log('⚠️ Posible problema con certificados SSL. En desarrollo, considera usar HTTP en lugar de HTTPS.');
        }
        
        // Continuar con el resto de las pruebas aún si esta falla
      }
      
      // Realizar prueba HTTP GET al endpoint /ping (debe ser implementado en el backend)
      _log('Probando endpoint de diagnóstico /ping...');
      final pingUrl = baseUrl.endsWith('/') 
          ? '${baseUrl}ping' 
          : '$baseUrl/ping';
          
      try {
        final response = await http.get(Uri.parse(pingUrl))
            .timeout(Duration(seconds: 30));
        _log('✅ Endpoint ping respondió: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          _log('Cuerpo: ${response.body}');
        }
      } catch (e) {
        _log('❌ Error al probar endpoint ping: $e');
        _log('Es posible que este endpoint no esté implementado en el backend.');
      }

      // Probar el endpoint específico de comprobantes
      _log('Probando endpoint de comprobantes...');
      
      final receiptsEndpoint = baseUrl.endsWith('/') 
          ? '${baseUrl}receipts/' 
          : '$baseUrl/receipts/';
          
      try {
        final response = await http.get(
          Uri.parse(receiptsEndpoint),
          headers: {'Content-Type': 'application/json'}
        ).timeout(Duration(seconds: 60)); // Tiempo extendido para Render (cold starts)
        
        _log('✅ Respuesta del endpoint de comprobantes: ${response.statusCode}');
        
        if (response.body.isNotEmpty) {
          _log('Cuerpo: ${response.body.substring(0, _min(100, response.body.length))}...');
          
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
          _log('Parece un problema de conectividad de red o servidor no disponible.');
        } else if (e.toString().contains('TimeoutException')) {
          _log('Si estás usando Render, puede ser un "cold start" del servidor. Intenta de nuevo en unos momentos.');
        } else if (e.toString().contains('HandshakeException')) {
          _log('Problema de SSL/TLS. Verifica que la URL sea correcta (http vs https).');
        } 
      }

      _log('Diagnóstico finalizado');
      
      // Recordatorio sobre Render
      if (baseUrl.contains('render.com')) {
        _log('⚠️ NOTA: Los servicios gratuitos en Render pueden tener "cold starts" de 30-60 segundos si el servicio no se ha usado recientemente.');
        _log('Si la primera conexión falló, espera un minuto y vuelve a intentarlo.');
      }
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
      appBar: AppBar(
        title: Text('Diagnóstico de Conexión'),
      ),
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
                hintText: 'https://riocaja-smart-backend.onrender.com/api/v1',
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
              child: _isTesting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              onPressed: _isTesting ? null : () {
                // Guardar la URL como predeterminada (en la instancia actual)
                _apiService.updateBaseUrl(_urlController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL establecida como predeterminada para esta sesión'),
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
                    _logs.isEmpty ? 'Inicie la prueba para ver los resultados...' : _logs,
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
                  title: Text(_predefinedUrls[index], 
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
}