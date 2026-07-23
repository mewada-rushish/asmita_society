import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback onReply;
  final VoidCallback onStar;
  final VoidCallback onPin;

  const ContactMessageBubble({
    super.key,
    required this.message,
    required this.onReply,
    required this.onStar,
    required this.onPin,
  });

  Future<void> _launchPhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse the contact from content (Format: "Name|Phone")
    final parts = message.content.split('|');
    final name = parts.isNotEmpty ? parts[0] : 'Unknown';
    final phone = parts.length > 1 ? parts[1] : '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: message.isMe 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                radius: 20,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    color: message.isMe ? Colors.white : AsmitaPalette.deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: message.isMe ? Colors.white : AsmitaPalette.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      phone,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: message.isMe ? Colors.white70 : AsmitaPalette.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchPhoneCall(phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: message.isMe ? Colors.white : AsmitaPalette.deepNavy,
                foregroundColor: message.isMe ? AsmitaPalette.deepNavy : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: const Text('Call Contact', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
