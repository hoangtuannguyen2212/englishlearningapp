import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tài khoản đã lưu trên máy (email + tên + có lưu mật khẩu hay không).
/// Mật khẩu nằm trong secure storage, KHÔNG bao giờ ra metadata này.
class RememberedAccount {
  const RememberedAccount({
    required this.email,
    this.displayName,
    required this.lastUsedMillis,
    this.hasStoredPassword = false,
  });

  final String email;
  final String? displayName;
  final int lastUsedMillis;
  final bool hasStoredPassword;

  String get initials {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String get shortLabel {
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email;
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'lastUsedMillis': lastUsedMillis,
      };

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    return RememberedAccount(
      email: (json['email'] as String?) ?? '',
      displayName: json['displayName'] as String?,
      lastUsedMillis: json['lastUsedMillis'] as int? ?? 0,
    );
  }

  RememberedAccount copyWith({bool? hasStoredPassword}) => RememberedAccount(
        email: email,
        displayName: displayName,
        lastUsedMillis: lastUsedMillis,
        hasStoredPassword: hasStoredPassword ?? this.hasStoredPassword,
      );
}

/// Lưu tối đa [maxAccounts] tài khoản — metadata trong SharedPreferences,
/// mật khẩu trong flutter_secure_storage (Keystore / Keychain).
class RememberAccountService {
  static const int maxAccounts = 5;

  static const String _keyList = 'remember_account_list_v2';

  // Key legacy của phiên bản 1 tài khoản.
  static const String _keyEnabledLegacy = 'remember_account_enabled';
  static const String _keyEmailLegacy = 'remember_account_email';
  static const String _keyDisplayNameLegacy = 'remember_account_display_name';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String _passwordKey(String email) =>
      'remember_account_password_${email.trim().toLowerCase()}';

  Future<List<RememberedAccount>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final raw = prefs.getString(_keyList);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final accounts = decoded
          .map(
            (item) => RememberedAccount.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((account) => account.email.trim().isNotEmpty)
          .toList();

      final result = <RememberedAccount>[];
      for (final account in accounts) {
        final has = await _hasPassword(account.email);
        result.add(account.copyWith(hasStoredPassword: has));
      }

      result.sort((a, b) => b.lastUsedMillis.compareTo(a.lastUsedMillis));
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<RememberedAccount?> loadMostRecent() async {
    final accounts = await loadAll();
    return accounts.isEmpty ? null : accounts.first;
  }

  Future<bool> _hasPassword(String email) async {
    try {
      final value = await _secure.read(key: _passwordKey(email));
      return value != null && value.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> readPassword(String email) async {
    try {
      return await _secure.read(key: _passwordKey(email));
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String email,
    String? displayName,
    String? password,
  }) =>
      upsert(email: email, displayName: displayName, password: password);

  Future<void> upsert({
    required String email,
    String? displayName,
    String? password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return;

    final normalized = trimmedEmail.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);
    final existing = await _loadMetadataOnly(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;

    RememberedAccount? previous;
    for (final account in existing) {
      if (account.email.trim().toLowerCase() == normalized) {
        previous = account;
        break;
      }
    }

    final trimmedName = displayName?.trim();
    final resolvedName = trimmedName != null && trimmedName.isNotEmpty
        ? trimmedName
        : previous?.displayName;

    final updated = <RememberedAccount>[
      RememberedAccount(
        email: trimmedEmail,
        displayName: resolvedName,
        lastUsedMillis: now,
      ),
      ...existing.where(
        (account) => account.email.trim().toLowerCase() != normalized,
      ),
    ];

    final limited = updated.take(maxAccounts).toList();
    await prefs.setString(
      _keyList,
      jsonEncode(limited.map((account) => account.toJson()).toList()),
    );

    // Mật khẩu (nếu có) lưu vào secure storage tách biệt.
    if (password != null && password.isNotEmpty) {
      try {
        await _secure.write(
          key: _passwordKey(trimmedEmail),
          value: password,
        );
      } catch (_) {
        // Bỏ qua: lần sau user vẫn nhập mật khẩu lại được.
      }
    }
  }

  Future<List<RememberedAccount>> _loadMetadataOnly(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_keyList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => RememberedAccount.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((account) => account.email.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> remove(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final remaining = (await _loadMetadataOnly(prefs))
        .where((account) => account.email.trim().toLowerCase() != normalized)
        .toList();

    if (remaining.isEmpty) {
      await prefs.remove(_keyList);
    } else {
      await prefs.setString(
        _keyList,
        jsonEncode(remaining.map((account) => account.toJson()).toList()),
      );
    }

    try {
      await _secure.delete(key: _passwordKey(email));
    } catch (_) {}
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadMetadataOnly(prefs);

    await prefs.remove(_keyList);
    await prefs.remove(_keyEnabledLegacy);
    await prefs.remove(_keyEmailLegacy);
    await prefs.remove(_keyDisplayNameLegacy);

    for (final account in accounts) {
      try {
        await _secure.delete(key: _passwordKey(account.email));
      } catch (_) {}
    }
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    if (prefs.containsKey(_keyList)) return;
    if (!(prefs.getBool(_keyEnabledLegacy) ?? false)) return;

    final email = prefs.getString(_keyEmailLegacy);
    if (email == null || email.trim().isEmpty) return;

    final legacy = RememberedAccount(
      email: email.trim(),
      displayName: prefs.getString(_keyDisplayNameLegacy),
      lastUsedMillis: DateTime.now().millisecondsSinceEpoch,
    );

    await prefs.setString(
      _keyList,
      jsonEncode([legacy.toJson()]),
    );
    await prefs.remove(_keyEnabledLegacy);
    await prefs.remove(_keyEmailLegacy);
    await prefs.remove(_keyDisplayNameLegacy);
  }
}
