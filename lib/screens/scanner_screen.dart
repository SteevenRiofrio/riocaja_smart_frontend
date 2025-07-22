// lib/screens/scanner_screen.dart - VERSIÓN COMPLETAMENTE RESPONSIVA
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
  FlashMode _currentFlashMode = FlashMode.auto;
  bool _showTips = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _initializeCamera();
  }
  
  void _checkAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
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
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      await _cameraController!.setZoomLevel(1.0);
      await _cameraController!.setExposureMode(ExposureMode.auto);
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setFlashMode(_currentFlashMode);
      
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar imagen'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    
    setState(() {
      switch (_currentFlashMode) {
        case FlashMode.off:
          _currentFlashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _currentFlashMode = FlashMode.always;
          break;
        case FlashMode.always:
          _currentFlashMode = FlashMode.off;
          break;
        default:
          _currentFlashMode = FlashMode.auto;
      }
    });
    
    await _cameraController!.setFlashMode(_currentFlashMode);
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_auto;
    }
  }

  // ← OVERLAY RESPONSIVO MEJORADO
  Widget _buildCameraOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular dimensiones responsivas
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Ajustar el marco según el tamaño de pantalla
        final frameWidth = screenWidth * 0.85;
        final frameHeight = screenHeight * 0.65;
        
        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
          ),
          child: Center(
            child: Container(
              width: frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long, 
                    size: screenWidth * 0.15, // Icono responsivo
                    color: Colors.green
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04, 
                      vertical: screenHeight * 0.01
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Coloca el comprobante dentro del marco',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04, // Texto responsivo
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Asegúrate de que esté bien iluminado y enfocado',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.03, // Texto responsivo
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ← TIPS RESPONSIVOS
  Widget _buildCameraTips() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        return Container(
          margin: EdgeInsets.all(screenWidth * 0.04),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.black87,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💡 Consejos para mejor escaneo:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              _tipItem('📱', 'Mantén el teléfono estable', screenWidth),
              _tipItem('💡', 'Asegura buena iluminación', screenWidth),
              _tipItem('📄', 'El recibo debe estar plano', screenWidth),
              _tipItem('🎯', 'Centra el recibo en el marco', screenWidth),
              _tipItem('📏', 'Mantén distancia adecuada', screenWidth),
              SizedBox(height: screenHeight * 0.01),
              TextButton(
                onPressed: () => setState(() => _showTips = false),
                child: Text(
                  'Entendido', 
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: screenWidth * 0.035,
                  )
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tipItem(String emoji, String tip, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: screenWidth * 0.04)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white, 
                fontSize: screenWidth * 0.03
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        appBar: AppBar(
          title: Text('Escanear Comprobante'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Escanear Comprobante'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('No se pudo inicializar la cámara')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear Comprobante'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => setState(() => _showTips = true),
          ),
        ],
      ),
      // ← CUERPO COMPLETAMENTE RESPONSIVO
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          
          // Calcular alturas responsivas
          final controlsHeight = screenHeight * 0.15; // 15% para controles
          final cameraHeight = screenHeight - controlsHeight; // Resto para cámara
          
          return Column(
            children: [
              // ← ÁREA DE CÁMARA RESPONSIVA
              Container(
                height: cameraHeight,
                width: screenWidth,
                child: Stack(
                  children: [
                    // Vista de la cámara
                    Positioned.fill(
                      child: ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.height ?? screenWidth,
                            height: _cameraController!.value.previewSize?.width ?? cameraHeight,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                    
                    // OVERLAY
                    Positioned.fill(
                      child: _buildCameraOverlay(),
                    ),
                    
                    // TIPS (SI ESTÁN HABILITADOS)
                    if (_showTips)
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: _buildCameraTips(),
                      ),
                  ],
                ),
              ),
              
              // ← CONTROLES RESPONSIVOS (ALTURA FIJA)
              Container(
                height: controlsHeight,
                width: screenWidth,
                decoration: BoxDecoration(
                  color: Colors.black87,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: controlsHeight * 0.15,
                    horizontal: screenWidth * 0.05,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _getFlashIcon(), 
                              color: Colors.white, 
                              size: screenWidth * 0.08 // Icono responsivo
                            ),
                            onPressed: _toggleFlash,
                          ),
                          Text(
                            'Flash',
                            style: TextStyle(
                              color: Colors.white70, 
                              fontSize: screenWidth * 0.025
                            ),
                          ),
                        ],
                      ),
                      
                      // Botón de captura responsivo
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePhoto,
                        child: Container(
                          height: controlsHeight * 0.6, // Botón responsivo
                          width: controlsHeight * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: _isCapturing
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Container(
                                  margin: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      // Cambiar cámara
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.flip_camera_ios, 
                              color: Colors.white, 
                              size: screenWidth * 0.08
                            ),
                            onPressed: () {
                              // TODO: Implementar cambio de cámara
                            },
                          ),
                          Text(
                            'Voltear',
                            style: TextStyle(
                              color: Colors.white70, 
                              fontSize: screenWidth * 0.025
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}