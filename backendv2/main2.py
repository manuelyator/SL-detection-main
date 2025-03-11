import cv2
from cvzone.HandTrackingModule import HandDetector
from cvzone.ClassificationModule import Classifier
import numpy as np
import math

cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("Failed to open webcam!", flush=True)
else:
    print("Webcam opened successfully!", flush=True)

try:
    detector = HandDetector(maxHands=1)
    classifier = Classifier("Model/keras_model.h5", "Model/labels.txt")
    print("Detector and Classifier initialized successfully!", flush=True)
except Exception as e:
    print("Error initializing detector or classifier:", e, flush=True)
offset = 20
imgSize = 300
counter = 0



labels = ["Hello", "I love you", "No", "Okay", "Please", "Thank you", "Yes"]

while True:
    success, img = cap.read()
    if not success:
        print("Failed to grab frame")
        continue
    print("Frame captured")  # Debug statement

    imgOutput = img.copy()
    hands, img = detector.findHands(img)
    print("Hands detected:", hands)  # Debug statement

    if hands:
        hand = hands[0]
        x, y, w, h = hand['bbox']
        print("Bounding box:", x, y, w, h)  # Debug statement

        imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255
        imgCrop = img[y - offset:y + h + offset, x - offset:x + w + offset]
        
        aspectRatio = h / w

        if aspectRatio > 1:
            k = imgSize / h
            wCal = math.ceil(k * w)
            imgResize = cv2.resize(imgCrop, (wCal, imgSize))
            wGap = math.ceil((imgSize - wCal) / 2)
            imgWhite[:, wGap: wCal + wGap] = imgResize
            prediction, index = classifier.getPrediction(imgWhite, draw=False)
            print("Prediction:", prediction, "Index:", index)
        else:
            k = imgSize / w
            hCal = math.ceil(k * h)
            imgResize = cv2.resize(imgCrop, (imgSize, hCal))
            hGap = math.ceil((imgSize - hCal) / 2)
            imgWhite[hGap: hCal + hGap, :] = imgResize
            prediction, index = classifier.getPrediction(imgWhite, draw=False)
            print("Prediction:", prediction, "Index:", index)

        cv2.rectangle(imgOutput, (x - offset, y - offset - 70), (x - offset + 400, y - offset + 60 - 50), (0, 255, 0), cv2.FILLED)
        cv2.putText(imgOutput, labels[index], (x, y - 30), cv2.FONT_HERSHEY_COMPLEX, 2, (0, 0, 0), 2)
        cv2.rectangle(imgOutput, (x - offset, y - offset), (x + w + offset, y + h + offset), (0, 255, 0), 4)
        cv2.imshow('ImageCrop', imgCrop)
        cv2.imshow('ImageWhite', imgWhite)

    cv2.imshow('Image', imgOutput)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()


