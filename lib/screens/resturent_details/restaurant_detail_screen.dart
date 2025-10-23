import 'package:flutter/material.dart';
import 'dart:ui';

class RestaurantDetailScreen extends StatefulWidget {
  final String name;
  final String image;
  final String discount;
  final String rating;
  final String deliveryTime;
  final String deliveryFee;

  const RestaurantDetailScreen({
    super.key,
    required this.name,
    required this.image,
    required this.discount,
    this.rating = "4.5",
    this.deliveryTime = "20-30 min",
    this.deliveryFee = "Free",
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _menuItems = [];
  int _totalItems = 0;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMenu();
  }

  void _initializeMenu() {
    _menuItems.addAll([
      {
        "name": "Chicken Burger",
        "price": 25.0,
        "description": "Crispy chicken with fresh lettuce and special sauce",
        "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
        "category": "Burgers",
        "quantity": 0,
      },
      {
        "name": "Beef Shawarma",
        "price": 18.0,
        "description": "Tender beef slices with tahini and vegetables",
        "image": "https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=500",
        "category": "Shawarma",
        "quantity": 0,
      },
      {
        "name": "Grilled Chicken",
        "price": 35.0,
        "description": "Juicy grilled chicken with aromatic spices",
        "image": "https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=500",
        "category": "Main Course",
        "quantity": 0,
      },
      {
        "name": "French Fries",
        "price": 8.0,
        "description": "Crispy golden fries with special seasoning",
        "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500",
        "category": "Sides",
        "quantity": 0,
      },
      {
        "name": "Fresh Juice",
        "price": 12.0,
        "description": "Freshly squeezed seasonal fruits",
        "image": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500",
        "category": "Drinks",
        "quantity": 0,
      },
      {
        "name": "Cheese Pizza",
        "price": 30.0,
        "description": "Classic cheese pizza with tomato sauce",
        "image": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500",
        "category": "Pizza",
        "quantity": 0,
      },
    ]);
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _menuItems[index]['quantity'] += change;
      if (_menuItems[index]['quantity'] < 0) {
        _menuItems[index]['quantity'] = 0;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalItems = 0;
    _totalPrice = 0.0;
    for (var item in _menuItems) {
      _totalItems += item['quantity'] as int;
      _totalPrice += (item['price'] as double) * (item['quantity'] as int);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildRestaurantInfo(),
              _buildTabBar(),
              _buildMenuList(),
            ],
          ),
          if (_totalItems > 0) _buildFloatingCart(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0D0D0D),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'restaurant_${widget.name}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRestaurantInfo() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.access_time, widget.deliveryTime),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.delivery_dining, widget.deliveryFee),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions,
                    label: "Direction",
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: "Call",
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.info_outline,
                    label: "Info",
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE91E63), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: const Color(0xFFE91E63),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: Colors.grey[500],
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: "Menu"),
            Tab(text: "Reviews"),
            Tab(text: "About"),
          ],
        ),
      ),
    );
  }

  SliverList _buildMenuList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _menuItems[index];
          return _buildMenuItem(item, index);
        },
        childCount: _menuItems.length,
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "SR ${item['price'].toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (item['quantity'] == 0)
                          InkWell(
                            onTap: () => _updateQuantity(index, 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE91E63),
                                    Color(0xFFD81B60),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "ADD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE91E63),
                                  Color(0xFFD81B60),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _updateQuantity(index, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "${item['quantity']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _updateQuantity(index, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCart() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showCheckoutBottomSheet();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$_totalItems",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "View Cart",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "SR ${_totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Your Cart",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ..._menuItems
                  .where((item) => item['quantity'] > 0)
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              "${item['quantity']}x",
                              style: const TextStyle(
                                color: Color(0xFFE91E63),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              "SR ${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              const Divider(color: Colors.grey, height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Total",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "SR ${_totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Order placed successfully!"),
                        backgroundColor: const Color(0xFF2ECC71),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Checkout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
