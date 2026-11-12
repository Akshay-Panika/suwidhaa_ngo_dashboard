import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 👈 Date format ke liye
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';

class UserCard extends StatefulWidget {
  const UserCard({super.key});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  // ── STATE VARIABLES ──
  List<Map<String, dynamic>> users = [
    {
      "id": 1,
      "name": "Amit Kumar",
      "email": "amit@gmail.com",
      "phone": "+91 9876543210",
      "role": "Admin",
      "image": "https://i.pravatar.cc/150?img=11",
      "date": DateTime(2023, 10, 12), // 👈 Date field added
    },
    {
      "id": 2,
      "name": "Priya Sharma",
      "email": "priya@gmail.com",
      "phone": "+91 9876543211",
      "role": "Volunteer",
      "image": "https://i.pravatar.cc/150?img=5",
      "date": DateTime(2024, 10, 15),
    },
    {
      "id": 3,
      "name": "Rahul Verma",
      "email": "rahul@gmail.com",
      "phone": "+91 9876543212",
      "role": "Donor",
      "image": "https://i.pravatar.cc/150?img=12",
      "date": DateTime(2025, 11, 20),
    },
  ];

  Map<String, dynamic>? selectedUser;
  bool isEditing = false;
  bool isAdding = false;

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Filter States
  String _searchQuery = "";
  int? _filterYear;
  int? _filterMonth;
  DateTime? _filterDate;

