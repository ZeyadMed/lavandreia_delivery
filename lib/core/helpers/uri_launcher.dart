import 'dart:io';

import 'package:url_launcher/url_launcher.dart' as launcher;

abstract interface class UriLauncher {
  // الـ prefix عشان launchUrl بتاعتنا كانت بتنادي نفسها بدل بتاعة الباكدج
  static Future<void> launchUrl(String url) async {
    await launcher.launchUrl(
      Uri.parse(url),
      mode: launcher.LaunchMode.externalApplication,
    );
  }

  static Future<void> launchWhatsApp(String number) async {
    String url() {
      if (Platform.isIOS) {
        return "https://wa.me/$number";
      } else {
        return "https://api.whatsapp.com/send?phone=$number";
      }
    }

    if (await launcher.canLaunchUrl(Uri.parse(url()))) {
      await launchUrl(url());
    } else {
      throw 'Could not launch whatsapp://send?phone=$number';
    }
  }

  static Future<void> launchPhone(String number) async {
    final url = 'tel:$number';
    if (await launcher.canLaunchUrl(Uri.parse(url))) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchBrowser(String url) async {
    if (await launcher.canLaunchUrl(Uri.parse(url))) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// بيفتح الملاحة للإحداثيات في Google Maps، ولو مش متسطب يجرب Waze،
  /// ولو الاتنين مش موجودين بيفتح لينك جوجل ماب في المتصفح
  static Future<void> launchNavigation(double lat, double lng) async {
    final candidates = [
      Platform.isIOS
          ? 'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'
          : 'google.navigation:q=$lat,$lng&mode=d',
      'waze://?ll=$lat,$lng&navigate=yes',
    ];
    for (final url in candidates) {
      final uri = Uri.parse(url);
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
        return;
      }
    }
    await launchUrl(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
  }
}
