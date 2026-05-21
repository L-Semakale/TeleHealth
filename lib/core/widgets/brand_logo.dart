import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.title = 'Telemedicine Platform',
    this.subtitle,
    this.compact = false,
    this.lightMode = false,
  });

  final double size;
  final bool showText;
  final String title;
  final String? subtitle;
  final bool compact;
  final bool lightMode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedWidth = constraints.hasBoundedWidth;
        final textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: lightMode ? Colors.white : null,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: lightMode ? Colors.white70 : Colors.black54,
                ),
              ),
          ],
        );
        return Row(
          mainAxisSize: compact || !boundedWidth ? MainAxisSize.min : MainAxisSize.max,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 12),
              if (boundedWidth && !compact)
                Expanded(child: textContent)
              else
                Flexible(fit: FlexFit.loose, child: textContent),
            ],
          ],
        );
      },
    );
  }
}
