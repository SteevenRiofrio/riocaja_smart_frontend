class TextConstants {
  // Constructor privado para prevenir instanciación
  TextConstants._();
  
  // ==================== APP ====================
  
  static const String appName = 'RioCaja Smart';
  static const String version = '1.0.0';
  static const String appVersion = 'v1.0.0';
  static const String appSubtitle = 'Sistema de Gestión CNB';
  
  // ==================== AUTENTICACIÓN ====================
  
  // Login
  static const String email = 'Email';
  static const String password = 'Contraseña';
  static const String login = 'Iniciar Sesión';
  static const String iniciarSesion = 'Iniciar Sesión';
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
  
  // Información usuarios
  static const String informacionNuevosUsuarios = 'Información para Nuevos Usuarios';
  static const String infoNuevosUsuarios = 'Los nuevos usuarios deben registrarse y esperar aprobación del administrador';
  
  // ==================== ROLES Y ESTADOS ====================
  
  // Roles
  static const String administrador = 'Administrador';
  static const String asesor = 'Asesor';                    // Antes era Operador
  static const String cnb = 'CNB';                          // Antes era Lector
  static const String administradorLocal = 'Administrador Local';
  static const String administracionPrincipal = 'Administración Principal';
  static const String administracion = 'Administración';
  
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
  static const String fechaTransaccion = 'Fecha de Transacción';
  static const String tipoTransaccion = 'Tipo de Transacción';
  static const String valorTransaccion = 'Valor de Transacción';
  static const String cedulaRemitente = 'Cédula Remitente';
  static const String nombreRemitente = 'Nombre Remitente';
  static const String cedulaBeneficiario = 'Cédula Beneficiario';
  static const String nombreBeneficiario = 'Nombre Beneficiario';
  static const String telefonoBeneficiario = 'Teléfono Beneficiario';
  static const String ciudadDestino = 'Ciudad Destino';
  static const String entidadPagadora = 'Entidad Pagadora';
  static const String codigoClaro = 'Código Claro';
  static const String numeroRecarga = 'Número para Recarga';
  static const String empresa = 'Empresa';
  static const String referencia = 'Referencia';
  static const String codigoBarras = 'Código de Barras';
  static const String numeroReferencia = 'Número de Referencia';
  
  // ==================== NAVEGACIÓN Y MENÚS ====================
  
  // Navegación principal
  static const String inicio = 'Inicio';
  static const String comprobantes = 'Comprobantes';
  static const String reportes = 'Reportes';
  static const String configuracion = 'Configuración';
  static const String perfil = 'Perfil';
  static const String ayuda = 'Ayuda';
  static const String salir = 'Salir';
  static const String cerrarSesion = 'Cerrar Sesión';
  
  // Menús específicos
  static const String escanearComprobante = 'Escanear Comprobante';
  static const String historialComprobantes = 'Historial de Comprobantes';
  static const String reportesCierre = 'Reportes de Cierre';
  static const String verCompartir = 'Ver y compartir reportes';
  static const String reportesExcel = 'Reportes Excel';
  static const String exportarDatos = 'Exportar datos detallados';
  static const String mensajes = 'Mensajes';
  static const String gestionUsuarios = 'Gestión de Usuarios';
  static const String administrarTodosLosUsuarios = 'Administrar todos los usuarios del sistema';
  static const String usuariosPendientes = 'Usuarios Pendientes';
  static const String soloPendientesAprobacion = 'Solo usuarios pendientes de aprobación';
  static const String diagnostico = 'Diagnóstico';
  
  // Acciones
  static const String crear = 'Crear';
  static const String editar = 'Editar';
  static const String eliminar = 'Eliminar';
  static const String guardar = 'Guardar';
  static const String cancelar = 'Cancelar';
  static const String buscar = 'Buscar';
  static const String filtrar = 'Filtrar';
  static const String exportar = 'Exportar';
  static const String imprimir = 'Imprimir';
  static const String actualizar = 'Actualizar';
  static const String confirmar = 'Confirmar';
  static const String aceptar = 'Aceptar';
  static const String rechazar = 'Rechazar';
  static const String aprobar = 'Aprobar';
  static const String siguiente = 'Siguiente';
  static const String anterior = 'Anterior';
  static const String continuar = 'Continuar';
  static const String finalizar = 'Finalizar';
  
  // ==================== MENSAJES Y VALIDACIONES ====================
  
  // Mensajes de éxito
  static const String operacionExitosa = 'Operación realizada exitosamente';
  static const String comprobanteCreado = 'Comprobante creado exitosamente';
  static const String perfilActualizado = 'Perfil actualizado correctamente';
  static const String cambiosGuardados = 'Cambios guardados correctamente';
  
  // Mensajes de error
  static const String errorGenerico = 'Ha ocurrido un error inesperado';
  static const String errorGeneral = 'Error';
  static const String credencialesInvalidas = 'Credenciales inválidas';
  static const String errorConexion = 'Error de conexión. Verifique su internet';
  static const String errorServidor = 'Error del servidor. Intente más tarde';
  static const String errorValidacion = 'Por favor, complete todos los campos requeridos';
  static const String emailInvalido = 'Email inválido';
  static const String passwordCorto = 'La contraseña debe tener al menos 6 caracteres';
  static const String passwordsNoCoinciden = 'Las contraseñas no coinciden';
  static const String campoRequerido = 'Este campo es requerido';
  static const String formatoInvalido = 'Formato inválido';
  
  // Mensajes de confirmación
  static const String confirmarAccion = '¿Está seguro que desea realizar esta acción?';
  static const String confirmarEliminacion = '¿Está seguro que desea eliminar este elemento?';
  static const String confirmarCambios = '¿Está seguro que desea guardar los cambios?';
  static const String estaSeguroCerrarSesion = 'Esta acción cerrará su sesión actual.';
  static const String confirmarCierreSesion = '¿Confirmar cierre de sesión?';
  
  // Estados de usuarios pendientes
  static const String noHayUsuariosPendientes = 'No hay usuarios pendientes';
  static const String todosUsuariosProcesados = 'Todos los usuarios han sido procesados';
  static const String registrado = 'Registrado';
  static const String rolSolicitado = 'Rol solicitado';
  static const String sinNombre = 'Sin nombre';
  static const String sinEmail = 'Sin email';
  static const String sinRol = 'Sin rol';
  
  // ==================== SESIÓN ====================
  
  static const String cerrandoSesion = 'Cerrando sesión...';
  static const String sesionCerradaCorrectamente = 'Sesión cerrada correctamente';
  static const String errorCerrarSesion = 'Error al cerrar sesión';
  
  // ==================== MÉTODOS AUXILIARES ====================
  
  /// Obtiene el nombre del rol en español
  static String getRoleName(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return administrador;
      case 'asesor':
        return asesor;
      case 'cnb':
        return cnb;
      default:
        return cnb;  // Por defecto CNB
    }
  }
  
  /// Obtiene el nombre del estado en español
static String getEstadoName(String estado) {
  switch (estado.toLowerCase()) {
    case 'activo': return 'Activo';
    case 'inactivo': return 'Inactivo'; 
    case 'suspendido': return 'Suspendido';
    case 'pendiente': return 'Pendiente';
    default: return estado.toUpperCase();
  }
}
}