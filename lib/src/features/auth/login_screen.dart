import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:map_market/src/core/auth/auth_provider.dart';
import 'package:map_market/src/core/auth/auth_state.dart';
import 'package:map_market/src/features/auth/register_screen.dart';
import 'package:map_market/src/core/routing/app_router.dart';

import '../../core/i18n/arb/app_localizations.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormBuilderState>();
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
                Icon(Icons.shopping_cart_checkout,
                    size: 80, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  'MapMarket',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 48),
                FormBuilderTextField(
                  name: 'email',
                  initialValue: 'shan21@gmail.com', //for testing purposes
                  decoration: InputDecoration(labelText: l10n.email, hintText: l10n.emailHint),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: l10n.fieldRequired),
                    FormBuilderValidators.email(errorText: l10n.invalidEmail),
                  ]),
                ),
                const SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'password',
                  initialValue: '123456', //for testing purposes
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password, hintText: l10n.passwordHint),
                  validator: FormBuilderValidators.required(errorText: l10n.fieldRequired),
                ),
                const SizedBox(height: 32),
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final isLoading = authState.when(loading: () => true, authenticated: (_) => false, unauthenticated: () => false, error: (_) => false,);

                    return ElevatedButton(
                      onPressed: isLoading ? null : () {
                        if (formKey.currentState?.saveAndValidate() ?? false) {
                          final credentials = formKey.currentState!.value;
                          ref.read(authProvider.notifier).login(
                            credentials['email'],
                            credentials['password'],
                          );
                        }
                      },
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.login),
                    );
                  },
                ),
                const SizedBox(height: 24),
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