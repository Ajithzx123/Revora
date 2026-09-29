class RouteNames {
  RouteNames._();

  // Root / Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Customer Portal
  static const String customerHome = '/customer/home';
  static const String customerPostBuy = '/customer/post-buy';
  static const String customerPostSell = '/customer/post-sell';
  static const String customerMyRequirements = '/customer/my-requirements';
  static const String customerRequirementDetails = '/customer/requirement/:id';
  static const String customerListingDetails = '/customer/listing/:id';
  static const String customerCompare = '/customer/compare/:id';

  // Legacy/Shortcut aliases for Customer
  static const String postRequirementAlias = '/post-requirement';
  static const String sellCarAlias = '/sell-car';

  // Dealer Portal
  static const String dealerHome = '/dealer/home';
  static const String dealerSendQuote = '/dealer/send-quote/:id';
  static const String dealerMakeOffer = '/dealer/make-offer/:id';
  static const String dealerAddCar = '/dealer/add-car';

  // Legacy/Shortcut aliases for Dealer
  static const String sendQuoteAlias = '/send-quote/:id';
  static const String addInventoryAlias = '/add-inventory';

  // Admin Portal
  static const String adminDashboard = '/admin/dashboard';
  static const String adminAlias = '/admin';

  // Shared
  static const String chat = '/chat';
  static const String chatWithId = '/chat/:id';
}
