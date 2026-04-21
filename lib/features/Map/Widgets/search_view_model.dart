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

      final res = await placesService.searchPlaces(query);
      results = res;
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
