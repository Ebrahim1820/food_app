// Food's Edit Order screen — thin wiring layer over the generic
// EditOrderScreen (see
// lib/screens/shared_customer_business_screens/customer_dashboard/views/edit_order_screen.dart)
// — the same generic screen Cosmetic's edit-order screen wires up. This file
// owns everything Food-specific: OrderModel, OrderController.editOrder.
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/controllers/order_controller.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/screens/shared_customer_business_screens/customer_dashboard/views/edit_order_screen.dart'
    as shared;
import 'package:get/get.dart';

class CustomerEditOrderScreen extends shared.EditOrderScreen {
  CustomerEditOrderScreen({super.key, required OrderModel order})
    : super(config: _configFor(order));

  static shared.EditOrderConfig _configFor(OrderModel order) {
    final orderCtrl = Get.find<OrderController>();
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
              availableStock: item.foodOffer.quantityAvailable ?? 0,
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
