import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/core/routing/app_router.dart';

import '../../core/i18n/arb/app_localizations.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormBuilderState>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 48),
                FormBuilderTextField(
                  name: 'fullName',
                  decoration: InputDecoration(labelText: l10n.fullName, hintText: l10n.fullNameHint),
                  validator: FormBuilderValidators.required(errorText: l10n.fieldRequired),
                ),
                const SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(labelText: l10n.email, hintText: l10n.emailHint),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: l10n.fieldRequired),
                    FormBuilderValidators.email(errorText: l10n.invalidEmail),
                  ]),
                ),
                const SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'password',
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
                      onPressed: isLoading ? null : () async {
                        if (formKey.currentState?.saveAndValidate() ?? false) {
                          final fields = formKey.currentState!.value;
                          final result = await ref.read(authProvider.notifier).register(
                            fullName: fields['fullName'],
                            email: fields['email'],
                            password: fields['password'],
                          );

                          if (result == 'Success' && context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(l10n.registrationSuccess), backgroundColor: Colors.green,));
                            AppRouter.back();
                          } else {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(result)));
                          }
                        }
                      },
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.register),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}