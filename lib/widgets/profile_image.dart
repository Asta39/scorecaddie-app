import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_theme.dart';

class ProfileImage extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const ProfileImage({
    super.key,
    required this.url,
    this.size = 80,
    this.borderRadius = 20,
    this.placeholderIcon = LucideIcons.user,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(placeholderIcon, color: AppColors.grey300, size: size * 0.4),
    );

    if (url == null || url!.isEmpty) return placeholder;

    ImageProvider? imageProvider;
    if (url!.startsWith('http')) {
      imageProvider = NetworkImage(url!);
    } else {
      final file = File(url!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    if (imageProvider == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: const Center(
              child: CupertinoActivityIndicator(radius: 10),
            ),
          );
        },
      ),
    );
  }
}
