from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector
import pandas as pd
import matplotlib


# ✅ Prevent crash on Mac
matplotlib.use('Agg')

import matplotlib.pyplot as plt
import seaborn as sns
import os

CLASSROOMS = {
    "T": {  # Theory → AC 304
        "lat": 18.490309,
        "lng": 73.809124,
        "radius": 100
    },
    "L": {  # Lab → MB 607
        "lat": 18.490589,
        "lng": 73.809472,
        "radius": 100
    }
}
# =========================
# APP INIT
# =========================
app = Flask(__name__)
CORS(app)

# =========================
# DATABASE CONNECTION
# =========================
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="139Virgo",
    database="spectra"
)

# =========================
# LOGIN API
# =========================
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    cursor = db.cursor(dictionary=True)

    query = "SELECT id, username, name, role FROM users WHERE username=%s AND password=%s"
    cursor.execute(query, (data.get('username'), data.get('password')))

    user = cursor.fetchone()

    if user:
        return jsonify({"status": "success", "user": user})
    else:
        return jsonify({"status": "fail", "message": "Invalid credentials"})


# =========================
# REGISTER API
# =========================
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    cursor = db.cursor(dictionary=True)

    if not data.get('username') or not data.get('password') or not data.get('name'):
        return jsonify({"status": "fail", "message": "All fields required"})

    cursor.execute("SELECT * FROM users WHERE username=%s", (data['username'],))
    if cursor.fetchone():
        return jsonify({"status": "fail", "message": "User exists"})

    cursor.execute("""
        INSERT INTO users (username, password, name, role)
        VALUES (%s, %s, %s, 'student')
    """, (data['username'], data['password'], data['name']))

    db.commit()
    return jsonify({"status": "success"})


# =========================
# GET TIMETABLE
# =========================
@app.route('/timetable', methods=['GET'])
def get_timetable():
    cursor = db.cursor(dictionary=True)

    date = request.args.get('date')

    from datetime import datetime
    day = datetime.strptime(date, "%Y-%m-%d").strftime("%A")

    cursor.execute("""
    SELECT
        t.day,
        t.time_slot,
        s.id AS subject_id,
        s.subject_name,
        s.subject_code,
        s.type,
        s.teacher_name,
        s.teacher_code
    FROM timetable t
    LEFT JOIN timetable_overrides o
        ON t.time_slot = o.time_slot
        AND t.day = o.day
        AND o.date = %s
    JOIN subjects s
        ON s.id = COALESCE(o.subject_id, t.subject_id)
    WHERE t.day = %s
    ORDER BY t.time_slot
    """, (date, day))

    return jsonify(cursor.fetchall())


# =========================
# USER TIMETABLE
# =========================
@app.route('/timetable/<int:user_id>', methods=['GET'])
def get_user_timetable(user_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT t.day, t.time_slot,
           s.id AS subject_id, s.subject_name,
           s.subject_code, s.type, s.teacher_name
    FROM timetable t
    JOIN subjects s ON t.subject_id = s.id
    JOIN student_subjects ss ON ss.subject_id = s.id
    WHERE ss.student_id = %s
    ORDER BY FIELD(t.day,'Monday','Tuesday','Wednesday','Thursday','Friday'),
             t.time_slot
    """, (user_id,))

    return jsonify(cursor.fetchall())

@app.route('/update_slot_override', methods=['POST'])
def update_slot_override():
    data = request.json

    date = data['date']
    time_slot = data['time_slot']
    subject_id = data['subject_id']

    from datetime import datetime
    day = datetime.strptime(date, "%Y-%m-%d").strftime("%A")

    cursor = db.cursor()

    cursor.execute("""
        DELETE FROM timetable_overrides
        WHERE date = %s AND time_slot = %s
    """, (date, time_slot))

    cursor.execute("""
        INSERT INTO timetable_overrides (date, day, time_slot, subject_id)
        VALUES (%s, %s, %s, %s)
    """, (date, day, time_slot, subject_id))

    db.commit()
    return jsonify({"status": "updated"})

# =========================
# MARK ATTENDANCE
# =========================
@app.route('/mark_attendance', methods=['POST'])
def mark_attendance():
    data = request.json
    cursor = db.cursor()

    cursor.execute("""
    INSERT INTO attendance (student_id, subject_id, date, status)
    VALUES (%s, %s, CURDATE(), %s)
    """, (data['student_id'], data['subject_id'], data['status']))

    db.commit()
    return jsonify({"status": "attendance marked"})


# =========================
# GET ATTENDANCE
# =========================
@app.route('/attendance/<int:student_id>', methods=['GET'])
def get_attendance(student_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT s.subject_name, s.subject_code, a.date, a.status
    FROM attendance a
    JOIN subjects s ON a.subject_id = s.id
    WHERE a.student_id = %s
    ORDER BY a.date DESC
    """, (student_id,))

    return jsonify(cursor.fetchall())


