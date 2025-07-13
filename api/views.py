from django.contrib.auth import get_user_model
from django.db.models import Q
from rest_framework import generics, permissions, viewsets, status
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError, PermissionDenied
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema
from .models import InsuranceContract, InsuranceType, ServiceRequest, RequestAttachment, MaintenanceContract, MaintenancePackage, TechnicianProfile
from .serializers import (
    InsuranceContractSerializer, InsuranceCreateSerializer, InsuranceQuoteSerializer, InsuranceTypeSerializer, UserRegisterSerializer, UserProfileSerializer, ServiceRequestSerializer,
    ServiceRequestListSerializer, ServiceRequestCreateSerializer, 
    ServiceRequestStatusUpdateSerializer, ServiceRequestCancelSerializer,
    ServiceRequestPriceSerializer, ServiceRequestDiscountSerializer,
    ServiceRequestPaymentSerializer, ServiceRequestRatingSerializer,
    MaintenanceContractSerializer, QuoteRequestSerializer, MaintenancePackageSerializer
)
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import MyTokenObtainPairSerializer
import django.db.models as models

User = get_user_model()


class UserRegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]


class UserProfileView(generics.RetrieveAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class ServiceRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    queryset = ServiceRequest.objects.all()

    def get_serializer_class(self):
        if self.action == 'create':
            return ServiceRequestCreateSerializer
        if self.action == 'list':
            return ServiceRequestListSerializer
        if self.action == 'cancel':
            return ServiceRequestCancelSerializer
        if self.action == 'set_price':
            return ServiceRequestPriceSerializer
        if self.action == 'apply_discount':
            return ServiceRequestDiscountSerializer
        if self.action == 'pay':
            return ServiceRequestPaymentSerializer
        if self.action == 'rate':
            return ServiceRequestRatingSerializer
        return ServiceRequestSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = super().get_queryset()
        
        if user.role == 'customer':
            return queryset.filter(customer=user)
        if user.role == 'technician':
            return queryset.filter(Q(technician=user) | Q(technician__isnull=True, status='submitted'))
        return queryset if user.is_staff else queryset.none()
    
    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)
    
    @extend_schema(summary="Accept a request", request=None, responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        if user.role != 'technician':
            return Response(
                {"detail": "فقط تکنسین‌ها می‌توانند درخواست را بپذیرند."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if service_request.technician is not None:
            return Response(
                {"detail": "این درخواست قبلاً به تکنسین دیگری اختصاص داده شده است."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if service_request.status != 'submitted':
            return Response(
                {"detail": "فقط درخواست‌های با وضعیت 'ثبت شده' قابل پذیرش هستند."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        service_request.technician = user
        service_request.status = 'assigned'
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        if service_request.technician != user:
            return Response(
                {"detail": "شما تکنسین اختصاص داده شده به این درخواست نیستید."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = ServiceRequestStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        new_status = serializer.validated_data['status']
        
        # بررسی انتقال وضعیت مجاز
        if service_request.status == 'assigned' and new_status != 'in_progress':
            return Response(
                {"detail": "فقط امکان تغییر به وضعیت 'در حال انجام' وجود دارد."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if service_request.status == 'in_progress' and new_status not in ['completed', 'cancelled']:
            return Response(
                {"detail": "فقط امکان تغییر به وضعیت 'تکمیل شده' یا 'لغو شده' وجود دارد."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        service_request.status = new_status
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @extend_schema(summary="Set final price for a completed request", 
                  request=ServiceRequestPriceSerializer, 
                  responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def set_price(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        if not service_request.can_set_price(user):
            raise PermissionDenied("You are not allowed to set price for this request.")
        
        serializer = ServiceRequestPriceSerializer(
            service_request,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        service_request.final_price = serializer.validated_data['final_price']
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @extend_schema(summary="Apply discount code", 
                  request=ServiceRequestDiscountSerializer, 
                  responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def apply_discount(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        if user != service_request.customer:
            raise PermissionDenied("Only customer can apply discount.")
        
        if service_request.status != 'completed' or service_request.final_price is None:
            raise ValidationError("Price must be set before applying discount.")
        
        serializer = ServiceRequestDiscountSerializer(
            service_request,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        # در اینجا می‌توانید منطق اعمال تخفیف را اضافه کنید
        discount_code = serializer.validated_data['discount_code']
        service_request.discount_code = discount_code
        service_request.discount_amount = 10000  # مثال: تخفیف 10,000 تومانی
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @extend_schema(summary="Pay for the service", 
                  request=ServiceRequestPaymentSerializer, 
                  responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        serializer = ServiceRequestPaymentSerializer(
            service_request,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        # در اینجا می‌توانید منطق پرداخت را اضافه کنید
        service_request.payment_status = True
        service_request.status = 'paid'
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @extend_schema(summary="Rate and review the service", 
                  request=ServiceRequestRatingSerializer, 
                  responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def rate(self, request, pk=None):
        service_request = self.get_object()
        user = request.user
        
        serializer = ServiceRequestRatingSerializer(
            service_request,
            data=request.data,
            context={'request': request}
        )
        if not serializer.is_valid():
            print("Validation errors:", serializer.errors)  # Log errors to console
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        serializer.is_valid(raise_exception=True)
        
        service_request.rating = serializer.validated_data['rating']
        service_request.review = serializer.validated_data.get('review', '')
        service_request.save()
        
        # به‌روزرسانی امتیاز تکنسین
        if service_request.technician:
            try:
                technician_profile = service_request.technician.technicianprofile
                completed_requests = ServiceRequest.objects.filter(
                    technician=service_request.technician,
                    status='paid',
                    rating__isnull=False
                )
                if completed_requests.exists():
                    technician_profile.rating = completed_requests.aggregate(
                        models.Avg('rating')
                    )['rating__avg']
                    technician_profile.save()
            except TechnicianProfile.DoesNotExist:
                pass
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )

    @extend_schema(summary="Cancel a request", request=ServiceRequestCancelSerializer, responses={200: ServiceRequestSerializer})
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        service_request = self.get_object()
        serializer = ServiceRequestCancelSerializer(
            service_request,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        service_request.status = 'cancelled'
        service_request.cancel_reason = serializer.validated_data.get('cancel_reason', '')
        service_request.save()
        
        return Response(
            ServiceRequestSerializer(service_request).data,
            status=status.HTTP_200_OK
        )


class MaintenanceContractViewSet(viewsets.ModelViewSet):
    queryset = MaintenanceContract.objects.all()
    serializer_class = MaintenanceContractSerializer
    
    def get_queryset(self):
        return MaintenanceContract.objects.filter(user=self.request.user, is_active=True)
    
    def get_serializer_class(self):
        if self.action == 'create':
            return MaintenanceContractSerializer  # یا یک سریالایزر جدا برای create
        return MaintenanceContractSerializer
    
    def perform_create(self, serializer):
        data = self.request.data
        package = MaintenancePackage.objects.get(package_type=data.get('package'))  # فرض بر package به جای package_id
        quote_serializer = QuoteRequestSerializer(data={
            'building_floors': data.get('building_floors'),
            'building_type': data.get('building_type'),
            'elevator_age': data.get('elevator_age'),
            'elevator_count': data.get('elevator_count'),
        })
        quote_serializer.is_valid(raise_exception=True)
        price = quote_serializer.calculate_price(package.package_type)
        serializer.save(user=self.request.user, price=price, package=package, start_date=date.today())

class InsuranceContractViewSet(viewsets.ModelViewSet):
    queryset = InsuranceContract.objects.all()
    serializer_class = InsuranceContractSerializer
    
    def get_queryset(self):
        return InsuranceContract.objects.filter(user=self.request.user, is_active=True)
    
    def get_serializer_class(self):
        if self.action == 'create':
            return InsuranceCreateSerializer
        return InsuranceContractSerializer
    
    def perform_create(self, serializer):
        data = self.request.data
        insurance_type = InsuranceType.objects.get(id=data.get('insurance_type'))  # ID رو بگیر
        quote_serializer = InsuranceQuoteSerializer(data={
            'building_floors': data.get('building_floors'),
            'building_type': data.get('building_type'),
            'elevator_age': data.get('elevator_age'),
            'elevator_count': data.get('elevator_count'),
            'coverage_level': data.get('coverage_level'),
        })
        quote_serializer.is_valid(raise_exception=True)
        price = quote_serializer.calculate_price(insurance_type.name)
        serializer.save(user=self.request.user, price=price, insurance_type=insurance_type, start_date=date.today())


class QuoteView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = QuoteRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # محاسبه قیمت برای هر پکیج
        packages = MaintenancePackage.objects.all()
        results = []
        
        for package in packages:
            price = serializer.calculate_price(package.package_type)
            results.append({
                'package': MaintenancePackageSerializer(package).data,
                'price': price
            })
        
        return Response(results)


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
class InsuranceQuoteView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = InsuranceQuoteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # محاسبه قیمت برای هر نوع بیمه
        insurance_types = InsuranceType.objects.all()
        results = []
        
        for ins_type in insurance_types:
            price = serializer.calculate_price(ins_type.name)
            results.append({
                'insurance_type': InsuranceTypeSerializer(ins_type).data,
                'price': price
            })
        
        return Response(results)