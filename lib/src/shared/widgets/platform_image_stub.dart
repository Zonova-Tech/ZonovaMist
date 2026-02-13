import 'package:flutter/widgets.dart';

// Stub implementation used on platforms without dart:io (e.g., web).
// Falls back to Image.network for any path since local files aren't available on web.
Widget platformImage(
  String path, {
  bool isNetwork = false,
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (isNetwork) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  // Local file paths are not supported on web - try network as a best-effort fallback
  return Image.network(
    path,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
