# Asan Service App

## Overview
The Asan Service App is a mobile application developed using Flutter, designed to provide elevator maintenance and insurance services. This app allows users (customers and technicians) to manage service requests, select maintenance packages, and apply for elevator insurance seamlessly. The backend is built with Django and REST Framework, ensuring robust API support and authentication via JWT.

## Features
- **User Authentication:** Register and log in with phone number-based authentication.
- **Service Requests:** Customers can create, view, and cancel service requests, while technicians can accept and update their status.
- **Maintenance Packages:** Choose from basic, standard, or premium maintenance packages with customizable options based on building details.
- **Elevator Insurance:** Apply for insurance with various coverage levels (basic, medium, full) tailored to elevator specifications.
- **Profile Management:** View and edit user profiles.
- **Real-Time Updates:** Sync with the backend for real-time request and contract status updates.
- **Multi-Language Support:** Supports Persian (RTL) with the Vazirmatn font.

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Django, Django REST Framework, DRF Spectacular (for API documentation)
- **Authentication:** REST Framework SimpleJWT
- **Database:** SQLite (default, can be configured for others)
- **Dependencies:** http, provider, intl, file_picker

## Installation

### Prerequisites
- Flutter SDK (install from [flutter.dev](https://flutter.dev))
- Python 3.x and pip
- Git (for version control)
- A code editor (e.g., VS Code or Android Studio)

### Backend Setup
1. Clone the repository:
   git clone https://github.com/username/asan-service-2.git
   cd asan-service-2
   
2. Create a virtual environment and activate it:
  python -m venv venv
  venv\Scripts\activate  # On Windows
  source venv/bin/activate  # On macOS/Linux

3. Install dependencies:
  pip install -r requirements.txt

4. Apply migrations:
  python manage.py makemigrations
  python manage.py migrate

5. Create a superuser:
  python manage.py createsuperuser

6. Run the server:
  python manage.py runserver

### Frontend Setup
1. Navigate to the Flutter project directory:
cd asan_service_2

2. Install dependencies:
flutter pub get

3. Run the app:
flutter run

## Configuration
- **API Base URL:** Update `_baseUrl` in `api_service.dart` to match your backend server (e.g., `http://10.0.2.2:8000/api` for local testing).
- **Environment Variables:** Add sensitive data (e.g., API keys) to a `.env` file if needed.

## Usage
1. **Register/Login:** Use the authentication screen to sign up or log in.
2. **Home Page:** Access service requests, contracts, and insurance options.
3. **Package Selection:** Enter building details and choose a maintenance package.
4. **Insurance Application:** Fill out the form to apply for elevator insurance.

## Contributing
1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -m "Add new feature"`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a Pull Request.

## Issues
If you encounter any bugs or have feature requests, please open an issue on the [GitHub Issues page](https://github.com/username/asan-service-2/issues).

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- Thanks to the Flutter and Django communities for their amazing tools and support.
- Inspired by the need for efficient elevator maintenance and insurance solutions.
