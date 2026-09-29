import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/auth/domain/entities/user.dart';
import '../../modules/auth/presentation/pages/login_screen.dart';
import '../../modules/auth/presentation/pages/register_screen.dart';
import '../../modules/auth/presentation/providers/auth_provider.dart';

import '../../modules/splash/presentation/pages/splash_screen.dart';
import '../../modules/customer/presentation/layouts/customer_shell.dart';
import '../../modules/customer/presentation/pages/buy_car_flow_screen.dart';
import '../../modules/customer/presentation/pages/post_sell_listing_screen.dart';
import '../../modules/customer/presentation/pages/my_requirements_screen.dart';
import '../../modules/customer/presentation/pages/requirement_details_screen.dart';
import '../../modules/customer/presentation/pages/listing_details_screen.dart';
import '../../modules/customer/presentation/pages/quote_comparison_screen.dart';

import '../../modules/dealer/presentation/layouts/dealer_shell.dart';
import '../../modules/dealer/presentation/pages/send_quote_screen.dart';
import '../../modules/dealer/presentation/pages/make_offer_screen.dart';
import '../../modules/dealer/presentation/pages/add_car_to_inventory_screen.dart';

import '../../modules/admin/presentation/layouts/admin_shell.dart';
import '../../shared/presentation/pages/chat_page.dart';
import 'route_names.dart';

/// Listenable adapter that triggers GoRouter redirects whenever AuthState changes.
class _RouterListenable extends ChangeNotifier {
  final Ref _ref;
  ProviderSubscription<AuthState>? _subscription;

  _RouterListenable(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.user != next.user ||
            previous?.isInitialized != next.isInitialized) {
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final routerListenableProvider = Provider.autoDispose<_RouterListenable>((ref) {
  final notifier = _RouterListenable(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authControllerProvider);

      final location = state.uri.path;
      final isGoingToSplash = location == RouteNames.splash;
      final isGoingToAuth =
          location == RouteNames.login || location == RouteNames.register;

      // 1. If auth is not yet checked from storage, let splash stay
      if (!authState.isInitialized) {
        return isGoingToSplash ? null : RouteNames.splash;
      }

      // 2. If user is NOT authenticated
      if (!authState.isAuthenticated) {
        // If already going to login or register, allow
        if (isGoingToAuth) return null;
        // Otherwise redirect to login
        return RouteNames.login;
      }

      // 3. User IS authenticated
      final user = authState.user;
      final role = user?.role ?? UserRole.customer;

      // If user is trying to access splash or login/register while authenticated,
      // redirect them to their home portal
      if (isGoingToSplash || isGoingToAuth) {
        switch (role) {
          case UserRole.customer:
            return RouteNames.customerHome;
          case UserRole.dealer:
            return RouteNames.dealerHome;
          case UserRole.admin:
            return RouteNames.adminDashboard;
        }
      }

      // 4. Role-based route guard
      // Protect Dealer routes from non-dealers
      if (location.startsWith('/dealer') && role != UserRole.dealer) {
        return role == UserRole.admin
            ? RouteNames.adminDashboard
            : RouteNames.customerHome;
      }

      // Protect Admin routes from non-admins
      if (location.startsWith('/admin') && role != UserRole.admin) {
        return role == UserRole.dealer
            ? RouteNames.dealerHome
            : RouteNames.customerHome;
      }

      // Allow navigation
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Portal
      GoRoute(
        path: RouteNames.customerHome,
        builder: (context, state) => const CustomerShell(),
      ),
      // Canonical redirect aliases
      GoRoute(
        path: RouteNames.postRequirementAlias,
        redirect: (context, state) => RouteNames.customerPostBuy,
      ),
      GoRoute(
        path: RouteNames.customerPostBuy,
        builder: (context, state) => const BuyCarFlowScreen(),
      ),
      GoRoute(
        path: RouteNames.sellCarAlias,
        redirect: (context, state) => RouteNames.customerPostSell,
      ),
      GoRoute(
        path: RouteNames.customerPostSell,
        builder: (context, state) => const PostSellListingScreen(),
      ),
      GoRoute(
        path: RouteNames.customerMyRequirements,
        builder: (context, state) => const MyRequirementsScreen(),
      ),
      GoRoute(
        path: RouteNames.customerRequirementDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequirementDetailsScreen(requirementId: id);
        },
      ),
      GoRoute(
        path: RouteNames.customerListingDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailsScreen(listingId: id);
        },
      ),
      GoRoute(
        path: RouteNames.customerCompare,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuoteComparisonScreen(requirementId: id);
        },
      ),

      // Dealer Portal
      GoRoute(
        path: RouteNames.dealerHome,
        builder: (context, state) => const DealerShell(),
      ),
      GoRoute(
        path: RouteNames.sendQuoteAlias,
        redirect: (_, state) =>
            '/dealer/send-quote/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: RouteNames.dealerSendQuote,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SendQuoteScreen(leadId: id);
        },
      ),
      GoRoute(
        path: RouteNames.dealerMakeOffer,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MakeOfferScreen(listingId: id);
        },
      ),
      GoRoute(
        path: RouteNames.addInventoryAlias,
        redirect: (context, state) => RouteNames.dealerAddCar,
      ),
      GoRoute(
        path: RouteNames.dealerAddCar,
        builder: (context, state) => const AddCarToInventoryScreen(),
      ),

      // Admin Portal
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: RouteNames.adminAlias,
        redirect: (context, state) => RouteNames.adminDashboard,
      ),

      // Shared
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) => const ChatScreen(chatId: 'default'),
      ),
      GoRoute(
        path: RouteNames.chatWithId,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
    ],
  );
});
