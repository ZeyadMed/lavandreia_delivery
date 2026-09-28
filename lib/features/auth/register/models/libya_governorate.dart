/// الشعبيات الليبية اللي بتظهر في دروب داون المحافظة في التسجيل
class LibyaGovernorate {
  final String id;
  final String nameAr;
  final String nameEn;

  const LibyaGovernorate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  static const List<LibyaGovernorate> all = [
    LibyaGovernorate(id: 'tripoli', nameAr: 'طرابلس', nameEn: 'Tripoli'),
    LibyaGovernorate(id: 'benghazi', nameAr: 'بنغازي', nameEn: 'Benghazi'),
    LibyaGovernorate(id: 'misrata', nameAr: 'مصراتة', nameEn: 'Misrata'),
    LibyaGovernorate(id: 'zawiya', nameAr: 'الزاوية', nameEn: 'Zawiya'),
    LibyaGovernorate(id: 'jafara', nameAr: 'الجفارة', nameEn: 'Jafara'),
    LibyaGovernorate(id: 'murqub', nameAr: 'المرقب', nameEn: 'Murqub'),
    LibyaGovernorate(
      id: 'nuqat_al_khams',
      nameAr: 'النقاط الخمس',
      nameEn: 'Nuqat al Khams',
    ),
    LibyaGovernorate(
      id: 'jabal_al_gharbi',
      nameAr: 'الجبل الغربي',
      nameEn: 'Jabal al Gharbi',
    ),
    LibyaGovernorate(id: 'nalut', nameAr: 'نالوت', nameEn: 'Nalut'),
    LibyaGovernorate(id: 'sirte', nameAr: 'سرت', nameEn: 'Sirte'),
    LibyaGovernorate(id: 'jufra', nameAr: 'الجفرة', nameEn: 'Jufra'),
    LibyaGovernorate(id: 'marj', nameAr: 'المرج', nameEn: 'Marj'),
    LibyaGovernorate(
      id: 'jabal_al_akhdar',
      nameAr: 'الجبل الأخضر',
      nameEn: 'Jabal al Akhdar',
    ),
    LibyaGovernorate(id: 'derna', nameAr: 'درنة', nameEn: 'Derna'),
    LibyaGovernorate(id: 'butnan', nameAr: 'البطنان', nameEn: 'Butnan'),
    LibyaGovernorate(id: 'al_wahat', nameAr: 'الواحات', nameEn: 'Al Wahat'),
    LibyaGovernorate(id: 'kufra', nameAr: 'الكفرة', nameEn: 'Kufra'),
    LibyaGovernorate(id: 'sabha', nameAr: 'سبها', nameEn: 'Sabha'),
    LibyaGovernorate(
      id: 'wadi_al_shatii',
      nameAr: 'وادي الشاطئ',
      nameEn: 'Wadi al Shatii',
    ),
    LibyaGovernorate(
      id: 'wadi_al_hayaa',
      nameAr: 'وادي الحياة',
      nameEn: 'Wadi al Hayaa',
    ),
    LibyaGovernorate(id: 'murzuq', nameAr: 'مرزق', nameEn: 'Murzuq'),
    LibyaGovernorate(id: 'ghat', nameAr: 'غات', nameEn: 'Ghat'),
  ];
}
