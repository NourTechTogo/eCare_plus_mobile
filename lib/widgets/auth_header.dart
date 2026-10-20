import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'page_header.dart';

/// En-tête signature d'eCare+ : dégradé profond, bord en vague et
/// un battement de cœur (ECG) qui se dessine à l'ouverture de la page.
class AuthHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final double height;
  final bool showBack;
  final bool showEcg;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 300,
    this.showBack = false,
    this.showEcg = true,
  });

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.showEcg) _pulse.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const deep = AppColors.primaryDeep;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          constraints: BoxConstraints(minHeight: widget.height),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deep, AppColors.primary, AppColors.primaryAccent],
              stops: const [0, .55, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -50,
                child: _Orb(size: 220, alpha: 22),
              ),
              Positioned(top: 90, left: -80, child: _Orb(size: 170, alpha: 14)),
              if (widget.showEcg)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => CustomPaint(
                      painter: _EcgPainter(
                        Curves.easeInOut.transform(_pulse.value),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                bottom: false,
                child: Padding(
                  // Leave room for the wave and the overlapping form card.
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 64),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.showBack) ...[
                            PageBackButton(
                              color: Colors.white,
                              backgroundColor: Colors.white.withAlpha(45),
                            ),
                            const SizedBox(width: 12),
                          ],
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _LogoMark(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      PageHeader(
                        title: widget.title,
                        subtitle: widget.subtitle,
                        showBack: false,
                        titleColor: Colors.white,
                        subtitleColor: Colors.white.withAlpha(215),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final int alpha;
  const _Orb({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withAlpha(alpha),
    ),
  );
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/branding/launcher_foreground.png',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'eCare+',
          style: AppTextStyles.heading1.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 44)
    ..quadraticBezierTo(s.width * .25, s.height, s.width * .55, s.height - 30)
    ..quadraticBezierTo(s.width * .82, s.height - 58, s.width, s.height - 26)
    ..lineTo(s.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _EcgPainter extends CustomPainter {
  final double t;
  _EcgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final baseY = size.height - 92;
    final p = Path()
      ..moveTo(0, baseY)
      ..lineTo(w * .30, baseY)
      ..lineTo(w * .36, baseY - 8)
      ..lineTo(w * .41, baseY)
      ..lineTo(w * .46, baseY + 10)
      ..lineTo(w * .52, baseY - 46)
      ..lineTo(w * .58, baseY + 22)
      ..lineTo(w * .63, baseY)
      ..lineTo(w * .70, baseY - 12)
      ..lineTo(w * .76, baseY)
      ..lineTo(w, baseY);

    final line = Paint()
      ..color = Colors.white.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final PathMetric m = p.computeMetrics().first;
    final len = m.length * t;
    canvas.drawPath(m.extractPath(0, len), line);

    if (t < 1) {
      final tip = m.getTangentForOffset(len)?.position;
      if (tip != null) {
        canvas.drawCircle(tip, 7, Paint()..color = Colors.white.withAlpha(60));
        canvas.drawCircle(tip, 3.5, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.t != t;
}
