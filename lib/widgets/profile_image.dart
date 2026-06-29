import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';

class ProfileImage extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;
  final bool isCircle;

  const ProfileImage({
    super.key,
    required this.url,
    this.name,
    this.size = 80,
    this.borderRadius = 20,
    this.placeholderIcon = LucideIcons.user,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircle ? size / 2 : borderRadius;
    
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: (name != null && name!.isNotEmpty)
            ? Text(
                name![0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.4,
                  color: AppColors.grey300,
                ),
              )
            : Icon(placeholderIcon, color: AppColors.grey300, size: size * 0.4),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    ImageProvider? imageProvider;
    String finalUrl = url!;
    
    // Handle Supabase storage paths (e.g., 'profiles/UID/pfp.jpg')
    if (!finalUrl.startsWith('http') && !finalUrl.startsWith('/') && !finalUrl.startsWith('assets/')) {
      // It's likely a Supabase path. Convert to public URL.
      finalUrl = 'https://qqvzklonfybticckpuvx.supabase.co/storage/v1/object/public/user_assets/$finalUrl';
    }

    if (finalUrl.startsWith('http')) {
      imageProvider = NetworkImage(finalUrl);
    } else if (finalUrl.startsWith('file://') || finalUrl.startsWith('/data/')) {
      // Local file path
      final cleanPath = finalUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      imageProvider = FileImage(file);
    } else {
      final file = File(finalUrl);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    if (imageProvider == null) return placeholder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: Border.all(color: AppColors.grey100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: Image(
          image: imageProvider,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CupertinoActivityIndicator(radius: 10),
            );
          },
        ),
      ),
    );
  }
}
