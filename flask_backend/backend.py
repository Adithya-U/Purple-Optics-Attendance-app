
from flask import Flask, request, jsonify
import os
from werkzeug.utils import secure_filename
import mysql.connector
import mysql.connector.pooling
import requests
import base64
from flask_cors import CORS
import random
from datetime import datetime, date, time, timedelta
import math
from contextlib import contextmanager
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
import atexit
import logging
import pytz

COMPRE_FACE_API_KEY = '1023b58b-60c7-4bc9-9376-fb28da83f4fa'
COMPRE_FACE_URL = 'http://localhost:8000/api/v1/verification/verify'

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": ["http://localhost:5173", "https://attendance-registration.vercel.app"]}})

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 5242880

# Database Configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'my-secret-pw',
    'database': 'attendance_db',
    'autocommit': True,
    'charset': 'utf8mb4',
    'connect_timeout': 60,
    'read_timeout': 60,
    'write_timeout': 60,
    'sql_mode': 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO'
}

# Create Connection Pool
try:
    connection_pool = mysql.connector.pooling.MySQLConnectionPool(
        pool_name="attendance_pool",
        pool_size=10,
        pool_reset_session=True,
        **DB_CONFIG
    )
    print("Database connection pool created successfully")
except mysql.connector.Error as e:
    print(f"Error creating connection pool: {e}")
    raise

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    connection = None
    try:
        connection = connection_pool.get_connection()
        yield connection
    except mysql.connector.Error as e:
        if connection:
            connection.rollback()
        print(f"Database error: {e}")
        raise
    finally:
        if connection and connection.is_connected():
            connection.close()

@contextmanager
def get_db_cursor(connection):
    """Context manager for database cursors"""
    cursor = None
    try:
        cursor = connection.cursor(dictionary=True)
        yield cursor
    finally:
        if cursor:
            cursor.close()


def to_base64(path):
    with open(path, 'rb') as img:
        return base64.b64encode(img.read()).decode('utf-8')
    
def is_face_detected(image_file):
    detect_url = 'http://localhost:8000/api/v1/detection/detect'
    headers = {'x-api-key': '21bebb56-600e-481a-a03a-97e130101543'}
    files = {'file': ('image.jpg', image_file, 'image/jpeg')}

    response = requests.post(detect_url, files=files, headers=headers)
    if response.status_code != 200:
        return False

    data = response.json()
    return bool(data.get('result'))

def generate_employee_id():
    """Generate a unique 5-digit employee ID"""
    max_attempts = 100
    for _ in range(max_attempts):
        emp_id = random.randint(10000, 99999)
        try:
            with get_db_connection() as conn:
                with get_db_cursor(conn) as cursor:
                    cursor.execute("SELECT 1 FROM Employees WHERE employee_id = %s", (emp_id,))
                    if not cursor.fetchone():
                        return emp_id
        except Exception as e:
            print(f"Error generating employee ID: {e}")
            continue
    
    raise Exception("Could not generate unique employee ID after maximum attempts")

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points using Haversine formula"""
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    r = 6371000  # Earth radius in meters
    return c * r

def find_nearest_store(user_lat, user_lon):
    """Find the nearest store within 50m radius"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("SELECT area_name, latitude, longitude FROM StoreLocations")
                stores = cursor.fetchall()
                
                for store in stores:
                    distance = calculate_distance(
                        user_lat, user_lon, 
                        float(store['latitude']), float(store['longitude'])
                    )
                    
                    if distance <= 50:
                        return store['area_name']
                
                return None
    except Exception as e:
        print(f"Error finding nearest store: {e}")
        return None

def mark_absent_employees():
    """
    Check for employees with no attendance record for today and mark them absent
    """
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Get today's date
                today = datetime.now().date()
                
                # Find all employees who don't have an attendance record for today
                query = """
                    SELECT e.employee_id, e.name 
                    FROM Employees e 
                    LEFT JOIN Attendance a ON e.employee_id = a.employee_id 
                        AND a.date = %s
                    WHERE a.employee_id IS NULL
                """
                
                cursor.execute(query, (today,))
                absent_employees = cursor.fetchall()
                
                if not absent_employees:
                    print(f"No employees to mark absent for {today}")
                    return
                
                print(f"Found {len(absent_employees)} employees to mark absent for {today}")
                
                # Insert absent records for these employees
                insert_query = """
                    INSERT INTO Attendance (employee_id, date, status, check_in, check_out, current_location)
                    VALUES (%s, %s, 'Absent', NULL, NULL, NULL)
                """
                
                absent_count = 0
                for employee in absent_employees:
                    try:
                        cursor.execute(insert_query, (employee['employee_id'], today))
                        conn.commit()
                        absent_count += 1
                        print(f"Marked employee {employee['name']} (ID: {employee['employee_id']}) as absent")
                    except Exception as e:
                        print(f"Error marking employee {employee['employee_id']} as absent: {e}")
                        conn.rollback()
                
                print(f"Successfully marked {absent_count} employees as absent for {today}")
                
    except Exception as e:
        print(f"Error in mark_absent_employees: {e}")
        logging.error(f"Error in mark_absent_employees: {e}")

