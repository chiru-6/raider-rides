final _ttuEmail = RegExp(r'^[a-z0-9._%+-]+@ttu\.edu$');

/// Only Texas Tech emails can sign in, which keeps the board student-only.
String? validateTtuEmail(String? value) {
  final email = value?.trim().toLowerCase() ?? '';
  if (email.isEmpty) return 'Enter your TTU email';
  if (!_ttuEmail.hasMatch(email)) return 'Use your @ttu.edu email';
  return null;
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) return 'Enter $label';
  return null;
}

/// Total trip cost: a number from 0 to 1000.
String? validateCost(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter the total trip cost (0 if free)';
  final cost = double.tryParse(text);
  if (cost == null) return 'Enter a number, like 60 or 42.50';
  if (cost < 0) return "Cost can't be negative";
  if (cost > 1000) return 'Keep it under \$1000';
  return null;
}
