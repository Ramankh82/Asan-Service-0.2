from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from .models import User, ServiceRequest

class ServiceRequestTests(APITestCase):
    def setUp(self):
        self.customer = User.objects.create_user(
            phone_number='09123456789',
            password='testpass',
            first_name='John',
            last_name='Doe',
            role='customer'
        )
        self.technician = User.objects.create_user(
            phone_number='09123456780',
            password='testpass',
            first_name='Tech',
            last_name='Nician',
            role='technician'
        )
        self.admin = User.objects.create_superuser(
            phone_number='09123456781',
            password='adminpass',
            first_name='Admin',
            last_name='User'
        )
        self.request = ServiceRequest.objects.create(
            customer=self.customer,
            title='Test Request',
            description='Test Description',
            address='Test Address',
            status='submitted'
        )

    def test_customer_cancel_request(self):
        self.client.force_authenticate(user=self.customer)
        url = reverse('servicerequest-cancel', args=[self.request.id])
        response = self.client.post(url, {'cancel_reason': 'No longer needed'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.request.refresh_from_db()
        self.assertEqual(self.request.status, 'cancelled')
        self.assertEqual(self.request.cancel_reason, 'No longer needed')

    def test_technician_cancel_assigned_request(self):
        self.request.technician = self.technician
        self.request.status = 'assigned'
        self.request.save()
        
        self.client.force_authenticate(user=self.technician)
        url = reverse('servicerequest-cancel', args=[self.request.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_admin_cancel_any_request(self):
        self.client.force_authenticate(user=self.admin)
        url = reverse('servicerequest-cancel', args=[self.request.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_cannot_cancel_completed_request(self):
        self.request.status = 'completed'
        self.request.save()
        
        self.client.force_authenticate(user=self.customer)
        url = reverse('servicerequest-cancel', args=[self.request.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)