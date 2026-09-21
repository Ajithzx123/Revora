import '../../domain/models/user_model.dart';

class MockAccount {
  final UserModel user;
  final String password;
  final String description;

  const MockAccount({
    required this.user,
    required this.password,
    required this.description,
  });
}

class AuthMockData {
  static const String defaultPassword = 'password123';

  static final MockAccount customerAccount = MockAccount(
    user: const UserModel(
      id: 'USR-CUST-101',
      email: 'buyer@revora.com',
      fullName: 'Rahul Verma',
      role: UserRole.customer,
      phone: '+91 98201 12345',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
    ),
    password: defaultPassword,
    description: 'Verified Buyer with 3 active car requirements & 5 received quotes',
  );

  static final MockAccount dealerAccount = MockAccount(
    user: const UserModel(
      id: 'USR-DLR-201',
      email: 'dealer@revora.com',
      fullName: 'Vikram Malhotra (Apex Motor Corp)',
      role: UserRole.dealer,
      phone: '+91 98205 99881',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
    ),
    password: defaultPassword,
    description: 'Premium Verified Dealer managing 28 cars in inventory',
  );

  static final MockAccount adminAccount = MockAccount(
    user: const UserModel(
      id: 'USR-ADM-001',
      email: 'admin@revora.com',
      fullName: 'Revora Platform Admin',
      role: UserRole.admin,
      phone: '+91 98111 00000',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300',
    ),
    password: defaultPassword,
    description: 'Marketplace Operations & Dealer Compliance Administrator',
  );

  static final List<MockAccount> presetAccounts = [
    customerAccount,
    dealerAccount,
    adminAccount,
  ];

  /// Dynamic registry for newly created accounts during runtime
  static final Map<String, MockAccount> _registeredAccounts = {};

  static MockAccount? findAccount(String email) {
    final lower = email.trim().toLowerCase();

    // Check presets first
    for (final acc in presetAccounts) {
      if (acc.user.email.toLowerCase() == lower) {
        return acc;
      }
    }

    // Check dynamic registered accounts
    if (_registeredAccounts.containsKey(lower)) {
      return _registeredAccounts[lower];
    }

    // Role detection by email pattern
    if (lower.contains('dealer') || lower.contains('delar')) {
      final user = dealerAccount.user.copyWith(
        id: 'USR-DLR-${lower.hashCode.abs() % 10000}',
        email: email.trim(),
      );
      return MockAccount(
        user: user,
        password: defaultPassword,
        description: dealerAccount.description,
      );
    }

    if (lower.contains('admin')) {
      final user = adminAccount.user.copyWith(
        id: 'USR-ADM-${lower.hashCode.abs() % 10000}',
        email: email.trim(),
      );
      return MockAccount(
        user: user,
        password: defaultPassword,
        description: adminAccount.description,
      );
    }

    if (lower.contains('customer') || lower.contains('buyer')) {
      final user = customerAccount.user.copyWith(
        id: 'USR-CUST-${lower.hashCode.abs() % 10000}',
        email: email.trim(),
      );
      return MockAccount(
        user: user,
        password: defaultPassword,
        description: customerAccount.description,
      );
    }

    return null;
  }

  static void registerAccount(UserModel user, String password) {
    _registeredAccounts[user.email.toLowerCase()] = MockAccount(
      user: user,
      password: password,
      description: 'Registered ${user.role.displayName} Account',
    );
  }

  /// Resolves or synthesizes a mock user for arbitrary input in demo mode
  static UserModel createDynamicUser({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  }) {
    final normalized = email.trim();
    final lower = normalized.toLowerCase();

    UserRole detectedRole = role ?? UserRole.customer;
    if (role == null) {
      if (lower.contains('dealer') || lower.contains('delar')) {
        detectedRole = UserRole.dealer;
      } else if (lower.contains('admin')) {
        detectedRole = UserRole.admin;
      } else {
        detectedRole = UserRole.customer;
      }
    }

    final name = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : _formatNameFromEmail(normalized);

    final newUser = UserModel(
      id: 'USR-DYN-${DateTime.now().millisecondsSinceEpoch % 100000}',
      email: normalized,
      fullName: name,
      role: detectedRole,
      phone: '+91 98000 ${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}',
    );

    registerAccount(newUser, password);
    return newUser;
  }

  static String _formatNameFromEmail(String email) {
    final prefix = email.split('@').first.replaceAll(RegExp(r'[._\d]'), ' ').trim();
    if (prefix.isEmpty) return 'Revora User';
    return prefix
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
