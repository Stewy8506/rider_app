import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/services/places_service.dart';

class SearchViewModel extends ChangeNotifier {
  final PlacesService placesService;

  SearchViewModel(this.placesService);

  List<Place> results = [];
  bool isLoading = false;

  final TextEditingController textController = TextEditingController();
  Timer? _debounce;

  String? currentCityName;
  double? currentLat;
  double? currentLng;

  Future<void> setCurrentLocation({required double lat, required double lng}) async {
    currentLat = lat;
    currentLng = lng;
  }

  bool _isExplicitCitySearch(String query) {
    final q = query.toLowerCase();
    return q.contains(",") || q.split(" ").length > 2;
  }

  /// Called on every text change
  void onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.isEmpty) {
      results = [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      search(query);
    });
  }

  /// Calls API
  Future<void> search(String query) async {
    try {
      isLoading = true;
      notifyListeners();

      final explicit = _isExplicitCitySearch(query);

      final res = await placesService.searchPlaces(
        query,
        lat: explicit ? null : currentLat,
        lng: explicit ? null : currentLng,
        radius: explicit ? null : 30000,
      );

      if (!explicit && currentCityName != null) {
        results = res.where((place) {
          final name = place.name.toLowerCase();
          return name.contains(currentCityName!);
        }).toList();
      } else {
        results = res;
      }
    } catch (e) {
      results = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Resolve full place (with coordinates)
  Future<Place?> selectPlace(Place place) async {
    try {
      isLoading = true;
      notifyListeners();

      final fullPlace = await placesService.getPlaceDetails(place);
      return fullPlace;
    } catch (e) {
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void collapseSearch() {
    results = [];
    notifyListeners();
  }

  void clearSearch() {
    textController.clear();
    results = [];
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
