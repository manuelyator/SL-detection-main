from flask import Flask, jsonify, request
from flask_mysqldb import MySQL
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import jwt as pyjwt
import datetime
import secrets

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# MySQL Configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'makaveli'
app.config['MYSQL_DB'] = 'db_signsync'

# Secret key for JWT token encoding
app.config['SECRET_KEY'] = 'f8bc5d9b9db00c7750e4695f24d4a3c7d02d7e67f2a56d9b17369a8a58268117'

mysql = MySQL(app)

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

        # Hash password
        password = generate_password_hash(raw_password)

        # Insert into database
        cur = mysql.connection.cursor()
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
        # Fetch user_id, password, and full_name
        cur.execute("SELECT user_id, password, full_name FROM users WHERE email = %s", (email,))
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
                'userName': user[2]
            })
        else:
            return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/profile', methods=['GET'])
def get_profile():
    try:
        # We get user_id from authentication
        user_id = request.args.get('user_id', default=1, type=int)

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

@app.route('/')
def home():
    return 'SignSync API is running!'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')