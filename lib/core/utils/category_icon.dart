import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Maps a category icon key (stored in Firestore) to a Lucide [IconData].
/// Falls back to [LucideIcons.tag] for unknown keys.
class CategoryIcon {
  CategoryIcon._();

  static final Map<String, IconData> _map = {
    // ── Default categories ───────────────────────────────────────
    'food': LucideIcons.utensils,
    'transport': LucideIcons.car,
    'shopping': LucideIcons.shoppingBag,
    'bills': LucideIcons.fileText,
    'entertainment': LucideIcons.tv2,
    'health': LucideIcons.heartPulse,
    'salary': LucideIcons.banknote,
    'other': LucideIcons.package,

    // ── Extras users might pick ──────────────────────────────────
    'home': LucideIcons.home,
    'education': LucideIcons.graduationCap,
    'travel': LucideIcons.plane,
    'gym': LucideIcons.dumbbell,
    'coffee': LucideIcons.coffee,
    'pets': LucideIcons.dog,
    'gifts': LucideIcons.gift,
    'savings': LucideIcons.piggyBank,
    'investment': LucideIcons.trendingUp,
    'subscriptions': LucideIcons.repeat,
    'clothing': LucideIcons.shirt,
    'beauty': LucideIcons.sparkles,
    'groceries': LucideIcons.shoppingCart,
    'fuel': LucideIcons.fuel,
    'insurance': LucideIcons.shield,
    'taxes': LucideIcons.receipt,
    'freelance': LucideIcons.briefcase,
    'rent': LucideIcons.building,
    'phone': LucideIcons.smartphone,
    'internet': LucideIcons.wifi,
    'charity': LucideIcons.heartHandshake,
  };

  /// All available icon keys, for display in a picker.
  static List<String> get allKeys => _map.keys.toList();

  // Legacy emoji → key mapping for existing Firestore documents.
  static const Map<String, String> _emojiFallback = {
    '🍔': 'food',
    '🚗': 'transport',
    '🛍️': 'shopping',
    '📄': 'bills',
    '🎬': 'entertainment',
    '🏥': 'health',
    '💰': 'salary',
    '📦': 'other',
  };

  /// Resolve a key to an [IconData]. Falls back to [LucideIcons.tag].
  static IconData resolve(String key) {
    // Direct key match
    final direct = _map[key.toLowerCase()];
    if (direct != null) return direct;
    // Legacy emoji match
    final legacyKey = _emojiFallback[key];
    if (legacyKey != null) return _map[legacyKey]!;
    return LucideIcons.tag;
  }

  /// Human-readable label for a key.
  static String label(String key) {
    if (key.isEmpty) return 'Other';
    return key[0].toUpperCase() + key.substring(1);
  }
}
