def test_technician_can_accept_request(self):
    self.client.force_authenticate(user=self.technician)
    url = reverse('servicerequest-accept', args=[self.request.id])
    response = self.client.post(url)
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.request.refresh_from_db()
    self.assertEqual(self.request.status, 'assigned')
    self.assertEqual(self.request.technician, self.technician)

def test_cannot_accept_already_assigned_request(self):
    self.request.technician = self.other_technician
    self.request.save()
    
    self.client.force_authenticate(user=self.technician)
    url = reverse('servicerequest-accept', args=[self.request.id])
    response = self.client.post(url)
    self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

def test_valid_status_transition(self):
    self.request.technician = self.technician
    self.request.status = 'assigned'
    self.request.save()
    
    self.client.force_authenticate(user=self.technician)
    url = reverse('servicerequest-update-status', args=[self.request.id])
    response = self.client.post(url, {'status': 'in_progress'})
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.request.refresh_from_db()
    self.assertEqual(self.request.status, 'in_progress')