// Customer Edit-Order screen for Cosmetics (and any other non-Food market).
// Thin wiring layer over the generic EditOrderScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/edit_order_screen.dart)
// — the same generic screen Food's edit-order screen wires up. New screen:
// Cosmetic previously had no edit-order flow at all, matching how it also
// had no actions section on its order-detail screen.
import 'package:food_app/controllers/prodcuct_controllers/product_order_controller.dart';
import 'package:food_app/models/product_models/product_order_model.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/edit_order_screen.dart'
    as shared;
import 'package:get/get.dart';

class CosmeticEditOrderScreen extends shared.EditOrderScreen {
  CosmeticEditOrderScreen({super.key, required ProductOrderModel order})
    : super(config: _configFor(order));

  static shared.EditOrderConfig _configFor(ProductOrderModel order) {
    final orderCtrl = Get.find<ProductOrderController>();
    return shared.EditOrderConfig(
      appBarTitle: CustomerOrderStrings.editAppBarTitle(order.id),
      initialNotes: order.notes,
      isSaving: orderCtrl.isUpdating,
      items: order.orderItems
          .map(
            (item) => shared.EditOrderLineItem(
              id: item.id,
              title: item.titleSnapshot,
              unitPrice: item.unitPrice,
              currentQuantity: item.quantity,
              availableStock: item.product.quantityAvailable ?? 0,
            ),
          )
          .toList(),
      onSave: ({required quantities, required notes, required deliveryAddressIri}) =>
          orderCtrl.editOrder(
            orderId: order.id,
            notes: notes,
            deliveryAddressIri: deliveryAddressIri,
            itemQuantities: quantities,
          ),
    );
  }
}