def init_absent_scheduler(hour=21, minute=0):
    """
    Initialize scheduler for marking absent employees
    Args:
        hour: Hour in 24-hour format (0-23)
        minute: Minute (0-59)
    """
    ist = pytz.timezone('Asia/Kolkata')
    
    scheduler = BackgroundScheduler(timezone=ist)
    
    scheduler.add_job(
        func=mark_absent_employees,
        trigger=CronTrigger(hour=hour, minute=minute, timezone=ist),
        id='absent_check',
        name=f'Mark absent employees daily at {hour:02d}:{minute:02d} IST',
        replace_existing=True
    )
    
    print(f"Absent employee scheduler set for {hour:02d}:{minute:02d} IST")
    return scheduler

def init_late_request_scheduler(hour=21, minute=0):
    """
    Initialize scheduler for rejecting late arrival requests
    Args:
        hour: Hour in 24-hour format (0-23)
        minute: Minute (0-59)
    """
    ist = pytz.timezone('Asia/Kolkata')
    
    scheduler = BackgroundScheduler(timezone=ist)
    
    scheduler.add_job(
        func=reject_pending_late_requests,
        trigger=CronTrigger(hour=hour, minute=minute, timezone=ist),
        id='late_request_rejection',
        name=f'Reject pending late requests daily at {hour:02d}:{minute:02d} IST',
        replace_existing=True
    )
    
    print(f"Late request rejection scheduler set for {hour:02d}:{minute:02d} IST")
    return scheduler

def init_all_schedulers(absent_hour=21, absent_minute=0, late_request_hour=21, late_request_minute=5):
    """
    Initialize both schedulers with custom timing
    Args:
        absent_hour: Hour for absent check (default: 21 = 9 PM)
        absent_minute: Minute for absent check (default: 0)
        late_request_hour: Hour for late request rejection (default: 21 = 9 PM)
        late_request_minute: Minute for late request rejection (default: 5 = 5 minutes after)
    """
    ist = pytz.timezone('Asia/Kolkata')
    
    scheduler = BackgroundScheduler(timezone=ist)
    
    # Add absent employee check job
    scheduler.add_job(
        func=mark_absent_employees,
        trigger=CronTrigger(hour=absent_hour, minute=absent_minute, timezone=ist),
        id='absent_check',
        name=f'Mark absent employees daily at {absent_hour:02d}:{absent_minute:02d} IST',
        replace_existing=True
    )
    
    # Add late request rejection job
    scheduler.add_job(
        func=reject_pending_late_requests,
        trigger=CronTrigger(hour=late_request_hour, minute=late_request_minute, timezone=ist),
        id='late_request_rejection',
        name=f'Reject pending late requests daily at {late_request_hour:02d}:{late_request_minute:02d} IST',
        replace_existing=True
    )
    
    scheduler.start()
    print(f"Both schedulers started:")
    print(f"  - Absent check: {absent_hour:02d}:{absent_minute:02d} IST")
    print(f"  - Late request rejection: {late_request_hour:02d}:{late_request_minute:02d} IST")
    
    # Shut down the scheduler when exiting the app
    atexit.register(lambda: scheduler.shutdown())
    
    return scheduler

def reject_pending_late_requests():
    """
    Check for pending late arrival requests and mark them as rejected
    """
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Find all pending late arrival requests
                select_query = """
                    SELECT lar.request_id, lar.employee_id, e.name, lar.requested_at
                    FROM LateArrivalRequests lar
                    JOIN Employees e ON lar.employee_id = e.employee_id
                    WHERE lar.status = 'Pending'
                """
                
                cursor.execute(select_query)
                pending_requests = cursor.fetchall()
                
                if not pending_requests:
                    print("No pending late arrival requests to reject")
                    return
                
                print(f"Found {len(pending_requests)} pending late arrival requests to reject")
                
                # Update all pending requests to rejected
                update_query = """
                    UPDATE LateArrivalRequests 
                    SET status = 'Rejected' 
                    WHERE status = 'Pending'
                """
                
                cursor.execute(update_query)
                rejected_count = cursor.rowcount
                conn.commit()
                
                # Log each rejected request
                for request in pending_requests:
                    print(f"Rejected late arrival request ID: {request['request_id']} for employee {request['name']} (ID: {request['employee_id']}) requested at {request['requested_at']}")
                
                print(f"Successfully rejected {rejected_count} pending late arrival requests")
                
    except Exception as e:
        print(f"Error in reject_pending_late_requests: {e}")
        logging.error(f"Error in reject_pending_late_requests: {e}")

scheduler = init_all_schedulers(
    absent_hour=21, absent_minute=10,           # 9:00 PM for absent check
    late_request_hour=21, late_request_minute=0  # 9:05 PM for late request rejection
)

@app.route('/upload_photo', methods=['POST'])
def upload_photo():
    if 'photo' not in request.files or 'employee_id' not in request.form:
        return jsonify({'error': 'Missing photo or employee_id'}), 400

    photo = request.files['photo']
    employee_id = request.form['employee_id']

    if photo.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT employee_id FROM Employees WHERE employee_id = %s", (employee_id,))
                if cursor.fetchone() is None:
                    return jsonify({'error': 'Employee ID does not exist'}), 404

                # Check for face in uploaded image
                photo.stream.seek(0)
                if not is_face_detected(photo.stream):
                    return jsonify({'error': 'No face detected in photo'}), 400

                photo.stream.seek(0)

                # Save photo
                filename = secure_filename(f"employee_{employee_id}.jpg")
                photo_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                photo.save(photo_path)

                # Update path in DB
                cursor.execute("UPDATE Employees SET photo_url = %s WHERE employee_id = %s", (photo_path, employee_id))
                conn.commit()

                return jsonify({'message': 'Photo uploaded successfully', 'photo_path': photo_path})

    except Exception as e:
        print(f"Error uploading photo: {e}")
        return jsonify({'error': 'Failed to upload photo'}), 500

