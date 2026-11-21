import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';

/// Asks in the app first, then asks the device for permission.
class DeviceLocation {
  const DeviceLocation._();

  static Future<LatLng?> ask(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.locationTitle),
          content: Text(l10n.locationBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.notNow)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.allowLocation)),
          ],
        );
      },
    );
    if (allow != true || !context.mounted) return null;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
