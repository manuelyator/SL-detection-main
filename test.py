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
        imgOutput (numpy.ndarray): Output image (unused directly here, but passed for consistency)

    Returns:
        tuple: (processed white background image, predicted label)
    """
    x, y, w, h = hand['bbox']

    # Create a white background image
    imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

    # Crop the hand region with padding
    imgCrop = img[max(0, y - offset):min(img.shape[0], y + h + offset),
              max(0, x - offset):min(img.shape[1], x + w + offset)]

    if imgCrop.size == 0:
        return None, ""

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

    predicted_label = ""

    try:
        # Get prediction
        prediction, index = classifier.getPrediction(imgWhite)

        # Ensure index is within labels range
        if 0 <= index < len(labels):
            predicted_label = labels[index]
    except Exception as e:
        print(f"Prediction error: {e}")

    # Optional: Show intermediate images for debugging - COMMENTED OUT
    # cv2.imshow("ImageCrop", imgCrop)
    # cv2.imshow("ImageWhite", imgWhite)

    return imgWhite, predicted_label


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
        imgOutput (numpy.ndarray): Output image (unused directly here, but passed for consistency)

    Returns:
        tuple: (processed white background image, predicted label)
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
        return None, ""

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

    predicted_label = ""

    try:
        # Get prediction
        prediction, index = classifier.getPrediction(imgWhite)

        # Ensure index is within labels range
        if 0 <= index < len(labels):
            predicted_label = labels[index]
    except Exception as e:
        print(f"Prediction error: {e}")

    # Optional: Show intermediate images for debugging - COMMENTED OUT
    # cv2.imshow("ImageCrop", imgCrop)
    # cv2.imshow("ImageWhite", imgWhite)

    return imgWhite, predicted_label


# --- NEW TEXT DISPLAY FUNCTION ---
def display_text_bottom(img, text):
    """
    Display text near the bottom-center of the image with background

    Args:
        img (numpy.ndarray): Image to display text on
        text (str): Text to display
    """
    h, w, _ = img.shape

    # Set font properties
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_scale = 1.2 # Slightly smaller scale might fit more text
    thickness = 2
    color = (255, 255, 255)  # White text
    bg_color = (0, 0, 0)     # Black background
    padding = 10             # Padding around text
    margin = 30              # Margin from bottom edge

    # Get text size
    (text_width, text_height), baseline = cv2.getTextSize(text, font, font_scale, thickness)

    # Calculate position near bottom-center
    # X centered horizontally
    x = (w - text_width) // 2
    # Y position based on bottom edge, margin, and text height (using baseline)
    y = h - margin # Baseline of the text

    # Ensure x is not negative (if text wider than screen)
    x = max(x, padding)

    # Calculate background rectangle coordinates
    bg_x1 = max(0, x - padding)
    bg_y1 = max(0, y - text_height - padding) # Top of background rect
    bg_x2 = min(w, x + text_width + padding)
    bg_y2 = min(h, y + baseline + padding) # Bottom of background rect (uses baseline)

    # Create semi-transparent overlay for better visibility
    overlay = img.copy()
    cv2.rectangle(overlay, (bg_x1, bg_y1), (bg_x2, bg_y2), bg_color, -1)

    # Apply transparency
    alpha = 0.6 # Transparency factor
    cv2.addWeighted(overlay, alpha, img, 1 - alpha, 0, img)

    # Draw text
    cv2.putText(img, text, (x, y), font, font_scale, color, thickness)


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
    # IMPORTANT: Make sure the paths to your model and labels are correct!
    script_dir = os.path.dirname(__file__) if "__file__" in locals() else "." # Get directory of script
    model_dir = os.path.join(script_dir, "Model")
    labels_path = os.path.join(model_dir, "labels.txt")
    model_path = os.path.join(model_dir, "keras_model.h5")

    print(f"Looking for labels at: {labels_path}")
    print(f"Looking for model at: {model_path}")

    labels = load_labels(labels_path)

    if not labels:
        print("No labels found. Exiting.")
        return

    if not os.path.exists(model_path):
        print(f"Model file not found at {model_path}. Exiting.")
        return

    classifier = Classifier(model_path, labels_path)

    offset = 20
    imgSize = 300

    # Current mode: 'single' or 'double'
    mode = 'single'

    # Variables to store the current prediction
    current_prediction = ""

    # For prediction stability - counter to avoid rapid flicker
    prediction_counter = 0
    prediction_stability_threshold = 5  # How many consecutive frames to keep prediction

    # Variable to collect a sentence of predictions
    sentence = []
    max_sentence_length = 5  # Maximum number of words to display in sentence
    last_prediction_time = cv2.getTickCount()
    prediction_timeout = 2.0  # Time in seconds before adding new prediction to sentence

    while True:
        # Read frame from camera
        success, img = cap.read()

        if not success:
            print("Failed to grab frame")
            break

        # Create a copy for output display
        imgOutput = img.copy()

        # Detect hands (use original img for detection)
        hands, img_with_hands_drawn = detector.findHands(img) # detector.findHands can draw on the image

        # Display current mode and instructions in small text at top corner on the output image
        cv2.putText(imgOutput, f"Mode: {mode}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(imgOutput, "m: switch mode", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(imgOutput, "c: clear", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(imgOutput, "s: save word", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(imgOutput, "ESC: quit", (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)


        # Process hands and get predictions using the original image (img) before hands were drawn on it
        new_prediction = ""

        if hands:
            if mode == 'single' and len(hands) > 0:
                # Process only the first detected hand (using the original 'img')
                _, pred = process_hand(img, hands[0], imgSize, offset, classifier, labels, imgOutput)
                if pred:
                    new_prediction = pred

            elif mode == 'double' and len(hands) >= 2:
                # Process both hands together (using the original 'img')
                _, pred = process_double_hands(img, hands, imgSize, offset, classifier, labels, imgOutput)
                if pred:
                    new_prediction = pred

            # Draw bounding boxes and landmarks onto the output image AFTER processing
            # Pass draw=False to findHands initially if you want finer control
            imgOutput_with_hands = detector.findHands(imgOutput, draw=True) # Draw on the output copy


        # Stability logic - only update prediction if same for multiple frames
        if new_prediction and new_prediction == current_prediction:
            prediction_counter += 1
        elif new_prediction:
            # If prediction changes, reset counter and update current prediction immediately for responsiveness
            prediction_counter = 0
            current_prediction = new_prediction
            # Reset timer only when prediction changes
            last_prediction_time = cv2.getTickCount()
        else: # No hand detected or no prediction
             prediction_counter = 0
             current_prediction = ""


        # Add to sentence based on stability and timeout
        if prediction_counter >= prediction_stability_threshold:
            current_time = cv2.getTickCount()
            time_elapsed = (current_time - last_prediction_time) / cv2.getTickFrequency()

            # Check if it's a stable prediction different from the last added word in the sentence
            # Or if the sentence is empty and we have a stable prediction
            should_add = (len(sentence) == 0 or current_prediction != sentence[-1])

            if should_add:
                 if len(sentence) >= max_sentence_length:
                     sentence.pop(0)  # Remove oldest word if we exceed max length
                 sentence.append(current_prediction)
                 # Reset timer after adding a word
                 last_prediction_time = cv2.getTickCount()
                 prediction_counter = 0 # Reset counter after adding to sentence to avoid immediate re-add


        # --- USE THE NEW FUNCTION TO DISPLAY TEXT ---
        # Display the current sentence at the bottom
        if sentence:
            display_text = " ".join(sentence)
            display_text_bottom(imgOutput, display_text) # Use the new bottom display function
        elif current_prediction: # Display current unstable prediction if sentence is empty
             display_text_bottom(imgOutput, f"({current_prediction})") # Indicate it's tentative


        # Display the final image (with hands drawn and text)
        cv2.imshow("Sign Language Detection", imgOutput)

        # Handle key events
        key = cv2.waitKey(1) & 0xFF
        if key == ord('m'):
            # Toggle mode between single and double
            mode = 'double' if mode == 'single' else 'single'
            print(f"Mode switched to: {mode}")
        elif key == ord('c'):
            # Clear current sentence
            sentence = []
            current_prediction = ""
            prediction_counter = 0
            print("Sentence cleared.")
        elif key == ord('s'):
             # Force add current stable prediction to sentence
             if current_prediction and prediction_counter >= prediction_stability_threshold:
                 if len(sentence) == 0 or current_prediction != sentence[-1]: # Avoid duplicates
                     if len(sentence) >= max_sentence_length:
                         sentence.pop(0)
                     sentence.append(current_prediction)
                     last_prediction_time = cv2.getTickCount()
                     prediction_counter = 0 # Reset counter after saving
                     print(f"Word '{current_prediction}' saved.")
             else:
                 print("No stable prediction to save.")

        elif key == 27:  # ESC key
            print("Exiting...")
            break

    # Cleanup
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()