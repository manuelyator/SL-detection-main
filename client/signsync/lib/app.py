from flask import Flask, jsonify, request
from flask_mysqldb import MySQL
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import jwt as pyjwt
import datetime
import secrets
from functools import wraps
from model_handler import HandSignModel
import threading

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# MySQL Configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''
app.config['MYSQL_DB'] = 'db_signsync'

# Secret key for JWT token encoding
app.config['SECRET_KEY'] = secrets.token_hex(32)  

# Initialize model handler
model_handler = HandSignModel()

mysql = MySQL(app)

# JWT decorator
def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(" ")[1]
        
        if not token:
            return jsonify({'status': 'error', 'message': 'Token is missing'}), 401
        
        try:
            data = pyjwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            request.user_id = data['user_id']
        except pyjwt.ExpiredSignatureError:
            return jsonify({'status': 'error', 'message': 'Token has expired'}), 401
        except Exception as e:
            return jsonify({'status': 'error', 'message': 'Token is invalid'}), 401
        
        return f(*args, **kwargs)
    return decorated

@app.route('/api/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()

        full_name = data.get('full_name')
        email = data.get('email')
        raw_password = data.get('password')
        is_pro = data.get('is_pro', 0)

        # Validate inputs
        if not full_name or not email or not raw_password:
            return jsonify({'status': 'error', 'message': 'Missing fields'}), 400

        # Check if email exists
        cur = mysql.connection.cursor()
        cur.execute("SELECT email FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            cur.close()
            return jsonify({'status': 'error', 'message': 'Email already exists'}), 400

        # Hash password
        password = generate_password_hash(raw_password)

        # Insert into database
        cur.execute(
            "INSERT INTO users (full_name, email, password, is_pro) VALUES (%s, %s, %s, %s)",
            (full_name, email, password, is_pro)
        )
        mysql.connection.commit()
        cur.close()

        return jsonify({'status': 'success', 'message': 'User registered successfully'})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'status': 'error', 'message': 'Missing email or password'}), 400

        cur = mysql.connection.cursor()
        cur.execute("SELECT user_id, password, full_name, is_pro FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close()

        if user and check_password_hash(user[1], password):
            token = pyjwt.encode({
                'user_id': user[0],
                'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)
            }, app.config['SECRET_KEY'], algorithm='HS256')

            return jsonify({
                'status': 'success',
                'token': token,
                'userName': user[2],
                'isPro': bool(user[3])
            })
        else:
            return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/profile', methods=['GET'])
@jwt_required
def get_profile():
    try:
        user_id = request.user_id

        cur = mysql.connection.cursor()
        cur.execute("SELECT full_name, email, is_pro FROM users WHERE user_id = %s", (user_id,))
        row = cur.fetchone()

        if row:
            return jsonify({
                'status': 'success',
                'data': {
                    'name': row[0],
                    'email': row[1],
                    'isPro': bool(row[2])
                }
            })
        else:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
        
@app.route('/api/translate', methods=['POST'])
def translate():
    data = request.get_json()
    
    if not data or 'image' not in data:
        return jsonify({'status': 'error', 'message': 'Missing image data'}), 400
    
    try:
        result = model_handler.process_image(data['image'])
        
        if 'error' in result:
            return jsonify({'status': 'error', 'message': result['error']}), 400
 
        # Only return the translated_text
        return jsonify({
            'status': 'success',
            'translated_text': result.get('label', 'No translation available') # Ensure it fetches 'label'
        }), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/labels', methods=['GET'])
def get_labels():
    try:
        labels = model_handler.get_labels()
        return jsonify({'status': 'success', 'data': labels}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'success', 'message': 'API is healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)