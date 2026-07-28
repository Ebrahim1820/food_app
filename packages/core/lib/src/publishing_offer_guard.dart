/// Set to true by the offer preview screen for the duration of publishing an
/// offer. [PushNotificationService] (app-level, since it also needs business
/// dashboard/order navigation) checks this to skip pushing extra routes from
/// a notification tap during that window. Lives in `core` so both sides can
/// reach it without a feature package depending on the app.
abstract class PublishingOfferGuard {
  static bool active = false;
}
