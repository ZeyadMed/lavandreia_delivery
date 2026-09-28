import 'dart:io';

enum DocumentStatus {
  verified('doc_status_verified'),
  pending('doc_status_pending'),
  rejected('doc_status_rejected');

  /// مفتاح الترجمة اللي بيتعرض في البادج
  final String labelKey;
  const DocumentStatus(this.labelKey);
}

/// صورة واحدة من صور المستند (زي الوجه الأمامي أو الخلفي)
class DocumentImage {
  final String labelKey;

  /// الصورة المحلية لو المندوب رفع واحدة جديدة
  final File? file;

  // TODO: هيتضاف رابط الصورة اللي على السيرفر لما الـ API يجهز
  const DocumentImage({required this.labelKey, this.file});

  DocumentImage withFile(File file) =>
      DocumentImage(labelKey: labelKey, file: file);
}

/// مستند من اللي المندوب رفعها في التسجيل: بياناته وصوره وحالة المراجعة
class DriverDocumentModel {
  final String titleKey;
  final DocumentStatus status;

  /// سطور البيانات: مفتاح ترجمة العنوان + القيمة
  final List<({String labelKey, String value})> fields;
  final List<DocumentImage> images;

  const DriverDocumentModel({
    required this.titleKey,
    required this.status,
    this.fields = const [],
    required this.images,
  });

  /// بتبدّل صورة وبترجّع المستند قيد المراجعة لأن الأدمن لازم يراجعها تاني
  DriverDocumentModel replaceImage(int index, File file) {
    return DriverDocumentModel(
      titleKey: titleKey,
      status: DocumentStatus.pending,
      fields: fields,
      images: [
        for (int i = 0; i < images.length; i++)
          i == index ? images[i].withFile(file) : images[i],
      ],
    );
  }
}
