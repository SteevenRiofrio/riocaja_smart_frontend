import 'package:flutter/material.dart';
import 'package:riocaja_smart/services/privacy_simple_service.dart';

class PrivacyTermsScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const PrivacyTermsScreen({
    Key? key,
    required this.onAccepted,
  }) : super(key: key);

  @override
  State<PrivacyTermsScreen> createState() => _PrivacyTermsScreenState();
}

class _PrivacyTermsScreenState extends State<PrivacyTermsScreen> {
  bool _hasReadCompletely = false;
  bool _termsAccepted = false;
  double _scrollProgress = 0.0;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final progress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
      
      setState(() {
        _scrollProgress = progress.clamp(0.0, 1.0);
        if (_scrollProgress >= 0.95) {
          _hasReadCompletely = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // No se puede regresar sin aceptar
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Protección de Datos Personales'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Sin botón de regreso
        ),
        body: Column(
          children: [
            // Barra de progreso de lectura
            LinearProgressIndicator(
              value: _scrollProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
            
            // Contenido de términos
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20),
                    _buildTermsContent(),
                    SizedBox(height: 40), // Espacio para asegurar scroll
                  ],
                ),
              ),
            ),
            
            // Panel de aceptación
            _buildAcceptancePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: Colors.green.shade700,
            ),
            SizedBox(height: 12),
            Text(
              'LEY DE PROTECCIÓN DE DATOS PERSONALES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Ecuador - Cumplimiento LOPDP 2021',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '🏢 RESPONSABLE DEL TRATAMIENTO',
          'RíoCaja Smart\nAplicación móvil independiente\nEmail: riocaja.smart09@gmail.com'
        ),
        
        _buildSection(
          '📋 ¿QUÉ DATOS RECOPILAMOS?',
          'La aplicación RíoCaja Smart únicamente recopila estos datos:\n\n• Correo electrónico - Para que puedas ingresar a la app\n• Nombre completo - Para saber quién eres\n• Contraseña - Para que solo tú puedas entrar (guardada de forma segura)\n• Código de corresponsal - Para identificar tu punto de trabajo\n\n¡Y ESO ES TODO! No recopilamos nada más.'
        ),
        
        _buildSection(
          '🎯 ¿QUÉ HACEMOS CON TUS DATOS?',
          'Usamos tu información únicamente para:\n\n• Que puedas entrar a la aplicación (usando tu correo y contraseña)\n• Identificarte dentro de la app (usando tu nombre)\n• Saber en qué punto trabajas (usando tu código de corresponsal)\n• Contactarte si hay algún problema técnico con la app\n• Nada más - No vendemos, no compartimos, no hacemos publicidad'
        ),
        
        _buildSection(
          '🔒 TUS DATOS ESTÁN SEGUROS',
          'Te garantizamos que:\n\n• Tu contraseña está encriptada - Nadie puede verla, ni nosotros\n• Usamos conexiones seguras - Toda la información viaja protegida\n• Solo personal autorizado puede acceder a los datos del sistema\n• NO vendemos tu información a nadie\n• NO compartimos tus datos con otras empresas\n• NO enviamos publicidad no deseada\n• NO accedemos a otros datos de tu teléfono'
        ),
        
        _buildSection(
          '⏰ ¿CUÁNTO TIEMPO GUARDAMOS TUS DATOS?',
          '• Mientras uses la aplicación - Mantenemos tu información activa\n• Si no usas la app por 2 años - Eliminamos automáticamente tus datos\n• Si nos pides eliminar tu cuenta - Borramos todo inmediatamente'
        ),
        
        _buildSection(
          '📞 CONTACTO',
          'Si tienes preguntas o quieres que eliminemos tu información:\n• Email: riocaja.smart09@gmail.com\n• Te respondemos en máximo 15 días'
        ),
        
        _buildSection(
          '⚖️ ¿ES ESTO LEGAL?',
          '¡SÍ! Esta aplicación cumple con:\n\n• Ley Orgánica de Protección de Datos Personales del Ecuador (2021)\n• Tu consentimiento que das al aceptar estos términos\n• Normativas técnicas de seguridad de información\n• Buenas prácticas de protección de datos'
        ),
        
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ AL ACEPTAR CONFIRMAS QUE:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '✓ Entiendes que solo recopilamos los 4 datos mencionados\n'
                '✓ Aceptas que usemos esos datos para que funcione la app\n'
                '✓ Confías en que mantendremos tu información segura\n'
                '✓ Sabes que puedes contactarnos para eliminar tus datos\n'
                '✓ Comprendes que esto es necesario para usar RíoCaja Smart\n\n'
                'Es simple: Solo pedimos lo necesario, solo lo usamos para la app, y está seguro.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptancePanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _termsAccepted,
            onChanged: _hasReadCompletely ? (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            } : null,
            title: Text(
              'He leído y acepto los términos de protección de datos personales',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _hasReadCompletely ? Colors.green.shade700 : Colors.grey,
              ),
            ),
            subtitle: Text(
              _hasReadCompletely 
                ? 'Necesario para usar RíoCaja Smart'
                : 'Debe leer completamente el documento primero',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            activeColor: Colors.green.shade700,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_hasReadCompletely && _termsAccepted) ? _acceptTermsAndContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Aceptar y Continuar a RíoCaja Smart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptTermsAndContinue() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Guardar aceptación
      await PrivacySimpleService.acceptTerms();

      // Cerrar loading
      Navigator.of(context).pop();
      
      // Continuar a la app
      widget.onAccepted();

    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando aceptación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}