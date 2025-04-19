import 'package:flutter/material.dart';

class IncomeIcons {
  static const List<String> categories = [
    'Salary',
    'Business',
    'Investments',
    'Gifts',
    'Freelance',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Salary':
        return Icons.work;
      case 'Business':
        return Icons.store;
      case 'Investments':
        return Icons.trending_up;
      case 'Gifts':
        return Icons.card_giftcard;
      case 'Freelance':
        return Icons.computer;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }
} 