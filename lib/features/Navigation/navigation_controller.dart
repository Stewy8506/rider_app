import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/models/navigation_state.dart';
import '../../core/services/navigation_service.dart';
import 'navigation_repository.dart';

class NavigationController extends ChangeNotifier {
  final NavigationRepository repository;

  NavigationState _state = NavigationState.initial();
  NavigationState get state => _state;

  bool _isRerouting = false;

  StreamSubscription<NavigationUpdate>? _navSub;

  NavigationController(this.repository);

  /// Set destination from LatLng (used by search)
  Future<void> setDestination({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    await previewRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }

  /// Preview route (before starting navigation)
  Future<void> previewRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final route = await repository.getRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    _state = NavigationState(
      status: NavigationStatus.preview,
      route: route,
      remainingDistance: route.distance,
      eta: route.durationTime,
      progress: 0.0,
    );

    notifyListeners();
  }

  /// Start navigation
  Future<void> startNavigation() async {
    if (_state.route == null) return;

    // 🔥 Immediately update UI state (this was missing)
    _state = _state.copyWith(
      status: NavigationStatus.navigating,
      progress: _state.progress,
    );
    notifyListeners();

    await repository.startLocation();
    repository.startNavigation(_state.route!);

    _navSub = repository.navigationStream.listen((update) async {
      if (update.isOffRoute) {
        if (!_isRerouting &&
            _state.route != null &&
            _state.route!.polyline.isNotEmpty) {
          _isRerouting = true;
          _state = _state.copyWith(isRerouting: true);
          notifyListeners();

          final endPoint = _state.route!.polyline.last;
          try {
            final newRoute = await repository.getRoute(
              startLat: update.position.latitude,
              startLng: update.position.longitude,
              endLat: endPoint[0],
              endLng: endPoint[1],
            );
            // This cleanly overwrites the route in NavigationService
            repository.startNavigation(newRoute);

            // Update UI state with new route
            _state = _state.copyWith(route: newRoute);
          } catch (e) {
            debugPrint("Reroute failed: $e");
          } finally {
            _isRerouting = false;
            _state = _state.copyWith(isRerouting: false);
            notifyListeners();
          }
        }
        return; // Skip standard updates while off route
      }

      final total = _state.route?.distance ?? 1;

      final progress = 1 - (update.remainingDistance / total);

      _state = _state.copyWith(
        status: NavigationStatus.navigating,
        remainingDistance: update.remainingDistance,
        eta: update.eta,
        progress: progress.clamp(0.0, 1.0),
        isRerouting: false,
        currentPosition: update.position,
        snappedPosition: update.snappedPosition,
        currentStep: update.currentStep,
        currentSegmentIndex: update.currentSegmentIndex,
      );

      notifyListeners();
    });
  }

  /// Stop navigation
  void stopNavigation() {
    _navSub?.cancel();
    repository.stopNavigation();
    repository.stopLocation();

    _state = NavigationState.initial();
    notifyListeners();
  }

  /// Pause navigation (optional)
  void pauseNavigation() {
    _navSub?.pause();

    _state = _state.copyWith(
      status: NavigationStatus.paused,
      progress: _state.progress,
    );

    notifyListeners();
  }

  /// Resume navigation
  void resumeNavigation() {
    _navSub?.resume();

    _state = _state.copyWith(
      status: NavigationStatus.navigating,
      progress: _state.progress,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _navSub?.cancel();
    repository.dispose();
    super.dispose();
  }
}
