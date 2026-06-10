class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nominal tidak boleh kosong';
    }
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(clean);
    if (amount == null) {
      return 'Nominal tidak valid';
    }
    if (amount <= 0) {
      return 'Nominal harus lebih dari 0';
    }
    return null;
  }

  static String? validateBudgetName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama budget tidak boleh kosong';
    }
    return null;
  }

  static String? validateSavingsTarget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Target tabungan tidak boleh kosong';
    }
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(clean);
    if (amount == null || amount <= 0) {
      return 'Target tabungan harus lebih dari 0';
    }
    return null;
  }

  static String? validatePersonName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }
}
