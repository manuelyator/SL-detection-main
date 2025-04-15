from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from datetime import timedelta
import os
from werkzeug.security import generate_password_hash, check_password_hash
from dotenv import load_dotenv
from model_handler import HandSignModel

# Load environment variables
load_dotenv()

app = Flask(__name__)

# MySQL Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+pymysql://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}@{os.getenv('MYSQL_HOST')}:{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DB')}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)

# Initialize extensions
db = SQLAlchemy(app)
jwt = JWTManager(app)
model_handler = HandSignModel()

# User model
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# Create database tables
with app.app_context():
    db.create_all()

# Routes
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'message': 'Username already exists'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'Email already exists'}), 400
    
    user = User(username=data['username'], email=data['email'])
    user.set_password(data['password'])
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data['username']).first()
    
    if user and user.check_password(data['password']):
        access_token = create_access_token(identity=user.id)
        return jsonify({'access_token': access_token}), 200
    
    return jsonify({'message': 'Invalid credentials'}), 401

@app.route('/collect-data', methods=['POST'])
@jwt_required()
def collect_data():
    data = request.get_json()
    
    if not data or 'image' not in data or 'label' not in data:
        return jsonify({'error': 'Missing required fields'}), 400
    
    result = model_handler.save_training_data(data['image'], data['label'])
    
    if 'error' in result:
        return jsonify(result), 400
    
    return jsonify(result), 200

@app.route('/test-model', methods=['POST'])
@jwt_required()
def test_model():
    data = request.get_json()
    
    if not data or 'image' not in data:
        return jsonify({'error': 'Missing image data'}), 400
    
    result = model_handler.process_image(data['image'])
    
    if 'error' in result:
        return jsonify(result), 400
    
    return jsonify(result), 200

@app.route('/labels', methods=['GET'])
def get_labels():
    try:
        with open('Model/labels.txt', 'r') as f:
            labels = [line.strip() for line in f if line.strip()]
        return jsonify({'labels': labels}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True) 