import 'package:get/get.dart';

abstract class OrderString {
  static String get pending => 'order_pending'.tr;
  static String get confirmed => 'order_confirmed'.tr;
  static String get delivered => 'order_delivered'.tr;
  static String get cancelled => 'order_cancelled'.tr;
  static String get quantity => 'order_quantity'.tr;
}
