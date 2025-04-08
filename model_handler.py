import cv2
import numpy as np
from cvzone.HandTrackingModule import HandDetector
import tensorflow as tf
import os
import base64
from io import BytesIO
from PIL import Image

class HandSignModel:
    def __init__(self):
        self.detector = HandDetector(maxHands=2)
        self.imgSize = 300
        self.offset = 20
        
        # Load model with custom objects
        self.model = tf.keras.models.load_model(
            "Model/keras_model.h5",
            compile=False,
            custom_objects={'DepthwiseConv2D': tf.keras.layers.DepthwiseConv2D}
        )
        
        # Load labels
        with open("Model/labels.txt", "r") as f:
            self.labels = [line.strip() for line in f if line.strip()]
        
    def process_image(self, image_data):
        # Convert base64 image data to numpy array
        try:
            # Remove the data URL prefix if present
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            # Decode base64
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes))
            img = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Process the image
            hands, img = self.detector.findHands(img)
            
            if not hands:
                return {"error": "No hands detected"}
            
            # Process single hand
            if len(hands) == 1:
                hand = hands[0]
                x, y, w, h = hand['bbox']
                
                # Create white background
                imgWhite = np.ones((self.imgSize, self.imgSize, 3), np.uint8) * 255
                
                # Crop and resize
                imgCrop = img[max(0, y - self.offset):min(img.shape[0], y + h + self.offset),
                            max(0, x - self.offset):min(img.shape[1], x + w + self.offset)]
                
                if imgCrop.size == 0:
                    return {"error": "Invalid hand crop"}
                
                aspectRatio = h / w
                
                if aspectRatio > 1:
                    k = self.imgSize / h
                    wCal = int(k * w)
                    imgResize = cv2.resize(imgCrop, (wCal, self.imgSize))
                    wGap = int((self.imgSize - wCal) / 2)
                    imgWhite[:, wGap:wCal + wGap] = imgResize
                else:
                    k = self.imgSize / w
                    hCal = int(k * h)
                    imgResize = cv2.resize(imgCrop, (self.imgSize, hCal))
                    hGap = int((self.imgSize - hCal) / 2)
                    imgWhite[hGap:hCal + hGap, :] = imgResize
                
                # Preprocess image for model
                imgWhite = cv2.cvtColor(imgWhite, cv2.COLOR_BGR2RGB)
                imgWhite = imgWhite.astype('float32') / 255.0
                imgWhite = np.expand_dims(imgWhite, axis=0)
                
                # Get prediction
                prediction = self.model.predict(imgWhite)
                index = np.argmax(prediction)
                confidence = float(prediction[0][index])
                
                return {
                    "prediction": confidence,
                    "index": int(index),
                    "label": self.labels[index]
                }
            
            # Process two hands
            elif len(hands) == 2:
                # TODO: Implement two-hand processing
                return {"error": "Two-hand processing not implemented yet"}
            
        except Exception as e:
            return {"error": str(e)}
    
    def save_training_data(self, image_data, label):
        try:
            # Create directory if it doesn't exist
            os.makedirs(f"Data/{label}", exist_ok=True)
            
            # Convert and save image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes))
            img = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Save the image
            filename = f"Data/{label}/{len(os.listdir(f'Data/{label}'))}.jpg"
            cv2.imwrite(filename, img)
            
            return {"message": "Data saved successfully"}
            
        except Exception as e:
            return {"error": str(e)} 