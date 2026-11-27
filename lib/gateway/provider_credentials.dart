import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ProviderCredentials {
  Future<String?> read(String id);
  Future<void> write(String id, String value);
  Future<void> delete(String id);
}

class SecureProviderCredentials implements ProviderCredentials {
  const SecureProviderCredentials();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  );

  String _key(String id) => 'magpie.upstream.$id';

  @override
  Future<String?> read(String id) => _storage.read(key: _key(id));

  @override
  Future<void> write(String id, String value) =>
      _storage.write(key: _key(id), value: value);

  @override
  Future<void> delete(String id) => _storage.delete(key: _key(id));
}