@app.route('/check_in', methods=['POST'])
def compare_photo():
    if 'photo' not in request.files or 'employee_id' not in request.form:
        return jsonify({'error': 'Missing photo or employee_id'}), 400
    
    photo = request.files['photo']
    employee_id = request.form['employee_id']
    user_lat = request.form.get('latitude')
    user_lon = request.form.get('longitude')
    timestamp = request.form.get('timestamp')
    
    if photo.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT photo_url, name FROM Employees WHERE employee_id = %s", (employee_id,))
                result = cursor.fetchone()
                if result is None:
                    return jsonify({'error': 'Employee not found'}), 404
                
                stored_photo_path = result['photo_url']
                emp_name = result['name']
                
                if not os.path.exists(stored_photo_path):
                    return jsonify({'error': 'Stored photo not found'}), 404
                
                # Check face in uploaded image
                photo.stream.seek(0)
                if not is_face_detected(photo.stream):
                    return jsonify({'error': 'No face detected in uploaded photo'}), 400
                photo.stream.seek(0)
                
                # Compare photos
                with open(stored_photo_path, 'rb') as stored_image:
                    files = {
                        'source_image': ('stored.jpg', stored_image, 'image/jpeg'),
                        'target_image': ('uploaded.jpg', photo, 'image/jpeg')
                    }
                    headers = {'x-api-key': COMPRE_FACE_API_KEY}
                    response = requests.post(COMPRE_FACE_URL, files=files, headers=headers)
                
                if response.status_code != 200:
                    return jsonify({'error': 'CompreFace verification failed', 'details': response.text}), 500
                
                result = response.json()
                similarity = result['result'][0]['face_matches'][0]['similarity']
                is_match = similarity >= 0.9
                
                response_data = {
                    'match': is_match,
                    'similarity': similarity,
                    'face_verification': 'success' if is_match else 'failed',
                    'location_check': None,
                    'time_check': None,
                    'attendance_recorded': False,
                    'message': None
                }
                
                if not is_match:
                    response_data['message'] = 'Face verification failed - attendance not recorded'
                    return jsonify(response_data)
                
                # Location validation
                if not user_lat or not user_lon:
                    response_data['location_check'] = 'missing_coordinates'
                    response_data['message'] = 'Location coordinates missing - attendance not recorded'
                    return jsonify(response_data)
                
                try:
                    user_lat = float(user_lat)
                    user_lon = float(user_lon)
                except (ValueError, TypeError):
                    response_data['location_check'] = 'invalid_coordinates'
                    response_data['message'] = 'Invalid location coordinates - attendance not recorded'
                    return jsonify(response_data)
                
                store_location = find_nearest_store(user_lat, user_lon)
                
                if not store_location:
                    response_data['location_check'] = 'too_far_from_store'
                    response_data['message'] = 'You are not within 50m of any store location - attendance not recorded'
                    return jsonify(response_data)
                
                response_data['location_check'] = 'success'
                response_data['store_location'] = store_location
                
                # Time validation
                if timestamp:
                    try:
                        check_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    except:
                        check_time = datetime.now()
                else:
                    check_time = datetime.now()
                
                is_on_time = check_time.time() <= time(9, 0)
                
                # Check for approved late arrival request if after 9 AM
                has_approved_late_request = False
                if not is_on_time:
                    cursor.execute("""
                        SELECT 1 FROM LateArrivalRequests 
                        WHERE employee_id = %s 
                        AND DATE(requested_at) = %s 
                        AND status = 'Accepted'
                    """, (employee_id, check_time.date()))
                    has_approved_late_request = bool(cursor.fetchone())
                
                if is_on_time:
                    attendance_status = 'Present'
                    response_data['time_check'] = 'on_time'
                elif has_approved_late_request:
                    attendance_status = 'Late'
                    response_data['time_check'] = 'late_with_approval'
                else:
                    response_data['time_check'] = 'late_without_approval'
                    response_data['message'] = 'Check-in after 9 AM without approved late arrival request - attendance not recorded'
                    return jsonify(response_data)
                
                # Record attendance
                cursor.execute("""
                    INSERT INTO Attendance (employee_id, current_location, date, status, check_in, check_out)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    status = VALUES(status),
                    check_in = VALUES(check_in),
                    current_location = VALUES(current_location)
                """, (employee_id, store_location, check_time.date(), attendance_status, check_time.time(), None))
                
                conn.commit()
                
                response_data.update({
                    'attendance_recorded': True,
                    'attendance_status': attendance_status,
                    'check_in_time': check_time.strftime('%H:%M:%S'),
                    'message': f'Attendance successfully recorded as {attendance_status} at {store_location}'
                })
                
                return jsonify(response_data)

    except Exception as e:
        print(f"Error during check-in: {e}")
        return jsonify({'error': 'Internal server error during check-in'}), 500

