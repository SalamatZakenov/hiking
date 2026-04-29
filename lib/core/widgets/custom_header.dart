// lib/core/widgets/custom_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const CustomHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // Фиксируем высоту внутреннего контента шапки
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_hdr_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22, // Единый шрифт для всех экранов
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5
                ),
              ),
            ],
          ),
          if (actions != null)
            Row(
              children: actions!.map((widget) => Padding(padding: const EdgeInsets.only(left: 10), child: widget)).toList(),
            )
        ],
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlassButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44, // Одинаковый размер кнопок для всех экранов
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}