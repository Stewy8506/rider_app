import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Place {
  final String name;
  final String placeId;
  final LatLng latLng;

  Place({
    required this.name,
    required this.placeId,
    required this.latLng,
  });
}

class PlacesService {
  late final String apiKey;

  PlacesService() {
    apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// Search places using autocomplete API
  Future<List<Place>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
    int? radius,
  }) async {
    if (query.isEmpty) return [];

    final locationParam = (lat != null && lng != null)
        ? '&location=$lat,$lng&radius=${radius ?? 30000}'
        : '';

    final strictBoundsParam = (lat != null && lng != null) ? '&strictbounds=true' : '';

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query$locationParam$strictBoundsParam&components=country:in&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') return [];

    final predictions = data['predictions'] as List;

    return predictions.map((p) {
      return Place(
        name: p['description'],
        placeId: p['place_id'],
        latLng: const LatLng(0, 0), // placeholder (resolved later)
      );
    }).toList();
  }

  /// Get coordinates from placeId
  Future<LatLng?> getPlaceCoordinates(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') return null;

    final location =
        data['result']['geometry']['location'];

    return LatLng(
      location['lat'],
      location['lng'],
    );
  }

  /// Convenience: full place with coordinates
  Future<Place?> getPlaceDetails(Place place) async {
    final coords = await getPlaceCoordinates(place.placeId);

    if (coords == null) return null;

    return Place(
      name: place.name,
      placeId: place.placeId,
      latLng: coords,
    );
  }
}