@app.route('/api/create-account', methods=['POST'])
def create_account():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    if not (username and password):
        return jsonify({'success': False, 'message': 'Missing fields'}), 400
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if username exists
                cursor.execute("SELECT * FROM admin WHERE user_name = %s", (username,))
                if cursor.fetchone():
                    return jsonify({'success': False, 'message': 'Username already taken'}), 409

                # Insert new account
                cursor.execute("INSERT INTO admin (user_name, password) VALUES (%s, %s)", (username, password))
                conn.commit()
                
                return jsonify({'success': True, 'message': 'Account created successfully'}), 201

    except Exception as e:
        print(f"Error creating account: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
   
    if not (username and password):
        return jsonify({'success': False, 'message': 'Missing username or password'}), 400
   
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("SELECT * FROM admin WHERE user_name = %s AND password = %s", (username, password))
                user = cursor.fetchone()
                
                if user:
                    return jsonify({
                        'success': True,
                        'message': 'Login successful',
                        'username': user['user_name']
                    }), 200
                else:
                    return jsonify({'success': False, 'message': 'Invalid username or password'}), 401
                    
    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/attendance', methods=['GET'])
def get_attendance():
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    SELECT 
                        a.attendance_id,
                        a.employee_id,
                        e.name AS emp_name,
                        a.current_location,
                        DATE(a.date) as date,
                        a.status,
                        CASE WHEN a.check_in = 'RUNE' THEN NULL ELSE TIME_FORMAT(a.check_in, '%H:%i:%s') END as check_in,
                        CASE WHEN a.check_out = 'RUNE' THEN NULL ELSE TIME_FORMAT(a.check_out, '%H:%i:%s') END as check_out
                    FROM Attendance a
                    JOIN Employees e ON a.employee_id = e.employee_id
                    ORDER BY a.date DESC
                    LIMIT 50
                """)
               
                attendance_data = []
                for row in cursor:
                    processed_row = {
                        'attendance_id': int(row['attendance_id']),
                        'employee_id': int(row['employee_id']),
                        'emp_name': str(row['emp_name']),
                        'current_location': str(row['current_location']) if row['current_location'] else None,
                        'date': str(row['date']) if row['date'] else None,
                        'status': str(row['status']),
                        'check_in': str(row['check_in']) if row['check_in'] else None,
                        'check_out': str(row['check_out']) if row['check_out'] else None
                    }
                    attendance_data.append(processed_row)
               
                return jsonify(attendance_data)
                
    except Exception as e:
        print(f"Error fetching attendance data: {e}")
        return jsonify({'error': 'Failed to fetch attendance data', 'details': str(e)}), 500

@app.route('/api/late-arrival-requests', methods=['GET'])
def get_late_arrival_requests():
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    SELECT
                        r.request_id,
                        r.employee_id,
                        e.name AS employee_name,
                        e.position,
                        e.permanent_location,
                        e.phone_no,
                        r.requested_at,
                        r.status
                    FROM LateArrivalRequests r
                    JOIN Employees e ON r.employee_id = e.employee_id
                    ORDER BY r.requested_at DESC
                """)
                
                requests = []
                for row in cursor:
                    requests.append({
                        'request_id': row['request_id'],
                        'employee_id': row['employee_id'],
                        'name': row['employee_name'],
                        'role': row['position'],
                        'branch': row['permanent_location'],
                        'phone': row['phone_no'],
                        'requested_at': row['requested_at'].strftime('%H:%M:%S'),
                        'status': row['status']
                    })
                
                return jsonify(requests), 200
                
    except Exception as e:
        print(f"Error fetching late arrival requests: {e}")
        return jsonify({'error': 'Failed to fetch late arrival requests'}), 500

@app.route('/api/late-arrival-requests/<int:request_id>/status', methods=['PUT'])
def update_late_arrival_status(request_id):
    new_status = request.json.get('status')
    if new_status not in ['Accepted', 'Rejected']:
        return jsonify({'error': 'Invalid status'}), 400
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Get late request details
                cursor.execute("""
                    SELECT r.employee_id, r.requested_at, e.name, e.permanent_location
                    FROM LateArrivalRequests r
                    JOIN Employees e ON r.employee_id = e.employee_id
                    WHERE r.request_id = %s
                """, (request_id,))
                
                row = cursor.fetchone()
                if not row:
                    return jsonify({'error': 'Late arrival request not found'}), 404
                
                employee_id = row['employee_id']
                current_location = row['permanent_location']
                requested_at = row['requested_at']
                
                attendance_status = 'Late' if new_status == 'Accepted' else 'Absent'
                check_in = requested_at if new_status == 'Accepted' else None
                
                # Insert attendance record
                cursor.execute("""
                    INSERT INTO Attendance (employee_id, current_location, date, status, check_in, check_out)
                    VALUES (%s, %s, CURDATE(), %s, %s, %s)
                """, (employee_id, current_location, attendance_status, check_in, None))
                
                # Update request status
                cursor.execute("UPDATE LateArrivalRequests SET status = %s WHERE request_id = %s", (new_status, request_id))
                
                conn.commit()
                return jsonify({'message': 'Status updated and attendance recorded'}), 200
                
    except Exception as e:
        print(f"Error updating late arrival status: {e}")
        return jsonify({'error': 'Failed to process request'}), 500


