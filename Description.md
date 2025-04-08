# Hand Sign Detection System

A comprehensive system for detecting and classifying hand signs using computer vision and machine learning. This project includes a Flask backend API that can be integrated with mobile applications for real-time hand sign detection.

## Features

- Real-time hand sign detection and classification
- Support for both single and double hand gestures
- User authentication and management
- Training data collection system
- RESTful API for mobile application integration
- MySQL database integration for user management

## Project Structure

```
HandSign_detection/
├── app.py                 # Main Flask application
├── model_handler.py       # Hand sign detection model handler
├── requirements.txt       # Python dependencies
├── .env                   # Environment variables
├── Model/                 # Trained model and labels
│   ├── keras_model.h5    # Pre-trained Keras model
│   └── labels.txt        # Hand sign labels
└── Data/                 # Training data directory
    ├── A/               # Directory for sign 'A'
    ├── B/               # Directory for sign 'B'
    └── ...              # Other sign directories
```

## Prerequisites

- Python 3.8 or higher
- MySQL Server
- Virtual environment (recommended)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd HandSign_detection
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Unix/macOS
# or
.\venv\Scripts\activate  # On Windows
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up MySQL database:
```sql
CREATE DATABASE handsign_detection;
```

5. Configure environment variables:
Create a `.env` file with the following content:
```
JWT_SECRET_KEY=your-secret-key-here
FLASK_ENV=development
FLASK_DEBUG=1

# MySQL Configuration
MYSQL_HOST=localhost
MYSQL_USER=your_mysql_username
MYSQL_PASSWORD=your_mysql_password
MYSQL_DB=handsign_detection
MYSQL_PORT=3306
```

## API Endpoints

### Authentication
- `POST /register` - Register a new user
  ```json
  {
    "username": "string",
    "email": "string",
    "password": "string"
  }
  ```

- `POST /login` - Login and get JWT token
  ```json
  {
    "username": "string",
    "password": "string"
  }
  ```

### Model Operations
- `POST /collect-data` - Collect training data (requires authentication)
  ```json
  {
    "image": "base64_encoded_image",
    "label": "string"
  }
  ```

- `POST /test-model` - Test the model with new images (requires authentication)
  ```json
  {
    "image": "base64_encoded_image"
  }
  ```

- `GET /labels` - Get available hand sign labels

## Usage

1. Start the Flask server:
```bash
python app.py
```

2. The server will run on `http://localhost:5000`

3. Example API calls:

Register a new user:
```bash
curl -X POST http://localhost:5000/register \
  -H "Content-Type: application/json" \
  -d '{"username": "user1", "email": "user1@example.com", "password": "password123"}'
```

Login:
```bash
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d '{"username": "user1", "password": "password123"}'
```

Test the model:
```bash
curl -X POST http://localhost:5000/test-model \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_encoded_image"}'
```

## Model Details

The system uses a pre-trained Keras model for hand sign classification. The model supports the following hand signs:
- Alphabet letters (A-Z)
- Numbers (0-9)
- Common gestures (Hello, Thanks, I love you, Yes, No)

## Mobile App Integration

To integrate with a mobile app:
1. Capture hand sign images using the device camera
2. Convert images to base64 format
3. Send the base64 image to the `/test-model` endpoint
4. Process the response to display the detected hand sign

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenCV for computer vision capabilities
- TensorFlow/Keras for machine learning framework
- MediaPipe for hand tracking
- Flask for the web framework 