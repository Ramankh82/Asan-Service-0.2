import 'package:asan_service_app/api_service.dart';
import 'package:asan_service_app/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RequestDetailPage extends StatefulWidget {
  final int requestId;
  const RequestDetailPage({super.key, required this.requestId});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  Future<Map<String, dynamic>>? _requestDetailFuture;
  final ApiService _apiService = ApiService();
  bool _isActionLoading = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequestDetails();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadRequestDetails() async {
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token != null && mounted) {
      setState(() {
        _requestDetailFuture = _apiService.getServiceRequestDetail(
          token: token,
          requestId: widget.requestId,
        );
      });
    }
  }

  Future<void> _acceptRequest() async {
    if (!mounted || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.acceptServiceRequest(
        token: token,
        requestId: widget.requestId,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست با موفقیت پذیرفته شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پذیرش درخواست: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (!mounted || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.updateRequestStatus(
        token: token,
        requestId: widget.requestId,
        newStatus: newStatus,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('وضعیت به ${_getStatusText(newStatus)} تغییر یافت'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تغییر وضعیت: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPrice() async {
    if (!mounted || _isActionLoading) return;

    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً مبلغ معتبر وارد کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.setRequestPrice(
        token: token,
        requestId: widget.requestId,
        price: price,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _priceController.clear();
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('قیمت ${price.toStringAsFixed(0)} تومان ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت قیمت: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyDiscount() async {
    if (!mounted || _isActionLoading || _discountController.text.isEmpty) return;

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.applyDiscount(
        token: token,
        requestId: widget.requestId,
        discountCode: _discountController.text,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _discountController.clear();
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کد تخفیف با موفقیت اعمال شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در اعمال تخفیف: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _payForRequest() async {
    if (!mounted || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.payForRequest(
        token: token,
        requestId: widget.requestId,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پرداخت با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پرداخت: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rateRequest() async {
    if (!mounted || _isActionLoading || _selectedRating == 0) return;

    setState(() => _isActionLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) return;

      final updatedRequest = await _apiService.rateRequest(
        token: token,
        requestId: widget.requestId,
        rating: _selectedRating,
        review: _reviewController.text,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _requestDetailFuture = Future.value(updatedRequest);
          _selectedRating = 0;
          _reviewController.clear();
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('امتیاز و نظر با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت امتیاز: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusUpdateDialog(String currentStatus) {
    final statusOptions = {
      'in_progress': 'در حال انجام',
      'completed': 'تکمیل شده',
      'cancelled': 'لغو شده',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر وضعیت درخواست'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.entries
              .where((entry) => entry.key != currentStatus)
              .map((entry) => ListTile(
                    title: Text(entry.value),
                    onTap: () {
                      Navigator.pop(context);
                      _updateStatus(entry.key);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  void _showPriceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت هزینه نهایی'),
        content: TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'مبلغ به تومان',
            hintText: 'مثال: 150000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setPrice();
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اعمال کد تخفیف'),
        content: TextField(
          controller: _discountController,
          decoration: const InputDecoration(
            labelText: 'کد تخفیف',
            hintText: 'کد تخفیف خود را وارد کنید',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyDiscount();
            },
            child: const Text('اعمال'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('امتیازدهی و نظر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('لطفاً به کیفیت خدمات امتیاز دهید:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'نظر شما (اختیاری)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rateRequest();
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isTechnician = authService.userRole == 'technician';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات درخواست')),
        body: RefreshIndicator(
          onRefresh: _loadRequestDetails,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _requestDetailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('خطا در دریافت اطلاعات درخواست'),
                      TextButton(
                        onPressed: _loadRequestDetails,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('اطلاعاتی برای نمایش وجود ندارد'));
              }

              final request = snapshot.data!;
              final customer = request['customer'] ?? {};
              final technician = request['technician'] ?? {};
              final status = request['status'] ?? 'unknown';
              final price = double.tryParse(request['final_price']?.toString() ?? '0') ?? 0;
              final discount = double.tryParse(request['discount_amount']?.toString() ?? '0') ?? 0;
              final totalPrice = price - discount;
              final paymentStatus = request['payment_status'] ?? false;
              final hasRating = request['rating'] != null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['title'] ?? 'بدون عنوان',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('وضعیت:', _getStatusText(status)),
                          _buildDetailRow('آدرس:', request['address'] ?? '-'),
                          const SizedBox(height: 12),
                          _buildDetailRow('توضیحات:', request['description'] ?? '-'),
                          const SizedBox(height: 12),
                          if (price > 0) ...[
                            const Divider(height: 24),
                            _buildDetailRow('هزینه خدمات:', '$price تومان'),
                            if (discount > 0)
                              _buildDetailRow('تخفیف:', '$discount تومان'),
                            _buildDetailRow(
                              'مبلغ قابل پرداخت:', 
                              '$totalPrice تومان',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            _buildDetailRow(
                              'وضعیت پرداخت:', 
                              paymentStatus ? 'پرداخت شده' : 'در انتظار پرداخت',
                              style: TextStyle(
                                color: paymentStatus ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                          if (hasRating) ...[
                            const Divider(height: 24),
                            _buildDetailRow('امتیاز:', '${request['rating']}/5'),
                            if (request['review'] != null)
                              _buildDetailRow('نظر مشتری:', request['review']),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isActionLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_isActionLoading) 
                    _buildActionButtons(isTechnician, status, paymentStatus, hasRating, price),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTechnician, String status, bool paymentStatus, bool hasRating, double price) {
    final buttons = <Widget>[];

    if (isTechnician) {
      if (status == 'submitted') {
        buttons.add(
          _buildActionButton(
            'پذیرفتن درخواست',
            _acceptRequest,
          ),
        );
      } else if (status == 'assigned' || status == 'in_progress') {
        buttons.add(
          _buildActionButton(
            'تغییر وضعیت',
            () => _showStatusUpdateDialog(status),
          ),
        );
      } else if (status == 'completed' && price == 0) {
        buttons.add(
          _buildActionButton(
            'ثبت هزینه نهایی',
            _showPriceDialog,
          ),
        );
      }
    } else {
      if (status == 'completed' && price > 0 && !paymentStatus) {
        buttons.addAll([
          _buildActionButton(
            'اعمال کد تخفیف',
            _showDiscountDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'پرداخت نهایی',
            _payForRequest,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          ),
        ]);
      } else if (status == 'paid' && !hasRating) {
        buttons.add(
          _buildActionButton(
            'ثبت امتیاز و نظر',
            _showRatingDialog,
          ),
        );
      }
    }

    return Column(
      children: buttons,
    );
  }

  Widget _buildActionButton(
    String text,
    VoidCallback onPressed, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: _isActionLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(text),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'ثبت شده';
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

  Widget _buildDetailRow(String title, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: style ?? const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}