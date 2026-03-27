import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_strings.dart';
import '../../services/geocoding_service.dart';

/// Widget for location and radius dialog with interactive map
class LocationRadiusDialog extends StatefulWidget {
  final String initialLocation;
  final double initialRadius;

  const LocationRadiusDialog({
    super.key,
    required this.initialLocation,
    required this.initialRadius,
  });

  @override
  State<LocationRadiusDialog> createState() => _LocationRadiusDialogState();
}

class _LocationRadiusDialogState extends State<LocationRadiusDialog> {
  late final TextEditingController controller;
  late double tempUmkreis;
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();

  LatLng _center = const LatLng(51.1657, 10.4515); // Germany center
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialLocation);
    tempUmkreis = widget.initialRadius;

    // If we have an initial location, search for it
    if (widget.initialLocation.isNotEmpty) {
      _searchLocation();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    if (controller.text.trim().isEmpty) return;

    setState(() => _isSearching = true);

    final coordinates = await _geocodingService.searchLocation(controller.text);

    if (coordinates != null && mounted) {
      setState(() {
        _center = coordinates;
        _hasSearched = true;
        _isSearching = false;
      });

      // Animate to the new location
      _mapController.move(_center, 11.0);
    } else if (mounted) {
      setState(() => _isSearching = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not found. Please try a different search.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _center = position;
      _hasSearched = true;
      _isSearching = true;
    });

    // Try to reverse geocode to get location name
    final locationName = await _geocodingService.reverseGeocode(position);

    if (locationName != null && mounted) {
      setState(() {
        controller.text = locationName;
        _isSearching = false;
      });
    } else if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search or tap on the map',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'e.g. Berlin, Munich, Hamburg',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _searchLocation(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: _searchLocation,
                            tooltip: 'Search location',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Radius slider
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Search Radius',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${tempUmkreis.toInt()} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: tempUmkreis,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            activeColor: const Color(0xFF6366F1),
                            label: '${tempUmkreis.toInt()} km',
                            onChanged: (v) => setState(() => tempUmkreis = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Map
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center,
                            initialZoom: _hasSearched ? 11.0 : 6.0,
                            onTap: _onMapTapped,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.job_search',
                              maxZoom: 19,
                            ),
                            if (_hasSearched) ...[
                              // Radius circle
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _center,
                                    radius:
                                        tempUmkreis *
                                        1000, // Convert km to meters
                                    useRadiusInMeter: true,
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.15),
                                    borderColor: const Color(0xFF6366F1),
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                              // Center marker
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _center,
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop({ort: controller.text, 'umkreis': tempUmkreis});
  }
}
