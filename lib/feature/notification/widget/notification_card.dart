import 'package:flutter/material.dart';
import '../../../core/constant/app_color.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // ✅ FIX 1: Explicitly define List<Map<String, dynamic>>
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "New Donation Received",
        "desc": "Ravi donated ₹5,000 for Education.",
        "time": "2 min ago",
        "isRead": false,
        "icon": Icons.attach_money,
        "color": AppColor.success,
      },
      {
        "title": "New User Registered",
        "desc": "Priya joined as a Volunteer.",
        "time": "1 hour ago",
        "isRead": false,
        "icon": Icons.person_add,
        "color": AppColor.primary,
      },
      {
        "title": "Banner Updated",
        "desc": "Healthcare camp banner was updated.",
        "time": "3 hours ago",
        "isRead": true,
        "icon": Icons.image,
        "color": AppColor.secondary,
      },
      {
        "title": "System Alert",
        "desc": "Backup completed successfully.",
        "time": "1 day ago",
        "isRead": true,
        "icon": Icons.check_circle,
        "color": Colors.blue,
      },
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      alignment: Alignment.topRight, // Right side me open hoga (AppBar bell ke niche)
      child: Container(
        width: isMobile ? double.infinity : 400,
        height: isMobile ? 500 : 550,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text("Mark all read", style: TextStyle(color: AppColor.primary, fontSize: 12)),
                )
              ],
            ),
            const Divider(),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final noti = notifications[index];

                  // ✅ FIX 2: Variables me cast karke store kiya
                  final bool isRead = noti['isRead'] as bool;
                  final Color color = noti['color'] as Color;
                  final IconData icon = noti['icon'] as IconData;
                  final String title = noti['title'] as String;
                  final String desc = noti['desc'] as String;
                  final String time = noti['time'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : AppColor.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRead ? AppColor.surface : AppColor.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 14
                              )),
                              const SizedBox(height: 4),
                              Text(desc, style: const TextStyle(color: AppColor.textGrey, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(time, style: const TextStyle(color: AppColor.textGrey, fontSize: 10, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
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