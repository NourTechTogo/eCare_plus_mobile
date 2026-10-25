import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import 'doctor_video_preview.dart';
import 'call_screen_connection.dart';
import 'call_presentation.dart';

class DoctorCallPage extends StatefulWidget {
  final CareDoctor doctor;
  final bool video;
  final CallScreenConnection? connection;
  const DoctorCallPage({
    super.key,
    required this.doctor,
    required this.video,
    this.connection,
  });
  @override
  State<DoctorCallPage> createState() => _DoctorCallPageState();
}

class _DoctorCallPageState extends State<DoctorCallPage> {
  bool muted = false, speaker = false;
  @override
  Widget build(BuildContext context) => widget.video
      ? DoctorVideoPreview(doctor: widget.doctor, connection: widget.connection)
      : CallPresentation(
          doctor: widget.doctor,
          video: false,
          connection: widget.connection,
          muted: muted,
          speaker: speaker,
          onMicrophone: () => setState(() => muted = !muted),
          onSpeaker: () => setState(() => speaker = !speaker),
          onVideo: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  DoctorCallPage(doctor: widget.doctor, video: true),
            ),
          ),
        );
}