@app.route('/api/employees', methods=['POST'])
def add_employee():
    try:
        data = request.get_json(force=True)
        
        # Basic validation
        required = ["name", "employee_id"]
        missing = [k for k in required if not data.get(k)]
        if missing:
            return jsonify({"success": False, "message": f"Missing fields: {', '.join(missing)}"}), 400
        
        # Extract data
        employee_id = data.get('employee_id')
        name = data.get('name')
        email = data.get('email')
        permanent_location = data.get('permanent_location')
        position = data.get('position')
        phone_no = data.get('phone_no')
        photo_url = None
        date_joined = date.today()
        
        # Use connection pool and context managers
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    INSERT INTO Employees
                      (employee_id, name, email, permanent_location, position, date_joined, phone_no, photo_url)
                    VALUES
                      (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (employee_id, name, email, permanent_location, position, date_joined, phone_no, photo_url))
                
                # Note: No need for conn.commit() since autocommit=True in your DB_CONFIG
                
        return jsonify({
            "success": True,
            "message": "Employee added successfully",
            "employee_id": employee_id,
            "date_joined": str(date_joined)
        }), 201
        
    except mysql.connector.Error as db_error:
        app.logger.exception("Database error in add_employee")
        return jsonify({"success": False, "message": f"Database error: {str(db_error)}"}), 500
    except Exception as e:
        app.logger.exception("Add employee failed")
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/api/employees/<int:employee_id>', methods=['DELETE'])
def remove_employee(employee_id):
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT * FROM Employees WHERE employee_id = %s", (employee_id,))
                if not cursor.fetchone():
                    return jsonify({'success': False, 'message': 'Employee not found'}), 404
                
                # Delete employee
                cursor.execute("DELETE FROM Employees WHERE employee_id = %s", (employee_id,))
                conn.commit()
                
                return jsonify({'success': True, 'message': 'Employee removed successfully'}), 200
                
    except Exception as e:
        print(f"Error removing employee: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/employee-status', methods=['POST'])
def get_employee_status():
    """Determine what action the employee should see"""
    data = request.get_json()
    employee_id = data.get('employee_id')
    
    if not employee_id:
        return jsonify({'error': 'Employee ID is required'}), 400
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT employee_id, name FROM Employees WHERE employee_id = %s", (employee_id,))
                employee = cursor.fetchone()
                
                if not employee:
                    return jsonify({'success': False, 'error': 'Employee not found', 'action': None}), 404
                
                current_time = datetime.now()
                today = current_time.date()
                
                # Check existing attendance
                cursor.execute("""
                    SELECT status, check_in, check_out 
                    FROM Attendance 
                    WHERE employee_id = %s AND date = %s
                """, (employee_id, today))
                
                attendance_record = cursor.fetchone()
                
                if attendance_record:
                    if attendance_record['check_out'] is None:
                        return jsonify({
                            'success': True,
                            'employee_name': employee['name'],
                            'action': 'check_out',
                            'current_status': attendance_record['status'],
                            'check_in_time': str(attendance_record['check_in']),
                            'message': f"Welcome back {employee['name']}! You're ready to check out."
                        })
                    else:
                        return jsonify({
                            'success': True,
                            'employee_name': employee['name'],
                            'action': 'already_completed',
                            'current_status': attendance_record['status'],
                            'check_in_time': str(attendance_record['check_in']),
                            'check_out_time': str(attendance_record['check_out']),
                            'message': f"Hi {employee['name']}, you've already completed your attendance for today."
                        })
                
                # No attendance - check time and late requests
                current_time_only = current_time.time()
                cutoff_time = time(9, 0)
                
                if current_time_only <= cutoff_time:
                    return jsonify({
                        'success': True,
                        'employee_name': employee['name'],
                        'action': 'check_in',
                        'message': f"Good morning {employee['name']}! Ready to check in?"
                    })
                else:
                    # Check late requests
                    cursor.execute("""
                        SELECT request_id, status, requested_at 
                        FROM LateArrivalRequests 
                        WHERE employee_id = %s AND DATE(requested_at) = %s
                        ORDER BY requested_at DESC 
                        LIMIT 1
                    """, (employee_id, today))
                    
                    late_request = cursor.fetchone()
                    
                    if late_request:
                        status = late_request['status']
                        if status == 'Pending':
                            return jsonify({
                                'success': True,
                                'employee_name': employee['name'],
                                'action': 'wait_for_approval',
                                'request_id': late_request['request_id'],
                                'requested_at': str(late_request['requested_at']),
                                'message': f"Hi {employee['name']}, your late arrival request is pending approval."
                            })
                        elif status == 'Accepted':
                            return jsonify({
                                'success': True,
                                'employee_name': employee['name'],
                                'action': 'check_in',
                                'late_approval': True,
                                'message': f"Hi {employee['name']}, your late arrival was approved. Ready to check in?"
                            })
                        elif status == 'Rejected':
                            return jsonify({
                                'success': True,
                                'employee_name': employee['name'],
                                'action': 'request_rejected',
                                'message': f"Hi {employee['name']}, your late arrival request was rejected. Please contact your supervisor."
                            })
                    else:
                        return jsonify({
                            'success': True,
                            'employee_name': employee['name'],
                            'action': 'late_arrival_request',
                            'current_time': current_time.strftime('%H:%M'),
                            'message': f"Hi {employee['name']}, it's past 9 AM. You need to submit a late arrival request."
                        })
                        
    except Exception as e:
        print(f"Error in employee status check: {e}")
        return jsonify({'success': False, 'error': 'Internal server error', 'action': None}), 500

@app.route('/api/submit-late-request', methods=['POST'])
def submit_late_request():
    """Submit a late arrival request for an employee"""
    data = request.get_json()
    employee_id = data.get('employee_id')
    requested_time = data.get('time')
    
    if not employee_id or not requested_time:
        return jsonify({'success': False, 'error': 'Employee ID and time are required'}), 400
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT name FROM Employees WHERE employee_id = %s", (employee_id,))
                employee = cursor.fetchone()
                
                if not employee:
                    return jsonify({'success': False, 'error': 'Employee not found'}), 404
                
                # Check existing request for today
                cursor.execute("""
                    SELECT request_id FROM LateArrivalRequests 
                    WHERE employee_id = %s AND DATE(requested_at) = CURDATE()
                """, (employee_id,))
                
                if cursor.fetchone():
                    return jsonify({'success': False, 'error': 'Late arrival request already submitted for today'}), 400
                
                # Parse time
                try:
                    if len(requested_time.split(':')) == 2:
                        requested_time += ":00"
                    
                    today = date.today()
                    time_obj = datetime.strptime(requested_time, "%H:%M:%S").time()
                    requested_datetime = datetime.combine(today, time_obj)
                    
                except ValueError:
                    return jsonify({'success': False, 'error': 'Invalid time format. Use HH:MM or HH:MM:SS'}), 400
                
                # Insert request
                cursor.execute("""
                    INSERT INTO LateArrivalRequests (employee_id, requested_at, status)
                    VALUES (%s, %s, %s)
                """, (employee_id, requested_datetime, 'Pending'))
                
                conn.commit()
                request_id = cursor.lastrowid
                
                return jsonify({
                    'success': True,
                    'message': f'Late arrival request submitted successfully for {employee["name"]}',
                    'request_id': request_id,
                    'employee_name': employee['name'],
                    'requested_time': requested_time,
                    'status': 'Pending',
                    'requested_at': requested_datetime.strftime('%Y-%m-%d %H:%M:%S')
                }), 201
                
    except Exception as e:
        print(f"Error submitting late arrival request: {e}")
        return jsonify({'success': False, 'error': 'Failed to submit request'}), 500

@app.route('/api/check-out-verify', methods=['POST'])
def check_out_verify():
    """Handle employee check-out with face verification"""
    if 'photo' not in request.files or 'employee_id' not in request.form:
        return jsonify({'error': 'Missing photo or employee_id'}), 400
    
    photo = request.files['photo']
    employee_id = request.form['employee_id']
    timestamp = request.form.get('timestamp')
    
    if photo.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    response_data = {
        'face_verification': None,
        'check_out_recorded': False,
        'message': None
    }
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # Check if employee exists
                cursor.execute("SELECT photo_url, name FROM Employees WHERE employee_id = %s", (employee_id,))
                result = cursor.fetchone()
                
                if result is None:
                    response_data['face_verification'] = 'employee_not_found'
                    response_data['message'] = 'Employee not found'
                    return jsonify(response_data), 404
                
                stored_photo_path = result['photo_url']
                emp_name = result['name']
                
                if not stored_photo_path or not os.path.exists(stored_photo_path):
                    response_data['face_verification'] = 'no_stored_photo'
                    response_data['message'] = 'No stored photo found for employee'
                    return jsonify(response_data), 404
                
                # Check for active check-in
                today = date.today()
                cursor.execute("""
                    SELECT attendance_id, check_in, status, current_location 
                    FROM Attendance 
                    WHERE employee_id = %s AND date = %s AND check_out IS NULL
                """, (employee_id, today))
                
                attendance_record = cursor.fetchone()

                if not attendance_record:
                    response_data['face_verification'] = 'no_active_checkin'
                    response_data['message'] = 'No active check-in found for today. Please check-in first.'
                    return jsonify(response_data), 404
                
                # Face detection
                photo.stream.seek(0)
                if not is_face_detected(photo.stream):
                    response_data['face_verification'] = 'no_face_detected'
                    response_data['message'] = 'No face detected in uploaded photo'
                    return jsonify(response_data), 400
                photo.stream.seek(0)
                
                # Face verification
                with open(stored_photo_path, 'rb') as stored_image:
                    files = {
                        'source_image': ('stored.jpg', stored_image, 'image/jpeg'),
                        'target_image': ('uploaded.jpg', photo, 'image/jpeg')
                    }
                    headers = {'x-api-key': COMPRE_FACE_API_KEY}
                    verification_response = requests.post(COMPRE_FACE_URL, files=files, headers=headers)
                
                if verification_response.status_code != 200:
                    response_data['face_verification'] = 'verification_service_error'
                    response_data['message'] = 'Face verification service failed'
                    response_data['details'] = verification_response.text
                    return jsonify(response_data), 500
                
                verification_result = verification_response.json()
                similarity = verification_result['result'][0]['face_matches'][0]['similarity']
                is_match = similarity >= 0.9
                
                response_data['similarity'] = similarity
                response_data['match'] = is_match
                
                if not is_match:
                    response_data['face_verification'] = 'face_mismatch'
                    response_data['message'] = f'Face verification failed. Similarity: {similarity:.2f}'
                    return jsonify(response_data)
                
                response_data['face_verification'] = 'success'
                
                # Parse timestamp
                if timestamp:
                    try:
                        check_out_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    except:
                        check_out_time = datetime.now()
                else:
                    check_out_time = datetime.now()

                # Validate check-out time
                check_in_value = attendance_record['check_in']
                if isinstance(check_in_value, datetime):
                    check_in_datetime = check_in_value
                elif isinstance(check_in_value, timedelta):
                    check_in_datetime = datetime.combine(today, time(0,0)) + check_in_value
                else:
                    check_in_datetime = datetime.combine(today, check_in_value)

                if check_out_time < check_in_datetime:
                    response_data['time_validation'] = 'invalid_checkout_time'
                    response_data['message'] = f'Check-out time cannot be before check-in time ({check_in_value})'
                    return jsonify(response_data), 400
                
                response_data['time_validation'] = 'success'
                
                # Update attendance record
                cursor.execute("""
                    UPDATE Attendance 
                    SET check_out = %s 
                    WHERE attendance_id = %s
                """, (check_out_time.time(), attendance_record['attendance_id']))
                
                conn.commit()
                
                # Calculate hours worked
                time_diff = check_out_time - check_in_datetime
                hours_worked = time_diff.total_seconds() / 3600
                
                response_data.update({
                    'check_out_recorded': True,
                    'employee_name': emp_name,
                    'check_in_time': str(attendance_record['check_in']),
                    'check_out_time': check_out_time.strftime('%H:%M:%S'),
                    'attendance_status': attendance_record['status'],
                    'location': attendance_record['current_location'],
                    'hours_worked': round(hours_worked, 2),
                    'message': f'Successfully checked out {emp_name} at {check_out_time.strftime("%H:%M:%S")}'
                })
                
                return jsonify(response_data), 200
        
    except Exception as e:
        print(f"Error during check-out verification: {e}")
        response_data['face_verification'] = 'system_error'
        response_data['message'] = 'Internal server error during check-out'
        return jsonify(response_data), 500

@app.route('/api/viewemployees', methods=['GET'])
def view_employees():
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    SELECT employee_id, name, email, phone_no, position, permanent_location, date_joined
                    FROM Employees
                """)
                employees = cursor.fetchall()

                return jsonify({"success": True, "employees": employees}), 200
                
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({"success": False, "message": "Failed to fetch employees"}), 500

@app.route('/api/monthlyrecords/dynamic', methods=['POST'])
def get_dynamic_monthly_records():
    try:
        data = request.get_json()
        start_date = data.get('start_date')
        end_date = data.get('end_date')
       
        if not start_date or not end_date:
            return jsonify({'error': 'Both start_date and end_date are required'}), 400
       
        # Use connection pool with context managers
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    SELECT
                        e.employee_id,
                        e.name,
                        e.permanent_location,
                        COUNT(CASE WHEN a.status = 'Present' THEN 1 END) as days_present,
                        COUNT(CASE WHEN a.status = 'Late' THEN 1 END) as late_days,
                        COUNT(CASE WHEN a.status = 'Absent' THEN 1 END) as absent_days,
                        COUNT(a.attendance_id) as total_recorded_days
                    FROM Employees e
                    LEFT JOIN Attendance a ON e.employee_id = a.employee_id
                        AND a.date BETWEEN %s AND %s
                    GROUP BY e.employee_id, e.name, e.permanent_location
                    ORDER BY e.employee_id
                """, (start_date, end_date))
               
                records = []
               
                # Calculate dates once, outside the loop
                from datetime import datetime, timedelta
                start = datetime.strptime(start_date, '%Y-%m-%d')
                end = datetime.strptime(end_date, '%Y-%m-%d')
                today = datetime.now().date()
               
                effective_end_date = min(end.date(), today)
               
                # Total working days
                total_working_days = sum(1 for d in (start + timedelta(days=i) for i in range((end-start).days+1)) if d.weekday() < 5)
               
                # Working days elapsed until today
                working_days_elapsed = sum(1 for d in (start + timedelta(days=i) for i in range((effective_end_date-start.date()).days+1)) if d.weekday() < 5)
               
                for row in cursor:
                    days_present = row['days_present'] or 0
                    late_days = row['late_days'] or 0
                    absent_days = row['absent_days'] or 0
                   
                    days_worked = days_present + late_days
                    leaves_taken = max(0, working_days_elapsed - days_worked)
                    overtime_days = max(0, days_worked - working_days_elapsed)
                   
                    records.append({
                        'id': row['employee_id'],
                        'name': row['name'],
                        'branch': row['permanent_location'],
                        'daysWorked': days_worked,
                        'daysPresent': days_present,
                        'lateDays': late_days,
                        'leavesTaken': leaves_taken,
                        'overtime': overtime_days,
                        'totalWorkingDays': total_working_days,
                        'workingDaysElapsed': working_days_elapsed,
                        'attendanceRate': round((days_worked / working_days_elapsed * 100), 1) if working_days_elapsed > 0 else 0
                    })
               
                return jsonify({
                    'success': True,
                    'records': records,
                    'period': {
                        'start_date': start_date,
                        'end_date': end_date,
                        'effective_end_date': effective_end_date.strftime('%Y-%m-%d'),
                        'total_working_days': total_working_days,
                        'working_days_elapsed': working_days_elapsed
                    }
                }), 200
       
    except Exception as e:
        print("Error calculating dynamic monthly records:", e)
        return jsonify({'error': 'Failed to calculate monthly records', 'details': str(e)}), 500

