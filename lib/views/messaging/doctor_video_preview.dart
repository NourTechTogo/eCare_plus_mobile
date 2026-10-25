import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import 'call_screen_connection.dart';
import 'call_presentation.dart';
import 'doctor_chat_page.dart';

class DoctorVideoPreview extends StatefulWidget {
  final CareDoctor doctor;
  final CallScreenConnection? connection;
  const DoctorVideoPreview({super.key, required this.doctor, this.connection});
  @override
  State<DoctorVideoPreview> createState() => _DoctorVideoPreviewState();
}

class _DoctorVideoPreviewState extends State<DoctorVideoPreview> {
  bool muted = false, speaker = false, camera = true, front = true;
  @override
  Widget build(BuildContext context) => CallPresentation(
    doctor: widget.doctor,
    video: true,
    connection: widget.connection,
    muted: muted,
    speaker: speaker,
    camera: camera,
    front: front,
    onMicrophone: () => setState(() => muted = !muted),
    onSpeaker: () => setState(() => speaker = !speaker),
    onCamera: () => setState(() => camera = !camera),
    onFlip: () => setState(() => front = !front),
    onMessages: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DoctorChatPage(doctor: widget.doctor),
      ),
    ),
  );
}
