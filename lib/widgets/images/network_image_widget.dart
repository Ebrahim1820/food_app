import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final double borderRadius;
  final BoxFit fit;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width,
        color: AppColors.primaryLight,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: fit,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.error,
                ),
              ),
      ),
    );
  }
}
