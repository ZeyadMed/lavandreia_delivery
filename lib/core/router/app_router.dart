import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/router/bottom_nav_app.dart';
import 'package:lavanderia_delivery/features/auth/change_password/presentation/view/change_password_screen.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/presentation/view/forget_password_screen.dart';
import 'package:lavanderia_delivery/features/auth/login/presentation/view/login_screen.dart';
import 'package:lavanderia_delivery/features/auth/otp/models/otp_args.dart';
import 'package:lavanderia_delivery/features/auth/otp/presentation/view/otp_screen.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/account_under_review_screen.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/register_screen.dart';
import 'package:lavanderia_delivery/features/on_boarding/presentation/views/on_boarding_screen.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/contact_us_screen.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/documents_screen.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/earnings_screen.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/edit_profile_screen.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/privacy_policy_screen.dart';
import 'package:lavanderia_delivery/features/splash/presentation/view/splash_screen.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/active_trip_screen.dart';
import 'package:lavanderia_delivery/main.dart';

abstract class AppRouter {
  static const String root = '/';
  static const String webViewContainer = '/webViewContainer';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String accountUnderReview = '/accountUnderReview';
  static const String forgetPassword = '/forgetPassword';
  static const String verifyOtp = '/verifyOtp';
  static const String changePassword = '/changePassword';
  static const String resetPasswordScreen = '/resetPasswordScreen';
  static const String successScreen = '/successScreen';
  // ************* HOME *************
  static const String initialRoot = '/initialRoot';
  static const String homeScreen = '/HomeScreen';
  static const String laundryDetails = '/laundryDetails';
  static const String orderPending = '/orderPending';
  static const String confirmOrder = '/confirmOrder';
  static const String rejectOrder = '/rejectOrder';
  static const String activeTrip = '/activeTrip';

  // ************* PROFILE *************
  static const String orderScreen = '/orderScreen';
  static const String orderDetails = '/orderDetails';
  static const String profileScreen = '/profileScreen';
  static const String contactUsScreen = '/contactUsScreen';
  static const String notificationScreen = '/notificationScreen';
  static const String customerServiceScreen = '/customerServiceScreen';
  static const String aboutUs = '/aboutUs';
  static const String updateProfileScreen = '/updateProfileScreen';
  static const String privacyPolicy = '/privacyPolicy';
  static const String documentsScreen = '/documentsScreen';
  static const String earningsScreen = '/earningsScreen';
  static const String comingSoonScreen = '/CommingSoonScreen';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      // -----------------------------------Splash Screen and OnBoarding--------------------------------
      GoRoute(path: root, builder: (context, state) => const SplashScreen()),
      //  GoRoute(
      //     path: webViewContainer,
      //     builder: (context, state) {
      //       final extra = state.extra;
      //       String url = '';
      //       if (extra is String) {
      //         url = extra;
      //       } else if (extra is Map<String, dynamic>) {
      //         url = (extra['url'] ?? '') as String;
      //       } else if (extra is Map) {
      //         url = (extra['url'] ?? '') as String;
      //       }
      //       return WebViewContainer(
      //         url: url,
      //       );
      //     },
      //   ),
      GoRoute(
        path: initialRoot,
        builder: (context, state) => const BottomNavApp(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // AUTHENTICATION ROUTES
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: signUp,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: accountUnderReview,
        builder: (context, state) => const AccountUnderReviewScreen(),
      ),
      GoRoute(
        path: forgetPassword,
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      // OtpArgs بيتبعت في state.extra جاي من التسجيل أو اللوجين (409)،
      // فيه الرقم اللي بيتبعت مع الكود والـ purpose اللي بيحدد نروح فين بعد التحقق
      GoRoute(
        path: verifyOtp,
        builder: (context, state) {
          final args = state.extra as OtpArgs?;
          return OtpScreen(
            phoneNumber: args?.phoneNumber ?? '',
            purpose: args?.purpose ?? OtpPurpose.register,
          );
        },
      ),
      // الرقم (String) بيتبعت في state.extra جاي من نسيت كلمة المرور
      GoRoute(
        path: changePassword,
        builder: (context, state) =>
            ChangePasswordScreen(phoneNumber: state.extra as String? ?? ''),
      ),
      // رقم الرحلة (int?) بيتبعت في state.extra، ولو null بتفتح أول رحلة شغالة
      GoRoute(
        path: activeTrip,
        builder: (context, state) =>
            ActiveTripScreen(tripId: state.extra as int?),
      ),
      // PROFILE ROUTES
      GoRoute(
        path: earningsScreen,
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: documentsScreen,
        builder: (context, state) => const DocumentsScreen(),
      ),
      // DriverProfileModel بيتبعت في state.extra جاي من شاشة حسابي
      GoRoute(
        path: updateProfileScreen,
        builder: (context, state) =>
            EditProfileScreen(profile: state.extra! as DriverProfileModel),
      ),
      GoRoute(
        path: privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: contactUsScreen,
        builder: (context, state) => const ContactUsScreen(),
      ),

      // GoRoute(
      //   path: homeScreen,
      //   builder: (context, state) => const HomeScreen(),
      // ),
    ],
  );
}
