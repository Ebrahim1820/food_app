// Generic customer Edit-Order screen — reusable across markets the same way
// OrderDetailScreen/OrderListScreen are: a market wiring layer (Food's
// CustomerEditOrderScreen, Cosmetic's CosmeticEditOrderScreen) extracts
// primitive values from its own order model into an [EditOrderConfig] and
// supplies an [onSave] callback that calls its own controller's editOrder.
//
// This file never imports a market model or market controller. It owns the
// one thing that used to differ (and, in Food's case, used to be buggy)
// between markets: the quantity stepper (now the shared
// [QuantityStepperField], with a correct stock cap) and the address picker
// (now the shared [BuildAddressPickerWidget], which supports adding/editing
// an address in place instead of a bare dropdown).
import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/widgets/common/quantity_stepper_field.dart';
import 'package:food_app/profile_and_orders/orders/constants/customer_order_strings.dart';
import 'package:food_app/profile_and_orders/orders/views/build_address_picker_widget.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/theme/app_colors.dart';
import 'package:get/get.dart';

/// One editable line item on the Edit Order screen.
class EditOrderLineItem {
  const EditOrderLineItem({
    required this.id,
    required this.title,
    required this.unitPrice,
    required this.currentQuantity,
    required this.availableStock,
  });

  /// Order-item id (used as the key in the quantities map passed to
  /// [EditOrderConfig.onSave]).
  final int id;
  final String title;
  final String unitPrice;
  final int currentQuantity;

  /// Raw remaining stock, *not* counting this order's own already-reserved
  /// quantity — the stepper's actual cap is `availableStock +
  /// currentQuantity` since that reserved stock is this order's to give
  /// back or keep.
  final int availableStock;
}

class EditOrderConfig {
  const EditOrderConfig({
    required this.appBarTitle,
    required this.items,
    this.initialNotes,
    required this.isSaving,
    required this.onSave,
  });

  final String appBarTitle;
  final List<EditOrderLineItem> items;
  final String? initialNotes;

  /// True while a save request is in flight — disables/spins the save button.
  final RxBool isSaving;

  final Future<void> Function({
    required Map<int, int> quantities,
    required String notes,
    required String deliveryAddressIri,
  })
  onSave;
}

class EditOrderScreen extends StatefulWidget {
  const EditOrderScreen({super.key, required this.config});

  final EditOrderConfig config;

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late final TextEditingController _notesCtrl;
  late final Map<int, RxInt> _quantities;

  final AddressController _addressCtrl = Get.find();

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.config.initialNotes ?? '');
    _quantities = {
      for (final item in widget.config.items)
        item.id: RxInt(item.currentQuantity),
    };
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(config.appBarTitle),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    title: CustomerOrderStrings.editSectionItems,
                    children: config.items.map((item) {
                      final quantity = _quantities[item.id]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CustomerOrderStrings.editUnitPrice(
                                item.unitPrice,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            QuantityStepperField(
                              quantity: quantity,
                              maxQuantity:
                                  item.availableStock + item.currentQuantity,
                              displayAvailable: item.availableStock,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: CustomerOrderStrings.editSectionAddress,
                    children: const [BuildAddressPickerWidget()],
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: CustomerOrderStrings.editSectionNotes,
                    children: [
                      TextField(
                        controller: _notesCtrl,
                        decoration: InputDecoration(
                          hintText: CustomerOrderStrings.editNotesHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SaveButton(
              isSaving: config.isSaving,
              onSave: () => config.onSave(
                quantities: _quantities.map(
                  (id, qty) => MapEntry(id, qty.value),
                ),
                notes: _notesCtrl.text.trim(),
                deliveryAddressIri:
                    _addressCtrl.selectedAddress.value?.iri ?? '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onSave});

  final RxBool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: CustomDynamicButton(
            fullWidth: true,
            borderRadius: 16,
            isLoading: isSaving.value,
            label: CustomerOrderStrings.editSaveButton,
            onPressed: onSave,
          ),
        ),
      ),
    );
  }
}
