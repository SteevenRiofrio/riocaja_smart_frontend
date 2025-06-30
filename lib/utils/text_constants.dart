// lib/utils/text_constants.dart
class TextConstants {
  // ==================== TEXTOS PRINCIPALES ====================
  
  // App
  static const String appName = 'RíoCaja Smart';
  static const String appSubtitle = 'Gestión de Comprobantes CNB';
  static const String appVersion = 'Versión 1.0.0';
  
  // ==================== SECCIONES PRINCIPALES ====================
  
  // Administración
  static const String administracion = 'Administración';
  static const String gestionUsuarios = 'Gestión de Usuarios';
  static const String usuariosPendientes = 'Usuarios Pendientes';
  static const String todosLosUsuarios = 'Todos los Usuarios';
  static const String pendientes = 'Pendientes';
  static const String administrarTodosLosUsuarios = 'Administrar todos los usuarios';
  static const String soloPendientesAprobacion = 'Solo pendientes de aprobación';
  
  // Reportes
  static const String reportes = 'Reportes';
  static const String reportesCierre = 'Reportes de Cierre';
  static const String reportesExcel = 'Reportes Excel';
  static const String exportarDatos = 'Exportar datos a Excel';
  static const String verCompartir = 'Ver y compartir como texto/PDF';
  
  // Mensajes
  static const String mensajes = 'Mensajes';
  static const String nuevoMensaje = 'Nuevo Mensaje';
  static const String marcarLeido = 'Marcar como leído';
  static const String crearMensaje = 'Crear Mensaje';
  
  // ==================== AUTENTICACIÓN ====================
  
  // Login
  static const String iniciarSesion = 'Iniciar Sesión';
  static const String cerrarSesion = 'Cerrar Sesión';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String recordarme = 'Recordarme';
  static const String olvidoPassword = '¿Olvidó su contraseña?';
  static const String noTieneCuenta = '¿No tiene cuenta?';
  static const String yaSeRegistro = '¿Ya se registró?';
  static const String registrese = 'Regístrese';
  static const String ingresar = 'Ingresar';
  static const String iniciaSesion = 'Inicia sesión';
  
  // Registro
  static const String registro = 'Registro';
  static const String nombreCompleto = 'Nombre Completo';
  static const String confirmarPassword = 'Confirmar Contraseña';
  static const String registrarse = 'Registrarse';
  static const String crearCuenta = 'Crear Cuenta';
  
  // ==================== ROLES Y ESTADOS ====================
  
  // Roles
  static const String administrador = 'Administrador';
  static const String operador = 'Operador';
  static const String lector = 'Lector';
  static const String administradorLocal = 'Administrador Local';
  static const String administracionPrincipal = 'Administración Principal';
  
  // Estados
  static const String activo = 'Activo';
  static const String inactivo = 'Inactivo';
  static const String pendiente = 'PENDIENTE';
  static const String aprobado = 'Aprobado';
  static const String rechazado = 'Rechazado';
  static const String bloqueado = 'Bloqueado';
  
  // ==================== TIPOS DE TRANSACCIONES ====================
  
  static const String recargaClaro = 'RECARGA CLARO';
  static const String efectivoMovil = 'EFECTIVO MOVIL';
  static const String deposito = 'DEPOSITO';
  static const String retiro = 'RETIRO';
  static const String envioGiro = 'ENVIO GIRO';
  static const String pagoGiro = 'PAGO GIRO';
  static const String pagoServicio = 'PAGO DE SERVICIO';
  
  // ==================== CAMPOS DE FORMULARIOS ====================
  
  // Campos comunes
  static const String fecha = 'Fecha';
  static const String hora = 'Hora';
  static const String tipo = 'Tipo';
  static const String valor = 'Valor';
  static const String valorTotal = 'Valor Total';
  static const String descripcion = 'Descripción';
  static const String observaciones = 'Observaciones';
  static const String codigo = 'Código';
  static const String nombre = 'Nombre';
  static const String telefono = 'Teléfono';
  static const String direccion = 'Dirección';
  
  // Campos específicos
  static const String nroTransaccion = 'Nro. Transacción';
  static const String codigoCorresponsal = 'Código de Corresponsal';
  static const String nombreCorresponsal = 'Nombre del Corresponsal';
  static const String nombreLocal = 'Nombre del Local';
  static const String fechaRegistro = 'Fecha de Registro';
  static const String ultimoAcceso = 'Último Acceso';
  
  // ==================== ACCIONES ====================
  
  // Acciones básicas
  static const String guardar = 'Guardar';
  static const String cancelar = 'Cancelar';
  static const String aceptar = 'Aceptar';
  static const String rechazar = 'Rechazar';
  static const String eliminar = 'Eliminar';
  static const String editar = 'Editar';
  static const String buscar = 'Buscar';
  static const String filtrar = 'Filtrar';
  static const String actualizar = 'Actualizar';
  static const String refrescar = 'Refrescar';
  static const String continuar = 'Continuar';
  
  // Acciones específicas
  static const String escanear = 'Escanear';
  static const String escanearComprobante = 'Escanear Comprobante';
  static const String fotografiar = 'Fotografiar';
  static const String procesar = 'Procesar';
  static const String generar = 'Generar';
  static const String descargar = 'Descargar';
  static const String compartir = 'Compartir';
  
