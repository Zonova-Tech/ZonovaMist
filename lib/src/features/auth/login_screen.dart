import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/features/auth/register_screen.dart';
import 'package:Zonova_Mist/src/core/routing/app_router.dart';

import '../../core/i18n/arb/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  String? _savedEmail;
  String? _savedPassword;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    final remember = await _storage.read(key: 'rememberMe') == 'true';

    if (mounted) {
      setState(() {
        _savedEmail = email;
        _savedPassword = password;
        _rememberMe = remember;
      });
    }
  }

  Future<void> _saveCredentials(String email, String password, bool remember) async {
    if (remember) {
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);
      await _storage.write(key: 'rememberMe', value: 'true');
    } else {
      await _storage.deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authProvider, (previous, next) {
      next.when(
        loading: () {},
        authenticated: (_) {},
        unauthenticated: () {},
        error: (message) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/icons/logo.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Zonova Mist',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 48),

                // Email
                FormBuilderTextField(
                  name: 'email',
                  initialValue: _savedEmail ?? '', // auto-fill
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: l10n.fieldRequired),
                    FormBuilderValidators.email(errorText: l10n.invalidEmail),
                  ]),
                ),
                const SizedBox(height: 20),

                // Password with eye button
                FormBuilderTextField(
                  name: 'password',
                  initialValue: _savedPassword ?? '', // auto-fill
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: FormBuilderValidators.required(errorText: l10n.fieldRequired),
                ),
                const SizedBox(height: 16),

                // Remember Me
                FormBuilderCheckbox(
                  name: 'remember_me',
                  initialValue: _rememberMe,
                  title: const Text("Remember Me"),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),

                const SizedBox(height: 32),

                // Login Button
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final isLoading = authState.when(
                      loading: () => true,
                      authenticated: (_) => false,
                      unauthenticated: () => false,
                      error: (_) => false,
                    );

                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                        if (formKey.currentState?.saveAndValidate() ?? false) {
                          final credentials = formKey.currentState!.value;

                          final email = credentials['email'];
                          final password = credentials['password'];
                          final rememberMe = credentials['remember_me'] ?? false;

                          await _saveCredentials(email, password, rememberMe);

                          ref.read(authProvider.notifier).login(
                            email,
                            password,
                          );
                        }
                      },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.login),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Register
                TextButton(
                  onPressed: () => AppRouter.to(const RegisterScreen()),
                  child: Text(
                    l10n.register,
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
