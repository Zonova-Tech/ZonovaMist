import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WhatsAppButton extends StatelessWidget {
  final String phoneNumber;
  final String message;

  // We require the phoneNumber to be passed in when this button is created
  const WhatsAppButton({
    super.key,
    required this.phoneNumber,
    this.message = "Hello! I have a query regarding my booking.",
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (phoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No phone number available.')),
          );
          return;
        }

        // 1. Clean the number (remove generic characters)
        // Ensure your DB provides the country code (e.g. 94...)
        String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

        // 2. Create the URL
        final Uri whatsappUrl = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );

        // 3. Launch
        try {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('Error launching WhatsApp: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open WhatsApp.')),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        elevation: 8, 
        shadowColor: Colors.black45,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(0), 
        ),
    ),
        minimumSize: Size.zero, 
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const FaIcon(
        FontAwesomeIcons.whatsapp, 
        size: 22, // 22-24 is a good balance for buttons
      ),
      
      label: const Text('Reach Us!'),
    );
  }
}