  // Acciones de usuarios
  static const String aprobar = 'Aprobar';
  static const String bloquear = 'Bloquear';
  static const String activar = 'Activar';
  
  // ==================== NAVEGACIÓN ====================
  
  static const String inicio = 'Inicio';
  static const String comprobantes = 'Comprobantes';
  static const String historial = 'Historial';
  static const String historialComprobantes = 'Historial de Comprobantes';
  static const String usuarios = 'Usuarios';
  static const String diagnostico = 'Diagnóstico';
  
  // ==================== MENSAJES Y NOTIFICACIONES ====================
  
  // Mensajes de éxito
  static const String loginExitoso = 'Inicio de sesión exitoso';
  static const String registroExitoso = 'Registro exitoso';
  static const String datoGuardado = 'Dato guardado correctamente';
  static const String usuarioAprobado = 'Usuario aprobado correctamente';
  static const String usuarioRechazado = 'Usuario rechazado';
  static const String sesionCerradaCorrectamente = 'Sesión cerrada correctamente';
  
  // Mensajes de error
  static const String errorGeneral = 'Ha ocurrido un error';
  static const String errorConexion = 'Error de conexión';
  static const String errorCerrarSesion = 'Error al cerrar sesión';
  static const String datosIncompletos = 'Datos incompletos';
  static const String credencialesInvalidas = 'Credenciales inválidas';
  
  // Mensajes informativos
  static const String verificandoCredenciales = 'Verificando credenciales...';
  static const String cargandoDatos = 'Cargando datos...';
  static const String guardandoDatos = 'Guardando datos...';
  static const String cerrandoSesion = 'Cerrando sesión...';
  static const String noDetectado = 'No detectado';
  
  // ==================== INFORMACIÓN Y AYUDA ====================
  
  // Títulos informativos
  static const String informacion = 'Información';
  static const String informacionImportante = 'Información importante';
  static const String informacionNuevosUsuarios = 'Información para nuevos usuarios';
  static const String caracteristicasReportes = 'Características de los reportes';
  
  // ==================== CONFIGURACIÓN ====================
  
  static const String configuracion = 'Configuración';
  static const String notificaciones = 'Notificaciones';
  static const String cuenta = 'Cuenta';
  static const String perfil = 'Perfil';
  
  // ==================== ESTADÍSTICAS ====================
  
  static const String estadisticas = 'Estadísticas';
  static const String resumen = 'Resumen';
  static const String totales = 'Totales';
  
  // ==================== FILTROS Y BÚSQUEDAS ====================
  
  static const String todos = 'Todos';
  static const String todosLosRoles = 'Todos los roles';
  static const String todosLosEstados = 'Todos los estados';
  
  // ==================== FECHAS Y TIEMPO ====================
  
  static const String hoy = 'Hoy';
  static const String ayer = 'Ayer';
  static const String estaSemana = 'Esta semana';
  static const String esteMes = 'Este mes';
  
  // ==================== INFORMACIÓN ESPECÍFICA ====================
  
  // Información de nuevos usuarios
  static const String infoNuevosUsuarios = '''• Los nuevos usuarios deben ser aprobados por un administrador
• Después de la aprobación, completará su perfil con el código de corresponsal
• Contacte al administrador si tiene dudas''';
  
  // Información importante
  static const String infoImportante = '''• Tu cuenta será revisada por un administrador
• Recibirás notificación cuando sea aprobada
• Mantén tus datos actualizados
• Contacta al administrador si tienes dudas''';
  
  // ==================== TEXTOS ESPECÍFICOS DE PANTALLAS ====================
  
  // OCR y Escaneo
  static const String textoCompletoEscaneado = 'Ver texto completo escaneado';
  static const String errorExtrayendoTexto = 'Error al extraer texto';
  
  // Dashboard
  static const String bienvenido = 'Bienvenido';
  
  // Banco
  static const String bancoDelBarrio = 'Banco del Barrio';
  static const String cnb = 'CNB';
  
  // Diálogos
  static const String confirmarCierreSesion = '¿Está seguro que desea cerrar sesión?';
  static const String estaSeguroCerrarSesion = 'Esta acción cerrará su sesión actual.';
  
  // Estados de usuarios pendientes
  static const String noHayUsuariosPendientes = 'No hay usuarios pendientes';
  static const String todosUsuariosProcesados = 'Todos los usuarios han sido procesados';
  static const String registrado = 'Registrado';
  static const String rolSolicitado = 'Rol solicitado';
  static const String sinNombre = 'Sin nombre';
  static const String sinEmail = 'Sin email';
  static const String sinRol = 'Sin rol';
  
  // ==================== MÉTODOS AUXILIARES ====================
  
  /// Obtiene el nombre del rol en español
  static String getRoleName(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return administrador;
      case 'operador':
        return operador;
      case 'lector':
        return lector;
      default:
        return lector;
    }
  }
  
  /// Obtiene el nombre del estado en español
  static String getEstadoName(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return activo;
      case 'inactivo':
        return inactivo;
      case 'pendiente':
        return pendiente;
      case 'aprobado':
        return aprobado;
      case 'rechazado':
        return rechazado;
      case 'bloqueado':
        return bloqueado;
      default:
        return pendiente;
    }
  }
}