# Optional: Add endpoint for getting current month records
@app.route('/api/monthlyrecords/current', methods=['GET'])
def get_current_month_records():
    try:
        from datetime import datetime
        now = datetime.now()
        start_date = now.replace(day=1).strftime('%Y-%m-%d')
        end_date = now.strftime('%Y-%m-%d')
        
        return jsonify({
            'success': True,
            'message': 'Use /api/monthlyrecords/dynamic with current month dates',
            'suggested_dates': {
                'start_date': start_date,
                'end_date': end_date
            }
        }), 200
        
    except Exception as e:
        print("Error:", e)
        return jsonify({'error': 'Failed to get current month data'}), 500



@app.route('/api/leave-requests', methods=['GET'])
def get_leave_requests():
    try:
        # Use connection pool with context managers
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                cursor.execute("""
                    SELECT
                        l.leave_id,
                        l.employee_id,
                        e.name AS employee_name,
                        l.start_date,
                        l.end_date,
                        l.reason,
                        l.status,
                        l.request_date
                    FROM LeaveRequests l
                    JOIN Employees e ON l.employee_id = e.employee_id
                    ORDER BY l.start_date DESC
                """)
                
                requests = []
                for row in cursor:
                    requests.append({
                        'request_id': row['leave_id'],
                        'employee_id': row['employee_id'],
                        'name': row['employee_name'],
                        'start_date': row['start_date'].strftime('%Y-%m-%d'),
                        'end_date': row['end_date'].strftime('%Y-%m-%d'),
                        'reason': row['reason'],
                        'status': row['status'],
                        'request_date': row['request_date'].strftime('%Y-%m-%d %H:%M:%S')
                    })
                
                return jsonify(requests), 200
                
    except Exception as e:
        print("Error fetching leave requests:", e)
        return jsonify({'error': 'Failed to fetch leave requests'}), 500
    
