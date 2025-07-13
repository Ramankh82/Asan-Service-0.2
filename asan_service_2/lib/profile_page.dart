import 'package:asan_service_app/api_service.dart';
import 'package:asan_service_app/auth_service.dart';
import 'package:asan_service_app/edit_profile_page.dart'; // import جدید
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>>? _profileFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileDetails();
    });
  }

  Future<void> _loadProfileDetails() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _profileFuture = _apiService.getUserProfile(token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل کاربری'),
        // دکمه ویرایش
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage(initialData: snapshot.data!)),
                    );
                    if (result == true) _loadProfileDetails(); // رفرش پس از ویرایش
                  },
                );
              }
              return const SizedBox.shrink(); // در حالت لودینگ دکمه را نشان نده
            }
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileDetails,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('خطا در دریافت اطلاعات.'));
            }

            final profileData = snapshot.data!;
            return ListView( // برای فعال کردن رفرش با کشیدن
              padding: const EdgeInsets.all(16.0),
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('نام و نام خانوادگی'),
                        subtitle: Text('${profileData['first_name']} ${profileData['last_name']}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_android_outlined),
                        title: const Text('شماره موبایل'),
                        subtitle: Text(profileData['phone_number'] ?? '-'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.work_outline),
                        title: const Text('نقش'),
                        subtitle: Text(profileData['role'] == 'technician' ? 'تکنسین' : 'مشتری'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}