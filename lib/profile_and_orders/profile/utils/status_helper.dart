import 'package:flutter/material.dart';
import 'package:food_app/theme/app_colors.dart';

class StatusHelper {
  /// =========================================
  /// FOOD OFFER STATUS
  /// =========================================
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      /// SUCCESS STATES
      case 'active':
      case 'available':
      case 'approved':
      case 'completed':
      case 'confirmed':
      case 'paid':
      case 'delivered':
      case 'verified':
      case 'published':
      case 'success':
        return AppColors.success;

      /// WARNING STATES
      case 'pending':
      case 'processing':
      case 'review':
      case 'scheduled':
      case 'draft':
      case 'reserved':
      case 'awaiting_payment':
      case 'waiting':
        return AppColors.warning;

      /// ERROR STATES
      case 'expired':
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'rejected':
      case 'denied':
      case 'inactive':
      case 'deleted':
      case 'blocked':
      case 'unverified':
      case 'out_of_stock':
        return AppColors.error;

      /// INFO STATES
      case 'in_progress':
      case 'ongoing':
      case 'shipping':
      case 'preparing':
      case 'updating':
        return AppColors.primary;

      /// NEUTRAL STATES
      case 'closed':
      case 'archived':
      case 'paused':
      case 'disabled':
        return AppColors.textSecondary;

      /// DEFAULT
      default:
        return AppColors.warning;
    }
  }
}
