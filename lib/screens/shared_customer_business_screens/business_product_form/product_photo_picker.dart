import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:food_app/models/image_model.dart';
import 'package:design_system/design_system.dart';

/// Opens the shared camera/gallery (and optional "remove photo") bottom
/// sheet used by every photo picker in the business "create/edit listing"
/// forms. The remove option only appears when both [removeLabel] and
/// [onRemove] are provided.
Future<ImageSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String cameraLabel,
  required String galleryLabel,
  String? removeLabel,
  VoidCallback? onRemove,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(cameraLabel),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(galleryLabel),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          if (removeLabel != null && onRemove != null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              title: Text(
                removeLabel,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                onRemove();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Single local-file photo picker for a "create" form, before the listing
/// exists on the backend — the picked file is uploaded later, once the
/// listing has an id. Used by both Food's and Cosmetic's create screens.
class SinglePendingPhotoPicker extends StatelessWidget {
  const SinglePendingPhotoPicker({
    super.key,
    required this.pendingImage,
    required this.onTap,
    this.addPhotoLabel,
  });

  final XFile? pendingImage;
  final VoidCallback onTap;
  final String? addPhotoLabel;

  @override
  Widget build(BuildContext context) {
    final image = pendingImage;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: image != null ? AppColors.successDark : AppColors.gray300,
            width: image != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(image.path), fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.gray400,
                    size: 36,
                  ),
                  if (addPhotoLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      addPhotoLabel!,
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Horizontal strip of already-uploaded photos (with per-item delete) plus
/// an "add" card — used by an "edit an existing listing" form, where every
/// add/delete hits the backend immediately rather than waiting for a
/// screen-level "Save".
class PersistedPhotoGallery extends StatelessWidget {
  const PersistedPhotoGallery({
    super.key,
    required this.images,
    required this.isUploading,
    required this.isDeleting,
    required this.onAddTap,
    required this.onDelete,
    this.addPhotoLabel,
  });

  final List<ImageModel> images;
  final bool isUploading;
  final bool isDeleting;
  final VoidCallback? onAddTap;
  final void Function(ImageModel)? onDelete;
  final String? addPhotoLabel;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final image in images)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: image.url,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => _placeholder(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onDelete != null ? () => onDelete!(image) : null,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: isDeleting
                            ? const Padding(
                                padding: EdgeInsets.all(4),
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gray300,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.gray400,
                          size: 28,
                        ),
                        const SizedBox(height: 5),
                        if (addPhotoLabel != null)
                          Text(
                            addPhotoLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: _size,
    height: _size,
    color: AppColors.gray100,
    child: const Icon(
      Icons.broken_image_outlined,
      color: AppColors.gray400,
      size: 28,
    ),
  );
}
