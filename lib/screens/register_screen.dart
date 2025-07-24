import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // Estados de validación en tiempo real
  bool _isNombreValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  // ✅ VARIABLES NUEVAS PARA TÉRMINOS
  bool _acceptTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validación en tiempo real del nombre
  void _validateNombre(String value) {
    setState(() {
      _isNombreValid = _isValidNombre(value);
    });
  }

  // Validación en tiempo real del email
  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = _isValidEmail(value);
    });
  }

  // Validación en tiempo real de la contraseña
  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = _isValidPassword(value);
      // Re-validar confirmación si ya tiene contenido
      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = _confirmPasswordController.text == value;
      }
    });
  }

  // Validación en tiempo real de confirmación
  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid = value == _passwordController.text && value.isNotEmpty;
    });
  }

  // Métodos de validación
  bool _isValidNombre(String nombre) {
    if (nombre.isEmpty) return false;
    
    // Debe tener al menos 2 palabras (nombre y apellido)
    final palabras = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.length < 2) return false;
    
    // Solo letras, espacios, acentos y apostrofes
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']+$");
    if (!regex.hasMatch(nombre)) return false;
    
    // Longitud mínima y máxima
    if (nombre.length < 3 || nombre.length > 50) return false;
    
    return true;
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Regex más estricto para email
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return false;
    
    // Longitud máxima
    if (email.length > 100) return false;
    
    // No debe empezar o terminar con punto
    if (email.startsWith('.') || email.endsWith('.')) return false;
    
    // No debe tener puntos consecutivos
    if (email.contains('..')) return false;
    
    return true;
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    
    // Longitud mínima
    if (password.length < 8) return false;
    
    // Longitud máxima
    if (password.length > 50) return false;
    
    // Debe contener al menos una letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
    
    // Debe contener al menos un número
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    // Debe contener al menos un carácter especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    // No debe contener espacios
    if (password.contains(' ')) return false;
    
    return true;
  }

  // Obtener mensaje de error para nombre
  String? _getNombreError(String value) {
    if (value.isEmpty) return 'El nombre completo es requerido';
    
    final palabras = value.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.length < 2) return 'Ingrese nombre y apellido completos';
    
    if (value.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (value.length > 50) return 'El nombre no puede exceder 50 caracteres';
    
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']+$");
    if (!regex.hasMatch(value)) return 'Solo se permiten letras, espacios y apostrofes';
    
    return null;
  }

  // Obtener mensaje de error para email
  String? _getEmailError(String value) {
    if (value.isEmpty) return 'El correo electrónico es requerido';
    
    if (value.length > 100) return 'El correo no puede exceder 100 caracteres';
    
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Ingrese un correo electrónico válido';
    
    if (value.startsWith('.') || value.endsWith('.')) {
      return 'El correo no puede empezar o terminar con punto';
    }
    
    if (value.contains('..')) return 'El correo no puede tener puntos consecutivos';
    
    return null;
  }

  // Obtener mensaje de error para contraseña
  String? _getPasswordError(String value) {
    if (value.isEmpty) return 'La contraseña es requerida';
    
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (value.length > 50) return 'La contraseña no puede exceder 50 caracteres';
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un carácter especial';
    }
    
    if (value.contains(' ')) {
      return 'La contraseña no puede contener espacios';
    }
    
    return null;
  }

  // Widget para mostrar indicadores de fortaleza de contraseña
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return SizedBox.shrink();
    
    List<bool> criteria = [
      _passwordController.text.length >= 8,
      RegExp(r'[a-zA-Z]').hasMatch(_passwordController.text),
      RegExp(r'[0-9]').hasMatch(_passwordController.text),
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text),
      !_passwordController.text.contains(' '),
    ];
    
    List<String> labels = [
      'Al menos 8 caracteres',
      'Contiene letras',
      'Contiene números',
      'Contiene símbolos especiales',
      'Sin espacios',
    ];
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          ...List.generate(criteria.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    criteria[index] ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: criteria[index] ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: criteria[index] ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Widget de términos y condiciones
  Widget _buildTermsSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _acceptTerms ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Instrucciones de lectura
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Lectura Requerida:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '1. Lee cuidadosamente los términos de servicio\n'
                  '2. Revisa la política de privacidad\n'
                  '3. Comprende tus derechos y responsabilidades',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Enlaces a términos
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTermsDialog('terms'),
                  icon: Icon(Icons.description, size: 16),
                  label: Text('Leer Términos y Condiciones'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue.shade400),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTermsDialog('privacy'),
                  icon: Icon(Icons.privacy_tip, size: 16),
                  label: Text('Leer Política de Privacidad'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue.shade400),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Checkbox de aceptación
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _acceptTerms ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptTerms ? Colors.green.shade300 : Colors.orange.shade300,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                      _showTermsError = false;
                    });
                  },
                  activeColor: Colors.green.shade700,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                        _showTermsError = false;
                      });
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '✅ ',
                            style: TextStyle(fontSize: 16),
                          ),
                          TextSpan(
                            text: 'Acepto los términos y condiciones',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _acceptTerms ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mensaje de error si no acepta términos
          if (_showTermsError)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debe aceptar los términos y condiciones para continuar',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Botón de crear cuenta modificado
  Widget _buildCreateAccountButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: (_isLoading || !_acceptTerms || !_isNombreValid || !_isEmailValid || !_isPasswordValid || !_isConfirmPasswordValid) 
            ? null 
            : _register,
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Registrando...'),
                ],
              )
            : Text(
                'Crear Cuenta',
                style: TextStyle(fontSize: 16),
              ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: (_acceptTerms && _isNombreValid && _isEmailValid && _isPasswordValid && _isConfirmPasswordValid) 
              ? Colors.green.shade700 
              : Colors.grey.shade400,
          disabledBackgroundColor: Colors.grey.shade400,
        ),
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Modal para mostrar términos
  void _showTermsDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type == 'terms' ? 'Términos y Condiciones' : 'Política de Privacidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: type == 'terms' ? _buildTermsContent() : _buildPrivacyContent(),
                  ),
                ),
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _acceptTerms = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Acepto',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Contenido de términos
  List<Widget> _buildTermsContent() {
    return [
      _buildModalSection(
        'Aceptación de los Términos',
        'Al registrarse en RíoCaja Smart, usted acepta cumplir con estos términos y condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe usar nuestra aplicación.',
      ),
      _buildModalSection(
        'Registro de Usuario',
        'Para usar la aplicación, debe registrarse proporcionando información precisa y actualizada. Es responsable de mantener la confidencialidad de su cuenta y todas las actividades que ocurran bajo su cuenta.',
      ),
      _buildModalSection(
        'Uso Apropiado',
        'RioCaja Smart es una herramienta administrativa para la gestión de cierres de caja mediante reconocimiento óptico de caracteres (OCR). Se compromete a:\n'
        '• Usar la aplicación únicamente para digitalizar y gestionar comprobantes\n'
        '• No procesar documentos que no sean de su propiedad o autorización\n'
        '• Mantener la integridad y veracidad de los datos registrados\n'
        '• No intentar comprometer la seguridad del sistema',
      ),
      _buildModalSection(
        'Responsabilidades del Usuario',
        'Como usuario de RioCaja Smart, usted es responsable de:\n'
        '• Mantener seguras sus credenciales de acceso\n'
        '• Verificar la precisión de los datos extraídos por OCR antes de confirmar\n'
        '• Reportar cualquier error o inconsistencia en el procesamiento\n'
        '• Usar la aplicación solo para fines contables y administrativos legítimos\n'
        '• Mantener la confidencialidad de la información procesada\n'
        '• Cumplir con las regulaciones contables aplicables en su jurisdicción',
      ),
      _buildModalSection(
        'Limitaciones de Servicio',
        'RioCaja Smart es una herramienta de apoyo administrativo. Las limitaciones incluyen:\n'
        '• La precisión del OCR puede variar según la calidad del documento\n'
        '• La aplicación requiere conexión a internet para funcionar correctamente\n'
        '• Los datos procesados deben ser validados por el usuario final\n'
        '• Nos reservamos el derecho de suspender cuentas por uso indebido\n'
        '• El servicio está sujeto a mantenimiento y actualizaciones periódicas',
      ),
      _buildModalSection(
        'Modificaciones',
        'Nos reservamos el derecho de modificar estos términos en cualquier momento para mejorar el servicio o cumplir con regulaciones. Los cambios serán notificados a través de la aplicación con al menos 15 días de anticipación.',
      ),
    ];
  }

  // ✅ NUEVA FUNCIÓN: Contenido de privacidad
  List<Widget> _buildPrivacyContent() {
    return [
      _buildModalSection(
        'Recolección de Datos',
        'RioCaja Smart recolecta únicamente la información necesaria para brindar el servicio de gestión de cierres de caja:\n'
        '• Datos de registro (nombre, email, nombre sus establecimiento,contraseña)\n'
        '• Información extraída de comprobantes mediante OCR\n'
        '• Registros de actividad en la aplicación\n'
        '• Datos técnicos para mejorar el servicio',
      ),
      _buildModalSection(
        'Uso de la Información',
        'Los datos recolectados se utilizan exclusivamente para:\n'
        '• Proporcionar el servicio de digitalización de comprobantes\n'
        '• Generar reportes y estadísticas de cierres de caja\n'
        '• Mejorar la precisión del reconocimiento óptico\n'
        '• Cumplir con obligaciones legales y contables',
      ),
      _buildModalSection(
        'Protección de Datos',
        'Implementamos medidas de seguridad robustas para proteger su información:\n'
        '• Encriptación de contraseña\n'
        '• Acceso restringido solo a personal autorizado\n'
        '• Respaldos seguros de la información\n'
      ),
      _buildModalSection(
        'Compartir Información',
        'RioCaja Smart NO comparte información personal con terceros. Los únicos casos donde podríamos compartir datos son:\n'
        '• Cuando sea requerido por autoridades legales competentes\n'
        '• Para cumplir con obligaciones regulatorias específicas\n'
        '• Con su consentimiento explícito y por escrito',
      ),
      _buildModalSection(
        'Derechos del Usuario',
        'Como usuario de RioCaja Smart, usted tiene derecho a:\n'
        '• Acceder a todos sus datos personales almacenados\n'
        '• Solicitar corrección de información inexacta\n'
        '• Solicitar eliminación de sus datos (derecho al olvido)\n'
        '• Exportar sus datos en formato legible\n'
      ),
      _buildModalSection(
        'Retención de Datos',
        'Conservamos sus datos durante el tiempo necesario para:\n'
        '• Proporcionar el servicio mientras mantenga su cuenta activa\n'
        '• Cumplir con obligaciones legales y contables (generalmente 5-7 años)\n'
        '• Resolver disputas o reclamos que puedan surgir\n'
        'Transcurrido este período, los datos serán eliminados de forma segura.',
      ),
    ];
  }

  // ✅ NUEVA FUNCIÓN: Sección del modal
  Widget _buildModalSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FUNCIÓN MODIFICADA: Validación de términos agregada
  void _register() async {
    // Validar términos PRIMERO
    if (!_acceptTerms) {
      setState(() {
        _showTermsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Debe aceptar los términos y condiciones para continuar'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validación del formulario
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() => _isLoading = true);
      
      try {
        final success = await authProvider.register(
          _nombreController.text.trim(),
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );
        
        if (success) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Registro Exitoso'),
                ],
              ),
              content: Text(
                'Su cuenta ha sido creada y está pendiente de aprobación por parte de un administrador. '
                'Recibirá notificación una vez que su cuenta sea aprobada.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pop(); // Volver a pantalla de login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Entendido'),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Crear una cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completa la información para registrarte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo de nombre completo
                        TextFormField(
                          controller: _nombreController,
                          onChanged: _validateNombre,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']")),
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo*',
                            hintText: 'Ej: Juan Carlos Pérez García',
                            prefixIcon: Icon(Icons.person),
                            suffixIcon: _nombreController.text.isNotEmpty
                                ? Icon(
                                    _isNombreValid ? Icons.check_circle : Icons.error,
                                    color: _isNombreValid ? Colors.green : Colors.red,
                                  )
                                : null,
                            border: OutlineInputBorder(),
                            helperText: 'Ingrese su nombre y apellidos completos',
                          ),
                          validator: (value) => _getNombreError(value ?? ''),
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de email
                        TextFormField(
                          controller: _emailController,
                          onChanged: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(100),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico*',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: Icon(Icons.email),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? Icon(
                                    _isEmailValid ? Icons.check_circle : Icons.error,
                                    color: _isEmailValid ? Colors.green : Colors.red,
                                  )
                                : null,
                            border: OutlineInputBorder(),
                            helperText: 'Será usado para iniciar sesión',
                          ),
                          validator: (value) => _getEmailError(value ?? ''),
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de contraseña
                        TextFormField(
                          controller: _passwordController,
                          onChanged: _validatePassword,
                          obscureText: _obscurePassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Contraseña*',
                            hintText: 'Mínimo 8 caracteres',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_passwordController.text.isNotEmpty)
                                  Icon(
                                    _isPasswordValid ? Icons.check_circle : Icons.error,
                                    color: _isPasswordValid ? Colors.green : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => _getPasswordError(value ?? ''),
                        ),
                        
                        // Indicador de fortaleza de contraseña
                        _buildPasswordStrengthIndicator(),
                        SizedBox(height: 16),
                        
                        // Campo de confirmar contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          onChanged: _validateConfirmPassword,
                          obscureText: _obscureConfirmPassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña*',
                            hintText: 'Repita la contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_confirmPasswordController.text.isNotEmpty)
                                  Icon(
                                    _isConfirmPasswordValid ? Icons.check_circle : Icons.error,
                                    color: _isConfirmPasswordValid ? Colors.green : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme su contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // ✅ AGREGAR: Sección de términos y condiciones
                        _buildTermsSection(),
                        SizedBox(height: 24),
                        
                        // ✅ REEMPLAZAR: Botón de registro con el nuevo
                        _buildCreateAccountButton(),
                        SizedBox(height: 16),
                        
                        // Opción para volver a login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Ya tienes una cuenta?'),
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.pop(context);
                              },
                              child: Text('Inicia sesión'),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Información adicional
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
                              Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                       color: Colors.blue.shade700, 
                                       size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información importante',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '📧 Recibirás confirmación por email\n'
                                '⏳ Tu cuenta será revisada por un administrador\n'
                                '🔔 Te notificaremos cuando sea aprobada\n'
                                '📞 Contacta al administrador si tienes dudas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}