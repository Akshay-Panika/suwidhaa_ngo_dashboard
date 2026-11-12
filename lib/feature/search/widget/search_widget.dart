import 'package:flutter/material.dart';
import '../../../core/constant/app_color.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  // Dummy search data
  final List<Map<String, dynamic>> _allData = [
    {"title": "Education Category", "type": "Category", "icon": Icons.category},
    {"title": "Ravi Sharma", "type": "User", "icon": Icons.person},
    {"title": "Scholarship Program", "type": "Service", "icon": Icons.room_service},
    {"title": "Healthcare Banner", "type": "Banner", "icon": Icons.image},
    {"title": "Amit Patel", "type": "User", "icon": Icons.person},
    {"title": "Food Relief", "type": "Category", "icon": Icons.category},
  ];

  @override
  Widget build(BuildContext context) {
    // Screen size ke hisaab se size set karna
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Search filter logic
    final filteredData = _allData.where((item) {
      return item['title'].toString().toLowerCase().contains(_query.toLowerCase()) ||
          item['type'].toString().toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: isMobile ? double.infinity : 600,
        height: isMobile ? 500 : 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Global Search", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColor.textGrey),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Search Input
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: "Search users, categories, services...",
                prefixIcon: const Icon(Icons.search, color: AppColor.primary),
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search Results
            const Text("Results", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 13)),
            const SizedBox(height: 10),

            Expanded(
              child: filteredData.isEmpty
                  ? const Center(child: Text("No results found", style: TextStyle(color: AppColor.textGrey)))
                  : ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final item = filteredData[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.primary.withOpacity(0.1),
                      child: Icon(item['icon'], color: AppColor.primary, size: 20),
                    ),
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['type']),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColor.textGrey),
                    onTap: () {
                      Navigator.pop(context);
                      // Yahan aap specific item par navigate kar sakte hain
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