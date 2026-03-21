import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const CampusBitesApp());
}

class CampusBitesApp extends StatelessWidget {
  const CampusBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusBites',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= SPLASH SCREEN =================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 90, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'CampusBites',
              style: TextStyle(
                fontSize: 32,
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

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusBites'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Weekly Budget"),
                  SizedBox(height: 8),
                  Text(
                    "\$45 / \$100",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 30),
            const Text(
              "Recommended for You",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chick-fil-A",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text("\$ - Fast Food"),
                  SizedBox(height: 5),
                  Text("Based on your budget & preferences"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }
}

// ================= FOOD LIST =================

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    _restaurantsFuture = DatabaseHelper.instance.getRestaurants();
  }

  void _refreshRestaurants() {
    setState(() {
      _loadRestaurants();
    });
  }

  Future<void> _goToAddRestaurant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRestaurantScreen()),
    );
    _refreshRestaurants();
  }

  Future<void> _goToEditRestaurant(Map<String, dynamic> restaurant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRestaurantScreen(existingData: restaurant),
      ),
    );
    _refreshRestaurants();
  }

  Future<void> _deleteRestaurant(Map<String, dynamic> restaurant) async {
    await DatabaseHelper.instance.deleteRestaurant(restaurant['id']);
    _refreshRestaurants();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${restaurant['name']} deleted')),
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
            return const Center(
              child: Text('Error loading restaurants'),
            );
          }

          final restaurants = snapshot.data ?? [];

          if (restaurants.isEmpty) {
            return const Center(
              child: Text('No restaurants found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final r = restaurants[index];

              return Dismissible(
                key: Key(r['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) => _deleteRestaurant(r),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text(r['name']),
                    subtitle: Text('${r['type']} • ${r['price']}'),
                    trailing: const Icon(Icons.arrow_forward),
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
          );
        },
      ),
    );
  }
}

// ================= ADD / EDIT RESTAURANT =================

class AddRestaurantScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;

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

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existingData == null) {
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

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final fav = await DatabaseHelper.instance.isFavorite(widget.id);
    if (!mounted) return;
    setState(() {
      isFav = fav;
    });
  }

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
            ElevatedButton.icon(
              onPressed: _toggleFavorite,
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              label: Text(isFav ? "Remove Favorite" : "Add to Favorites"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddReviewScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: const Text("Add Review"),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ADD REVIEW =================

class AddReviewScreen extends StatelessWidget {
  const AddReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Review")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(
              decoration: InputDecoration(labelText: "Your Review"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text("Submit (Coming Soon)"),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= FAVORITES =================

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
    _favoritesFuture = DatabaseHelper.instance.getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorites yet'),
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

// ================= BUDGET =================

class BudgetTrackerScreen extends StatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  late Future<List<Map<String, dynamic>>> _expensesFuture;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    _expensesFuture = DatabaseHelper.instance.getExpenses();
    _total = await DatabaseHelper.instance.getTotalExpenses();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Total Spending"),
                  const SizedBox(height: 8),
                  Text(
                    "\$${_total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data ?? [];

                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text("No expenses yet"),
                    );
                  }

                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (_, i) {
                      final e = expenses[i];
                      return Card(
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
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}