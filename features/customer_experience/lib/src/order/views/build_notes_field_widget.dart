import 'package:flutter/material.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';

class BuildNotesFieldWidget extends StatelessWidget {
  BuildNotesFieldWidget({super.key});
  final OrderController orderController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CustomerCheckoutStrings.notesLabel,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          // controller: notesController,
          onChanged: (value) => orderController.notes.value = value,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: CustomerCheckoutStrings.notesHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
