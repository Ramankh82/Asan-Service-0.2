from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import InsuranceContractViewSet, InsuranceQuoteView, ServiceRequestViewSet, UserRegisterView, UserProfileView, MyTokenObtainPairView, MaintenanceContractViewSet, QuoteView 
from django.conf import settings
from django.conf.urls.static import static

router = DefaultRouter()
router.register(r'requests', ServiceRequestViewSet, basename='servicerequest')
router.register(r'contracts', MaintenanceContractViewSet, basename='contract')

urlpatterns = [
    path('auth/register/', UserRegisterView.as_view(), name='register'),
    path('auth/login/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/profile/', UserProfileView.as_view(), name='user_profile'),
    path('contracts/quote/', QuoteView.as_view(), name='contract-quote'),
    path('contracts/active/', MaintenanceContractViewSet.as_view({'get': 'active'}), name='active-contract'),
    path('', include(router.urls)),
    path('insurance/', InsuranceContractViewSet.as_view({'get': 'list', 'post': 'create'}), name='insurance-list'),
    path('insurance/quote/', InsuranceQuoteView.as_view(), name='insurance-quote'),
]