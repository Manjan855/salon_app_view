import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _selectedCity = '';
  TextEditingController _searchController = TextEditingController();

  // List of available cities
  final List<String> _allCities = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
    'Austin',
    'Jacksonville',
    'Fort Worth',
    'Columbus',
    'Charlotte',
    'San Francisco',
    'Indianapolis',
    'Seattle',
    'Denver',
    'Washington DC',
    'Boston',
    'Nashville',
    'Baltimore',
    'Portland',
    'Las Vegas',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = _allCities;
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCities);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    setState(() {
      _filteredCities = _allCities
          .where(
            (city) => city.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  const Text(
                    'Select Your City',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search cities...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.deepPurple,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cities count
                  Text(
                    '${_filteredCities.length} cities available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),

                  const SizedBox(height: 12),

                  // Cities List
                  Expanded(
                    child: _filteredCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No cities found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple
                                      .withOpacity(0.1),
                                  child: const Icon(
                                    Icons.location_city,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  city,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: _selectedCity == city
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.deepPurple,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCity = city;
                                  });
                                  Navigator.pop(context);
                                  _showSelectedCitySnackBar(city);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectedCitySnackBar(String city) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected city: $city'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Map icon
          Center(
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.map, size: 80, color: Colors.white),
            ),
          ),

          // Main content card
          Positioned(
            top: 200,
            left: 14,
            right: 14,
            child: Container(
              height: MediaQuery.sizeOf(context).height * 0.6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Want to see the\nmost happening salons\nnear you?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "SalonCut needs to enable your location services for this",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enable Location Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          // Request location permission
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Requesting location access...'),
                            ),
                          );
                        },
                        child: const Text(
                          "Turn on your Location Services",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          indent: 24,
                          endIndent: 16,
                        ),
                      ),
                      Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          indent: 16,
                          endIndent: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Select city manually (underlined)
                  GestureDetector(
                    onTap: _showCitySelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _selectedCity.isEmpty
                            ? "Select city manually"
                            : "Selected: $_selectedCity",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedCity.isEmpty
                              ? Colors.deepPurple
                              : Colors.green,
                          decoration: _selectedCity.isEmpty
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Show selected city
                  if (_selectedCity.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Showing salons in $_selectedCity',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
