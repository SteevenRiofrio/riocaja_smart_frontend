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
          'CNB Banco Guayaquil S.A.\nRUC: [Número de RUC]\nDirección: [Dirección completa]\nEmail: privacidad@cnbguayaquil.com.ec'
        ),
        
        _buildSection(
          '📋 DATOS QUE RECOPILAMOS',
          '• Nombre completo\n• Correo electrónico\n• Nombre del local\n• Código de corresponsal\n• Ubicación del establecimiento\n• Logs de uso de la aplicación'
        ),
        
        _buildSection(
          '🎯 FINALIDAD DEL TRATAMIENTO',
          '• Gestión de comprobantes bancarios\n• Autenticación de usuarios autorizados\n• Cumplimiento de normativa financiera\n• Prevención de fraude y lavado de activos\n• Mejora de servicios (solo con su consentimiento)'
        ),
        
        _buildSection(
          '📅 TIEMPO DE CONSERVACIÓN',
          '• Datos operacionales: Durante la relación contractual\n• Datos de auditoría: 7 años (normativa bancaria)\n• Datos de marketing: Hasta revocación del consentimiento'
        ),
        
        _buildSection(
          '⚖️ SUS DERECHOS FUNDAMENTALES',
          '• ACCESO: Conocer qué datos tenemos\n• RECTIFICACIÓN: Corregir datos incorrectos\n• ELIMINACIÓN: Solicitar borrado cuando proceda\n• OPOSICIÓN: Negarse a ciertos tratamientos\n• PORTABILIDAD: Recibir datos en formato estructurado\n• REVOCACIÓN: Retirar consentimiento en cualquier momento'
        ),
        
        _buildSection(
          '🔒 MEDIDAS DE SEGURIDAD',
          '• Cifrado de datos con estándares bancarios\n• Autenticación multifactor\n• Controles de acceso estrictos\n• Auditorías de seguridad regulares\n• Respaldos seguros y encriptados'
        ),
        
        _buildSection(
          '📞 CONTACTO Y RECLAMOS',
          'Para ejercer sus derechos:\n• Email: privacidad@cnbguayaquil.com.ec\n• Plazo de respuesta: 15 días calendario\n\nPara reclamos:\n• SPDP: www.spdp.gob.ec\n• Email SPDP: denuncias@spdp.gob.ec'
        ),
        
        _buildSection(
          '📜 BASE LEGAL',
          'Este tratamiento se basa en:\n• Ley Orgánica de Protección de Datos Personales del Ecuador\n• Normativa de la Superintendencia de Bancos\n• Relación contractual para servicios bancarios\n• Consentimiento para funcionalidades opcionales'
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
                '⚠️ IMPORTANTE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Al aceptar estos términos, usted confirma que:\n\n'
                '✓ Ha leído y comprendido este aviso de privacidad\n'
                '✓ Consiente el tratamiento de sus datos para las finalidades descritas\n'
                '✓ Entiende sus derechos y cómo ejercerlos\n'
                '✓ Puede revocar su consentimiento en cualquier momento\n\n'
                'Este consentimiento es necesario para usar RíoCaja Smart.',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptancePanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasReadCompletely)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.vertical_align_bottom, color: Colors.orange.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Debe leer completamente los términos antes de aceptar',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (_hasReadCompletely) ...[
            SizedBox(height: 12),
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
              title: Text(
                'He leído y acepto los términos de protección de datos personales',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
              subtitle: Text(
                'Necesario para usar RíoCaja Smart',
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
                onPressed: _termsAccepted ? _acceptTermsAndContinue : null,
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