# =========================
# STUDENT RAW DATA
# =========================
@app.route('/student_stats/<int:student_id>', methods=['GET'])
def student_stats(student_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT date, status, subject_id
    FROM attendance
    WHERE student_id = %s
    ORDER BY date
    """, (student_id,))

    return jsonify(cursor.fetchall())


# =========================
# TEACHER RAW DATA
# =========================
@app.route('/teacher_stats/<int:teacher_id>', methods=['GET'])
def teacher_stats(teacher_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT a.date, a.status, a.subject_id
    FROM attendance a
    JOIN subjects s ON a.subject_id = s.id
    JOIN users u ON u.username = s.teacher_code
    WHERE u.id = %s
    ORDER BY a.date
    """, (teacher_id,))

    return jsonify(cursor.fetchall())


# =========================
# ✅ FIXED STUDENT ANALYTICS
# =========================
@app.route('/student_analytics/<int:student_id>', methods=['GET'])
def student_analytics(student_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT
        a.date,
        a.status,
        a.subject_id,
        CONCAT(
            CASE
                WHEN s.subject_name = 'Data Structures and Algorithms' THEN 'DSA'
                WHEN s.subject_name = 'Database Management System' THEN 'DBMS'
                WHEN s.subject_name = 'Applied Statistics Theory' THEN 'AS'
                WHEN s.subject_name = 'Engineering Design and Innovation' THEN 'EDI'
                WHEN s.subject_name = 'Media Literacy and Critical Thinking' THEN 'MLCT'
                WHEN s.subject_name = 'Campus To Corporate' THEN 'CTC'
            END,
            ' (', s.type, ')'
        ) AS subject_name
    FROM attendance a
    JOIN subjects s ON a.subject_id = s.id
    WHERE a.student_id = %s
    ORDER BY a.date
    """, (student_id,))

    df = pd.DataFrame(cursor.fetchall())

    if df.empty:
        return jsonify({"error": "No data"})

    df['date'] = pd.to_datetime(df['date'])

    # ===== OVERALL =====
    total = len(df)
    present = len(df[df['status'] == 'Present'])
    absent = total - present

    overall = {
        "present": present,
        "absent": absent,
        "present_pct": round((present/total)*100, 2),
        "absent_pct": round((absent/total)*100, 2)
    }

    # ===== DAILY LIST (FOR ARROWS) =====
    daily_list = []

    for date, group in df.groupby(df['date'].dt.date):
        slots = group['status'].tolist()[:4]

        while len(slots) < 4:
            slots.append("Absent")

        daily_list.append({
            "date": str(date),
            "slots": slots
        })

    daily_list = sorted(daily_list, key=lambda x: x['date'])
    latest_day = daily_list[-1]

    # ===== WEEKLY =====
    df['day'] = df['date'].dt.day_name()

    weekly = df.groupby('day')['status'].apply(
        lambda x: (x == "Present").sum() / len(x) * 100
    )

    weekly = weekly.reindex(
        ["Monday","Tuesday","Wednesday","Thursday","Friday"]
    ).fillna(0)

    weekly.index = ["Mon","Tue","Wed","Thu","Fri"]

    # ===== MONTHLY =====
    df['month'] = df['date'].dt.strftime('%b')

    monthly = df.groupby('month')['status'].apply(
        lambda x: (x == "Present").sum() / len(x) * 100
    )

    # ===== SUBJECTS =====
    subjects = []

    grouped = df.groupby('subject_name')

    for name, group in grouped:
        total = len(group)
        p = len(group[group['status'] == "Present"])
        a = total - p

        subjects.append({
            "subject": name,
            "total": total,
            "present": p,
            "absent": a,
            "percentage": round((p / total) * 100, 2)
        })

    return jsonify({
        "overall": overall,
        "daily": latest_day,
        "daily_list": daily_list,
        "weekly": weekly.to_dict(),
        "monthly": monthly.to_dict(),
        "subjects": subjects
    })


# =========================
# TEACHER ANALYTICS
# =========================
@app.route('/teacher_analytics/<int:teacher_id>', methods=['GET'])
def teacher_analytics(teacher_id):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
    SELECT
        s.subject_name,
        s.subject_code,
        COUNT(DISTINCT CONCAT(a.date, a.subject_id)) as total
    FROM attendance a
    JOIN subjects s ON a.subject_id = s.id
    JOIN users u ON u.username = s.teacher_code
    WHERE u.id = %s
    GROUP BY s.subject_name, s.subject_code
    """, (teacher_id,))

    return jsonify(cursor.fetchall())