@app.route('/api/leave-requests/<int:leave_id>/status', methods=['PUT'])
def update_leave_status(leave_id):
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data provided'}), 400
        
    new_status = data.get('status')
    if new_status not in ['Approved', 'Rejected']:
        return jsonify({'error': 'Invalid status. Must be "Approved" or "Rejected"'}), 400

    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cursor:
                # First check if the leave request exists
                cursor.execute("SELECT leave_id, status FROM LeaveRequests WHERE leave_id = %s", (leave_id,))
                leave_request = cursor.fetchone()
                
                if not leave_request:
                    return jsonify({'error': 'Leave request not found'}), 404
                
                # Check if already processed (optional - remove if you want to allow status changes)
                if leave_request['status'] in ['Approved', 'Rejected']:
                    return jsonify({'error': f'Leave request already {leave_request["status"].lower()}'}), 400

                # Update the status
                cursor.execute("UPDATE LeaveRequests SET status = %s WHERE leave_id = %s", (new_status, leave_id))
                
                # Since autocommit is True in your config, no need for conn.commit()
                # If you changed autocommit to False, uncomment the next line:
                # conn.commit()

                return jsonify({
                    'message': 'Leave request status updated successfully',
                    'leave_id': leave_id,
                    'new_status': new_status
                }), 200

    except mysql.connector.Error as e:
        print(f"Database error updating leave request {leave_id}: {e}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        print(f"Error updating leave request {leave_id}: {e}")
        return jsonify({'error': 'Failed to update leave status'}), 500
    
# Optional: Add a manual trigger endpoint for testing
@app.route('/api/trigger-absent-check', methods=['POST'])
def trigger_absent_check():
    """
    Manual trigger for testing the absent employee check
    """
    try:
        mark_absent_employees()
        return jsonify({"status": "success", "message": "Absent employee check completed"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trigger-late-request-rejection', methods=['POST'])
def trigger_late_request_rejection():
    """
    Manual trigger for testing the late request rejection
    """
    try:
        reject_pending_late_requests()
        return jsonify({"status": "success", "message": "Late request rejection completed"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/api/scheduler-status', methods=['GET'])
def scheduler_status():
    """
    Check if both schedulers are running and show next run times
    """
    try:
        absent_job = scheduler.get_job('absent_check')
        late_job = scheduler.get_job('late_request_rejection')
        
        result = {
            "absent_check": {
                "status": "running" if absent_job else "not_found",
                "next_run": absent_job.next_run_time.isoformat() if absent_job and absent_job.next_run_time else "Not scheduled"
            },
            "late_request_rejection": {
                "status": "running" if late_job else "not_found", 
                "next_run": late_job.next_run_time.isoformat() if late_job and late_job.next_run_time else "Not scheduled"
            }
        }
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)