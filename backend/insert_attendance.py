import pandas as pd
import mysql.connector

# Load CSV
df = pd.read_csv("attendance.csv")

# DB connection
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="139Virgo",
    database="spectra"
)
cursor = db.cursor()

# Subject mapping
subject_map = {
    "DSA (T)": 1,
    "DSA (L)": 2,
    "DBMS (T)": 3,
    "DBMS (L)": 4,
    "AS (T)": 5,
    "EDI (L)": 6,
    "MLCT (L)": 7,
    "CTC (L)": 8
}

for _, row in df.iterrows():
    date = row['Date']
    subject = row['Subject']

    if subject not in subject_map:
        continue

    subject_id = subject_map[subject]

    for student in df.columns[3:]:
        status = "Present" if row[student] == 'P' else "Absent"

        cursor.execute("""
            INSERT INTO attendance (student_id, subject_id, date, status)
            SELECT id, %s, %s, %s FROM users WHERE username = %s
            ON DUPLICATE KEY UPDATE status = VALUES(status)
        """, (subject_id, date, status, student))

db.commit()
cursor.close()
db.close()

print("✅ Attendance inserted successfully")

@app.route('/student_stats/<int:student_id>', methods=['GET'])
def student_stats(student_id):
    cursor = db.cursor(dictionary=True)

    query = """
    SELECT date, status, subject_id
    FROM attendance
    WHERE student_id = %s
    ORDER BY date
    """
    cursor.execute(query, (student_id,))
    data = cursor.fetchall()

    return jsonify(data)

@app.route('/teacher_stats/<int:teacher_id>', methods=['GET'])
def teacher_stats(teacher_id):
    cursor = db.cursor(dictionary=True)

    query = """
    SELECT a.date, a.status, a.subject_id
    FROM attendance a
    JOIN subjects s ON a.subject_id = s.id
    JOIN users u ON u.username = s.teacher_code
    WHERE u.id = %s
    """
    cursor.execute(query, (teacher_id,))
    data = cursor.fetchall()

    return jsonify(data)