# =========================
# SERVE CHARTS
# =========================
@app.route('/charts/<path:filename>')
def get_chart(filename):
    return send_from_directory('charts', filename)


# =========================
# LOGOUT API
# =========================
@app.route('/logout', methods=['POST'])
def logout():
    try:
        data = request.json

        if not data or 'user_id' not in data:
            return jsonify({
                "status": "fail",
                "message": "Invalid request"
            }), 400

        return jsonify({
            "status": "success",
            "message": "Logged out successfully"
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route('/slot_attendance', methods=['GET'])
def slot_attendance():
    subject_id = request.args.get('subject_id')
    date = request.args.get('date')

    cursor = db.cursor(dictionary=True)

    # ✅ Check if ANY attendance has been marked for this slot
    cursor.execute("""
        SELECT COUNT(*) AS cnt FROM attendance
        WHERE subject_id = %s AND date = %s
    """, (subject_id, date))

    row = cursor.fetchone()

    if row['cnt'] == 0:
        return jsonify([])  # No attendance marked yet → return empty list

    # Attendance exists → return full list with statuses
    cursor.execute("""
    SELECT u.id, u.username AS prn, u.name,
           COALESCE(
               MAX(CASE WHEN a.status = 'Present' THEN 'Present' END),
               'Absent'
           ) AS status
    FROM users u
    JOIN student_subjects ss ON ss.student_id = u.id
    LEFT JOIN attendance a
        ON a.student_id = u.id
        AND a.subject_id = %s
        AND a.date = %s
    WHERE ss.subject_id = %s
    AND u.role = 'student'
    GROUP BY u.id, u.username, u.name
    """, (subject_id, date, subject_id))

    return jsonify(cursor.fetchall())


@app.route('/update_attendance', methods=['POST'])
def update_attendance():
    data = request.json
    cursor = db.cursor()

    # check if already exists
    cursor.execute("""
    SELECT * FROM attendance
    WHERE student_id=%s AND subject_id=%s AND date=%s
    """, (data['student_id'], data['subject_id'], data['date']))

    exists = cursor.fetchall()

    if exists:
        cursor.execute("""
        UPDATE attendance
        SET status=%s
        WHERE student_id=%s AND subject_id=%s AND date=%s
        """, (data['status'], data['student_id'], data['subject_id'], data['date']))
    else:
        cursor.execute("""
        INSERT INTO attendance (student_id, subject_id, date, status)
        VALUES (%s, %s, %s, %s)
        """, (data['student_id'], data['subject_id'], data['date'], data['status']))

    db.commit()
    return jsonify({"status": "updated"})

import cv2
from face_recognizer import recognizer, label_map


import math

def calculate_distance(lat1, lon1, lat2, lon2):
    lat1 = float(lat1)
    lon1 = float(lon1)
    lat2 = float(lat2)   # ✅ added
    lon2 = float(lon2)   # ✅ added

    R = 6371000  # Earth radius in meters

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)

    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi/2)**2 + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda/2)**2

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

    return R * c

