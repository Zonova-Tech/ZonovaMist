import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/api/api_service.dart';

/// Public contact form. Submits an inquiry to the backend, which relays it to
/// the business WhatsApp line via the OpenWA gateway. The WhatsApp API call
/// happens server-side only — this screen never touches the gateway or its
/// secrets; it only POSTs to /api/contact.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Business WhatsApp line (fallback link if delivery fails).
  static const String _whatsappNumber = '94710433228';

  bool _sending = false;
  String? _errorMessage;
  bool _showFallback = false;
  bool _sent = false;

  Future<void> _submit() async {
    // Native field validation first.
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    final values = _formKey.currentState!.value;

    setState(() {
      _sending = true;
      _errorMessage = null;
      _showFallback = false;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/contact',
        data: {
          'name': (values['name'] ?? '').toString().trim(),
          'email': (values['email'] ?? '').toString().trim(),
          'phone': (values['phone'] ?? '').toString().trim(),
          'message': (values['message'] ?? '').toString().trim(),
          // Honeypot: always false for real users; the server drops truthy.
          'botcheck': false,
        },
        options: Options(
          // Accept 4xx/5xx so we can read {ok:false, error} without throwing.
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final body = response.data is Map ? response.data as Map : const {};
      final ok = body['ok'] == true;

      if (ok) {
        _formKey.currentState?.reset();
        setState(() {
          _sent = true;
          _sending = false;
        });
      } else {
        setState(() {
          _sending = false;
          _errorMessage = (body['error'] ??
                  'Could not deliver your message. Please try WhatsApp instead.')
              .toString();
          // Offer the WhatsApp fallback whenever delivery failed server-side.
          _showFallback = response.statusCode == 502 ||
              (response.statusCode ?? 0) >= 500;
        });
      }
    } catch (e) {
      setState(() {
        _sending = false;
        _errorMessage =
            'Could not reach the server. Please try WhatsApp instead.';
        _showFallback = true;
      });
    }
  }

  Future<void> _openWhatsAppFallback() async {
    const greeting =
        "Hello Zonova Mist! I'd like to make an inquiry.";
    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(greeting)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _sent ? _buildSuccess(theme) : _buildForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.check_circle_rounded,
            size: 64, color: theme.colorScheme.secondary),
        const SizedBox(height: 16),
        Text(
          "✅ Message sent! We'll get back to you within one business day.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Send another message'),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Get in touch',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Send us an inquiry and we’ll reply on WhatsApp.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Name (required)
          FormBuilderTextField(
            name: 'name',
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Your full name',
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Please enter your name.'),
              FormBuilderValidators.minLength(2,
                  errorText: 'Please enter your name.'),
              FormBuilderValidators.maxLength(200,
                  errorText: 'Name is too long.'),
            ]),
          ),
          const SizedBox(height: 18),

          // Email (required)
          FormBuilderTextField(
            name: 'email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'Please enter a valid email address.'),
              FormBuilderValidators.email(
                  errorText: 'Please enter a valid email address.'),
              FormBuilderValidators.maxLength(200,
                  errorText: 'Email is too long.'),
            ]),
          ),
          const SizedBox(height: 18),

          // Phone (optional)
          FormBuilderTextField(
            name: 'phone',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              hintText: '+94 7X XXX XXXX',
            ),
            validator: FormBuilderValidators.maxLength(50,
                errorText: 'Phone is too long.'),
          ),
          const SizedBox(height: 18),

          // Message (required)
          FormBuilderTextField(
            name: 'message',
            minLines: 4,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Tell us a bit about your inquiry…',
              alignLabelWithHint: true,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'Please tell us a bit more about your project.'),
              FormBuilderValidators.minLength(10,
                  errorText: 'Please tell us a bit more about your project.'),
              FormBuilderValidators.maxLength(3000,
                  errorText: 'Message is too long.'),
            ]),
          ),

          // Honeypot — kept off-screen and out of the tab order. Bots that fill
          // every field will set this; real users never see it.
          Offstage(
            offstage: true,
            child: FormBuilderField<bool>(
              name: 'botcheck',
              initialValue: false,
              builder: (field) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Sending…'),
                    ],
                  )
                : Text(_errorMessage == null ? 'Send' : 'Try again'),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.red.shade900),
                  ),
                  if (_showFallback) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _openWhatsAppFallback,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.whatsapp,
                              size: 18, color: Color(0xFF25D366)),
                          const SizedBox(width: 8),
                          Text(
                            'Open WhatsApp instead →',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF128C7E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
