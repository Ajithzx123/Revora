import '../config/app_config.dart';

/// The API returns photo paths like `/api/media/<id>`; this makes them absolute
/// against whichever server the app is talking to.
String resolveMediaUrl(String path) {
  if (path.startsWith('http')) return path;
  final base = Uri.parse(AppConfig.instance.baseUrl);
  return base.replace(path: path, query: null).toString();
}
