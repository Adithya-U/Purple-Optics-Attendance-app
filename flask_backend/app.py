
from flask import Flask, request, jsonify
import os
from werkzeug.utils import secure_filename
import mysql.connector
import requests
import base64
from flask_cors import CORS
import random
from datetime import datetime, date, time,timedelta
import math


COMPRE_FACE_API_KEY = '1023b58b-60c7-4bc9-9376-fb28da83f4fa'
COMPRE_FACE_URL = 'http://localhost:8000/api/v1/verification/verify'  # adjust if needed

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "http://localhost:5173"}}) # allow cross-origin requests from your frontend

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 5242880  

# MySQL connection with dictionary cursor
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='my-secret-pw',
    database='attendance_db'
)
cursor = conn.cursor(dictionary=True)

def to_base64(path):
    with open(path, 'rb') as img:
        return base64.b64encode(img.read()).decode('utf-8')
    
def is_face_detected(image_file):
    detect_url = 'http://localhost:8000/api/v1/detection/detect'
    headers = {
        'x-api-key': '21bebb56-600e-481a-a03a-97e130101543'
    }
    files = {
        'file': ('image.jpg', image_file, 'image/jpeg')
    }

    response = requests.post(detect_url, files=files, headers=headers)
    if response.status_code != 200:
        return False

    data = response.json()
    return bool(data.get('result'))  # True if face is detected

