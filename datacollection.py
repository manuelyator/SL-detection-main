import cv2
from cvzone.HandTrackingModule import HandDetector
import numpy as np
import math
import time
import os


# Function to process a single hand
def process_hand(img, hand, imgSize, offset):
    global imgWhite

    x, y, w, h = hand['bbox']

    # Create a white background image
    imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

    # Crop the hand region with padding
    imgCrop = img[max(0, y - offset):min(img.shape[0], y + h + offset),
              max(0, x - offset):min(img.shape[1], x + w + offset)]

    if imgCrop.size == 0:
        return

    aspectRatio = h / w

    if aspectRatio > 1:
        # Height greater than width
        k = imgSize / h
        wCal = math.ceil(k * w)
        imgResize = cv2.resize(imgCrop, (wCal, imgSize))
        wGap = math.ceil((imgSize - wCal) / 2)
        imgWhite[:, wGap:wCal + wGap] = imgResize
    else:
        # Width greater than height
        k = imgSize / w
        hCal = math.ceil(k * h)
        imgResize = cv2.resize(imgCrop, (imgSize, hCal))
        hGap = math.ceil((imgSize - hCal) / 2)
        imgWhite[hGap:hCal + hGap, :] = imgResize

    cv2.imshow("ImageCrop", imgCrop)
    cv2.imshow("ImageWhite", imgWhite)


# Function to process both hands together
def process_double_hands(img, hands, imgSize, offset):
    global imgWhite

    # Find the bounding box that encompasses both hands
    min_x = min(hands[0]['bbox'][0], hands[1]['bbox'][0])
    min_y = min(hands[0]['bbox'][1], hands[1]['bbox'][1])

    max_x = max(hands[0]['bbox'][0] + hands[0]['bbox'][2],
                hands[1]['bbox'][0] + hands[1]['bbox'][2])
    max_y = max(hands[0]['bbox'][1] + hands[0]['bbox'][3],
                hands[1]['bbox'][1] + hands[1]['bbox'][3])

    w = max_x - min_x
    h = max_y - min_y

    # Create a white background image
    imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

    # Crop the region containing both hands with padding
    imgCrop = img[max(0, min_y - offset):min(img.shape[0], max_y + offset),
              max(0, min_x - offset):min(img.shape[1], max_x + offset)]

    if imgCrop.size == 0:
        return

    aspectRatio = h / w

    if aspectRatio > 1:
        # Height greater than width
        k = imgSize / h
        wCal = math.ceil(k * w)
        imgResize = cv2.resize(imgCrop, (wCal, imgSize))
        wGap = math.ceil((imgSize - wCal) / 2)
        imgWhite[:, wGap:wCal + wGap] = imgResize
    else:
        # Width greater than height
        k = imgSize / w
        hCal = math.ceil(k * h)
        imgResize = cv2.resize(imgCrop, (imgSize, hCal))
        hGap = math.ceil((imgSize - hCal) / 2)
        imgWhite[hGap:hCal + hGap, :] = imgResize

    cv2.imshow("ImageCrop", imgCrop)
    cv2.imshow("ImageWhite", imgWhite)


# Create the data folder if it doesn't exist
os.makedirs("Data/No", exist_ok=True)

cap = cv2.VideoCapture(0)
detector = HandDetector(maxHands=2)  # Set to detect up to 2 hands

offset = 20
imgSize = 300

folder = "Data/No"
counter = 0

# Current mode: 'single' or 'double'
mode = 'single'
imgWhite = None

while True:
    success, img = cap.read()
    hands, img = detector.findHands(img)

    # Display current mode on the image
    cv2.putText(img, f"Mode: {mode}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.putText(img, "Press 'm' to switch mode", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.putText(img, "Press 's' to save", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    if hands:
        if mode == 'single' and len(hands) > 0:
            # Process only the first detected hand
            process_hand(img, hands[0], imgSize, offset)

        elif mode == 'double' and len(hands) >= 2:
            # Process both hands together in a single image
            process_double_hands(img, hands, imgSize, offset)

    cv2.imshow("Image", img)
    key = cv2.waitKey(1)

    if key == ord("s"):
        if ((mode == 'single' and len(hands) > 0) or
            (mode == 'double' and len(hands) >= 2)) and imgWhite is not None:
            counter += 1
            # Save the appropriate image based on mode
            if mode == 'single':
                cv2.imwrite(f'{folder}/Single_{time.time()}.jpg', imgWhite)
            else:
                cv2.imwrite(f'{folder}/Double_{time.time()}.jpg', imgWhite)
            print(f"Saved image {counter}")

    # Switch between single and double hand modes
    if key == ord('m'):
        mode = 'double' if mode == 'single' else 'single'
        print(f"Switched to {mode} hand mode")

    # Exit on 'q'
    if key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()