export 'src/mercure_controller.dart';
export 'src/mercure_credentials_model.dart';
export 'src/mercure_service.dart';
export 'src/notification_bell.dart';
export 'src/notification_card.dart';
export 'src/notification_controller.dart';
export 'src/notification_model.dart';
export 'src/notification_service.dart';
// UserService lives here (not its own "account" feature) because it's the
// only thing MercureController needs beyond the mercure domain itself, and
// splitting it out would just recreate the same package-can't-depend-on-app
// problem this move was solving. It's still consumed broadly (auth, profile,
// dashboard) — that's expected; apps/other features may depend on this
// package freely, only the reverse is disallowed. Revisit if/when an
// account/identity feature is carved out.
export 'src/user_service.dart';
