import cv2
from cvzone.HandTrackingModule import HandDetector
import numpy as np
import math
import time
import os

# Ensure the folder exists
folder = "Data/Okay"
os.makedirs(folder, exist_ok=True)

cap = cv2.VideoCapture(0)
detector = HandDetector(maxHands=1)
offset = 20
imgSize = 300
counter = 0

try:
    while True:
        success, img = cap.read()
        if not success:
            print("Failed to grab frame")
            continue
        
        print("Frame captured")  # Debug statement

        hands, img = detector.findHands(img)
        print("Hands detected:", hands)  # Debug statement
        
        if hands:
            hand = hands[0]
            x, y, w, h = hand['bbox']
            print("Bounding box:", x, y, w, h)  # Debug statement

            # Create a white background image
            imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

            # Crop the hand image with some offset
            imgCrop = img[y - offset:y + h + offset, x - offset:x + w + offset]

            aspectRatio = h / w

            if aspectRatio > 1:
                k = imgSize / h
                wCal = math.ceil(k * w)
                imgResize = cv2.resize(imgCrop, (wCal, imgSize))
                wGap = math.ceil((imgSize - wCal) / 2)
                imgWhite[:, wGap: wCal + wGap] = imgResize
            else:
                k = imgSize / w
                hCal = math.ceil(k * h)
                imgResize = cv2.resize(imgCrop, (imgSize, hCal))
                hGap = math.ceil((imgSize - hCal) / 2)
                imgWhite[hGap: hCal + hGap, :] = imgResize

            cv2.imshow('ImageCrop', imgCrop)
            cv2.imshow('ImageWhite', imgWhite)

        cv2.imshow('Image', img)
        key = cv2.waitKey(1)
        if key == ord("s"):
            counter += 1
            cv2.imwrite(f'{folder}/Image_{time.time()}.jpg', imgWhite)
            print("Saved image number:", counter)
except Exception as e:
    print("An error occurred:", e)
finally:
    cap.release()
    cv2.destroyAllWindows()
