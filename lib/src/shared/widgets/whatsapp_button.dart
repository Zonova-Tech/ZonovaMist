import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // 1. Setup the phone number and message
        // Use international format without '+' (e.g., 94 for Sri Lanka)
        String phoneNumber = '94771234567';
        String message = "Hello! I'm interested in your services.";

        // 2. Create the URL
        final Uri whatsappUrl = Uri.parse(
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
        );

        // 3. Launch the URL
        try {
          if (await canLaunchUrl(whatsappUrl)) {
            await launchUrl(
              whatsappUrl,
              mode: LaunchMode.externalApplication, // IMPORTANT: Opens in WhatsApp app
            );
          } else {
            // Fallback: If WhatsApp is not installed, this might open the browser
            // or you can show a SnackBar here telling the user to install WhatsApp.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open WhatsApp.')),
            );
          }
        } catch (e) {
          print('Error launching WhatsApp: $e');
        }
      },
      // Button Styling
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // Official WhatsApp Green
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.chat),
      label: const Text(
        'Chat with WhatsApp',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}