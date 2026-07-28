import 'package:flutter/material.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:food_app/profile_and_orders/profile/controllers/address_controller.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/address_widgets.dart';

/// Returns the [showModalBottomSheet] future so callers that need to react
/// after the sheet closes (e.g. auto-selecting a newly added address) can
/// await it. Fire-and-forget callers can simply ignore the return value.
Future<void> showAddressFormSheet(
  BuildContext context,
  AddressController ctrl, {
  required AddressModel? existing,
  required List<({String value, String label, IconData icon})> labelOptions,
  required String addTitle,
  required String editTitle,
  required String saveLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddressFormSheet(
      ctrl: ctrl,
      existing: existing,
      labelOptions: labelOptions,
      addTitle: addTitle,
      editTitle: editTitle,
      saveLabel: saveLabel,
    ),
  );
}

class AddressFormSheet extends StatefulWidget {
  final AddressController ctrl;
  final AddressModel? existing;
  final List<({String value, String label, IconData icon})> labelOptions;
  final String addTitle;
  final String editTitle;
  final String saveLabel;

  const AddressFormSheet({
    super.key,
    required this.ctrl,
    required this.existing,
    required this.labelOptions,
    required this.addTitle,
    required this.editTitle,
    required this.saveLabel,
  });

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late final TextEditingController _street;
  late final TextEditingController _street2;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late final TextEditingController _country;
  late final TextEditingController _countryCode;
  late final TextEditingController _state;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = a?.labelOrDefault ?? widget.labelOptions.first.value;
    _street = TextEditingController(text: a?.street ?? '');
    _street2 = TextEditingController(text: a?.street2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _country = TextEditingController(text: a?.country ?? '');
    _countryCode = TextEditingController(text: a?.countryCode ?? '');
    _state = TextEditingController(text: a?.state ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _street,
      _street2,
      _city,
      _postal,
      _country,
      _countryCode,
      _state,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'label': _label,
      'street': _street.text.trim(),
      if (_street2.text.trim().isNotEmpty) 'street2': _street2.text.trim(),
      'city': _city.text.trim(),
      'postalCode': _postal.text.trim(),
      'country': _country.text.trim(),
      'countryCode': _countryCode.text.trim(),
      if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
    };

    if (widget.existing == null) {
      await widget.ctrl.createAddress(fields);
    } else {
      await widget.ctrl.updateAddress(widget.existing!.id, fields);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom
        : mq.padding.bottom;
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              Text(
                isEdit ? widget.editTitle : widget.addTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              AddressLabelSelector(
                options: widget.labelOptions,
                selected: _label,
                onChanged: (v) => setState(() => _label = v),
              ),
              const SizedBox(height: 16),
              AddressFormField(
                controller: _street,
                label: CustomerProfileStrings.streetLabel,
                required: true,
              ),
              const SizedBox(height: 10),
              AddressFormField(
                controller: _street2,
                label: CustomerProfileStrings.street2Label,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AddressFormField(
                      controller: _city,
                      label: CustomerProfileStrings.cityLabel,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AddressFormField(
                      controller: _postal,
                      label: CustomerProfileStrings.postalLabel,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AddressFormField(
                      controller: _country,
                      label: CustomerProfileStrings.countryLabel,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AddressFormField(
                      controller: _countryCode,
                      label: CustomerProfileStrings.countryCodeLabel,
                      required: true,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AddressFormField(
                controller: _state,
                label: CustomerProfileStrings.stateLabel,
              ),
              const SizedBox(height: 20),
              CustomDynamicButton(
                fullWidth: true,
                borderRadius: 14,
                isLoading: _saving,
                label: widget.saveLabel,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
