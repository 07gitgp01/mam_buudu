import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LogoWidget({
    super.key,
    this.size = 120.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFffffff),
            const Color(0xFFf0f0f0),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: size * 0.17,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: const Color(0xFF87CEEB).withOpacity(0.3),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.13),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          width: size * 0.8,
          height: size * 0.8,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