def is_qr_active(subject_id, date, time_slot):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT is_active FROM qr_sessions
        WHERE subject_id=%s AND date=%s AND time_slot=%s
    """, (subject_id, date, time_slot))

    row = cursor.fetchone()

    return row and row['is_active'] == 1

@app.route('/recognize', methods=['POST'])
def recognize():
    try:
        print("\n========== NEW REQUEST ==========")
        print("🔥 Recognize API hit")

        # =========================
        # GET DATA
        # =========================
        file = request.files.get('image')
        qr_data = request.form.get('qr_data')
        lat = request.form.get('lat')
        lng = request.form.get('lng')

        print("1️⃣ Received request")
        print("2️⃣ QR:", qr_data)
        print("3️⃣ Location:", lat, lng)

        # =========================
        # VALIDATION
        # =========================
        if not file:
            return jsonify({"message": "❌ Image not received"}), 400

        if not qr_data:
            return jsonify({"message": "❌ QR data missing"}), 400

        if not lat or not lng:
            return jsonify({"message": "❌ Location not received"}), 400

        # =========================
        # PARSE QR (FIXED)
        # =========================
        subject_id = "1"   # default
        date = None        # ✅ ALWAYS defined

        try:
            parts = {}
            for item in qr_data.split("|"):
                key, value = item.split(":", 1)  # 👈 ONLY split once
                parts[key] = value

            subject_id = parts.get("SUB", "1")
            date_str = parts.get("DATE")

            if date_str:
                date = date_str.split("T")[0]

        except Exception as e:
            print("⚠️ QR PARSE ERROR:", e)

        # ✅ FALLBACK DATE (VERY IMPORTANT)
        if not date:
            from datetime import datetime
            date = datetime.now().strftime("%Y-%m-%d")

        # =========================
        # QR ACTIVE CHECK (FIXED)
        # =========================

        time_slot = parts.get("TIME")

        date_str = parts.get("DATE")
        date = date_str.split("T")[0] if date_str else date

        # safety check (VERY IMPORTANT)
        if not subject_id or not time_slot:
            return jsonify({
                    "message": "❌ Invalid QR data"
            }), 400

        # check if QR is active
        if not is_qr_active(subject_id, date, time_slot):
            return jsonify({
                   "message": "❌ QR is not active"
            }), 403

        # ✅ BACKEND SLOT CROSS-CHECK
        expected_time_slot = request.form.get('expected_time_slot')
        print("🕐 Expected slot from app:", expected_time_slot)
        print("🕐 QR slot:", time_slot)

        if expected_time_slot and time_slot != expected_time_slot:
            return jsonify({
                   "message": "❌ Wrong QR! This QR is for a different slot."
            }), 403

        # ✅ ADDED — verify the scanned QR's time_slot matches
        # an actually active session (not just any session)
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT time_slot FROM qr_sessions
            WHERE subject_id=%s AND date=%s AND time_slot=%s AND is_active=1
        """, (subject_id, date, time_slot))

        active_session = cursor.fetchone()

        if not active_session:
            return jsonify({
                "message": "❌ QR does not match any active slot"
            }), 403

        # =========================
        # GET SUBJECT
        # =========================
        cursor = db.cursor(dictionary=True)

        cursor.execute("SELECT type FROM subjects WHERE id=%s", (subject_id,))
        subject = cursor.fetchone()

        if not subject:
            return jsonify({"message": "❌ Subject not found"}), 404

        classroom = CLASSROOMS.get(subject['type'])

        if not classroom:
            return jsonify({"message": "❌ Classroom config missing"}), 400

        # =========================
        # GEOFENCING
        # =========================
        distance = calculate_distance(
            lat, lng,
            classroom["lat"],
            classroom["lng"]
        )

        print(f"📍 Distance from classroom: {distance:.2f}m (allowed: {classroom['radius']}m)")

        if distance > classroom["radius"]:
            return jsonify({
                "message": f"❌ You are outside the classroom (distance: {round(distance)}m)"
            }), 403

        # =========================
        # SAVE IMAGE
        # =========================
        import uuid
        import os

        filepath = f"temp_{uuid.uuid4()}.jpg"
        file.save(filepath)

        print("4️⃣ Image saved:", filepath)

        # =========================
        # LOAD IMAGE
        # =========================
        import cv2
        import time

        img = cv2.imread(filepath)

        if img is None:
            return jsonify({"message": "❌ Image error"}), 500

        # ✅ resize BEFORE processing
        img = cv2.resize(img, (640, 480))

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # =========================
        # FACE DETECTION
        # =========================
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )



        faces = face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=4,
            minSize=(40, 40)
        )

        # ✅ ADD THIS LINE RIGHT HERE
        print("👁 Faces detected:", len(faces))

        if len(faces) == 0:
            return jsonify({"message": "❌ No face detected"}), 400
        else:
            faces = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)
            (x, y, w, h) = faces[0]

            face = gray[y:y+h, x:x+w]
            face = cv2.equalizeHist(face)
            face = cv2.normalize(face, None, 0, 255, cv2.NORM_MINMAX)
            face = cv2.resize(face, (200, 200))

        # =========================
        # RECOGNITION (WITH TIMEOUT + DEBUG)
        # =========================
        print("6️⃣ Before recognition")

        import time
        start = time.time()

        try:
            label, confidence = recognizer.predict(face)
        except Exception as e:
            print("❌ Recognition error:", e)
            return jsonify({"message": "❌ Face recognition failed"}), 500

        print("⏱ Recognition time:", time.time() - start)
        print("🎯 Label:", label, "Confidence:", confidence)

        # =========================
        # MATCH CHECK
        # =========================
        if confidence > 80:
            print("❌ Face not recognized")
            return jsonify({"message": "❌ Face not recognized"}), 401

        logged_in_student_id = request.form.get('student_id')

        recognized_id = label_map.get(label)
        print("🔍 Recognized ID:", recognized_id)
        print("🧑 Logged-in ID:", logged_in_student_id)

        if not recognized_id:
            return jsonify({"message": "❌ User not mapped"}), 404


        # ✅ MATCH CHECK
        if str(recognized_id) != str(logged_in_student_id):
            print("❌ Face does not match logged-in user")
            return jsonify({
                "message": "❌ Face does not match logged-in user"
            }), 403

        student_id = recognized_id

        cursor.execute("""
        SELECT * FROM attendance
        WHERE student_id=%s AND subject_id=%s AND date=%s
        """, (student_id, subject_id, date))

        if cursor.fetchone():
            return jsonify({"message": "⚠️ Already marked"})

        cursor.execute("""
        INSERT INTO attendance (student_id, subject_id, date, status)
        VALUES (%s, %s, %s, 'Present')
        """, (student_id, subject_id, date))

        db.commit()

        print("✅ Attendance marked")

        return jsonify({
            "message": f"✅ Attendance marked for student ID {recognized_id}"
        })

    except Exception as e:
        print("🔥 SERVER ERROR:", str(e))
        return jsonify({
            "message": "❌ Server error",
            "error": str(e)
        }), 500

    finally:
        try:
            if 'filepath' in locals() and os.path.exists(filepath):
                os.remove(filepath)
                print("🧹 Temp file deleted")
        except Exception as e:
            print("⚠️ Cleanup error:", e)

