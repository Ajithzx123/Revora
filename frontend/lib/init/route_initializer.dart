import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../modules/splash/presentation/ui/splash_screen.dart';
import '../modules/customer/presentation/ui/customer_shell.dart';
import '../core/network/api_error.dart';
import '../modules/customer/presentation/providers/requirements_provider.dart';
import '../modules/dealer/presentation/providers/inventory_provider.dart';
import '../modules/customer/presentation/ui/post_buy_requirement_screen.dart';
import '../modules/customer/presentation/ui/post_sell_listing_screen.dart';
import '../modules/customer/presentation/ui/my_requirements_screen.dart';
import '../modules/customer/presentation/ui/requirement_details_screen.dart';
import '../modules/customer/presentation/ui/listing_details_screen.dart';
import '../modules/customer/presentation/ui/quote_comparison_screen.dart';
import '../modules/dealer/presentation/ui/dealer_application_screen.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
        path: '/customer/edit-requirement/:id',
        builder: (context, state) =>
            _EditRequirementRoute(id: state.pathParameters['id']!),
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
        builder: (context, state) => const _DealerGate(),
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
        path: '/dealer/edit-car/:id',
        builder: (context, state) =>
            _EditVehicleRoute(id: state.pathParameters['id']!),
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

/// Dealers see the portal only once approved; until then, their application.
/// A missing status means mock/demo data, which is treated as approved.
class _DealerGate extends ConsumerWidget {
  const _DealerGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      authControllerProvider.select((s) => s.user?.dealerStatus),
    );
    if (status == null || status == 'APPROVED') return const DealerShell();
    return const DealerApplicationScreen();
  }
}

/// Loads the request being edited from the buyer's own list.
class _EditRequirementRoute extends ConsumerWidget {
  final String id;
  const _EditRequirementRoute({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirements = ref.watch(requirementsProvider);
    return requirements.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (items) {
        final match = items.where((r) => r.id == id);
        if (match.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This request no longer exists.')),
          );
        }
        return PostBuyRequirementScreen(existing: match.first);
      },
    );
  }
}

/// Loads the car being edited from the dealer's own stock.
class _EditVehicleRoute extends ConsumerWidget {
  final String id;
  const _EditVehicleRoute({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    return inventory.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (items) {
        final match = items.where((v) => v.id == id);
        if (match.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This car no longer exists.')),
          );
        }
        return AddCarToInventoryScreen(existing: match.first);
      },
    );
  }
}
