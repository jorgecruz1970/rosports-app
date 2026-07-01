/// Validadores reutilizables para formularios de la app.
/// Retornan null si el valor es válido, o un mensaje de error si no lo es.
class Validators {
  Validators._();

  // ── Email ────────────────────────────────────────────────────────────────────
  /// Valida que el email tenga un formato correcto.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    // Regex básica para email — cubre la gran mayoría de casos reales
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  // ── Contraseña ───────────────────────────────────────────────────────────────
  /// Valida que la contraseña tenga mínimo 8 caracteres y al menos 1 número.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  // ── Nombre ───────────────────────────────────────────────────────────────────
  /// Valida que el nombre tenga al menos 2 caracteres.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'Ingresa tu nombre completo';
    }
    return null;
  }

  // ── Teléfono ─────────────────────────────────────────────────────────────────
  /// Valida que el teléfono tenga entre 7 y 15 dígitos (formato E.164 flexible).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      // El teléfono es opcional — si está vacío, se permite
      return null;
    }
    // Solo dígitos y opcionalmente "+" al inicio
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  // ── Campo requerido genérico ─────────────────────────────────────────────────
  /// Valida que el campo no esté vacío.
  static String? validateRequired(String? value,
      {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }
}
