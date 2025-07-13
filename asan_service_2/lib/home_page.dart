import 'package:asan_service_app/insurance_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'create_request_page.dart';
import 'profile_page.dart';
import 'request_detail_page.dart';
import 'contract_card.dart';
import 'project_request_page.dart';
import 'quote_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<dynamic> _requests = [];
  List<dynamic> _contracts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await Future.wait([
        _loadServiceRequests(),
        _loadMaintenanceContracts(),
      ]);
    }
  }

  Future<void> _loadServiceRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        await authService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final requests = await _apiService.getServiceRequests(token).timeout(const Duration(seconds: 15));
      print('Service requests loaded: $requests'); // لاگ برای دیباگ

      final processedRequests = requests.map((request) {
        if (request['final_price'] != null) {
          request['final_price'] = request['final_price'] is String
              ? double.tryParse(request['final_price']) ?? 0.0
              : (request['final_price'] as num).toDouble();
        }
        return request;
      }).toList();

      if (mounted) {
        setState(() {
          _requests = processedRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading service requests: $e'); // لاگ برای دیباگ
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در بارگذاری درخواست‌ها. لطفاً دوباره تلاش کنید.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMaintenanceContracts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        await authService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final contracts = await _apiService.getMaintenanceContracts(token).timeout(const Duration(seconds: 15));
      print('Contracts loaded: $contracts'); // لاگ برای دیباگ

      if (mounted) {
        setState(() {
          _contracts = contracts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contracts: $e'); // لاگ برای دیباگ
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در بارگذاری قراردادها. لطفاً دوباره تلاش کنید.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _navigateAndRefresh(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (result == true && mounted) {
      await Future.wait([
        _loadServiceRequests(),
        _loadMaintenanceContracts(),
      ]);
    }
  }

  List<dynamic> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    return _requests.where((request) {
      final title = request['title']?.toString().toLowerCase() ?? '';
      final status = request['status']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
             status.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> get _filteredContracts {
    if (_searchQuery.isEmpty) return _contracts;
    return _contracts.where((contract) {
      final packageName = contract['package']['name']?.toString().toLowerCase() ?? '';
      return packageName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildRequestItem(BuildContext context, dynamic request) {
    final status = request['status'] ?? 'unknown';
    final icon = _getStatusIcon(status);
    final color = _getStatusColor(status);

    final price = request['final_price'] is num
        ? (request['final_price'] as num).toDouble()
        : 0.0;
    final paymentStatus = request['payment_status'] ?? false;
    final formattedPrice = NumberFormat.currency(
      symbol: '',
      decimalDigits: 0,
    ).format(price);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateAndRefresh(RequestDetailPage(requestId: request['id'])),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['title'] ?? "بدون عنوان",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'وضعیت: ${_getStatusText(status)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (price > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'هزینه: $formattedPrice تومان',
                        style: TextStyle(
                          fontSize: 14,
                          color: paymentStatus ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractItem(BuildContext context, dynamic contract) {
    return ContractCard(
      hasActiveContract: contract['is_active'] ?? false,
      daysRemaining: contract['days_remaining'] ?? 0,
      packageName: contract['package']['name']?.toString() ?? 'نامشخص',
      onSubscribePressed: () => _navigateAndRefresh(const QuotePage()),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.access_time;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'paid':
        return Icons.payment;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.blueAccent;
      case 'completed':
        return Colors.green;
      case 'paid':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'در انتظار بررسی';
      case 'assigned':
        return 'اختصاص داده شده';
      case 'in_progress':
        return 'در حال انجام';
      case 'completed':
        return 'تکمیل شده';
      case 'paid':
        return 'پرداخت شده';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'درخواستی یا قراردادی برای نمایش وجود ندارد',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _loadServiceRequests();
              _loadMaintenanceContracts();
            },
            child: const Text('بارگذاری مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 72,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'خطایی رخ داده است',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadServiceRequests();
              _loadMaintenanceContracts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildMainSections() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('خدمات اصلی'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildServiceCard(
                  title: 'قرارداد نگهداری',
                  icon: Icons.verified_user,
                  color: Colors.blue.shade600,
                  onTap: () => _navigateAndRefresh(const QuotePage()),
                ),
                _buildServiceCard(
                  title: 'درخواست نصب',
                  icon: Icons.construction,
                  color: Colors.green.shade600,
                  onTap: () => _navigateAndRefresh(const ProjectRequestPage()),
                ),
                _buildServiceCard(
                  title: 'بیمه آسانسور',
                  icon: Icons.security,
                  color: Colors.orange.shade600,
                  onTap: () => _navigateAndRefresh(const InsurancePage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractList() {
    if (_filteredContracts.isEmpty) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('قراردادهای نگهداری'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filteredContracts.length,
            itemBuilder: (context, index) =>
                _buildContractItem(context, _filteredContracts[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    if (_filteredRequests.isEmpty) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('درخواست‌های سرویس'),
          ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filteredRequests.length,
            itemBuilder: (context, index) =>
                _buildRequestItem(context, _filteredRequests[index]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isTechnician = authService.userRole == 'technician';
    final appBarTitle = isTechnician ? 'کارهای من' : 'درخواست‌های من';
    print('User role: ${authService.userRole}, isTechnician: $isTechnician'); // لاگ برای دیباگ

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _navigateAndRefresh(const ProfilePage()),
            tooltip: 'پروفایل کاربری',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('خروج از حساب'),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
              _loadServiceRequests();
              _loadMaintenanceContracts();
            },
            tooltip: 'بارگذاری مجدد',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await Future.wait([
            _loadServiceRequests(),
            _loadMaintenanceContracts(),
          ]);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : (_requests.isEmpty && _contracts.isEmpty && isTechnician)
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'جستجو در درخواست‌ها و قراردادها...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                onChanged: (value) => setState(() => _searchQuery = value),
                              ),
                            ),
                            if (!isTechnician) ...[
                              _buildMainSections(),
                              _buildContractList(),
                            ],
                            _buildRequestList(),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: isTechnician
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateAndRefresh(const CreateRequestPage()),
              icon: const Icon(Icons.add),
              label: const Text('درخواست جدید'),
              tooltip: 'ثبت درخواست جدید',
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
    );
  }
}