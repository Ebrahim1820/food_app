import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:food_app/services/image_service.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// A self-contained avatar widget that fetches, displays, and optionally
/// uploads an image to the backend.
///
/// Supports both business logos and user avatars:
///   - Business logo: pass [partnerIri], imageType: 'business_logo'
///   - User avatar:   pass [userIri],    imageType: 'avatar'
///
/// When [canUpload] is true, tapping opens the gallery picker and uploads
/// the chosen image. A camera badge is shown over the bottom-right corner.
///
/// Shape is controlled by [borderRadius]:
///   - null   → full circle (borderRadius = size / 2)
///   - value  → rounded rectangle with that radius
class UploadableAvatar extends StatefulWidget {
  const UploadableAvatar({
    super.key,
    required this.initials,
    required this.imageType,
    this.partnerIri,
    this.userIri,
    this.uploadPartnerIri,
    this.iriResolver,
    this.size = 72,
    this.borderRadius,
    this.canUpload = true,
    this.backgroundColor = AppColors.successDark,
    this.initialsColor = AppColors.white,
    this.boxShadow,
    this.onTap,
  });

  final String initials;
  final String imageType;

  /// Used for BOTH fetching and uploading (e.g. business logo).
  final String? partnerIri;
  final String? userIri;

  /// Added to the upload payload only — not used when fetching the image.
  /// Use this to tag an avatar upload with its owner's business partner IRI.
  final String? uploadPartnerIri;

  /// Called at upload time when both [partnerIri] and [userIri] are null.
  /// Async so the resolver can fetch data (e.g. call fetchMyPartner) if the
  /// IRI isn't cached yet. Resolved once per upload tap, not at build time.
  final Future<String?> Function()? iriResolver;

  final double size;

  /// null → full circle; non-null → rounded rectangle with this corner radius.
  final double? borderRadius;
  final bool canUpload;
  final Color backgroundColor;
  final Color initialsColor;
  final List<BoxShadow>? boxShadow;

  /// Overrides the default tap behaviour (full-image preview when an image
  /// is loaded) — e.g. the AppBar's leading avatar uses this to open the
  /// drawer instead, regardless of whether an image has loaded yet.
  final VoidCallback? onTap;

  @override
  State<UploadableAvatar> createState() => _UploadableAvatarState();
}

class _UploadableAvatarState extends State<UploadableAvatar> {
  String? _imageUrl;
  bool _uploading = false;
  final _imageService = Get.find<ImageService>();
  final _picker = ImagePicker();

  static const _tag = 'UploadableAvatar';

  /// The IRI actually backing this avatar's cache key. Usually just mirrors
  /// [widget.partnerIri]/[widget.userIri], but [iriResolver] is an async,
  /// fire-once callback whose result never gets written back into the
  /// widget's own props — without tracking it here separately, the cache key
  /// would stay stuck on 'unknown' for the entire lifetime of a widget built
  /// with no IRI prop (e.g. the customer drawer avatar before
  /// AuthController.userId is populated), even after resolving successfully.
  String? _resolvedIri;

  // Unique storage key per IRI + imageType so different avatars don't collide.
  String get _cacheKey =>
      'avatar_url__${widget.partnerIri ?? widget.userIri ?? _resolvedIri ?? 'unknown'}__${widget.imageType}';

  String? get _cachedUrl => AppStorage.read<String>(_cacheKey);
  void _persistUrl(String url) => AppStorage.write(_cacheKey, url);

  @override
  void initState() {
    super.initState();
    // Show the last known URL immediately (zero network, zero wait).
    final saved = _cachedUrl;
    if (saved != null) _imageUrl = saved;
    _initLoad();
  }

  Future<void> _initLoad() async {
    // The cached URL (if any) was already shown synchronously above, so the
    // UI paints instantly either way — but always revalidate against the
    // network here rather than trusting the cache forever. This used to
    // return early whenever a cached URL existed, which meant a URL once
    // written incorrectly under a given (iri, imageType) key — e.g. by a
    // since-fixed bug, or a stale cross-account write — would keep showing
    // the wrong image on every future mount, in every market, for as long as
    // that cache entry existed, since nothing ever re-checked it against the
    // server.
    if (_isValidIri(widget.partnerIri) || _isValidIri(widget.userIri)) {
      _loadImage();
    } else if (widget.iriResolver != null) {
      final resolvedIri = await widget.iriResolver!();
      if (!mounted || resolvedIri == null) return;
      _resolvedIri = resolvedIri;

      final url = await _imageService.fetchImageUrl(
        userIri: resolvedIri,
        imageType: widget.imageType,
      );
      if (mounted && url != null) {
        _persistUrl(url);
        setState(() => _imageUrl = url);
      }
    }
  }

