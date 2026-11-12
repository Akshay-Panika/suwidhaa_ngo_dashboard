import 'package:flutter/material.dart';
import '../../../core/constant/app_color.dart';

class DashboardCard extends StatelessWidget {
  final Function(int index) onNavigate; // 👈 Navigation Callback

  const DashboardCard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. WELCOME HEADER ──
          _buildWelcomeHeader(),
          const SizedBox(height: 24),

          // ── 2. STATS GRID ──
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // ── 3. QUICK ACTIONS ──
          _buildQuickActions(),
          const SizedBox(height: 24),

          // ── 4. BOTTOM SECTION (Recent Activity & Top Categories) ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRecentDonations()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildTopCategories()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecentDonations(),
                    const SizedBox(height: 24),
                    _buildTopCategories(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION 1: WELCOME HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back, Admin! 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your NGO today.",
              style: TextStyle(fontSize: 14, color: AppColor.textGrey.withOpacity(0.8)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.primary.withOpacity(0.3)),
          ),
          child: Text(
            formattedDate,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION 2: STATS GRID (Responsive)
  // ─────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final List<Map<String, dynamic>> dashboardStats = [
      {"title": "Total Donations", "value": "₹ 1,50,000", "icon": Icons.money, "color": AppColor.success},
      {"title": "Total Users", "value": "1,240", "icon": Icons.people, "color": AppColor.primary},
      {"title": "Categories", "value": "12", "icon": Icons.category, "color": Colors.blue},
      {"title": "Active Banners", "value": "05", "icon": Icons.image, "color": AppColor.secondary},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboardStats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final stat = dashboardStats[index];
            return _buildStatCard(
                stat["title"] as String,
                stat["value"] as String,
                stat["icon"] as IconData,
                stat["color"] as Color
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.textDark)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: AppColor.textGrey, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION 3: QUICK ACTIONS (Updated with all menus)
  // ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textDark)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            // Index 1: Banners
            _buildActionButton("Add Banner", Icons.image_rounded, AppColor.secondary, () => onNavigate(1)),

            // Index 2: Categories
            _buildActionButton("Add Category", Icons.category_rounded, Colors.blue, () => onNavigate(2)),

            // Index 3: Services
            _buildActionButton("Add Service", Icons.room_service_rounded, Colors.purple, () => onNavigate(3)),

            // Index 4: Donations
            _buildActionButton("View Donations", Icons.attach_money_rounded, AppColor.success, () => onNavigate(4)),

            // Index 5: Users
            _buildActionButton("Manage Users", Icons.people_rounded, Colors.orange, () => onNavigate(5)),

            // Index 6: Ads
            _buildActionButton("Create Ad", Icons.campaign_rounded, Colors.red, () => onNavigate(6)),
          ],
        )
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap, // 👈 Naviagte on click
      icon: Icon(icon, size: 18, color: color),
      label: Text(title, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: color.withOpacity(0.05),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION 4: RECENT DONATIONS LIST
  // ─────────────────────────────────────────────────────────
  Widget _buildRecentDonations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Donations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textDark)),
              TextButton(onPressed: () => onNavigate(4), child: const Text("View All", style: TextStyle(color: AppColor.primary))),
            ],
          ),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.success.withOpacity(0.1),
                    child: const Icon(Icons.arrow_downward, color: AppColor.success, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Donor Name ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Text("Just now", style: TextStyle(fontSize: 12, color: AppColor.textGrey)),
                      ],
                    ),
                  ),
                  const Text("+ ₹ 5,000", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.success, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION 5: TOP CATEGORIES
  // ─────────────────────────────────────────────────────────
  Widget _buildTopCategories() {
    final List<Map<String, dynamic>> categories = [
      {"name": "Education", "percent": 0.75, "color": Colors.blue},
      {"name": "Healthcare", "percent": 0.50, "color": AppColor.primary},
      {"name": "Food Relief", "percent": 0.30, "color": AppColor.secondary},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textDark)),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final String name = cat["name"] as String;
              final double percent = cat["percent"] as double;
              final Color color = cat["color"] as Color;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }
}