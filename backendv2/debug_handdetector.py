import cv2
from cvzone.HandTrackingModule import HandDetector
import traceback

def main():
    try:
        print("Starting webcam...")
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("Error: Webcam could not be opened.")
            return
        print("Webcam initialized.")
    except Exception as e:
        print("Error initializing webcam:")
        traceback.print_exc()
        return

    try:
        # Wrap HandDetector initialization in try/except to capture any errors
        detector = HandDetector(staticMode=False, maxHands=2, modelComplexity=1, detectionCon=0.5, minTrackCon=0.5)
        print("HandDetector initialized.")
    except Exception as e:
        print("Error initializing HandDetector:")
        traceback.print_exc()
        return

    while True:
        try:
            success, img = cap.read()
            if not success:
                print("Failed to capture frame from webcam.")
                break

            hands, img = detector.findHands(img, draw=True, flipType=True)
            print(f"Hands detected: {len(hands)}")

            cv2.imshow("Image", img)
            # Exit on 'q' key press
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        except Exception as e:
            print("Error during frame processing:")
            traceback.print_exc()
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
