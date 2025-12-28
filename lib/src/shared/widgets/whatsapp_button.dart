import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WhatsAppButton extends StatelessWidget {
  final String phoneNumber;
  final String message;

  const WhatsAppButton({
    super.key,
    required this.phoneNumber,
    this.message = "Hello! I have a query regarding my booking.",
  });

  @override
  Widget build(BuildContext context) {
    // 1. Use standard ElevatedButton (not .icon)
    return ElevatedButton(
      onPressed: () async {
        if (phoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No phone number available.')),
          );
          return;
        }

        // number sanitisation
        String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

        if (cleanNumber.length >= 9) {
          cleanNumber = '94${cleanNumber.substring(cleanNumber.length - 9)}';
        }

        final Uri whatsappUrl = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );

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
        
        // 2. This forces the button into a perfect circle
        shape: const CircleBorder(), 
        
        // 3. Adjust padding to increase/decrease the circle size
        padding: const EdgeInsets.all(15), 
        minimumSize: Size.zero, 
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      
      // 4. Place the Icon directly as the child
      child: const FaIcon(
        FontAwesomeIcons.whatsapp, 
        size: 20, // Increased size slightly for better visibility
      ),
    );
  }
}

