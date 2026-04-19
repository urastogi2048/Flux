import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';

class TaskMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final void Function(Map<String, dynamic>)? onMarkerTap;

  const TaskMapWidget({
    super.key,
    required this.tasks,
    this.onMarkerTap,
  });

  @override
  State<TaskMapWidget> createState() => _TaskMapWidgetState();
}

class _TaskMapWidgetState extends State<TaskMapWidget> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = true;
  LatLng _centerPoint = GeocodingService.getIndiaCenter();
  
  // Cache to store already geocoded locations
  static final Map<String, LatLng> _geocodeCache = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    try {
      print('[TaskMapWidget] Loading markers for ${widget.tasks.length} tasks');
      List<Marker> markers = [];
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

      for (int i = 0; i < widget.tasks.length; i++) {
        final task = widget.tasks[i];
        final location = task['location'] ?? '';
        final title = task['title'] ?? 'Untitled Task';
        final status = (task['status'] ?? 'ASSIGNED').toString().toUpperCase();

        print('[TaskMapWidget] Task: $title | Location: "$location" | Status: $status');

        if (location.isEmpty) {
          print('[TaskMapWidget] ⚠️ Skipping task - empty location');
          continue;
        }

        // Check cache first
        LatLng coordinates;
        if (_geocodeCache.containsKey(location)) {
          coordinates = _geocodeCache[location]!;
          print('[TaskMapWidget] ⚡ Got from cache: $location -> ${coordinates.latitude}, ${coordinates.longitude}');
        } else {
          // Add delay between requests to avoid rate limiting (500ms per request)
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          coordinates = await GeocodingService.getCoordinatesFromLocation(location);
          _geocodeCache[location] = coordinates; // Store in cache
          print('[TaskMapWidget] ✓ Geocoded "$location" -> ${coordinates.latitude}, ${coordinates.longitude}');
        }
        
        // Track bounds for centering
        minLat = coordinates.latitude < minLat ? coordinates.latitude : minLat;
        maxLat = coordinates.latitude > maxLat ? coordinates.latitude : maxLat;
        minLng = coordinates.longitude < minLng ? coordinates.longitude : minLng;
        maxLng = coordinates.longitude > maxLng ? coordinates.longitude : maxLng;

        // Determine marker color based on status
        Color markerColor = const Color(0xFFCDE8FF); // Sky - ASSIGNED
        if (status == 'IN PROGRESS') {
          markerColor = const Color(0xFFFFD700); // Yellow
        } else if (status == 'COMPLETED') {
          markerColor = const Color(0xFF1B8A4A); // Green
        } else if (status == 'REJECTED') {
          markerColor = const Color(0xFFE53935); // Red
        }

        final marker = Marker(
          point: coordinates,
          width: 80,
          height: 90,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              widget.onMarkerTap?.call(task);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title - $status'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF002B9A),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: status == 'COMPLETED'
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${widget.tasks.indexOf(task) + 1}',
                            style: const TextStyle(
                              color: Color(0xFF002B9A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: markerColor, width: 1),
                  ),
                  child: Text(
                    title.length > 15 ? '${title.substring(0, 12)}...' : title,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B9A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );

        markers.add(marker);
      }

      print('[TaskMapWidget] Created ${markers.length} markers from ${widget.tasks.length} tasks');

      setState(() {
        _markers = markers;
        _isLoading = false;

        // Center map on all markers
        if (minLat != 90 && maxLat != -90 && minLng != 180 && maxLng != -180) {
          _centerPoint = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
          
          // Fit bounds with padding
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(
                LatLng(minLat, minLng),
                LatLng(maxLat, maxLng),
              ),
              padding: const EdgeInsets.all(100),
            ),
          );
        }
      });
    } catch (e) {
      print('[TaskMapWidget] Error loading markers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant TaskMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerPoint,
            initialZoom: GeocodingService.getIndiaZoomLevel(),
            maxZoom: 18,
            minZoom: 2,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxZoom: 19,
              minZoom: 1,
              retinaMode: true,
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (widget.tasks.isEmpty && !_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Tasks Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B9A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create tasks to see them on the map',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