def generate_employee_id():
    """Generate a unique 5-digit employee ID"""
    while True:
        emp_id = random.randint(10000, 99999)  # 5-digit number
        cursor.execute("SELECT 1 FROM Employees WHERE employee_id = %s", (emp_id,))
        if not cursor.fetchone():  # unique
            return emp_id

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two points using Haversine formula
    Returns distance in meters
    """
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Radius of earth in meters
    r = 6371000
    return c * r

def find_nearest_store(user_lat, user_lon):
    """
    Find the nearest store within 50m radius
    Returns store area_name if found, None otherwise
    """
    cursor.execute("SELECT area_name, latitude, longitude FROM StoreLocations")
    stores = cursor.fetchall()
    
    for store in stores:
        distance = calculate_distance(
            user_lat, user_lon, 
            float(store['latitude']), float(store['longitude'])
        )
        
        if distance <= 50:  # Within 50 meters
            return store['area_name']
    
    return None


@app.route('/upload_photo', methods=['POST'])
def upload_photo():
    if 'photo' not in request.files or 'employee_id' not in request.form:
        print('missing photo or emp id')
        return jsonify({'error': 'Missing photo or employee_id'}), 400

    photo = request.files['photo']
    employee_id = request.form['employee_id']

    if photo.filename == '':
        print('no file selected')
        return jsonify({'error': 'No selected file'}), 400

    # Check if employee exists
    cursor.execute("SELECT employee_id FROM Employees WHERE employee_id = %s", (employee_id,))
    if cursor.fetchone() is None:
        return jsonify({'error': 'Employee ID does not exist'}), 404

    # Check for face in uploaded image
    photo.stream.seek(0)  # rewind file stream before reading
    if not is_face_detected(photo.stream):
        print('no face detected')
        return jsonify({'error': 'No face detected in photo'}), 400

    photo.stream.seek(0)  # rewind again to save after detection

    # Save photo
    filename = secure_filename(f"employee_{employee_id}.jpg")
    photo_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    photo.save(photo_path)

    # Update path in DB
    cursor.execute("UPDATE Employees SET photo_url = %s WHERE employee_id = %s", (photo_path, employee_id))
    conn.commit()

    return jsonify({'message': 'Photo uploaded successfully', 'photo_path': photo_path})


@app.route('/check_in', methods=['POST'])
def compare_photo():
    if 'photo' not in request.files or 'employee_id' not in request.form:
        return jsonify({'error': 'Missing photo or employee_id'}), 400
    
    photo = request.files['photo']
    employee_id = request.form['employee_id']
    
    # Get location and timestamp from request
    user_lat = request.form.get('latitude')
    user_lon = request.form.get('longitude')
    timestamp = request.form.get('timestamp')  # Expected in ISO format or will use current time
    
    if photo.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
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
        headers = {
            'x-api-key': COMPRE_FACE_API_KEY
        }
        response = requests.post(COMPRE_FACE_URL, files=files, headers=headers)
    
    if response.status_code != 200:
        return jsonify({'error': 'CompreFace verification failed', 'details': response.text}), 500
    
    result = response.json()
    similarity = result['result'][0]['face_matches'][0]['similarity']
    is_match = similarity >= 0.9
    
    # Initialize response object with face verification results
    response_data = {
        'match': is_match,
        'similarity': similarity,
        'face_verification': 'success' if is_match else 'failed',
        'location_check': None,
        'time_check': None,
        'attendance_recorded': False,
        'message': None
    }
    
    # If face verification failed, return early
    if not is_match:
        response_data['message'] = 'Face verification failed - attendance not recorded'
        return jsonify(response_data)
    
    # Check if location data is provided
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
    
    # Find nearest store within 50m
    store_location = find_nearest_store(user_lat, user_lon)
    
    if not store_location:
        response_data['location_check'] = 'too_far_from_store'
        response_data['message'] = 'You are not within 50m of any store location - attendance not recorded'
        return jsonify(response_data)
    
    response_data['location_check'] = 'success'
    response_data['store_location'] = store_location
    
    # Parse timestamp or use current time
    if timestamp:
        try:
            check_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        except:
            check_time = datetime.now()
    else:
        check_time = datetime.now()
    
    # Check if time is before 9 AM
    is_on_time = check_time.time() <= time(9, 0)  # 9:00 AM
    
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
    
    # Determine attendance status and time check result
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
    try:
        cursor.execute("""
            INSERT INTO Attendance (employee_id,current_location, date, status, check_in, check_out)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            check_in = VALUES(check_in),
            current_location = VALUES(current_location)
        """, (
            employee_id,
            store_location,
            check_time.date(),
            attendance_status,
            check_time.time(),
            None  # check_out
        ))
        conn.commit()
        
        response_data['attendance_recorded'] = True
        response_data['attendance_status'] = attendance_status
        response_data['check_in_time'] = check_time.strftime('%H:%M:%S')
        response_data['message'] = f'Attendance successfully recorded as {attendance_status} at {store_location}'
        
    except Exception as e:
        response_data['message'] = f'Database error while recording attendance: {str(e)}'
        print(f"Database error: {e}")
    
    return jsonify(response_data)


@app.route('/api/create-account', methods=['POST'])
def create_account():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not (username and password):
        return jsonify({'success': False, 'message': 'Missing fields'}), 400
    
    try:
        # Check if username already exists
        cursor.execute("SELECT * FROM admin WHERE user_name = %s", (username,))
        if cursor.fetchone():
            return jsonify({'success': False, 'message': 'Username already taken'}), 409

        # Insert new account
        cursor.execute(
            "INSERT INTO admin (user_name, password) VALUES (%s, %s)",
            (username, password)
        )
        conn.commit()
        return jsonify({'success': True, 'message': 'Account created successfully'}), 201

    except Exception as e:
        print("Error:", e)
        return jsonify({'success': False, 'message': 'Internal server error'}), 500
    

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
   
    if not (username and password):
        return jsonify({'success': False, 'message': 'Missing username or password'}), 400
   
    try:
        cursor.execute(
            "SELECT * FROM admin WHERE user_name = %s AND password = %s",
            (username, password)
        )
        user = cursor.fetchone()
        if user:
            # Return username along with success message
            return jsonify({
                'success': True,
                'message': 'Login successful',
                'username': user['user_name']  # Now works with dictionary cursor
            }), 200
        else:
            return jsonify({'success': False, 'message': 'Invalid username or password'}), 401
    except Exception as e:
        print("Error:", e)
        return jsonify({'success': False, 'message': 'Internal server error'}), 500
    
@app.route('/api/attendance', methods=['GET'])
def get_attendance():
    try:
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
LIMIT 50;

        """)
       
        attendance_data = []
        for row in cursor:
            # Convert all data to native Python types
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
        print("Error fetching attendance data:", e)
        return jsonify({'error': 'Failed to fetch attendance data', 'details': str(e)}), 500


