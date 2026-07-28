import 'admin_pages.dart';
import 'customer_pages.dart';
import 'seller_pages.dart';
import 'shared_pages.dart';

/// The production route table — every team's pages combined. Each team's
/// pages live in their own file (customer_pages.dart, seller_pages.dart,
/// admin_pages.dart); this file just concatenates them, so a PR adding one
/// route touches one small owned file instead of this one.
class AppPages {
  static final routes = [
    ...SharedPages.pages,
    ...CustomerPages.pages,
    ...SellerPages.pages,
    ...AdminPages.pages,
  ];
}
