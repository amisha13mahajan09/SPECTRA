import cv2
import os
import numpy as np

# =========================
# DATASET PATH
# =========================
dataset_path = os.path.join(os.path.dirname(__file__), "dataset")

# =========================
# NAME → ID MAPPING
# (KEEP THIS SAME AS DB USERS)
# =========================
name_to_id = {
    "Amisha Mahajan": 26,
    "Aryan Bhosale": 9,
    "Maithily Tembhurne": 7,
    "Pranav Borse": 6
}

# =========================
# TRAIN MODEL FUNCTION
# =========================
def train_model():
    faces = []
    labels = []
    label_map = {}

    current_label = 0

    # Load Haar Cascade ONCE
    face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )

    # =========================
    # LOOP THROUGH PEOPLE
    # =========================
    for person in os.listdir(dataset_path):
        person_path = os.path.join(dataset_path, person)

        if not os.path.isdir(person_path):
            continue

        print(f"Processing: {person}")

        # Skip unknown folders
        if person not in name_to_id:
            print(f"⚠️ Unknown person: {person}")
            continue

        label_map[current_label] = name_to_id[person]

        # =========================
        # LOOP IMAGES
        # =========================
        for img_name in os.listdir(person_path):
            img_path = os.path.join(person_path, img_name)

            # Skip hidden files
            if img_name.startswith("."):
                continue

            img = cv2.imread(img_path)

            if img is None:
                print(f"❌ Failed to load: {img_path}")
                continue

            # Convert to grayscale
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

            # Slight normalization (helps accuracy)
            gray = cv2.equalizeHist(gray)

            # =========================
            # FACE DETECTION
            # =========================
            faces_rect = face_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=4,
                minSize=(40, 40)
            )

            print(f"👁 Faces detected in {img_path}: {len(faces_rect)}")

            if len(faces_rect) == 0:
                print(f"⚠️ No face in {img_path}")
                continue

            # Pick largest face
            faces_rect = sorted(faces_rect, key=lambda f: f[2] * f[3], reverse=True)
            (x, y, w, h) = faces_rect[0]

            face = gray[y:y+h, x:x+w]
            face = cv2.resize(face, (200, 200))

            faces.append(face)
            labels.append(current_label)

        current_label += 1

    # =========================
    # SAFETY CHECK
    # =========================
    if len(faces) == 0:
        raise Exception("🚨 No valid training images found!")

    # =========================
    # TRAIN LBPH MODEL
    # =========================
    recognizer = cv2.face.LBPHFaceRecognizer_create()
    recognizer.train(faces, np.array(labels))

    print("✅ Training completed successfully")

    return recognizer, label_map


# =========================
# TRAIN ON IMPORT
# =========================
recognizer, label_map = train_model()