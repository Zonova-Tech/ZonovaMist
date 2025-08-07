// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get fullName => 'Nombre Completo';

  @override
  String get emailHint => 'Ingrese su correo electrónico';

  @override
  String get passwordHint => 'Ingrese su contraseña';

  @override
  String get fullNameHint => 'Ingrese su nombre completo';

  @override
  String get loginSuccess => 'Inicio de sesión exitoso';

  @override
  String get registrationSuccess => 'Registro exitoso';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get invalidEmail =>
      'Por favor, ingrese una dirección de correo electrónico válida.';
}