@app.route('/api/late-arrival-requests', methods=['GET'])
def get_late_arrival_requests():
    try:
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
        print("Error:", e)
        return jsonify({'error': 'Failed to fetch late arrival requests'}), 500


@app.route('/api/late-arrival-requests/<int:request_id>/status', methods=['PUT'])
def update_late_arrival_status(request_id):
    new_status = request.json.get('status')
    if new_status not in ['Accepted', 'Rejected']:
        return jsonify({'error': 'Invalid status'}), 400
    
    try:
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
        emp_name = row['name']
        current_location = row['permanent_location']
        requested_at = row['requested_at']
        
        # Determine attendance status
        attendance_status = 'Late' if new_status == 'Accepted' else 'Absent'
        # Determine check_in time
        check_in = requested_at if new_status == 'Accepted' else None
        
        # Insert attendance record
        cursor.execute("""
            INSERT INTO Attendance (employee_id,current_location, date, status, check_in, check_out)
            VALUES (%s, %s, CURDATE(), %s, %s, %s)
        """, (
            employee_id,
            current_location,
            attendance_status,
            check_in,
            None  # check_out
        ))
        
        # Update request status
        cursor.execute(
            "UPDATE LateArrivalRequests SET status = %s WHERE request_id = %s",
            (new_status, request_id)
        )
        
        conn.commit()
        return jsonify({'message': 'Status updated and attendance recorded'}), 200
    except Exception as e:
        print("Error updating status or inserting attendance:", e)
        import traceback
        traceback.print_exc()
        return jsonify({'error': 'Failed to process request'}), 500


