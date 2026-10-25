import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_session.dart';
import '../views/auth/login_page.dart';
import '../views/profile/profile_page.dart';
import '../views/profile/reference_page.dart';
import 'care_page.dart';
import 'legal_consent.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});
  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _loaded = false, _accepted = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      await context.read<ApiSession>().refreshProfile();
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _consent() async {
    setState(() => _busy = true);
    try {
      await context.read<ApiSession>().consent();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ApiSession>();
    if (!session.authenticated) return const LoginPage();
    if (!_loaded) {
      return CarePage(
        title: 'Mon dossier',
        subtitle: null,
        child: Column(
          children: [
            if (_error != null) Text(_error!),
            if (_error == null) const CircularProgressIndicator(),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
            TextButton(
              onPressed: session.logout,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
    }
    if (widget.child is ReferencePage) return widget.child;
    if (session.profile?['consentementAccepte'] != true) {
      return CarePage(
        title: 'Votre consentement',
        subtitle: 'Lisez les deux documents jusqu’à la fin.',
        child: Column(
          children: [
            LegalConsent(
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ReferencePage()),
              ),
              child: const Text('Mon code de référencement'),
            ),
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _accepted && !_busy ? _consent : null,
              child: const Text(
                'Accepter le traitement de mes données de santé',
              ),
            ),
            TextButton(
              onPressed: session.logout,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
    }
    if (widget.child is! ProfilePage &&
        (session.profile?['dossierId'] == null ||
            session.profile?['professionnelId'] == null)) {
      return CarePage(
        title: 'Rattachement en attente',
        subtitle: 'Votre compte est créé.',
        child: Column(
          children: [
            const DossierStatus(),
            TextButton(
              onPressed: _load,
              child: const Text('Actualiser mon dossier'),
            ),
            TextButton(
              onPressed: session.logout,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
    }
    return widget.child;
  }
}

class DossierStatus extends StatelessWidget {
  const DossierStatus({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ApiSession>().profile;
    if (p?['dossierId'] != null && p?['professionnelId'] != null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Votre rattachement à un dossier actif et à un professionnel est en attente. Contactez votre établissement. Les fonctions cliniques restent soumises à cette affectation.',
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ReferencePage()),
              ),
              child: const Text('Présenter mon code de référencement'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              ),
              child: const Text('Compléter mon profil'),
            ),
          ],
        ),
      ),
    );
  }
}
