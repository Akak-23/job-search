import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geocoding_service.dart';

/// Dialog to show job location on a map
class JobLocationMapDialog extends StatefulWidget {
  final Map<String, String> locationData;

  const JobLocationMapDialog({super.key, required this.locationData});

  @override
  State<JobLocationMapDialog> createState() => _JobLocationMapDialogState();
}

class _JobLocationMapDialogState extends State<JobLocationMapDialog> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();

  LatLng? _center;
  bool _isLoading = true;
  String? _errorMessage;

  bool _hasValue(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return false;
    return cleaned.toLowerCase() != 'null';
  }

  String? _cleanValue(String? value) => _hasValue(value) ? value!.trim() : null;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _buildSearchQuery() {
    final parts = <String>[];

    final street = _cleanValue(widget.locationData['arbeitsort_strasse']);
    final plz = _cleanValue(widget.locationData['arbeitsort_plz']);
    final city = _cleanValue(widget.locationData['arbeitsort_ort']);
    final region = _cleanValue(widget.locationData['arbeitsort_region']);
    final country = _cleanValue(widget.locationData['arbeitsort_land']);

    if (_hasValue(street)) {
      parts.add(street!);
    }
    if (_hasValue(plz)) {
      parts.add(plz!);
    }
    if (_hasValue(city)) {
      parts.add(city!);
    }
    if (_hasValue(region)) {
      parts.add(region!);
    }
    if (_hasValue(country)) {
      parts.add(country!);
    }

    return parts.join(', ');
  }

  String _getDisplayLocation() {
    final ort = _cleanValue(widget.locationData['arbeitsort_ort']);
    final region = _cleanValue(widget.locationData['arbeitsort_region']);

    if (_hasValue(ort)) {
      if (_hasValue(region)) {
        return '$ort, $region';
      }
      return ort!;
    }

    return _buildSearchQuery();
  }

  Future<void> _loadLocation() async {
    try {
      // Try different search strategies with fallbacks
      LatLng? coordinates;
      double zoom = 14.0;

      // Strategy 1: Full address with street
      final fullQuery = _buildSearchQuery();
      if (fullQuery.isNotEmpty) {
        coordinates = await _geocodingService.searchLocation(fullQuery);
      }
    
      // Strategy 2: Without street (PLZ + City + Region + Country)
      if (coordinates == null) {
        final parts = <String>[];
        if (_hasValue(widget.locationData['arbeitsort_plz'])) {
          parts.add(widget.locationData['arbeitsort_plz']!);
        }
        if (_hasValue(widget.locationData['arbeitsort_ort'])) {
          parts.add(widget.locationData['arbeitsort_ort']!);
        }
        if (_hasValue(widget.locationData['arbeitsort_region'])) {
          parts.add(widget.locationData['arbeitsort_region']!);
        }
        if (_hasValue(widget.locationData['arbeitsort_land'])) {
          parts.add(widget.locationData['arbeitsort_land']!);
        }
        if (parts.isNotEmpty) {
          coordinates = await _geocodingService.searchLocation(
            parts.join(', '),
          );
          zoom = 13.0;
        }
      }

      // Strategy 3: City + Country only
      if (coordinates == null) {
        final parts = <String>[];
        if (_hasValue(widget.locationData['arbeitsort_ort'])) {
          parts.add(widget.locationData['arbeitsort_ort']!);
        }
        if (_hasValue(widget.locationData['arbeitsort_land'])) {
          parts.add(widget.locationData['arbeitsort_land']!);
        }
        if (parts.isNotEmpty) {
          coordinates = await _geocodingService.searchLocation(
            parts.join(', '),
          );
          zoom = 11.0;
        }
      }

      // Strategy 4: City or Region only
      if (coordinates == null) {
        final city = _cleanValue(widget.locationData['arbeitsort_ort']);
        final region = _cleanValue(widget.locationData['arbeitsort_region']);

        if (_hasValue(city)) {
          coordinates = await _geocodingService.searchLocation(city!);
          zoom = 11.0;
        } else if (_hasValue(region)) {
          coordinates = await _geocodingService.searchLocation(region!);
          zoom = 10.0;
        }
      }

      if (coordinates != null && mounted) {
        setState(() {
          _center = coordinates;
          _isLoading = false;
        });

        // Move to location after the map is rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(coordinates!, zoom);
          }
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location could not be found on the map';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading location: $e';
        });
      }
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.only(
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
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDisplayLocation(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // Map content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2196F3)),
                          SizedBox(height: 16),
                          Text(
                            'Loading location...',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _center == null
                  ? const Center(
                      child: Text(
                        'Location not available',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(20),
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
                          initialCenter: _center!,
                          initialZoom: 14.0,
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
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center!,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2196F3),
                                        Color(0xFF1976D2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2196F3,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.work_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),

            // Footer with address details
            if (!_isLoading && _errorMessage == null && _center != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildAddressDetails(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddressDetails() {
    final details = <Widget>[];

    final street = _cleanValue(widget.locationData['arbeitsort_strasse']);
    final plz = _cleanValue(widget.locationData['arbeitsort_plz']);
    final city = _cleanValue(widget.locationData['arbeitsort_ort']);
    final region = _cleanValue(widget.locationData['arbeitsort_region']);
    final country = _cleanValue(widget.locationData['arbeitsort_land']);

    final addressParts = [
      if (_hasValue(street))
        {
          'icon': Icons.signpost_outlined,
          'label': 'Street',
          'value': street!,
        },
      if (_hasValue(plz))
        {
          'icon': Icons.mail_outline,
          'label': 'Postal Code',
          'value': plz!,
        },
      if (_hasValue(city))
        {
          'icon': Icons.location_city_outlined,
          'label': 'City',
          'value': city!,
        },
      if (_hasValue(region))
        {
          'icon': Icons.map_outlined,
          'label': 'Region',
          'value': region!,
        },
      if (_hasValue(country))
        {
          'icon': Icons.public_outlined,
          'label': 'Country',
          'value': country!,
        },
    ];

    for (final part in addressParts) {
      details.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(part['icon'] as IconData, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '${part['label']}:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  part['value'] as String,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return details;
  }
}
