import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/center_info.dart';
import '../../core/utils/reminder_helper.dart';

/// Signature green WhatsApp button with crisp custom speech-bubble + phone glyph.
class WhatsAppBadgeButton extends StatelessWidget {
  const WhatsAppBadgeButton({
    super.key,
    required this.onPressed,
    this.label = 'WhatsApp',
    this.compact = true,
  });

  final VoidCallback onPressed;
  final String label;
  final bool compact;

  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDeep = Color(0xFF128C7E);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'WhatsApp ${CenterInfo.primaryPhone}',
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: whatsappGreen,
          foregroundColor: Colors.white,
          visualDensity: compact ? VisualDensity.compact : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        icon: CustomPaint(
          size: Size(compact ? 16 : 18, compact ? 16 : 18),
          painter: const _WhatsAppIconPainter(),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13.5,
          ),
        ),
      ),
    );
  }
}

class _WhatsAppIconPainter extends CustomPainter {
  const _WhatsAppIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer chat bubble circle + bottom-left tail
    final center = Offset(w * 0.52, h * 0.48);
    final radius = w * 0.42;
    final bubblePath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        2.35,
        5.55,
      )
      ..lineTo(w * 0.12, h * 0.88)
      ..close();
    canvas.drawPath(bubblePath, stroke);

    // Classic handset curve inside bubble
    final phonePath = Path()
      ..moveTo(w * 0.37, h * 0.34)
      ..quadraticBezierTo(w * 0.34, h * 0.50, w * 0.46, h * 0.60)
      ..quadraticBezierTo(w * 0.58, h * 0.68, w * 0.68, h * 0.60)
      ..lineTo(w * 0.63, h * 0.53)
      ..lineTo(w * 0.57, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.53, w * 0.44, h * 0.44)
      ..lineTo(w * 0.47, h * 0.38)
      ..close();
    canvas.drawPath(phonePath, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clickable phone chip launching native phone dialer (`tel:`).
class PhoneCallBadgeButton extends StatelessWidget {
  const PhoneCallBadgeButton({
    super.key,
    required this.phoneDisplay,
    required this.phoneTel,
    this.compact = true,
  });

  final String phoneDisplay;
  final String phoneTel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      onPressed: () => ReminderHelper.openPhoneDialer(context, phoneTel),
      icon: Icon(
        CupertinoIcons.phone_fill,
        size: compact ? 14 : 16,
        color: WhatsAppBadgeButton.whatsappDeep,
      ),
      label: Text(
        phoneDisplay,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}

/// Clickable 2GIS route button opening Bishkek building map & directions.
class TwoGisRouteButton extends StatelessWidget {
  const TwoGisRouteButton({
    super.key,
    this.label = '2GIS Route',
    this.compact = true,
  });

  final String label;
  final bool compact;

  static const Color twoGisGreen = Color(0xFF1FA83D);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open 2GIS map & route to Ogonbaeva 222',
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: twoGisGreen,
          foregroundColor: Colors.white,
          visualDensity: compact ? VisualDensity.compact : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 15,
            vertical: compact ? 8 : 11,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: () => ReminderHelper.openExternalUrl(
          context,
          CenterInfo.twoGisUrl,
          copiedNotice: '2GIS link copied to clipboard',
        ),
        icon: Icon(CupertinoIcons.map_pin_ellipse, size: compact ? 14 : 16),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}
