import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// App entry point — sets up the database before launching the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const CampusBitesApp());
}

// Root widget — sets the app theme and starting screen
class CampusBitesApp extends StatelessWidget {
  const CampusBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusBites',
      // App-wide green theme with rounded card style
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Handles saving and loading the weekly budget using local device storage
class AppSettings {
  static const String weeklyBudgetKey = 'weekly_budget';

  // Gets the saved budget, defaults to $100 if not set
  static Future<double> getWeeklyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(weeklyBudgetKey) ?? 100.0;
  }

  // Saves the user's weekly budget to local storage
  static Future<void> setWeeklyBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(weeklyBudgetKey, amount);
  }
}

// ================= SHARED WIDGETS =================

// Reusable bold section title used across multiple screens
class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// Reusable empty state widget shown when a list has no items
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SPLASH SCREEN =================

// First screen shown when the app opens — waits 2 seconds then goes to dashboard
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 2 seconds then navigate to the home dashboard
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        // Green gradient background for the splash screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 96, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'CampusBites',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Smart Food & Budget Tracker',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 10),
            // Tagline shown below subtitle
            Text(
              'Eat smart. Spend less.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ================= HOME DASHBOARD =================

// Main screen showing budget summary, quick actions, and a restaurant recommendation
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  double _weeklyBudget = 100.0;
  double _totalSpent = 0.0;

  // Stores the recommended restaurant to display on the dashboard
  Map<String, dynamic>? _recommendation;

  // Loads the most affordable restaurant from the database as a recommendation
  Future<void> _loadRecommendation() async {
    final restaurants = await DatabaseHelper.instance.getRestaurants();
    if (restaurants.isEmpty) return;

    // Filter for budget-friendly options first, fallback to first available
    final affordable = restaurants.where((r) => r['price'] == '\$').toList();
    final pick = affordable.isNotEmpty ? affordable.first : restaurants.first;

    if (!mounted) return;
    setState(() {
      _recommendation = pick;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadRecommendation(); // Load recommendation when dashboard opens
  }

  // Loads the budget and total spending from storage and database
  Future<void> _loadDashboardData() async {
    final budget = await AppSettings.getWeeklyBudget();
    final total = await DatabaseHelper.instance.getTotalExpenses();

    if (!mounted) return;
    setState(() {
      _weeklyBudget = budget;
      _totalSpent = total;
    });
  }

  // Opens settings screen then refreshes dashboard data when returning
  Future<void> _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate money left and progress bar ratio
    final remaining = _weeklyBudget - _totalSpent;
    final ratio =
        _weeklyBudget > 0 ? (_totalSpent / _weeklyBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusBites'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _goToSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      // Pull down to refresh the dashboard
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Budget summary card showing spent vs total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weekly Budget"),
                  const SizedBox(height: 8),
                  Text(
                    "\$${_totalSpent.toStringAsFixed(2)} / \$${_weeklyBudget.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Progress bar fills as spending increases
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
=======
                    // Turns red when over 80% of budget is used
>>>>>>> 887bc7f (Finalize comments update)
                    color: ratio >= 0.8 ? Colors.red : Colors.green,
                    backgroundColor: Colors.green.shade100,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remaining >= 0
                        ? "Remaining: \$${remaining.toStringAsFixed(2)}"
                        : "Over budget by \$${remaining.abs().toStringAsFixed(2)}",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle("Quick Actions"),
            const SizedBox(height: 12),
            // Row of buttons to navigate to main app sections
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  context,
                  Icons.restaurant,
                  "Food",
                  const FoodListScreen(),
                ),
                _buildActionButton(
                  context,
                  Icons.favorite,
                  "Favorites",
                  const FavoritesScreen(),
                ),
                _buildActionButton(
                  context,
                  Icons.attach_money,
                  "Budget",
                  const BudgetTrackerScreen(),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionTitle("Recommended for You"),
            const SizedBox(height: 12),
<<<<<<< HEAD
=======
            // Show dynamic recommendation or fallback message if none available
>>>>>>> 887bc7f (Finalize comments update)
            _recommendation == null
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No restaurants available yet.'),
                    ),
                  )
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
<<<<<<< HEAD
=======
                          // Icon container for the recommendation card
>>>>>>> 887bc7f (Finalize comments update)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_dining,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _recommendation!['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_recommendation!['price']} • ${_recommendation!['type']}',
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Recommended because it is a budget-friendly option that fits your weekly spending goal.',
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
      ),
    );
  }

  // Builds a tappable icon button that navigates to a given screen
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ================= FOOD LIST =================

// Shows all restaurants with search and filter options
class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;
  String _searchText = '';
  String _selectedType = 'All';
  String _selectedPrice = 'All';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  // Fetches all restaurants from the database
  void _loadRestaurants() {
    _restaurantsFuture = DatabaseHelper.instance.getRestaurants();
  }

  // Triggers a fresh load and rebuilds the list
  void _refreshRestaurants() {
    setState(() {
      _loadRestaurants();
    });
  }

  // Opens the add restaurant screen, then refreshes the list
  Future<void> _goToAddRestaurant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRestaurantScreen()),
    );
    _refreshRestaurants();
  }

  // Opens the edit screen with the selected restaurant's existing data
  Future<void> _goToEditRestaurant(Map<String, dynamic> restaurant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRestaurantScreen(existingData: restaurant),
      ),
    );
    _refreshRestaurants();
  }

  // Deletes a restaurant from the database and refreshes the list
  Future<void> _deleteRestaurant(Map<String, dynamic> restaurant) async {
    await DatabaseHelper.instance.deleteRestaurant(restaurant['id']);
    _refreshRestaurants();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${restaurant['name']} deleted')),
    );
  }

  // Filters the restaurant list by search text, cuisine type, and price
  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> restaurants,
  ) {
    return restaurants.where((restaurant) {
      final matchesSearch = restaurant['name']
          .toString()
          .toLowerCase()
          .contains(_searchText.toLowerCase());

      final matchesType = _selectedType == 'All' ||
          restaurant['type'].toString() == _selectedType;

      final matchesPrice = _selectedPrice == 'All' ||
          restaurant['price'].toString() == _selectedPrice;

      return matchesSearch && matchesType && matchesPrice;
    }).toList();
  }

  // Pulls unique cuisine types from the list to populate the filter dropdown
  List<String> _extractTypes(List<Map<String, dynamic>> restaurants) {
    final types = restaurants.map((r) => r['type'].toString()).toSet().toList();
    types.sort();
    return ['All', ...types];
  }

  // Builds the search bar and cuisine/price filter dropdowns
  Widget _buildFilterSection(List<Map<String, dynamic>> restaurants) {
    final typeOptions = _extractTypes(restaurants);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Search bar filters list as user types
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search restaurants',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Cuisine type filter dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: typeOptions.contains(_selectedType)
                      ? _selectedType
                      : 'All',
                  decoration: const InputDecoration(
                    labelText: 'Cuisine',
                    border: OutlineInputBorder(),
                  ),
                  items: typeOptions
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Price range filter dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPrice,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: '\$', child: Text('\$')),
                    DropdownMenuItem(value: '\$\$', child: Text('\$\$')),
                    DropdownMenuItem(value: '\$\$\$', child: Text('\$\$\$')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPrice = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food List'),
        actions: [
          IconButton(
            onPressed: _goToAddRestaurant,
            icon: const Icon(Icons.add),
            tooltip: 'Add Restaurant',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading restaurants'));
          }

          final restaurants = snapshot.data ?? [];
          final filteredRestaurants = _applyFilters(restaurants);

          return Column(
            children: [
              _buildFilterSection(restaurants),
              Expanded(
                child: filteredRestaurants.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching restaurants',
                        subtitle:
                            'Try changing your search or filter selections.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final r = filteredRestaurants[index];

                          // Swipe left on a card to delete the restaurant
                          return Dismissible(
                            key: Key(r['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteRestaurant(r),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.restaurant),
                                ),
                                title: Text(r['name']),
                                subtitle: Text('${r['type']} • ${r['price']}'),
                                trailing: const Icon(Icons.arrow_forward),
                                // Tap to view restaurant details and reviews
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailsScreen(
                                        id: r['id'],
                                        name: r['name'],
                                        type: r['type'],
                                        price: r['price'],
                                        onEdit: () => _goToEditRestaurant(r),
                                      ),
                                    ),
                                  ).then((_) => _refreshRestaurants());
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================= ADD / EDIT RESTAURANT =================

// Screen for adding a new restaurant or editing an existing one
class AddRestaurantScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData; // null means adding, not editing

  const AddRestaurantScreen({super.key, this.existingData});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  String _selectedPrice = '\$';

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing an existing restaurant
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'];
      _typeController.text = widget.existingData!['type'];
      _selectedPrice = widget.existingData!['price'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // Saves a new restaurant or updates an existing one in the database
  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existingData == null) {
      // Insert new restaurant
      await DatabaseHelper.instance.insertRestaurant({
        'name': _nameController.text.trim(),
        'type': _typeController.text.trim(),
        'price': _selectedPrice,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant added successfully')),
      );
    } else {
      // Update existing restaurant by ID
      await DatabaseHelper.instance.updateRestaurant({
        'id': widget.existingData!['id'],
        'name': _nameController.text.trim(),
        'type': _typeController.text.trim(),
        'price': _selectedPrice,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant updated successfully')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Restaurant' : 'Add Restaurant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Restaurant name input
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a restaurant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Cuisine type input
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine / Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a cuisine or type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Price range selector
                  DropdownButtonFormField<String>(
                    value: _selectedPrice,
                    decoration: const InputDecoration(
                      labelText: 'Price Range',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('\$')),
                      DropdownMenuItem(value: '\$\$', child: Text('\$\$')),
                      DropdownMenuItem(value: '\$\$\$', child: Text('\$\$\$')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPrice = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveRestaurant,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isEditing ? 'Update Restaurant' : 'Save Restaurant',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= RESTAURANT DETAILS =================

// Shows full info for a restaurant including favorite toggle and reviews
class RestaurantDetailsScreen extends StatefulWidget {
  final int id;
  final String name;
  final String type;
  final String price;
  final VoidCallback onEdit;

  const RestaurantDetailsScreen({
    super.key,
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.onEdit,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  bool isFav = false;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _loadReviews();
  }

  // Checks if this restaurant is saved as a favorite
  Future<void> _loadFavorite() async {
    final fav = await DatabaseHelper.instance.isFavorite(widget.id);
    if (!mounted) return;
    setState(() {
      isFav = fav;
    });
  }

  // Loads reviews for this specific restaurant
  void _loadReviews() {
    _reviewsFuture = DatabaseHelper.instance.getReviewsForRestaurant(widget.id);
  }

  // Refreshes the review list after a new review is added
  Future<void> _refreshReviews() async {
    setState(() {
      _loadReviews();
    });
  }

  // Adds or removes this restaurant from favorites
  Future<void> _toggleFavorite() async {
    await DatabaseHelper.instance.toggleFavorite(widget.id);
    await _loadFavorite();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? '${widget.name} added to favorites'
              : '${widget.name} removed from favorites',
        ),
      ),
    );
  }

  // Opens the add review screen for this restaurant
  Future<void> _goToAddReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(restaurantId: widget.id),
      ),
    );
    await _refreshReviews();
  }

  // Builds a row of star icons based on the rating value
  Widget _buildStarRow(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.pop(context);
              widget.onEdit();
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Restaurant',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("${widget.type} • ${widget.price}"),
            const SizedBox(height: 20),
            Row(
              children: [
                // Button to save or remove from favorites
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleFavorite,
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    label:
                        Text(isFav ? "Remove Favorite" : "Add to Favorites"),
                  ),
                ),
                const SizedBox(width: 12),
                // Button to open the add review screen
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goToAddReview,
                    icon: const Icon(Icons.rate_review),
                    label: const Text("Add Review"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle("Reviews"),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _reviewsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reviews = snapshot.data ?? [];

<<<<<<< HEAD
=======
                  // Improved empty state with clearer call to action for reviews
>>>>>>> 887bc7f (Finalize comments update)
                  if (reviews.isEmpty) {
                    return const EmptyState(
                      icon: Icons.rate_review_outlined,
                      title: 'No reviews yet',
                      subtitle:
                          'Tap "Add Review" above to share your experience with this restaurant.',
                    );
                  }

                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (_, i) {
                      final review = reviews[i];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStarRow(review['rating']),
                              const SizedBox(height: 6),
<<<<<<< HEAD
=======
                              // Divider between rating stars and comment text
>>>>>>> 887bc7f (Finalize comments update)
                              const Divider(thickness: 1),
                              const SizedBox(height: 4),
                              Text(review['comment']),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ADD REVIEW =================

// Screen where the user picks a star rating and writes a comment
class AddReviewScreen extends StatefulWidget {
  final int restaurantId;

  const AddReviewScreen({super.key, required this.restaurantId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _selectedRating = 5; // Default rating is 5 stars

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Saves the review to the database and goes back
  Future<void> _saveReview() async {
    if (!_formKey.currentState!.validate()) return;

    await DatabaseHelper.instance.insertReview({
      'restaurantId': widget.restaurantId,
      'rating': _selectedRating,
      'comment': _commentController.text.trim(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review added successfully')),
    );

    Navigator.pop(context);
  }

  // Builds the interactive star row — tap a star to set the rating
  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) {
          final starValue = index + 1;
          return IconButton(
            onPressed: () {
              setState(() {
                _selectedRating = starValue;
              });
            },
            icon: Icon(
              starValue <= _selectedRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Review"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Select a Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
<<<<<<< HEAD
=======
                  // Helper text guides user on how to use the star selector
>>>>>>> 887bc7f (Finalize comments update)
                  const Text(
                    'Tap a star to set your rating',
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingSelector(),
                  const SizedBox(height: 16),
<<<<<<< HEAD
=======
                  // maxLength enables built-in character counter below the field
>>>>>>> 887bc7f (Finalize comments update)
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Review Comment',
                      border: OutlineInputBorder(),
                      helperText: 'Share your experience',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a review comment';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveReview,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= FAVORITES =================

// Shows all restaurants the user has saved as favorites
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    // Load favorites from the database when screen opens
    _favoritesFuture = DatabaseHelper.instance.getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<List<Map<String, dynamic>>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Text('Favorites ($count)');
          },
        ),
        // Subtitle gives context to the screen
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Your saved restaurants',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle:
                  'Browse the food list and tap a restaurant to save it as a favorite.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (_, i) {
              final r = favorites[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text(r['name']),
                  subtitle: Text('${r['type']} • ${r['price']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ================= BUDGET TRACKER =================

// Shows spending history and progress toward the weekly budget goal
class BudgetTrackerScreen extends StatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  late Future<List<Map<String, dynamic>>> _expensesFuture;
  double _total = 0.0;
  double _weeklyBudget = 100.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // Loads all expenses and the current budget from storage
  Future<void> _loadExpenses() async {
    _expensesFuture = DatabaseHelper.instance.getExpenses();
    _total = await DatabaseHelper.instance.getTotalExpenses();
    _weeklyBudget = await AppSettings.getWeeklyBudget();
    if (!mounted) return;
    setState(() {});
  }

  // Opens the add expense screen then refreshes the list
  Future<void> _goToAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    await _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _weeklyBudget - _total;
    final ratio =
        _weeklyBudget > 0 ? (_total / _weeklyBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracker')),
      // Floating button to add a new expense
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddExpense,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Budget progress summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Weekly Budget Progress"),
                  const SizedBox(height: 8),
                  Text(
                    "\$${_total.toStringAsFixed(2)} / \$${_weeklyBudget.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remaining >= 0
                        ? "Remaining: \$${remaining.toStringAsFixed(2)}"
                        : "Over budget by \$${remaining.abs().toStringAsFixed(2)}",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              // Rebuild total spent every time state changes after deletion
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data ?? [];

                  if (expenses.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses yet',
                      subtitle: 'Tap the + button to add your first expense.',
                    );
                  }

                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (_, i) {
                      final e = expenses[i];

                      return Dismissible(
                        key: Key(e['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await DatabaseHelper.instance.deleteExpense(e['id']);
<<<<<<< HEAD
                          await _loadExpenses();

=======
                          setState(() {}); // Trigger rebuild to update total
>>>>>>> 887bc7f (Finalize comments update)
                          if (!mounted) return;
                          // Notify user that expense was removed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${e['item']} removed')),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Text(e['item']),
                            trailing: Text(
                              "\$${(e['cost'] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ADD EXPENSE =================

// Screen to add a new food expense with item name and cost
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _costController.dispose();
    super.dispose();
  }

  // Validates inputs and saves the expense to the database
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    await DatabaseHelper.instance.insertExpense({
      'item': _itemController.text.trim(),
      'cost': double.parse(_costController.text.trim()),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense added successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input for the name of the food item purchased
                  TextFormField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Item',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an expense item';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Input for the cost — only accepts valid positive numbers
                  TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a cost';
                      }

                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Please enter a valid amount';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveExpense,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= SETTINGS =================

// Lets the user set their weekly spending goal, saved to local storage
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  // Pre-fills the input with the currently saved budget
  Future<void> _loadCurrentBudget() async {
    final budget = await AppSettings.getWeeklyBudget();
    _budgetController.text = budget.toStringAsFixed(2);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // Validates and saves the new budget to local storage
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_budgetController.text.trim());
    await AppSettings.setWeeklyBudget(amount);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
<<<<<<< HEAD
=======
                  // Header with icon for the budget goal section
>>>>>>> 887bc7f (Finalize comments update)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.savings, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Weekly Budget Goal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Input for the user's weekly budget amount
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a budget amount';
                      }

                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Please enter a valid positive amount';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}