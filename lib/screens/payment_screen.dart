import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> driver;
  final double total;

  const PaymentScreen({Key? key, required this.driver, required this.total})
      : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  bool isPaid = false;
  bool orderPicked = false;
  bool orderDelivered = false;
  String userCode = "";
  String driverCode = "";
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _chatMessages = [
    {"sender": "driver", "message": "Hello! I'm on my way to pick up your order."},
  ];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _generateUserCode();
    
    // Pulse animation for waiting states
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for new elements
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  void _generateUserCode() {
    userCode = "U${DateTime.now().millisecondsSinceEpoch % 10000}";
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showChatPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE91E63),
                          const Color(0xFFD81B60),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.driver['image'] ?? 
                                'https://ui-avatars.com/api/?name=${widget.driver['name']}&background=E91E63&color=fff',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.driver['name'] ?? 'Driver',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2ECC71),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Online",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = _chatMessages[index];
                          final isDriver = message['sender'] == 'driver';
                          
                          return Align(
                            alignment: isDriver
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                gradient: isDriver
                                    ? null
                                    : LinearGradient(
                                        colors: [
                                          const Color(0xFFE91E63),
                                          const Color(0xFFD81B60),
                                        ],
                                      ),
                                color: isDriver ? const Color(0xFF2B2C4A) : null,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isDriver
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                  bottomRight: isDriver
                                      ? const Radius.circular(16)
                                      : const Radius.circular(0),
                                ),
                              ),
                              child: Text(
                                message['message']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Input area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Location button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE91E63),
                                  const Color(0xFFD81B60),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.location_on, color: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                                _showLocationSentMessage();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Text field
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2C4A),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _msgController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setModalState(() {
                                      _chatMessages.add({
                                        "sender": "user",
                                        "message": value.trim(),
                                      });
                                      _msgController.clear();
                                    });
                                    
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Send button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE91E63),
                                  const Color(0xFFD81B60),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () {
                                if (_msgController.text.trim().isNotEmpty) {
                                  setModalState(() {
                                    _chatMessages.add({
                                      "sender": "user",
                                      "message": _msgController.text.trim(),
                                    });
                                    _msgController.clear();
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
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

  void _showLocationSentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text("Location sent to driver successfully!"),
          ],
        ),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Tracking",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Driver Info Card
              _buildDriverInfoCard(),
              
              const SizedBox(height: 24),
              
              // Total Amount Card
              _buildTotalAmountCard(),
              
              const SizedBox(height: 24),
              
              // Payment Status Section
              _buildPaymentStatusSection(),
              
              const SizedBox(height: 24),
              
              // Order Timeline
              _buildOrderTimeline(),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              if (isPaid && !orderDelivered) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE91E63),
              const Color(0xFFD81B60),
              const Color(0xFF9C27B0),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Driver Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(
                    widget.driver['image'] ?? 
                    'https://ui-avatars.com/api/?name=${widget.driver['name']}&background=E91E63&color=fff',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Driver Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Driver",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.driver['name'] ?? 'Driver',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.driver['rating']?.toString() ?? '4.8',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.driver['vehicle'] ?? 'Motorcycle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildTotalAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63).withOpacity(0.2),
                  const Color(0xFFD81B60).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Color(0xFFE91E63),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SR ${widget.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Paid",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid 
              ? const Color(0xFF2ECC71).withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPaid
                        ? [
                            const Color(0xFF2ECC71),
                            const Color(0xFF27AE60),
                          ]
                        : [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle : Icons.payment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Payment Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Payment checkbox
          InkWell(
            onTap: () {
              if (!orderDelivered) {
                setState(() {
                  isPaid = !isPaid;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPaid
                    ? const Color(0xFF2ECC71).withOpacity(0.1)
                    : const Color(0xFF2B2C4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPaid
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: isPaid
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF2ECC71),
                                const Color(0xFF27AE60),
                              ],
                            )
                          : null,
                      color: isPaid ? null : Colors.transparent,
                      border: Border.all(
                        color: isPaid ? Colors.transparent : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isPaid
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPaid ? "Payment Completed" : "Mark as Paid",
                    style: TextStyle(
                      color: isPaid ? const Color(0xFF2ECC71) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isPaid) ...[
            const SizedBox(height: 20),
            
            // User Code Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE91E63).withOpacity(0.1),
                    const Color(0xFFD81B60).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE91E63).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.qr_code,
                        color: Color(0xFFE91E63),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Your Pickup Code",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userCode,
                          style: const TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Code copied to clipboard!"),
                              backgroundColor: const Color(0xFF2ECC71),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Share this code with the driver to confirm pickup",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Progress",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Timeline Steps
          _buildTimelineStep(
            icon: Icons.payment,
            title: "Payment",
            subtitle: isPaid ? "Payment completed" : "Waiting for payment",
            isCompleted: isPaid,
            isActive: !isPaid,
            showLine: true,
          ),
          
          _buildTimelineStep(
            icon: Icons.restaurant,
            title: "Order Pickup",
            subtitle: orderPicked 
                ? "Order picked up by driver"
                : isPaid 
                    ? "Waiting for driver to pick up"
                    : "Not started yet",
            isCompleted: orderPicked,
            isActive: isPaid && !orderPicked,
            showLine: true,
          ),
          
          _buildTimelineStep(
            icon: Icons.delivery_dining,
            title: "Delivery",
            subtitle: orderDelivered
                ? "Order delivered successfully! 🎉"
                : orderPicked
                    ? "Driver is on the way"
                    : "Not started yet",
            isCompleted: orderDelivered,
            isActive: orderPicked && !orderDelivered,
            showLine: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isCompleted || isActive
                    ? LinearGradient(
                        colors: isCompleted
                            ? [
                                const Color(0xFF2ECC71),
                                const Color(0xFF27AE60),
                              ]
                            : [
                                const Color(0xFFE91E63),
                                const Color(0xFFD81B60),
                              ],
                      )
                    : null,
                color: isCompleted || isActive ? null : const Color(0xFF2B2C4A),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isActive
                  ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: Icon(icon, color: Colors.white, size: 24),
                    )
                  : Icon(
                      isCompleted ? Icons.check : icon,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2ECC71),
                            const Color(0xFF2ECC71).withOpacity(0.3),
                          ],
                        )
                      : null,
                  color: isCompleted ? null : const Color(0xFF2B2C4A),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: showLine ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted || isActive ? Colors.white : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF2ECC71)
                        : isActive
                            ? const Color(0xFFE91E63)
                            : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Chat Button
        if (!orderDelivered)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63),
                  const Color(0xFFD81B60),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showChatPopup,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_bubble_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Chat with Driver",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        if (!orderPicked && isPaid) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE91E63).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showPickupConfirmationDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Color(0xFFE91E63)),
                    SizedBox(width: 12),
                    Text(
                      "Confirm Pickup (Driver)",
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        
        if (orderPicked && !orderDelivered) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2ECC71),
                  const Color(0xFF27AE60),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ECC71).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    orderDelivered = true;
                  });
                  
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _showDeliverySuccessDialog();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Confirm Delivery",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPickupConfirmationDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.qr_code_scanner, color: Color(0xFFE91E63)),
                SizedBox(width: 12),
                Text(
                  "Enter Pickup Code",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Driver should enter the code received from the restaurant",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Enter Code",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF2B2C4A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  maxLength: 10,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (codeController.text == userCode) {
                    setState(() {
                      orderPicked = true;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Order picked up successfully!"),
                        backgroundColor: const Color(0xFF2ECC71),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Invalid code. Please try again."),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeliverySuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2ECC71),
                          const Color(0xFF27AE60),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Order Delivered! 🎉",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Thank you for your order!\nEnjoy your meal!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
