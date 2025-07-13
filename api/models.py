from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from decimal import Decimal
from datetime import date, timedelta

# تعریف STATUS_CHOICES قبل از استفاده در مدل
STATUS_CHOICES = (
    ('submitted', 'Submitted'),
    ('assigned', 'Assigned'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
    ('paid', 'Paid'),
)


class UserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError('The Phone Number field must be set')
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(phone_number, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = (
        ('customer', 'Customer'),
        ('technician', 'Technician'),
        ('admin', 'Admin'),
    )
    
    phone_number = models.CharField(max_length=20, unique=True)
    first_name = models.CharField(max_length=100, blank=True)
    last_name = models.CharField(max_length=100, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    def __str__(self):
        return self.phone_number


class TechnicianProfile(models.Model):
    STATUS_CHOICES = (
        ('pending_approval', 'Pending Approval'),
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('rejected', 'Rejected'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    bio = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='pending_approval')
    rating = models.FloatField(default=0.0)
    
    def __str__(self):
        return f"Profile of {self.user.phone_number}"


class ServiceRequest(models.Model):
    customer = models.ForeignKey(User, related_name='customer_requests', on_delete=models.CASCADE)
    technician = models.ForeignKey(User, related_name='technician_requests', on_delete=models.SET_NULL, null=True, blank=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    address = models.TextField()
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='submitted')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    cancel_reason = models.TextField(blank=True, null=True)
    final_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    discount_code = models.CharField(max_length=50, blank=True, null=True)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    payment_status = models.BooleanField(default=False)
    rating = models.IntegerField(null=True, blank=True)
    review = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.title} for {self.customer.phone_number}"

    def can_cancel(self, user):
        """Check if user can cancel this request"""
        if user.is_staff or user.role == 'admin':
            return True
        if user == self.customer:
            return self.status in ['submitted', 'assigned']
        if user == self.technician:
            return self.status in ['assigned', 'in_progress']
        return False

    def can_set_price(self, user):
        return (user == self.technician and 
                self.status == 'completed' and 
                self.final_price is None)

    def can_pay(self, user):
        return (user == self.customer and 
                self.status == 'completed' and 
                self.final_price is not None)

    def can_rate(self, user):
        return (user == self.customer and 
                self.status == 'paid' and 
                self.rating is None)

        def save(self, *args, **kwargs):
            # تبدیل مقدار به Decimal قبل از ذخیره
            if isinstance(self.final_price, str):
                self.final_price = Decimal(self.final_price)
            super().save(*args, **kwargs)
 
# Define MaintenancePackage before MaintenanceContract
class MaintenancePackage(models.Model):
    PACKAGE_TYPES = (
        ('basic', 'پکیج پایه'),
        ('standard', 'پکیج استاندارد'),
        ('premium', 'پکیج ویژه'),
    )
    
    name = models.CharField(max_length=100)
    package_type = models.CharField(max_length=20, choices=PACKAGE_TYPES)
    description = models.TextField()
    base_price = models.DecimalField(max_digits=10, decimal_places=2)
    features = models.JSONField(default=list)
    
    def __str__(self):
        return f"{self.name} ({self.get_package_type_display()})"
    
    # در فایل models.py قبل از کلاس QuoteRequestSerializer این مدل را اضافه کنید
class RequestAttachment(models.Model):
    request = models.ForeignKey(ServiceRequest, related_name='attachments', on_delete=models.CASCADE)
    file = models.FileField(upload_to='request_attachments/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Attachment for {self.request.title}"

# Then define other models that depend on MaintenancePackage
class MaintenanceContract(models.Model):
    user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='contracts')
    package = models.ForeignKey(MaintenancePackage, on_delete=models.PROTECT)
    start_date = models.DateField()
    end_date = models.DateField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    building_floors = models.IntegerField()
    building_type = models.CharField(max_length=50)
    elevator_age = models.CharField(max_length=50)
    elevator_count = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"قرارداد {self.package.name} برای {self.user.phone_number}"
    
    def save(self, *args, **kwargs):
        # محاسبه خودکار end_date بر اساس نوع پکیج
        if not self.pk:
            if self.package.package_type == 'basic':
                self.end_date = self.start_date + timedelta(days=365)
            elif self.package.package_type == 'standard':
                self.end_date = self.start_date + timedelta(days=730)  # 2 سال
            else:
                self.end_date = self.start_date + timedelta(days=1095)  # 3 سال
        super().save(*args, **kwargs)
    
    @property
    def days_remaining(self):
        return (self.end_date - date.today()).days if self.is_active else 0
class InsuranceType(models.Model):
    name = models.CharField(max_length=100)  # مثلاً 'مسئولیت مدنی', 'حوادث', etc.
    description = models.TextField(blank=True)
    base_price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return self.name

class InsuranceContract(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='insurance_contracts')
    insurance_type = models.ForeignKey(InsuranceType, on_delete=models.PROTECT)
    start_date = models.DateField(default=date.today)
    end_date = models.DateField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    building_floors = models.IntegerField()
    building_type = models.CharField(max_length=50)  # مثلاً 'مسکونی', 'تجاری'
    elevator_age = models.CharField(max_length=50)  # مثلاً 'کمتر از ۵ سال'
    elevator_count = models.IntegerField()
    coverage_level = models.CharField(max_length=50)  # مثلاً 'پایه', 'متوسط', 'کامل'
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"بیمه {self.insurance_type.name} برای {self.user.phone_number}"
    
    def save(self, *args, **kwargs):
        # محاسبه خودکار end_date (فرضاً ۱ سال)
        if not self.pk:
            self.end_date = self.start_date + timedelta(days=365)
        super().save(*args, **kwargs)
    
    @property
    def days_remaining(self):
        return (self.end_date - date.today()).days if self.is_active else 0
# Rest of your models (User, TechnicianProfile, ServiceRequest, etc.)...