  // Lists for Dropdowns
  final List<int> _years = [2023, 2024, 2025, 2026];
  final List<Map<String, dynamic>> _months = [
    {"id": 1, "name": "Jan"}, {"id": 2, "name": "Feb"}, {"id": 3, "name": "Mar"},
    {"id": 4, "name": "Apr"}, {"id": 5, "name": "May"}, {"id": 6, "name": "Jun"},
    {"id": 7, "name": "Jul"}, {"id": 8, "name": "Aug"}, {"id": 9, "name": "Sep"},
    {"id": 10, "name": "Oct"}, {"id": 11, "name": "Nov"}, {"id": 12, "name": "Dec"},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── DATE PICKER FUNCTION ──
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: AppColor.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _filterYear = null;
        _filterMonth = null;
      });
    }
  }

  // ── ACTIONS ──
  void _resetState() {
    setState(() {
      selectedUser = null;
      isEditing = false;
      isAdding = false;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _roleCtrl.clear();
    });
  }

  void _openAddForm() {
    setState(() {
      isAdding = true;
      isEditing = false;
      selectedUser = null;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _roleCtrl.clear();
    });
  }

  void _openEditForm(Map<String, dynamic> user) {
    setState(() {
      isAdding = false;
      isEditing = true;
      selectedUser = user;
      _nameCtrl.text = user['name'];
      _emailCtrl.text = user['email'];
      _phoneCtrl.text = user['phone'];
      _roleCtrl.text = user['role'];
    });
  }

  void _saveForm() {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      FlutterToast.error("Please fill all fields");
      return;
    }

    setState(() {
      if (isAdding) {
        users.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch,
          "name": _nameCtrl.text,
          "email": _emailCtrl.text,
          "phone": _phoneCtrl.text,
          "role": _roleCtrl.text.isEmpty ? "User" : _roleCtrl.text,
          "image": "https://i.pravatar.cc/150?img=8",
          "date": DateTime.now(), // 👈 Naye user me current date
        });
        FlutterToast.success("User Added Successfully");
      } else if (isEditing && selectedUser != null) {
        int index = users.indexWhere((element) => element['id'] == selectedUser!['id']);
        if (index != -1) {
          users[index]['name'] = _nameCtrl.text;
          users[index]['email'] = _emailCtrl.text;
          users[index]['phone'] = _phoneCtrl.text;
          users[index]['role'] = _roleCtrl.text;
        }
        FlutterToast.success("User Updated Successfully");
      }
      _resetState();
    });
  }

  void _deleteUser(int id) {
    setState(() {
      users.removeWhere((element) => element['id'] == id);
      if (selectedUser != null && selectedUser!['id'] == id) {
        _resetState();
      }
      FlutterToast.success("User Deleted");
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 3-WAY FILTER LOGIC (Search + Year + Month + Date)
    final filteredUsers = users.where((user) {
      final DateTime date = user['date'];
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final phone = user['phone'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      // 1. Search Match
      bool matchesSearch = name.contains(query) || email.contains(query) || phone.contains(query);

      // 2. Filter Match (Date / Month / Year)
      bool matchesDateFilter = true;
      if (_filterDate != null) {
        matchesDateFilter = DateUtils.isSameDay(date, _filterDate);
      } else if (_filterMonth != null) {
        matchesDateFilter = date.month == _filterMonth &&
            (_filterYear == null || date.year == _filterYear);
      } else if (_filterYear != null) {
        matchesDateFilter = date.year == _filterYear;
      }

      return matchesSearch && matchesDateFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(width: 3, height: 20, color: AppColor.primary),
                  const Text(
                    "Manage Users",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textDark),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text("Add User"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // ── BODY: SPLIT VIEW ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════
                // LEFT PANEL: SEARCH + FILTERS + LIST
                // ═══════════════════════════════════════
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.surface),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 🔍 SEARCH BAR
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: "Search users by name, email or phone...",
                                  hintStyle: const TextStyle(fontSize: 14, color: AppColor.textGrey),
                                  prefixIcon: const Icon(Icons.search, color: AppColor.primary, size: 20),
                                  filled: true,
                                  fillColor: AppColor.surface,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: AppColor.textGrey),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = "");
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 📅 3-WAY FILTER ROW (YEAR, MONTH, DATE)
                            Expanded(
                              child: Row(
                                children: [
                                  // YEAR DROPDOWN
                                  Expanded(
                                    child: Container(
                                      height: 45,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _filterYear != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _filterYear != null ? AppColor.primary : Colors.transparent),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          isExpanded: true,
                                          hint: const Text("Year", style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
                                          value: _filterYear,
                                          icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
                                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _filterYear = val;
                                              _filterDate = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                              
                                  // MONTH DROPDOWN
                                  Expanded(
                                    child: Container(
                                      height: 45,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _filterMonth != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _filterMonth != null ? AppColor.primary : Colors.transparent),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          isExpanded: true,
                                          hint: const Text("Month", style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
                                          value: _filterMonth,
                                          icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
                                          items: _months.map((m) => DropdownMenuItem(value: m['id'] as int, child: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _filterMonth = val;
                                              _filterDate = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                              
                                  // DATE PICKER BUTTON
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickDate,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: 45,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: _filterDate != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _filterDate != null ? AppColor.primary : Colors.transparent),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.calendar_month, color: _filterDate != null ? AppColor.primary : AppColor.textGrey, size: 18),
                                            if (_filterDate != null) ...[
                                              const SizedBox(width: 4),
                                              Text(DateFormat('dd/MM').format(_filterDate!), style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () => setState(() => _filterDate = null),
                                                child: const Icon(Icons.close, size: 14, color: AppColor.primary),
                                              )
                                            ] else ...[
                                              const SizedBox(width: 4),
                                              const Text("Date", style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                        const SizedBox(height: 16),

                        // 📋 LIST VIEW
                        Expanded(
                          child: filteredUsers.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 50, color: AppColor.textGrey.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                const Text("No results found for your filters", style: TextStyle(color: AppColor.textGrey)),
                              ],
                            ),
                          )
                              : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected = selectedUser?['id'] == user['id'] && !isEditing && !isAdding;
                              final DateTime date = user['date'];

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppColor.primary : AppColor.surface,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      selectedUser = user;
                                      isEditing = false;
                                      isAdding = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // User Avatar
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(user['image']),
                                        ),
                                        const SizedBox(width: 16),
                                        // Text Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    user['name'],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Role Badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColor.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      user['role'],
                                                      style: const TextStyle(color: AppColor.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user['email'],
                                                style: const TextStyle(color: AppColor.textGrey, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    user['phone'],
                                                    style: const TextStyle(color: AppColor.textGrey, fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.calendar_today, size: 10, color: AppColor.textGrey),
                                                  const SizedBox(width: 4),
                                                  Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: AppColor.textGrey, fontSize: 11)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Actions
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _openEditForm(user),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: AppColor.error, size: 20),
                                              onPressed: () => _deleteUser(user['id']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // ═══════════════════════════════════════
                // RIGHT PANEL: VIEW / FORM / EMPTY
                // ═══════════════════════════════════════
                SizedBox(
                  width: 420,
                  child: _buildRightPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── RIGHT PANEL LOGIC ──
  Widget _buildRightPanel() {
    // 1. Empty State
    if (!isAdding && !isEditing && selectedUser == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.surface),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 60, color: AppColor.textGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text("Select a user to view details", style: TextStyle(color: AppColor.textGrey, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    // 2. Form State (Add / Edit)
    if (isAdding || isEditing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.surface, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdding ? "Add New User" : "Edit User",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Name Field
            const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: "Enter full name",
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Email Field
            const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                hintText: "Enter email",
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Phone Field
            const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                hintText: "Enter phone number",
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Role Field
            const Text("Role (Admin, Volunteer, Donor)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _roleCtrl,
              decoration: InputDecoration(
                hintText: "e.g. Volunteer",
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _resetState,
                    child: const Text("Cancel", style: TextStyle(color: AppColor.textGrey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isAdding ? "SAVE" : "UPDATE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    // 3. View State
    final DateTime date = selectedUser!['date'] as DateTime;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: _resetState,
              icon: const Icon(Icons.close, color: AppColor.textGrey),
            ),
          ),

          // Avatar Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(selectedUser!['image']),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedUser!['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedUser!['role'],
                    style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Contact Data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                _buildInfoRow(Icons.email_outlined, "Email", selectedUser!['email']),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.phone_outlined, "Phone", selectedUser!['phone']),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today_outlined, "Joined Date", DateFormat('dd MMMM yyyy').format(date)), // 👈 Date added
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for View State
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColor.textDark, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColor.textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ],
    );
  }
}