import 'package:dar_al_safwa/presentation/view/dashboard/screens/dashboard_screen.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/add_property_screen.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/customer_enquiry_screen.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/properties_screen.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenant_complaint_register.dart';
import 'package:dar_al_safwa/presentation/view/error/screens/error_screen.dart';
import 'package:dar_al_safwa/presentation/view/home/screens/home_screen.dart';
import 'package:dar_al_safwa/presentation/view/inbox/screens/inbox_screen.dart';
import 'package:dar_al_safwa/presentation/view/login/login_screen.dart';
import 'package:dar_al_safwa/presentation/view/login/mobile_login_otp.dart';
import 'package:dar_al_safwa/presentation/view/login/mobile_login_screen.dart';
import 'package:dar_al_safwa/presentation/view/agent/screens/signin_screen.dart';
import 'package:dar_al_safwa/presentation/view/agent/screens/signup_screen.dart';
import 'package:dar_al_safwa/presentation/view/profile/screens/profile_screen.dart';
import 'package:dar_al_safwa/presentation/view/property_details/screens/proprety_details_screen.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/view_gallery.dart';
import 'package:dar_al_safwa/presentation/view/property_listings/screens/property_listings.dart';
import 'package:dar_al_safwa/presentation/view/search/screens/search_screen.dart';
import 'package:dar_al_safwa/presentation/view/splash/screens/splash_screen.dart';
import 'package:dar_al_safwa/presentation/widgets/bottom_navbar_widget.dart';

import 'package:get/get.dart';

import '../../presentation/view/agent/screens/approval_pending.dart';
import '../../presentation/view/chat/screen/agent_chat_screen.dart';
import '../../presentation/view/dashboard/widgets/tenant_properties_list.dart';
import '../../presentation/view/dashboard/widgets/tenants_documents_widget.dart';
import '../../presentation/view/property_details/controller/property_details_controller.dart';
import '../../presentation/widgets/signup_warning_screen.dart';

class AppRoute {
  static const String initial = '/';
  static const String login = '/login';
  static const String mobileLogin = '/mobileLogin';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String home = '/home';
  static const String navbar = '/navbar';
  static const String dashboard = '/dashboard';
  static const String search = '/search';
  static const String inbox = '/inbox';
  static const String profile = '/profile';
  static const String propertyListing = '/propertyListing';
  static const String propertyDetails = '/propertyDetails';
  static const String agent = '/agent';
  static const String viewGallery = '/viewGallery';
  static const String mobileLoginOtp = '/mobileLoginOtp';
  static const String approvalPendingPage = '/approvalPendingPage';
  static const String tenantComplaintReg = '/tenantComplaintReg';
  static const String compliantRegister = '/compliantRegister';
  static const String signupWarning = '/signupWarning';
  static const String error = '/error';
  static const String properties = '/properties';
  static const String addProperties = '/addProperties';
  static const String enquiry = '/enquiry';
  static const String tenantPropertyList = '/tenantPropertyList';
  static const String tenantDocumentsList = '/tenantDocumentsList';

  static final routes = [
    GetPage(
      name: signupWarning,
      page: () => SignupWarningScreen(),
    ),
    GetPage(
      name: initial,
      page: () => SplashScreen(),
    ),
    GetPage(
      name: approvalPendingPage,
      page: () => const ApprovalPendingPage(),
    ),
    GetPage(
      name: login,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: mobileLogin,
      page: () => MobileLoginScreen(),
    ),
    GetPage(
      name: signup,
      page: () => SignUpScreen(),
    ),
    GetPage(
      name: signin,
      page: () => SigninScreen(),
    ),
    GetPage(
      name: navbar,
      page: () => const BottomNavbarWidget(),
    ),
    GetPage(
      name: home,
      page: () => HomeScreen(),
    ),
    GetPage(
      name: dashboard,
      page: () => DashboardScreen(),
    ),
    GetPage(
      name: search,
      page: () => SearchScreen(),
    ),
    GetPage(
      name: inbox,
      page: () => InboxScreen(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: propertyListing,
      page: () => PropertyListings(),
    ),
    GetPage(
      name: properties,
      page: () => PropertiesScreen(),
    ),
    GetPage(
      name: addProperties,
      page: () => AddPropertyScreen(),
    ),
    GetPage(
      name: tenantDocumentsList,
      page: () => TenantsDocumentsWidget(),
    ),
    GetPage(
      name: enquiry,
      page: () => CustomerEnquiryScreen(),
    ),
    GetPage(
      name: propertyDetails,
      page: () => PropertyDetailsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PropertyDetailsController());
      }),
    ),
    GetPage(
      name: agent,
      page: () => AgentChatScreen(),
    ),
    GetPage(
      name: viewGallery,
      page: () => GalleryViewer(),
    ),
    GetPage(
      name: mobileLoginOtp,
      page: () => MobileLoginOtp(),
    ),
    GetPage(
      name: tenantComplaintReg,
      page: () => TenantComplaintRegister(),
    ),
    GetPage(
      name: tenantPropertyList,
      page: () => TenantPropertiesList(),
    ),
    GetPage(
      name: error,
      page: () => const ErrorScreen(),
    ),
  ];
}
