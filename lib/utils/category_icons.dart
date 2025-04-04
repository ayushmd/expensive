import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'groceries':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.power;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'rent':
        return Icons.home;
      case 'bills':
        return Icons.receipt;
      case 'others':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
