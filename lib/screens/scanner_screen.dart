import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:riocaja_smart/screens/preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isLoading = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    // Verificar autenticación
    _checkAuthentication();
    _initializeCamera();
  }
  
  // Método para verificar autenticación
  void _checkAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        // Si no está autenticado, redirigir a login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _isCapturing = false;
      });

      // Navegar a la pantalla de vista previa
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar autenticación en tiempo de renderizado también
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Si no está autenticado, mostrar pantalla de error
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text('Error de Autenticación')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Sesión no válida',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Por favor inicie sesión nuevamente'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Ir a Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Escanear Comprobante')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Escanear Comprobante')),
        body: Center(child: Text('No se pudo inicializar la cámara')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Escanear Comprobante')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Vista de la cámara
                Container(
                  width: double.infinity,
                  child: CameraPreview(_cameraController!),
                ),
                // Overlay de guía para el documento
                Positioned.fill(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Texto de guía
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      'Alinee el comprobante dentro del marco',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Controles de cámara
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () {
                    // Cambiar modo de flash
                  },
                ),
                GestureDetector(
                  onTap: _isCapturing ? null : _takePhoto,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _isCapturing
                        ? Center(child: CircularProgressIndicator())
                        : Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () {
                    // Cambiar entre cámaras
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}