// import 'package:flutter/material.dart';
// import '../models/salon_model.dart';
// import '../models/service_model.dart';

// class SalonProvider extends ChangeNotifier {
//   List<SalonModel> _salons = [];
//   List<ServiceModel> _services = [];
//   bool _isLoading = false;
//   String? _error;

//   List<SalonModel> get salons => _salons;
//   List<ServiceModel> get services => _services;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   // Fetch all salons
//   Future<void> fetchSalons() async {
//     _setLoading(true);
//     _clearError();

//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 1));

//       // Load sample data
//       _salons = SalonModel.getSampleSalons();

//       _setLoading(false);
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//     }
//   }

//   // Fetch salons by category
//   Future<void> fetchSalonsByCategory(String category) async {
//     _setLoading(true);

//     try {
//       await Future.delayed(const Duration(milliseconds: 500));

//       // Filter salons by category
//       _salons = SalonModel.getSampleSalons()
//           .where((salon) => salon.services.contains(category))
//           .toList();

//       _setLoading(false);
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//     }
//   }

//   // Fetch services by salon
//   Future<void> fetchServicesBySalon(String salonId) async {
//     _setLoading(true);

//     try {
//       await Future.delayed(const Duration(milliseconds: 500));

//       _services = ServiceModel.getSampleServices();

//       _setLoading(false);
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//     }
//   }

//   // Get salon by ID
//   SalonModel? getSalonById(String id) {
//     try {
//       return _salons.firstWhere((salon) => salon.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Search salons
//   List<SalonModel> searchSalons(String query) {
//     if (query.isEmpty) return _salons;

//     return _salons.where((salon) {
//       return salon.name.toLowerCase().contains(query.toLowerCase()) ||
//           salon.address.toLowerCase().contains(query.toLowerCase());
//     }).toList();
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   void _clearError() {
//     _error = null;
//   }
// }
import 'package:flutter/material.dart';
import 'package:salon_app_view/repositories/salon_repositories.dart';

import '../models/salon_model.dart';

class SalonProvider with ChangeNotifier {
  final SalonRepository _salonRepo = SalonRepository();

  List<SalonModel> _salons = [];
  bool _isLoading = false;

  /// salon id → set of service genders ('men' | 'women' | 'unisex').
  /// Populated by [fetchSalonGenders]; never throws (missing/migrated column
  /// degrades to an empty map, i.e. "everything is unisex").
  Map<String, Set<String>> _gendersBySalon = {};

  List<SalonModel> get salons => _salons;
  bool get isLoading => _isLoading;

  /// Gender facets for the Explore filter. Empty until loaded (or when the
  /// `services.gender` column is not yet deployed).
  Map<String, Set<String>> get gendersBySalon => _gendersBySalon;

  Future<void> fetchSalons() async {
    _isLoading = true;
    notifyListeners();

    try {
      _salons = await _salonRepo.getAllSalons();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Independent of the salon list; loads in parallel with the UI already
    // rendering the unfiltered list.
    await fetchSalonGenders();
  }

  Future<void> fetchSalonGenders() async {
    try {
      _gendersBySalon = await _salonRepo.getSalonGenders();
    } catch (e) {
      // e.g. `services.gender` does not exist yet (migration not applied):
      // keep the app usable, the Gender filter just shows Unisex salons.
      debugPrint('Gender facets unavailable: $e');
      _gendersBySalon = {};
    }
    notifyListeners();
  }
}
