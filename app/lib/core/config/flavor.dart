/// Build flavor of the app. Set once at startup by main_dev.dart or main_prod.dart.
enum Flavor { dev, prod }

class FlavorConfig {
  FlavorConfig._(this.flavor, this.appName);

  final Flavor flavor;
  final String appName;

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('FlavorConfig.init() was not called.');
    }
    return config;
  }

  static void init(Flavor flavor) {
    _instance = FlavorConfig._(
      flavor,
      flavor == Flavor.dev ? 'CashFlow Dev' : 'CashFlow',
    );
  }

  bool get isDev => flavor == Flavor.dev;
}
