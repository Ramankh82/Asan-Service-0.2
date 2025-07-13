from decimal import Decimal
from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import InsuranceContract, InsuranceType, RequestAttachment, ServiceRequest, MaintenancePackage, MaintenanceContract

User = get_user_model()


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['phone_number'] = user.phone_number
        token['role'] = user.role
        token['first_name'] = user.first_name
        return token


class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = User
        fields = ('phone_number', 'password', 'first_name', 'last_name', 'role')
    
    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('phone_number', 'first_name', 'last_name', 'role')


class ServiceRequestListSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ('id', 'title', 'status', 'customer_id', 'technician_id', 'created_at', 'final_price', 'payment_status')


class ServiceRequestCreateSerializer(serializers.ModelSerializer):
    attachments = serializers.ListField(
        child=serializers.FileField(max_length=100000, allow_empty_file=False),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = ServiceRequest
        fields = ('title', 'description', 'address', 'attachments')
    
    def create(self, validated_data):
        attachments = validated_data.pop('attachments', [])
        request = super().create(validated_data)
        
        # ذخیره فایل‌های پیوست
        for attachment in attachments:
            RequestAttachment.objects.create(
                request=request,
                file=attachment
            )
        
        return request


class ServiceRequestSerializer(serializers.ModelSerializer):
    customer = UserProfileSerializer(read_only=True)
    technician = UserProfileSerializer(read_only=True)
    final_price = serializers.SerializerMethodField()

    class Meta:
        model = ServiceRequest
        fields = ('id', 'customer', 'technician', 'title', 'description', 'address',
                 'status', 'created_at', 'updated_at', 'cancel_reason', 'final_price',
                 'discount_code', 'discount_amount', 'payment_status', 'rating', 'review')
    
    def get_final_price(self, obj):
        return float(obj.final_price) if obj.final_price else 0.0
    

class ServiceRequestStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ['status']
    
    def validate_status(self, value):
        valid_statuses = ['assigned', 'in_progress', 'completed', 'cancelled']
        if value not in valid_statuses:
            raise ValidationError(
                f"وضعیت نامعتبر است. وضعیت‌های مجاز: {', '.join(valid_statuses)}"
            )
        return value


class ServiceRequestCancelSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ['cancel_reason']
    
    def validate(self, data):
        request = self.context.get('request')
        service_request = self.instance
        
        if not service_request.can_cancel(request.user):
            raise ValidationError("شما نمی‌توانید این درخواست را لغو کنید.")
        
        return data


class ServiceRequestPriceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ['final_price']
    
    def validate_final_price(self, value):
        if value <= 0:
            raise ValidationError("مبلغ باید بیشتر از صفر باشد.")
        return value


class ServiceRequestDiscountSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ['discount_code']
    
    def validate(self, data):
        # در اینجا می‌توانید منطق اعتبارسنجی کد تخفیف را اضافه کنید
        return data


class ServiceRequestPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = []
    
    def validate(self, data):
        service_request = self.instance
        if not service_request.can_pay(self.context['request'].user):
            raise ValidationError("شما نمی‌توانید این درخواست را پرداخت کنید.")
        return data


class ServiceRequestRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = ['rating', 'review']
    
    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise ValidationError("امتیاز باید بین 1 تا 5 باشد.")
        return value
    
    def validate(self, data):
        service_request = self.instance
        if not service_request.can_rate(self.context['request'].user):
            raise ValidationError("شما نمی‌توانید به این درخواست امتیاز دهید.")
        return data
    

class MaintenancePackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaintenancePackage
        fields = '__all__'


class MaintenanceContractSerializer(serializers.ModelSerializer):
    package = MaintenancePackageSerializer()
    days_remaining = serializers.SerializerMethodField()
    
    class Meta:
        model = MaintenanceContract
        fields = '__all__'
    
    def get_days_remaining(self, obj):
        return obj.days_remaining


class QuoteRequestSerializer(serializers.Serializer):
    building_floors = serializers.IntegerField(min_value=1)
    building_type = serializers.CharField(max_length=50)
    elevator_age = serializers.CharField(max_length=50)
    elevator_count = serializers.IntegerField(min_value=1)
    
    def calculate_price(self, package_type):
        # منطق قیمت‌دهی بر اساس پارامترهای ورودی
        floors = self.validated_data['building_floors']
        elevator_count = self.validated_data['elevator_count']
        age = self.validated_data['elevator_age']
        
        base_price = 1000000  # قیمت پایه
        
        # محاسبه بر اساس تعداد طبقات
        if floors > 10:
            base_price += (floors - 10) * 50000
        
        # محاسبه بر اساس تعداد آسانسورها
        base_price *= elevator_count
        
        # محاسبه بر اساس عمر آسانسور
        if age == '5-15':
            base_price *= 1.2
        elif age == '15+':
            base_price *= 1.5
        
        # اعمال ضریب بر اساس نوع پکیج
        if package_type == 'standard':
            base_price *= 1.5
        elif package_type == 'premium':
            base_price *= 2.0
        
        return base_price


class RequestAttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = RequestAttachment
        fields = ['id', 'file', 'uploaded_at']
class InsuranceTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = InsuranceType
        fields = '__all__'

class InsuranceContractSerializer(serializers.ModelSerializer):
    insurance_type = InsuranceTypeSerializer()
    days_remaining = serializers.SerializerMethodField()
    
    class Meta:
        model = InsuranceContract
        fields = '__all__'
    
    def get_days_remaining(self, obj):
        return obj.days_remaining

class InsuranceQuoteSerializer(serializers.Serializer):
    building_floors = serializers.IntegerField(min_value=1)
    building_type = serializers.CharField(max_length=50)
    elevator_age = serializers.CharField(max_length=50)
    elevator_count = serializers.IntegerField(min_value=1)
    coverage_level = serializers.CharField(max_length=50)  # 'پایه', 'متوسط', 'کامل'
    
    def calculate_price(self, insurance_type_name):
        # منطق محاسبه قیمت (شبیه به QuoteRequestSerializer)
        floors = self.validated_data['building_floors']
        elevator_count = self.validated_data['elevator_count']
        age = self.validated_data['elevator_age']
        coverage = self.validated_data['coverage_level']
        
        try:
            insurance_type = InsuranceType.objects.get(name=insurance_type_name)
            base_price = insurance_type.base_price
        except InsuranceType.DoesNotExist:
            raise ValidationError("نوع بیمه نامعتبر است.")
        
        # محاسبه بر اساس تعداد طبقات
        if floors > 10:
            base_price += (floors - 10) * Decimal('50000')
        
        # محاسبه بر اساس تعداد آسانسورها
        base_price *= elevator_count
        
        # محاسبه بر اساس عمر آسانسور
        if age == '۵ تا ۱۵ سال':
            base_price *= Decimal('1.2')
        elif age == 'بیشتر از ۱۵ سال':
            base_price *= Decimal('1.5')
        
        # محاسبه بر اساس سطح پوشش
        if coverage == 'متوسط':
            base_price *= Decimal('1.5')
        elif coverage == 'کامل':
            base_price *= Decimal('2.0')
        
        return base_price

class InsuranceCreateSerializer(serializers.ModelSerializer):
    insurance_type = serializers.PrimaryKeyRelatedField(queryset=InsuranceType.objects.all())

    class Meta:
        model = InsuranceContract
        fields = ['insurance_type', 'building_floors', 'building_type', 'elevator_age', 'elevator_count', 'coverage_level']
    
    def create(self, validated_data):
        quote_serializer = InsuranceQuoteSerializer(data=validated_data)
        quote_serializer.is_valid(raise_exception=True)
        price = quote_serializer.calculate_price(validated_data['insurance_type'].name)
        validated_data['price'] = price
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)