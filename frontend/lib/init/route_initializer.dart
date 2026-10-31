import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../modules/splash/presentation/ui/splash_screen.dart';
import '../modules/customer/presentation/ui/customer_shell.dart';
import '../modules/customer/presentation/ui/post_buy_requirement_screen.dart';
import '../modules/customer/presentation/ui/post_sell_listing_screen.dart';
import '../modules/customer/presentation/ui/my_requirements_screen.dart';
import '../modules/customer/presentation/ui/requirement_details_screen.dart';
import '../modules/customer/presentation/ui/listing_details_screen.dart';
import '../modules/customer/presentation/ui/quote_comparison_screen.dart';
import '../modules/dealer/presentation/ui/dealer_shell.dart';
import '../modules/dealer/presentation/ui/send_quote_screen.dart';
import '../modules/dealer/presentation/ui/make_offer_screen.dart';
import '../modules/dealer/presentation/ui/add_car_to_inventory_screen.dart';
import '../modules/admin/presentation/ui/admin_shell.dart';
import '../shared/presentation/ui/chat_screen.dart';

import '../modules/auth/presentation/ui/login_screen.dart';
import '../modules/auth/presentation/ui/register_screen.dart';
import '../modules/auth/domain/models/user_model.dart';
import '../modules/auth/presentation/controllers/auth_controller.dart';

const _publicPaths = {'/splash', '/login', '/register'};

String _homeFor(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return '/customer/home';
    case UserRole.dealer:
      return '/dealer/home';
    case UserRole.admin:
      return '/admin/dashboard';
  }
}

/// Sends signed-out users to /login and keeps each role inside its own area.
/// This is a UX guard only; the API enforces the real permissions.
@visibleForTesting
String? guardRoute(AuthState auth, String location) {
  final isPublic = _publicPaths.contains(location);
  final user = auth.user;

  if (user == null) {
    if (isPublic) return null;
    // Session restore still running: keep the splash screen up.
    return auth.isInitialized ? '/login' : '/splash';
  }

  if (location == '/login' || location == '/register') {
    return _homeFor(user.role);
  }

  final area = {
    '/customer': UserRole.customer,
    '/dealer': UserRole.dealer,
    '/admin': UserRole.admin,
  };
  for (final entry in area.entries) {
    if ((location == entry.key || location.startsWith('${entry.key}/')) &&
        user.role != entry.value) {
      return _homeFor(user.role);
    }
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        guardRoute(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Portal
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const CustomerShell(),
      ),
      GoRoute(
        path: '/customer/post-buy',
        builder: (context, state) => const PostBuyRequirementScreen(),
      ),
      GoRoute(
        path: '/customer/post-sell',
        builder: (context, state) => const PostSellListingScreen(),
      ),
      GoRoute(
        path: '/customer/my-requirements',
        builder: (context, state) => const MyRequirementsScreen(),
      ),
      GoRoute(
        path: '/customer/requirement/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequirementDetailsScreen(requirementId: id);
        },
      ),
      GoRoute(
        path: '/customer/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailsScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/customer/compare/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuoteComparisonScreen(requirementId: id);
        },
      ),

      // Dealer Portal
      GoRoute(
        path: '/dealer/home',
        builder: (context, state) => const DealerShell(),
      ),
      GoRoute(
        path: '/dealer/send-quote/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SendQuoteScreen(leadId: id);
        },
      ),
      GoRoute(
        path: '/dealer/make-offer/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MakeOfferScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/dealer/add-car',
        builder: (context, state) => const AddCarToInventoryScreen(),
      ),

      // Admin Portal
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminShell(),
      ),

      // Shared
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(chatId: 'default'),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
    ],
  );
});
