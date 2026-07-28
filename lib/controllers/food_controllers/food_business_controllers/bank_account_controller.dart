import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/models/food_models/business_models/bank_account_model.dart';
import 'package:food_app/services/food_services/business_services/bank_account_service.dart';
import 'package:core/core.dart';
import 'package:food_app/constants/food/business_constants/business_bank_account_strings.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class BankAccountController extends GetxController {
  BankAccountController(this._service);

  final BankAccountService _service;

  final accounts = <BankAccountModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    final bpCtrl = Get.find<BusinessPartnerController>();
    if (bpCtrl.partner.value != null) {
      fetch();
    } else {
      // Partner may still be loading — wait for it then fetch once
      ever(bpCtrl.partner, (partner) {
        if (partner != null && accounts.isEmpty && !isLoading.value) {
          fetch();
        }
      });
    }
  }

  String? get _partnerIri =>
      Get.find<BusinessPartnerController>().partner.value?.iri;

  Future<void> fetch() async {
    final iri = _partnerIri;
    if (iri == null) return;

    isLoading.value = true;
    errorMessage.value = null;
    try {
      accounts.value = await _service.fetchForPartner(iri);

      // The GET collection endpoint may not serialize isDefault.
      // If none of the returned accounts are marked as default, restore from
      // the last value we persisted locally when the user set a default.
      if (accounts.isNotEmpty && !accounts.any((a) => a.isDefault)) {
        final storedId = AppStorage.read<String?>('defaultBankAccountId_$iri');
        if (storedId != null) {
          final idx = accounts.indexWhere((a) => a.id == storedId);
          if (idx != -1) {
            accounts[idx] = accounts[idx].copyWith(isDefault: true);
          }
        }
      }
    } catch (e) {
      errorMessage.value = BusinessBankAccountScreenStrings.errorCouldNotLoad;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> create(BankAccountModel data) async {
    final iri = _partnerIri;
    if (iri == null) return false;

    isSaving.value = true;
    try {
      final created = await _service.create(
        businessPartnerIri: iri,
        data: data,
      );
      if (created.isDefault) _clearOtherDefaults(created.id);
      accounts.add(created);
      _showSuccess(BusinessBankAccountScreenStrings.snackAdded);
      return true;
    } catch (e) {
      _showError(BusinessBankAccountScreenStrings.snackCouldNotSave);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> patch(String id, Map<String, dynamic> fields) async {
    isSaving.value = true;
    try {
      // If switching default, unset the current default on backend first.
      if (fields['isDefault'] == true) {
        for (final a in accounts) {
          if (a.id != id && a.isDefault) {
            await _service.update(a.id, {'isDefault': false});
          }
        }
      }

      await _service.update(id, fields);

      // Update local state from fields directly — don't rely on the PATCH
      // response body having correct serialization groups.
      final idx = accounts.indexWhere((a) => a.id == id);
      if (idx != -1) {
        accounts[idx] = accounts[idx].copyWith(
          bankName: fields['bankName'] as String?,
          accountHolderName: fields['accountHolderName'] as String?,
          iban: fields['iban'] as String?,
          swiftOrBicCode: fields['swiftOrBicCode'] as String?,
          accountNumber: fields['accountNumber'] as String?,
          isDefault: fields['isDefault'] as bool?,
        );
        if (fields['isDefault'] == true) {
          _clearOtherDefaults(id);
          // Persist so fetch() can restore the default after re-login even if
          // the GET collection endpoint doesn't serialize isDefault.
          final iri = _partnerIri;
          if (iri != null) AppStorage.write('defaultBankAccountId_$iri', id);
        }
      }
      _showSuccess(BusinessBankAccountScreenStrings.snackUpdated);
      return true;
    } catch (e) {
      _showError(BusinessBankAccountScreenStrings.snackCouldNotUpdate);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> delete(String id) async {
    isSaving.value = true;
    try {
      await _service.delete(id);
      accounts.removeWhere((a) => a.id == id);
      _showSuccess(BusinessBankAccountScreenStrings.snackDeleted);
      return true;
    } catch (e) {
      _showError(BusinessBankAccountScreenStrings.snackCouldNotDelete);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _clearOtherDefaults(String keepId) {
    for (var i = 0; i < accounts.length; i++) {
      if (accounts[i].id != keepId && accounts[i].isDefault) {
        accounts[i] = accounts[i].copyWith(isDefault: false);
      }
    }
  }

  void _showSuccess(String msg) {
    AppSnackbar.success('', msg, duration: const Duration(seconds: 2));
  }

  void _showError(String msg) {
    AppSnackbar.error('', msg);
  }
}