  @override
  void didUpdateWidget(covariant UploadableAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final iriChanged =
        oldWidget.partnerIri != widget.partnerIri ||
        oldWidget.userIri != widget.userIri;
    if (!iriChanged) return;

    // The real IRI just arrived (or changed) — re-check the cache under the
    // new key before falling back to network. This used to always refetch
    // over the network here, even when a valid cached URL already existed
    // for the resolved IRI: both drawer avatars build with partnerIri/userIri
    // null on the very first frame (identity hasn't resolved yet) and only
    // get the real value a frame later via Obx, which lands here.
    final cached = _cachedUrl;
    if (cached != null) {
      setState(() => _imageUrl = cached);
    } else {
      // No cached URL for the new identity — any image currently shown
      // belongs to the OLD iri (e.g. a stale cached BusinessPartnerController
      // value shown before the real fetch resolved). Clear it before
      // fetching so the previous identity's avatar never lingers on screen;
      // this used to only fire when `_imageUrl == null`, which meant a
      // still-displayed old image was never refetched or replaced.
      setState(() => _imageUrl = null);
      _loadImage();
    }
  }

  double get _effectiveRadius => widget.borderRadius ?? widget.size / 2;

  static bool _isValidIri(String? iri) {
    if (iri == null || iri.isEmpty) return false;
    if (iri.endsWith('/')) return false;
    return iri.contains('/') && iri.split('/').last.isNotEmpty;
  }

  Future<void> _loadImage() async {
    if (!_isValidIri(widget.partnerIri) && !_isValidIri(widget.userIri)) return;
    final url = await _imageService.fetchImageUrl(
      partnerIri: widget.partnerIri,
      userIri: widget.userIri,
      imageType: widget.imageType,
    );
    if (mounted && url != null) {
      _persistUrl(url);
      setState(() => _imageUrl = url);
    }
  }

  Future<ImageSource?> _askImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final partnerIri = widget.partnerIri;
    final resolvedByProp = widget.userIri;
    final resolvedByCallback = widget.iriResolver != null
        ? await widget.iriResolver!()
        : null;
    final userIri = resolvedByProp ?? resolvedByCallback;

    AppLogger.info(
      _tag,
      'tap: partnerIri=$partnerIri '
      'userIri(prop)=$resolvedByProp '
      'userIri(resolver)=$resolvedByCallback '
      'hasResolver=${widget.iriResolver != null} '
      'imageType=${widget.imageType}',
    );

    final hasIri = _isValidIri(partnerIri) || _isValidIri(userIri);
    if (!hasIri) {
      AppSnackbar.error('avatar_notReadyTitle'.tr, 'avatar_notReadyBody'.tr);
      return;
    }

    final source = await _askImageSource();
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
    } catch (e) {
      AppLogger.info(_tag, 'pickImage error: $e');
      picked = null;
    }
    if (picked == null) {
      if (source == ImageSource.camera) {
        AppSnackbar.error(
          'avatar_cameraUnavailableTitle'.tr,
          'avatar_cameraUnavailableBody'.tr,
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final image = await _imageService.uploadImage(
        fileBytes: bytes,
        filename: picked.name,
        imageType: widget.imageType,
        partnerIri: partnerIri ?? widget.uploadPartnerIri,
        userIri: userIri,
      );
      if (mounted) {
        _persistUrl(image.url);
        setState(() => _imageUrl = image.url);
      }
      AppSnackbar.success('common_successTitle'.tr, 'avatar_imageUpdated'.tr);
    } catch (e) {
      AppLogger.info(_tag, 'Upload error: $e');
      AppSnackbar.error('avatar_uploadFailedTitle'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _initialsChild() => Center(
    child: Text(
      widget.initials,
      style: TextStyle(
        color: widget.initialsColor,
        fontSize: widget.size * 0.32,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  void _showFullImage() {
    if (_imageUrl == null) return;
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black87,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              // Background tap → dismiss
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(ctx).pop(),
                child: const SizedBox.expand(),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: _imageUrl!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _uploading
        ? Center(
            child: SizedBox(
              width: widget.size * 0.35,
              height: widget.size * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.initialsColor,
              ),
            ),
          )
        : _imageUrl != null
        ? CachedNetworkImage(
            imageUrl: _imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => _initialsChild(),
            errorWidget: (_, _, err) {
              AppLogger.info(_tag, 'Load error: $err');
              return _initialsChild();
            },
          )
        : _initialsChild();

    final avatar = GestureDetector(
      onTap:
          widget.onTap ??
          ((_imageUrl != null && !_uploading) ? _showFullImage : null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_effectiveRadius),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            boxShadow: widget.boxShadow,
          ),
          child: imageWidget,
        ),
      ),
    );

    if (!widget.canUpload) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _uploading ? null : _pickAndUpload,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
