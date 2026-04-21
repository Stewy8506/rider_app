import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'map_view_model.dart';
import '../Navigation/navigation_controller.dart';
import '../../core/models/navigation_state.dart';
import 'widgets/search_bar.dart';
import 'Widgets/search_view_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  bool _isCameraStableDriveView = false;

  Future<void> _fitCameraToRoute(NavigationState state) async {
    if (_mapController == null || state.route == null) return;

    final points = state.route!.polyline
        .map((p) => LatLng(p[0], p[1]))
        .toList();

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  Future<void> _followUser(NavigationState nav) async {
    if (_mapController == null || nav.currentPosition == null) return;

    final pos = nav.currentPosition!;
    final bearing = pos.heading == 0 ? 45.0 : pos.heading;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 19.5,
          tilt: 0, // Real top-down view requested by user
          bearing: bearing,
        ),
      ),
    );

    // Only boldly thicken the polyline AFTER the camera has arrived in driving mode
    if (mounted && !_isCameraStableDriveView) {
      setState(() {
        _isCameraStableDriveView = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<MapViewModel>();

      // Request location permission first
      PermissionStatus status = await Permission.location.request();

      if (!mounted) return;

      if (status.isGranted) {
        vm.fetchCurrentLocation();
      } else {
        debugPrint("Location permission denied");
      }
      // Listen to navigation state for smooth camera follow
      final navController = context.read<NavigationController>();
      navController.addListener(() {
        if (navController.state.status == NavigationStatus.navigating) {
          _followUser(navController.state);
        } else {
          if (mounted && _isCameraStableDriveView) {
            setState(() {
              _isCameraStableDriveView = false;
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final nav = context.watch<NavigationController>().state;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nav.status == NavigationStatus.preview) {
        _fitCameraToRoute(nav);
      }
    });

    return Scaffold(
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.currentPosition == null
          ? const Center(child: Text("Location unavailable"))
          : Stack(
              children: [
                GoogleMap(
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  onTap: (_) {
                    FocusScope.of(context).unfocus();
                    context.read<SearchViewModel>().clearSearch();
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      vm.currentPosition!.latitude,
                      vm.currentPosition!.longitude,
                    ),
                    zoom: 15,
                  ),
                  padding: nav.status == NavigationStatus.navigating
                      ? EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.45,
                          bottom: MediaQuery.of(context).size.height * 0.15,
                        )
                      : const EdgeInsets.only(top: 140, bottom: 100),
                  myLocationEnabled: true,
                  polylines: _buildPolylines(nav),
                  onMapCreated: (controller) async {
                    _mapController = controller;

                    // Move camera to user location smoothly
                    final vm = context.read<MapViewModel>();
                    if (vm.currentPosition != null) {
                      await _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            vm.currentPosition!.latitude,
                            vm.currentPosition!.longitude,
                          ),
                          16,
                        ),
                      );
                    }
                  },
                ),

                /// 🎨 Top fade overlay (depth effect)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// ↕️ Animated Top Overlay (Search / Instructions)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: nav.status == NavigationStatus.idle
                        ? const SafeArea(
                            key: ValueKey("search_bar"),
                            child: SearchBarWidget(),
                          )
                        : nav.status == NavigationStatus.navigating
                            ? SafeArea(
                                key: const ValueKey("directions_box"),
                                child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: nav.isRerouting
                                    ? Colors.redAccent.withAlpha(220)
                                    : Colors.black.withAlpha(200),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: nav.isRerouting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Text(
                                          "Rerouting...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        const Icon(
                                          Icons.directions,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            nav.currentStep?.instruction ??
                                                "Proceed to route",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey("preview_spacer")),
                  ),
                ),

                /// 🔘 Start / Cancel Navigation Buttons
                if (nav.status == NavigationStatus.preview)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: SizedBox(
                      height: 55,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              onPressed: () {
                                context.read<NavigationController>().stopNavigation();
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white, // Ensure text is visible
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              onPressed: () {
                                final vm = context.read<MapViewModel>();
                                // trigger map view model start
                                final navCtrl = context.read<NavigationController>();
                                if (navCtrl.state.route != null) {
                                  navCtrl.startNavigation();
                                }
                              },
                              child: const Text(
                                "Start Navigation",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                /// 🧭 Navigation Bottom Panel
                if (nav.status == NavigationStatus.navigating)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildNavigationPanel(nav),
                  ),
              ],
            ),
    );
  }

  Set<Polyline> _buildPolylines(NavigationState state) {
    if (state.route == null) return {};

    List<LatLng> points = [];

    if (state.status == NavigationStatus.navigating &&
        state.snappedPosition != null &&
        state.currentSegmentIndex != null) {
      // Connect current car position straight to the next coordinate on the path
      points.add(state.snappedPosition!);
      for (
        int i = state.currentSegmentIndex! + 1;
        i < state.route!.polyline.length;
        i++
      ) {
        points.add(
          LatLng(state.route!.polyline[i][0], state.route!.polyline[i][1]),
        );
      }
    } else {
      points = state.route!.polyline.map((p) => LatLng(p[0], p[1])).toList();
    }

    return {
      Polyline(
        polylineId: const PolylineId("route"),
        points: points,
        width:
            (state.status == NavigationStatus.navigating &&
                _isCameraStableDriveView)
            ? 14
            : 6,
        color: Colors.blueAccent,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic:
            true, // Forces smooth earth-curve rendering for long straightaways
      ),
    };
  }

  Widget _buildNavigationPanel(NavigationState nav) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: nav.progress,
            minHeight: 4,
            backgroundColor: Colors.white12,
          ),

          const SizedBox(height: 12),

          // Distance + ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${((nav.remainingDistance ?? 0) / 1000).toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "${((nav.eta?.inSeconds ?? 0) / 60).round()} min",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stop button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                context.read<NavigationController>().stopNavigation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Stop Navigation",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