# =========================
# DEFAULTERS (<75%)
# =========================
@app.route('/defaulters', methods=['GET'])
def get_defaulters():
    cursor = db.cursor(dictionary=True)

    # Get attendance per student
    cursor.execute("""
    SELECT
        u.id,
        u.username AS prn,
        u.name,
        COUNT(a.id) AS total,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present
    FROM users u
    JOIN attendance a ON a.student_id = u.id
    WHERE u.role = 'student'
    GROUP BY u.id, u.username, u.name
    """)

    students = cursor.fetchall()

    defaulters = []

    for s in students:
        total = s['total']
        present = s['present'] or 0

        if total == 0:
            continue

        percentage = (present / total) * 100

        if percentage < 75:
            defaulters.append({
                "prn": s['prn'],
                "name": s['name'],
                "attendance": round(percentage, 2)
            })

    return jsonify(defaulters)

@app.route('/qr/start', methods=['POST'])
def start_qr():
    data = request.json
    cursor = db.cursor()

    cursor.execute("""
        INSERT INTO qr_sessions (subject_id, date, time_slot, is_active)
        VALUES (%s, %s, %s, 1)
        ON DUPLICATE KEY UPDATE is_active=1
    """, (data['subject_id'], data['date'], data['time_slot']))

    db.commit()
    return jsonify({"status": "QR started"})

@app.route('/qr/stop', methods=['POST'])
def stop_qr():
    data = request.json
    cursor = db.cursor()

    cursor.execute("""
        UPDATE qr_sessions
        SET is_active = 0
        WHERE subject_id=%s AND date=%s AND time_slot=%s
    """, (data['subject_id'], data['date'], data['time_slot']))

    db.commit()
    return jsonify({"status": "QR stopped"})

def is_qr_active(subject_id, date, time_slot):
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT is_active FROM qr_sessions
        WHERE subject_id=%s AND date=%s AND time_slot=%s
    """, (subject_id, date, time_slot))

    row = cursor.fetchone()

    return row and row['is_active'] == 1

# =========================
# RUN SERVER
# =========================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
