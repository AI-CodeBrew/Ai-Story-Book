/// Local stand-in for the original `api_key_pool` git package
/// (https://github.com/IzzaTech-Hub/Api-Keys-Config-Package), whose
/// repository is no longer reachable. Keeps the same API surface the
/// app calls (`init`, `initialize`, `allKeys`, `getKey`) but never
/// resolves any keys — callers already treat an empty pool as "use
/// the backend's own fallback key", so this is a safe no-op source.
class ApiKeyPool {
  static final List<String> allKeys = [];

  static Future<void> init(String appName) async {}

  static Future<void> initialize() async {}

  static String getKey() {
    if (allKeys.isEmpty) {
      throw StateError('No API keys available in ApiKeyPool');
    }
    return allKeys.first;
  }
}
