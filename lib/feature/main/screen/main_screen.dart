import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../../ads/widget/ads_card.dart';
import '../../auth/screen/auth_screen.dart';
import '../../banner/widget/banner_card.dart';
import '../../category/widget/category_widget.dart';
import '../../dashboard/widget/dashboard_card.dart';
import '../../donation/widget/donation_card.dart';
import '../../notification/widget/notification_card.dart';
import '../../search/widget/search_widget.dart';
import '../../service/widget/service_card.dart';
import '../../user/widget/user_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Fixed Menu Items
  final List<Map<String, dynamic>> _menuItems = [
    {"title": "Dashboard", "icon": Icons.dashboard_rounded},
    {"title": "Banners", "icon": Icons.image_rounded},
    {"title": "Categories", "icon": Icons.category_rounded},
    {"title": "Services", "icon": Icons.room_service_rounded},
    {"title": "Donations", "icon": Icons.attach_money_rounded},
    {"title": "Users", "icon": Icons.people_rounded},
    {"title": "Ads", "icon": Icons.campaign_rounded},
  ];

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;
    FlutterToast.success("Logged out successfully");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColor.surface,

      drawer: isMobile
          ? Drawer(
        child: _buildSidebar(isMobile: true),
      )
          : null,

      // ═══════════════════════════════════════════════════════
      // 🚀 UPDATED MODERN APPBAR
      // ═══════════════════════════════════════════════════════
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for clean look
        elevation: 0,
        scrolledUnderElevation: 0, // Removes shadow when scrolling
        shape: const Border(
          bottom: BorderSide(color: AppColor.surface, width: 1.5), // Subtle bottom border
        ),
        // Hamburger Icon for Mobile
        iconTheme: const IconThemeData(color: AppColor.textDark),

        title: Row(
          children: [
            // Web par ek logo icon dikha sakte hain
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.volunteer_activism, color: AppColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              _menuItems[_selectedIndex]['title'],
              style: const TextStyle(
                  color: AppColor.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20
              ),
            ),
          ],
        ),

        actions: [
          // 1. Search Icon
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SearchDialog(),
              );
            },
            icon: const Icon(Icons.search_rounded, color: AppColor.textDark),
            tooltip: "Search",
          ),

          // 2. Notification Bell with Red Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const NotificationDialog(),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded, color: AppColor.textDark),
                tooltip: "Notifications",
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColor.error,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(width: 8),

          // 3. Profile Popup Menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: AppColor.textGrey),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: AppColor.error),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: AppColor.error)),
                    ],
                  ),
                ),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColor.primary,
                child: Text(
                    "A",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),

      body: Row(
        children: [
          // ── LEFT SIDEBAR (Web/Tablet) ──
          if (!isMobile)
            Container(
              width: 260,
              color: Colors.white,
              child: _buildSidebar(isMobile: false),
            ),

          if (!isMobile)
            const VerticalDivider(width: 1, color: AppColor.surface),

          // ── RIGHT CONTENT AREA ──
          Expanded(
            child: Container(
              color: AppColor.surface,
              child: _buildRightContent(),
            ),
          ),
        ],
      ),
    );
  }

  // SIDEBAR WIDGET (Reusable)
  Widget _buildSidebar({required bool isMobile}) {
    return Column(
      children: [
        // ── Profile Section ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColor.surface, width: 1.5)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColor.primary,
                child: Icon(Icons.admin_panel_settings_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Admin User",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                "admin@ngo.com",
                style: TextStyle(fontSize: 13, color: AppColor.textGrey),
              ),
            ],
          ),
        ),

        // ── Menu List ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isMobile) Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? AppColor.primary : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _menuItems[index]['icon'],
                          color: isSelected ? AppColor.primary : AppColor.textGrey,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _menuItems[index]['title'],
                          style: TextStyle(
                            color: isSelected ? AppColor.primary : AppColor.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Logout Button ──
        const Divider(height: 1, color: AppColor.surface),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: AppColor.error),
              label: const Text("Logout", style: TextStyle(color: AppColor.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColor.error, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── RIGHT CONTENT ROUTER ──
  Widget _buildRightContent() {
    return switch (_selectedIndex) {
      0 => DashboardCard(
        onNavigate: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      1 =>  BannerCard(),
      2 => const CategoryWidget(),
      3 => const ServiceCard(),
      4 => const DonationCard(),
      5 => const UserCard(),
      6 => const AdsCard(),
      _ => const Center(child: Text("Select a menu")),
    };
  }
}