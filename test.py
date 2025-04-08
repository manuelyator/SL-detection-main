import cv2
from cvzone.HandTrackingModule import HandDetector
from cvzone.ClassificationModule import Classifier
import numpy as np
import math
import os


def load_labels(labels_path):
    """
    Load labels from the labels.txt file

    Args:
        labels_path (str): Path to the labels.txt file

    Returns:
        list: List of labels
    """
    try:
        with open(labels_path, 'r') as file:
            # Strip whitespace and remove empty lines
            labels = [line.strip() for line in file if line.strip()]
        return labels
    except FileNotFoundError:
        print(f"Labels file not found at {labels_path}")
        return []
    except Exception as e:
        print(f"Error reading labels file: {e}")
        return []


def process_hand(img, hand, imgSize, offset, classifier, labels, imgOutput):
    """
    Process a single hand for classification

    Args:
        img (numpy.ndarray): Input image
        hand (dict): Hand detection dictionary
        imgSize (int): Size of the white background image
        offset (int): Padding around the hand
        classifier (Classifier): Hand gesture classifier
        labels (list): List of hand gesture labels
        imgOutput (numpy.ndarray): Output image for drawing predictions

    Returns:
        numpy.ndarray or None: Processed white background image
    """
    x, y, w, h = hand['bbox']

    # Create a white background image
    imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

    # Crop the hand region with padding
    imgCrop = img[max(0, y - offset):min(img.shape[0], y + h + offset),
              max(0, x - offset):min(img.shape[1], x + w + offset)]

    if imgCrop.size == 0:
        return None

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

    try:
        # Get prediction
        prediction, index = classifier.getPrediction(imgWhite)

        # Ensure index is within labels range
        if 0 <= index < len(labels):
            # Draw prediction text
            cv2.putText(imgOutput,
                        f"{labels[index]} ({prediction:.2f})",
                        (x, y - 20),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (255, 0, 255),
                        2)
    except Exception as e:
        print(f"Prediction error: {e}")

    # Optional: Show intermediate images for debugging
    cv2.imshow("ImageCrop", imgCrop)
    cv2.imshow("ImageWhite", imgWhite)

    return imgWhite


def process_double_hands(img, hands, imgSize, offset, classifier, labels, imgOutput):
    """
    Process two hands together for classification

    Args:
        img (numpy.ndarray): Input image
        hands (list): List of hand detection dictionaries
        imgSize (int): Size of the white background image
        offset (int): Padding around the hands
        classifier (Classifier): Hand gesture classifier
        labels (list): List of hand gesture labels
        imgOutput (numpy.ndarray): Output image for drawing predictions

    Returns:
        numpy.ndarray or None: Processed white background image
    """
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
        return None

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

    # Optional: Show intermediate images for debugging
    cv2.imshow("ImageCrop", imgCrop)
    cv2.imshow("ImageWhite", imgWhite)

    return imgWhite


def main():
    # Initialize video capture
    cap = cv2.VideoCapture(0)

    # Check if camera opened successfully
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return

    # Initialize hand detector and classifier
    detector = HandDetector(maxHands=2)

    # Dynamically load labels
    labels_path = "Model/labels.txt"
    labels = load_labels(labels_path)

    if not labels:
        print("No labels found. Exiting.")
        return

    classifier = Classifier("Model/keras_model.h5", labels_path)

    offset = 20
    imgSize = 300

    # Current mode: 'single' or 'double'
    mode = 'single'

    while True:
        # Read frame from camera
        success, img = cap.read()

        if not success:
            print("Failed to grab frame")
            break

        # Create a copy for output
        imgOutput = img.copy()

        # Detect hands
        hands, img = detector.findHands(img)

        # Display current mode and instructions
        cv2.putText(img, f"Mode: {mode}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(img, "Press 'm' to switch mode", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        if hands:
            if mode == 'single' and len(hands) > 0:
                # Process only the first detected hand
                process_hand(img, hands[0], imgSize, offset, classifier, labels, imgOutput)

            elif mode == 'double' and len(hands) >= 2:
                # Process both hands together
                process_double_hands(img, hands, imgSize, offset, classifier, labels, imgOutput)

        # Display the image
        cv2.imshow("Hand Detection", imgOutput)

        # Handle key events
        key = cv2.waitKey(1) & 0xFF
        if key == ord('m'):
            # Toggle mode between single and double
            mode = 'double' if mode == 'single' else 'single'
        elif key == 27:  # ESC key
            break

    # Cleanup
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()