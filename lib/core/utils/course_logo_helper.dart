import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps golf course names to their corresponding logo image asset paths.
class CourseLogoHelper {
  CourseLogoHelper._();

  static const Map<String, String> _logoMap = {
    'royal nairobi': 'royal golf club.jpeg',
    'karen country': 'Karen country club.jpeg',
    'muthaiga': 'muthaiga golf club.jpeg',
    'windsor': 'Windsor.jpeg',
    'sigona': 'sigona golf club.jpeg',
    'vet lab': 'vet lab.jpeg',
    'thika greens': 'Thika greens.jpeg',
    'limuru': 'Limuru country club.jpeg',
    'nyali': 'nyali golf.jpeg',
    'mombasa golf': 'mombasa golf club.jpeg',
    'vipingo': 'vipingo ridge.jpeg',
    'eldoret': 'Eldoret club.jpeg',
    'nyanza': 'Nyanza club.jpeg',
    'nandi bears': 'nandi bears.jpeg',
    'machakos': 'machakos golf club.jpeg',
    'ruiru': 'ruiru sportd club.jpeg',
    'kenya railways': 'kenya railways golf club.jpeg',
  };

  static String? getLogoAssetPath(String courseName) {
    final lower = courseName.toLowerCase();
    for (final entry in _logoMap.entries) {
      if (lower.contains(entry.key)) {
        return 'assets/images/${entry.value}';
      }
    }
    return null;
  }

  static Widget getLogo(String courseName, {double size = 40}) {
    final assetPath = getLogoAssetPath(courseName);
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.asset(assetPath, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Icon(LucideIcons.map, size: size * 0.6, color: Colors.grey[300]);
  }

  static bool hasLogo(String courseName) => getLogoAssetPath(courseName) != null;
}
