import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_success_message.dart';
import 'package:lavanderia_delivery/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_document_model.dart';

/// شاشة المستندات: كل المستندات اللي المندوب رفعها في التسجيل وحالة مراجعتها
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // TODO: هتتجاب من الـ API لما يجهز
  List<DriverDocumentModel> _documents = const [
    DriverDocumentModel(
      titleKey: 'driving_license',
      status: DocumentStatus.verified,
      fields: [
        (labelKey: 'issue_date', value: '2023-05-10'),
        (labelKey: 'expiry_date', value: '2028-05-10'),
      ],
      images: [
        DocumentImage(labelKey: 'front_side'),
        DocumentImage(labelKey: 'back_side'),
      ],
    ),
    DriverDocumentModel(
      titleKey: 'national_id_card',
      status: DocumentStatus.verified,
      fields: [(labelKey: 'national_id', value: '29012345678901')],
      images: [
        DocumentImage(labelKey: 'front_side'),
        DocumentImage(labelKey: 'back_side'),
      ],
    ),
    DriverDocumentModel(
      titleKey: 'vehicle_image',
      status: DocumentStatus.pending,
      fields: [(labelKey: 'plate_number', value: 'أ ب ج 123')],
      images: [DocumentImage(labelKey: 'vehicle_image')],
    ),
    DriverDocumentModel(
      titleKey: 'personal_photo',
      status: DocumentStatus.verified,
      images: [DocumentImage(labelKey: 'personal_photo')],
    ),
  ];

  void _pickImage(int documentIndex, int imageIndex) {
    ImagePickerHelper.showImagePicker(context, (file) {
      if (file == null || !mounted) return;
      setState(() {
        _documents = [
          for (int i = 0; i < _documents.length; i++)
            i == documentIndex
                ? _documents[i].replaceImage(imageIndex, file)
                : _documents[i],
        ];
      });
      // TODO: هتترفع للـ API لما يجهز
      CustomSuccessOverlay.show(context: context, text: 'document_uploaded');
    });
  }

  /// لو فيه صورة بنعرضها الأول ومنها يقدر يحدّثها، لو مفيش بنفتح الرفع على طول
  Future<void> _onImageTap(int documentIndex, int imageIndex) async {
    final image = _documents[documentIndex].images[imageIndex];
    if (image.file == null) {
      _pickImage(documentIndex, imageIndex);
      return;
    }
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (_) => _ImagePreviewDialog(file: image.file!),
    );
    if (shouldUpdate == true) _pickImage(documentIndex, imageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const _DocumentsHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
              itemCount: _documents.length,
              separatorBuilder: (_, _) => Gap(16.h),
              itemBuilder: (context, index) => DocumentCard(
                document: _documents[index],
                onImageTap: (imageIndex) => _onImageTap(index, imageIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => context.pop(),
                  child: SizedBox(
                    width: 40.r,
                    height: 40.r,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18.sp,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
              Gap(12.h),
              Text(
                'documents_title'.tr(),
                style: TextStyles.boldStyle(22, color: AppColors.whiteColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// كارت المستند: العنوان والحالة، سطور البيانات، وتحتهم خانات الصور
class DocumentCard extends StatelessWidget {
  final DriverDocumentModel document;
  final ValueChanged<int> onImageTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = document.images;
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  document.titleKey.tr(),
                  style: TextStyles.boldStyle(16, color: AppColors.blackColor),
                ),
              ),
              DocumentStatusBadge(status: document.status),
            ],
          ),
          for (final field in document.fields) ...[
            Gap(12.h),
            Row(
              children: [
                Text(
                  field.labelKey.tr(),
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  field.value,
                  style: TextStyles.boldStyle(14, color: AppColors.blackColor),
                ),
              ],
            ),
          ],
          Gap(16.h),
          // الوجه الأمامي والخلفي جنب بعض، والصورة الواحدة بتاخد العرض كله
          Row(
            children: [
              for (int i = 0; i < images.length; i++) ...[
                if (i > 0) Gap(10.w),
                Expanded(
                  child: _DocumentImageBox(
                    image: images[i],
                    showLabel: images.length > 1,
                    onTap: () => onImageTap(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DocumentStatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const DocumentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      DocumentStatus.verified => (HomeColors.lightGreen, HomeColors.green),
      DocumentStatus.pending => (HomeColors.lightOrange, HomeColors.orange),
      DocumentStatus.rejected => (const Color(0xffFDECEC), HomeColors.red),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status.labelKey.tr(),
        style: TextStyles.boldStyle(12, color: fg),
      ),
    );
  }
}

/// خانة صورة بإطار متقطع: فاضية فيها "عرض / تحديث الصورة" أو فيها الصورة نفسها
class _DocumentImageBox extends StatelessWidget {
  final DocumentImage image;
  final bool showLabel;
  final VoidCallback onTap;

  const _DocumentImageBox({
    required this.image,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 14.r;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.semiWhiteColor2,
          radius: radius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: showLabel ? 90.h : 60.h,
            width: double.infinity,
            child: image.file != null
                ? Image.file(image.file!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showLabel) ...[
                        Text(
                          image.labelKey.tr(),
                          style: TextStyles.boldStyle(
                            13,
                            color: AppColors.greyColor6,
                          ),
                        ),
                        Gap(6.h),
                      ],
                      Text(
                        '📷 ${'view_update_image'.tr()}',
                        textAlign: TextAlign.center,
                        style: TextStyles.boldStyle(
                          12,
                          color: AppColors.greyColor4,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// عرض الصورة كبيرة مع إمكانية الزوم، وزرار لتحديثها
class _ImagePreviewDialog extends StatelessWidget {
  final File file;

  const _ImagePreviewDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      insetPadding: EdgeInsets.all(20.r),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyles.boldStyle(
                        14,
                        color: AppColors.greyColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'update_image'.tr(),
                      style: TextStyles.boldStyle(
                        14,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
