import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import 'customer_edit_profile_controller.dart';
import 'package:notification/notification.dart';
import 'customer_profile_strings.dart';
import 'section_label.dart';
import 'package:get/get.dart';

class CustomerEditProfileScreen extends StatelessWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return GetBuilder<CustomerEditProfileController>(
      init: CustomerEditProfileController(Get.find<UserService>()),
      builder: (ctrl) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            CustomerProfileStrings.editProfileTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(
          () => ctrl.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    children: [
                      // ── Avatar ────────────────────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Personal info ─────────────────────────────────────
                      SectionLabel(CustomerProfileStrings.personalInfo),
                      const SizedBox(height: 10),

                      _ProfileField(
                        label: CustomerProfileStrings.firstName,
                        controller: ctrl.firstNameCtrl,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      _ProfileField(
                        label: CustomerProfileStrings.lastName,
                        controller: ctrl.lastNameCtrl,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      _ProfileField(
                        label: CustomerProfileStrings.phone,
                        controller: ctrl.phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // Email read-only — managed by Keycloak
                      _ProfileField(
                        label: CustomerProfileStrings.email,
                        controller: TextEditingController(text: auth.email),
                        icon: Icons.email_outlined,
                        readOnly: true,
                        helperText: CustomerProfileStrings.emailReadOnly,
                      ),

                      const SizedBox(height: 32),

                      // ── Save button ───────────────────────────────────────
                      Obx(
                        () => CustomDynamicButton(
                          fullWidth: true,
                          borderRadius: 14,
                          isLoading: ctrl.isSaving.value,
                          label: CustomerProfileStrings.saveChanges,
                          onPressed: ctrl.save,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Single editable form field ────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;
  final String? helperText;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.readOnly = false,
    this.helperText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: readOnly ? AppColors.textSecondary : AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 20, color: AppColors.gray400),
        filled: true,
        fillColor: readOnly ? AppColors.gray100 : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
