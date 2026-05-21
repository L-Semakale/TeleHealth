import 'package:flutter/material.dart';

const LinearGradient kBrandGradient = LinearGradient(
  colors: [
    Color(0xFFD6246F),
    Color(0xFF8C3B95),
    Color(0xFF5B4AA0),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

AppBar buildBrandAppBar(String title) {
  return AppBar(
    title: Text(title),
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
    elevation: 0,
    flexibleSpace: Container(decoration: const BoxDecoration(gradient: kBrandGradient)),
  );
}

class BrandGradientCard extends StatelessWidget {
  const BrandGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