@app.route('/api/employees', methods=['POST'])
def add_employee():
    try:
        data = request.get_json(force=True)
        
        # basic validation
        required = ["name", "email"]
        missing = [k for k in required if not data.get(k)]
        if missing:
            return jsonify({"success": False, "message": f"Missing fields: {', '.join(missing)}"}), 400
        
        name = data.get('name')
        email = data.get('email')
        permanent_location = data.get('permanent_location')
        position = data.get('position')
        phone_no = data.get('phone_no')
        photo_url = None
        date_joined = date.today()
        
        employee_id = generate_employee_id()
        
        cursor.execute("""
            INSERT INTO Employees
              (employee_id, name, email, permanent_location, position, date_joined, phone_no, photo_url)
            VALUES
              (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (employee_id, name, email, permanent_location, position, date_joined, phone_no, photo_url))
        
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "Employee added successfully",
            "employee_id": employee_id,
            "date_joined": str(date_joined)
        }), 201
        
    except Exception as e:
        app.logger.exception("Add employee failed")
        return jsonify({"success": False, "message": str(e)}), 500
    
@app.route('/api/employees/<int:employee_id>', methods=['DELETE'])
def remove_employee(employee_id):
    try:
        # Check if employee exists
        cursor.execute("SELECT * FROM Employees WHERE employee_id = %s", (employee_id,))
        if not cursor.fetchone():
            return jsonify({'success': False, 'message': 'Employee not found'}), 404
        
        # Delete employee
        cursor.execute("DELETE FROM Employees WHERE employee_id = %s", (employee_id,))
        conn.commit()
        
        return jsonify({'success': True, 'message': 'Employee removed successfully'}), 200
    except Exception as e:
        print("Error removing employee:", e)
        return jsonify({'success': False, 'message': 'Internal server error'}), 500
    
@app.route('/api/employee-status', methods=['POST'])
def get_employee_status():
    """
    Determine what action the employee should see based on:
    1. Employee ID validity
    2. Current time
    3. Existing attendance records for today
    4. Pending/approved late arrival requests
    """
    data = request.get_json()
    employee_id = data.get('employee_id')
    
    if not employee_id:
        return jsonify({'error': 'Employee ID is required'}), 400
    
    try:
        # Check if employee exists
        cursor.execute("SELECT employee_id, name FROM Employees WHERE employee_id = %s", (employee_id,))
        employee = cursor.fetchone()
        
        if not employee:
            return jsonify({
                'success': False,
                'error': 'Employee not found',
                'action': None
            }), 404
        
        current_time = datetime.now()
        today = current_time.date()
        
        # Check if employee already has attendance record for today
        cursor.execute("""
            SELECT status, check_in, check_out 
            FROM Attendance 
            WHERE employee_id = %s AND date = %s
        """, (employee_id, today))
        
        attendance_record = cursor.fetchone()
        
        # If already checked in today
        if attendance_record:
            if attendance_record['check_out'] is None:
                # Checked in but not checked out
                return jsonify({
                    'success': True,
                    'employee_name': employee['name'],
                    'action': 'check_out',
                    'current_status': attendance_record['status'],
                    'check_in_time': str(attendance_record['check_in']),
                    'message': f"Welcome back {employee['name']}! You're ready to check out."
                })
            else:
                # Already completed full day (checked in and out)
                return jsonify({
                    'success': True,
                    'employee_name': employee['name'],
                    'action': 'already_completed',
                    'current_status': attendance_record['status'],
                    'check_in_time': str(attendance_record['check_in']),
                    'check_out_time': str(attendance_record['check_out']),
                    'message': f"Hi {employee['name']}, you've already completed your attendance for today."
                })
        
        # No attendance record for today - determine what to show
        current_time_only = current_time.time()
        cutoff_time = time(9, 0)  # 9:00 AM
        
        if current_time_only <= cutoff_time:
            # Before 9 AM - show regular check-in
            return jsonify({
                'success': True,
                'employee_name': employee['name'],
                'action': 'check_in',
                'message': f"Good morning {employee['name']}! Ready to check in?"
            })
        else:
            # After 9 AM - check for existing late arrival requests
            cursor.execute("""
                SELECT request_id, status, requested_at 
                FROM LateArrivalRequests 
                WHERE employee_id = %s AND DATE(requested_at) = %s
                ORDER BY requested_at DESC 
                LIMIT 1
            """, (employee_id, today))
            
            late_request = cursor.fetchone()
            
            if late_request:
                if late_request['status'] == 'Pending':
                    return jsonify({
                        'success': True,
                        'employee_name': employee['name'],
                        'action': 'wait_for_approval',
                        'request_id': late_request['request_id'],
                        'requested_at': str(late_request['requested_at']),
                        'message': f"Hi {employee['name']}, your late arrival request is pending approval."
                    })
                elif late_request['status'] == 'Accepted':
                    return jsonify({
                        'success': True,
                        'employee_name': employee['name'],
                        'action': 'check_in',
                        'late_approval': True,
                        'message': f"Hi {employee['name']}, your late arrival was approved. Ready to check in?"
                    })
                elif late_request['status'] == 'Rejected':
                    return jsonify({
                        'success': True,
                        'employee_name': employee['name'],
                        'action': 'request_rejected',
                        'message': f"Hi {employee['name']}, your late arrival request was rejected. Please contact your supervisor."
                    })
            else:
                # No late request exists - show option to create one
                return jsonify({
                    'success': True,
                    'employee_name': employee['name'],
                    'action': 'late_arrival_request',
                    'current_time': current_time.strftime('%H:%M'),
                    'message': f"Hi {employee['name']}, it's past 9 AM. You need to submit a late arrival request."
                })
                
    except Exception as e:
        print(f"Error in employee status check: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'action': None
        }), 500
    
@app.route('/api/submit-late-request', methods=['POST'])
def submit_late_request():
    """
    Submit a late arrival request for an employee
    Accepts employee_id and time, stores with status 'Pending'
    """
    data = request.get_json()
    employee_id = data.get('employee_id')
    requested_time = data.get('time')  # Expected format: "10:30" or "10:30:00"
    
    if not employee_id:
        return jsonify({
            'success': False,
            'error': 'Employee ID is required'
        }), 400
    
    if not requested_time:
        return jsonify({
            'success': False,
            'error': 'Time is required'
        }), 400
    
    try:
        # Check if employee exists
        cursor.execute("SELECT name FROM Employees WHERE employee_id = %s", (employee_id,))
        employee = cursor.fetchone()
        
        if not employee:
            return jsonify({
                'success': False,
                'error': 'Employee not found'
            }), 404
        
        # Check if request already exists for today
        cursor.execute("""
            SELECT request_id FROM LateArrivalRequests 
            WHERE employee_id = %s AND DATE(requested_at) = CURDATE()
        """, (employee_id,))
        
        if cursor.fetchone():
            return jsonify({
                'success': False,
                'error': 'Late arrival request already submitted for today'
            }), 400
        
        # Parse the time and create datetime for today
        try:
            # Handle both "HH:MM" and "HH:MM:SS" formats
            if len(requested_time.split(':')) == 2:
                requested_time += ":00"  # Add seconds if not provided
            
            # Create datetime object for today with the requested time
            from datetime import datetime, date
            today = date.today()
            time_obj = datetime.strptime(requested_time, "%H:%M:%S").time()
            requested_datetime = datetime.combine(today, time_obj)
            
        except ValueError:
            return jsonify({
                'success': False,
                'error': 'Invalid time format. Use HH:MM or HH:MM:SS'
            }), 400
        
        # Insert late arrival request
        cursor.execute("""
            INSERT INTO LateArrivalRequests (employee_id, requested_at, status)
            VALUES (%s, %s, %s)
        """, (employee_id, requested_datetime, 'Pending'))
        
        conn.commit()
        
        # Get the inserted request ID for response
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
        return jsonify({
            'success': False,
            'error': 'Failed to submit request'
        }), 500


# @app.route('/api/check-out-verify', methods=['POST'])
# def check_out_verify():
#     """
#     Handle employee check-out with face verification and time input
#     """
#     if 'photo' not in request.files or 'employee_id' not in request.form:
#         return jsonify({'error': 'Missing photo or employee_id'}), 400
    
#     photo = request.files['photo']
#     employee_id = request.form['employee_id']
#     timestamp = request.form.get('timestamp')  # Optional timestamp
    
#     if photo.filename == '':
#         return jsonify({'error': 'No selected file'}), 400
    
#     # Initialize response object
#     response_data = {
#         'face_verification': None,
#         'check_out_recorded': False,
#         'message': None
#     }
    
#     try:
#         # Check if employee exists and get stored photo
#         cursor.execute("SELECT photo_url, name FROM Employees WHERE employee_id = %s", (employee_id,))
#         result = cursor.fetchone()
        
#         if result is None:
#             response_data['face_verification'] = 'employee_not_found'
#             response_data['message'] = 'Employee not found'
#             return jsonify(response_data), 404
        
#         stored_photo_path = result['photo_url']
#         emp_name = result['name']
        
#         if not stored_photo_path or not os.path.exists(stored_photo_path):
#             response_data['face_verification'] = 'no_stored_photo'
#             response_data['message'] = 'No stored photo found for employee'
#             return jsonify(response_data), 404
        
#         # Check if employee has an active check-in (not checked out yet)
#         cursor.execute("""
#             SELECT attendance_id, check_in, status, current_location 
#             FROM Attendance 
#             WHERE employee_id = %s AND date = CURDATE() AND check_out IS NULL
#         """, (employee_id,))
        
#         attendance_record = cursor.fetchone()

#         if not attendance_record:
#             response_data['face_verification'] = 'no_active_checkin'
#             response_data['message'] = 'No active check-in found for today. Please check-in first.'
#             return jsonify(response_data), 404
        
#         # Face detection on uploaded photo
#         photo.stream.seek(0)
#         if not is_face_detected(photo.stream):
#             response_data['face_verification'] = 'no_face_detected'
#             response_data['message'] = 'No face detected in uploaded photo'
#             return jsonify(response_data), 400
#         photo.stream.seek(0)
        
#         # Face verification with stored photo
#         with open(stored_photo_path, 'rb') as stored_image:
#             files = {
#                 'source_image': ('stored.jpg', stored_image, 'image/jpeg'),
#                 'target_image': ('uploaded.jpg', photo, 'image/jpeg')
#             }
#             headers = {
#                 'x-api-key': COMPRE_FACE_API_KEY
#             }
#             verification_response = requests.post(COMPRE_FACE_URL, files=files, headers=headers)
        
#         if verification_response.status_code != 200:
#             response_data['face_verification'] = 'verification_service_error'
#             response_data['message'] = 'Face verification service failed'
#             response_data['details'] = verification_response.text
#             return jsonify(response_data), 500
        
#         verification_result = verification_response.json()
#         similarity = verification_result['result'][0]['face_matches'][0]['similarity']
#         is_match = similarity >= 0.9
        
#         response_data['similarity'] = similarity
#         response_data['match'] = is_match
        
#         if not is_match:
#             response_data['face_verification'] = 'face_mismatch'
#             response_data['message'] = f'Face verification failed. Similarity: {similarity:.2f}'
#             return jsonify(response_data)
        
#         # Face verification successful
#         response_data['face_verification'] = 'success'
        
#         # Parse timestamp or use current time
#         if timestamp:
#             try:
#                 check_out_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
#             except:
#                 check_out_time = datetime.now()
#         else:
#             check_out_time = datetime.now()

#         check_in_value = attendance_record['check_in']
#         if isinstance(check_in_value, datetime):
#             check_in_datetime = check_in_value
#         elif isinstance(check_in_value, timedelta):
#             # If DB returned a duration instead of time, add it to today's midnight
#             check_in_datetime = datetime.combine(date.today(), time(0,0)) + check_in_value
#         else:
#             # Normal case: it's a time
#             check_in_datetime = datetime.combine(date.today(), check_in_value)

#         if check_out_time < check_in_datetime:
#             response_data['time_validation'] = 'invalid_checkout_time'
#             response_data['message'] = f'Check-out time cannot be before check-in time ({check_in_value})'
#             return jsonify(response_data), 400
        
#         response_data['time_validation'] = 'success'
        
#         # Update attendance record with check-out time
#         cursor.execute("""
#             UPDATE Attendance 
#             SET check_out = %s 
#             WHERE attendance_id = %s
#         """, (check_out_time.time(), attendance_record['attendance_id']))
        
#         conn.commit()
        
#         # Calculate total hours worked
#         time_diff = check_out_time - check_in_datetime
#         hours_worked = time_diff.total_seconds() / 3600
#         response_data.update({
#             'check_out_recorded': True,
#             'employee_name': emp_name,
#             'check_in_time': str(attendance_record['check_in']),
#             'check_out_time': check_out_time.strftime('%H:%M:%S'),
#             'attendance_status': attendance_record['status'],
#             'location': attendance_record['current_location'],
#             'hours_worked': round(hours_worked, 2),
#             'message': f'Successfully checked out {emp_name} at {check_out_time.strftime("%H:%M:%S")}'
#         })
        
#         return jsonify(response_data), 200
        
#     except Exception as e:
#         print(f"Error during check-out verification: {e}")
#         response_data['face_verification'] = 'system_error'
#         response_data['message'] = 'Internal server error during check-out'
#         return jsonify(response_data), 500

from datetime import datetime, date, time, timedelta

@app.route('/api/check-out-verify', methods=['POST'])
def check_out_verify():
    """
    Handle employee check-out with face verification and time input
    """
    if 'photo' not in request.files or 'employee_id' not in request.form:
        return jsonify({'error': 'Missing photo or employee_id'}), 400
    
    photo = request.files['photo']
    employee_id = request.form['employee_id']
    timestamp = request.form.get('timestamp')  # Optional timestamp
    
    if photo.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    response_data = {
        'face_verification': None,
        'check_out_recorded': False,
        'message': None
    }
    
    try:
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
        
        # ✅ FIX: Use Python’s date.today() instead of CURDATE()
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
        
        # Face verification with stored photo
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
        
        # Update record
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
        cursor.execute("""
            SELECT employee_id, name, email, phone_no, position, permanent_location, date_joined
            FROM Employees
        """)
        employees = cursor.fetchall()

        return jsonify({"success": True, "employees": employees}), 200
    except Exception as e:
        print("Error fetching employees:", e)
        return jsonify({"success": False, "message": "Failed to fetch employees"}), 500 
   

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
