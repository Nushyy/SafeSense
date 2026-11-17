import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/saps/saps_case.dart';
import '../saps_colors.dart';

/// Small map with one pin. SOS cases that are still open get a pulsing
/// "live" pin. Uses OpenStreetMap tiles (light use only; for heavy use the
/// map owner should switch to a paid or self-hosted tile source).
class CaseMap extends StatelessWidget {
  const CaseMap({super.key, required this.c});
  final SapsCase c;

  @override
  Widget build(BuildContext context) {
    final live = c.isSos && c.isOpen;
    return SizedBox(
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: c.hasLocation
            ? Stack(
                children: [
                  FlutterMap(
                    key: ValueKey('${c.id}-${c.lat}-${c.lng}'),
                    options: MapOptions(
                      initialCenter: LatLng(c.lat!, c.lng!),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'za.safesense.saps_desk',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(c.lat!, c.lng!),
                          width: 40,
                          height: 40,
                          child: _PulsePin(live: live),
                        ),
                      ]),
                    ],
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _Chip(live ? 'Live position' : 'Reported location'),
                  ),
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: _Chip('© OpenStreetMap contributors', small: true),
                  ),
                ],
              )
            : Container(
                color: SapsColors.blueTint,
                alignment: Alignment.center,
                child: const Text('No location was shared with this case.',
                    style: TextStyle(color: SapsColors.blueTintText)),
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.small = false});
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xEBFFFFFF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: small ? 11 : 12, color: SapsColors.navy)),
      );
}

class _PulsePin extends StatefulWidget {
  const _PulsePin({required this.live});
  final bool live;

  @override
  State<_PulsePin> createState() => _PulsePinState();
}

class _PulsePinState extends State<_PulsePin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _ctl.repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.live)
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, _) => Opacity(
              opacity: 1 - _ctl.value,
              child: Container(
                width: 14 + 24 * _ctl.value,
                height: 14 + 24 * _ctl.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: SapsColors.red, width: 2),
                ),
              ),
            ),
          ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: SapsColors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}
