import 'package:flutter/material.dart';
import '../data/doctor_catalog.dart';
import '../utils/app_colors.dart';
import '../views/messaging/doctor_chat_page.dart';
import '../views/messaging/server_chat_page.dart';
import '../services/api_session.dart';
import 'package:provider/provider.dart';

class DoctorMessageButton extends StatelessWidget {
  final CareDoctor doctor;
  const DoctorMessageButton({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Message à ${doctor.name}',
    style: IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      backgroundColor: AppColors.primaryLighter,
      foregroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: () async {
      if (doctor.serverId == null) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DoctorChatPage(doctor: doctor),
          ),
        );
        return;
      }
      final api = context.read<ApiSession>();
      final generation = api.generation;
      try {
        final row = await api.request(
          'POST',
          '/mobile/conversations',
          body: {'professionnelId': doctor.serverId},
        );
        if (!context.mounted || generation != api.generation) return;
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ServerChatPage(
              conversationId: '${row['id']}',
              doctorName: doctor.name,
              doctor: doctor,
            ),
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    },
    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 23),
  );
}
