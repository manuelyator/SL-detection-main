import cv2
import numpy as np
from cvzone.HandTrackingModule import HandDetector
import tensorflow as tf
import os
import base64
from io import BytesIO
from PIL import Image
import time
import threading
from concurrent.futures import ThreadPoolExecutor

class HandSignModel:
    def _init_(self):
        # Initialize with optimized parameters
        self.detector = HandDetector(
            maxHands=2,
            detectionCon=0.8,
            minTrackCon=0.5
        )
        self.imgSize = 224
        self.offset = 20
        self.min_confidence = 0.8  # Minimum confidence threshold
        
        # Load model with thread-safe initialization
        self.model_lock = threading.Lock()
        self._initialize_model()
        
        # Thread pool for parallel processing
        self.executor = ThreadPoolExecutor(max_workers=4)
        
    def _initialize_model(self):
        """Thread-safe model initialization"""
        with self.model_lock:
            if not hasattr(self, 'model'):
                # Load model with custom objects
                self.model = tf.keras.models.load_model(
                    "Model/keras_model.h5",
                    compile=False,
                    custom_objects={'DepthwiseConv2D': tf.keras.layers.DepthwiseConv2D}
                )
                
                # Warm up the model
                dummy_input = np.zeros((1, self.imgSize, self.imgSize, 3), dtype=np.float32)
                self.model.predict(dummy_input)
                
                # Load labels
                with open("Model/labels.txt", "r") as f:
                    self.labels = [line.strip() for line in f if line.strip()]
    
    def get_labels(self):
        """Get available labels"""
        return self.labels
    
    def process_image(self, image_data):
        """Process image data with error handling and performance optimizations"""
        try:
            start_time = time.time()
            
            # Decode image
            img = self._decode_image(image_data)
            if img is None:
                return {"error": "Invalid image data"}
            
            # Detect hands
            hands, _ = self.detector.findHands(img)
            if not hands:
                return {"error": "No hands detected"}
            
            # Process hands
            if len(hands) == 1:
                result = self._process_single_hand(img, hands[0])
            elif len(hands) == 2:
                result = self._process_two_hands(img, hands)
            else:
                return {"error": "Too many hands detected"}
            
            # Add processing time to result
            result['processing_time'] = time.time() - start_time
            return result
            
        except Exception as e:
            return {"error": f"Processing error: {str(e)}"}
    
    def _decode_image(self, image_data):
        """Decode base64 image data to numpy array"""
        try:
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes))
            return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        except Exception as e:
            print(f"Error decoding image: {e}")
            return None
    
    def _process_single_hand(self, img, hand):
        """Process single hand detection"""
        x, y, w, h = hand['bbox']
        
        # Create white background
        imgWhite = np.ones((self.imgSize, self.imgSize, 3), np.uint8) * 255
        
        # Crop with boundary checks
        y1, y2 = max(0, y - self.offset), min(img.shape[0], y + h + self.offset)
        x1, x2 = max(0, x - self.offset), min(img.shape[1], x + w + self.offset)
        imgCrop = img[y1:y2, x1:x2]
        
        if imgCrop.size == 0:
            return {"error": "Invalid hand crop"}
        
        # Resize maintaining aspect ratio
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
        
        # Preprocess and predict
        imgWhite = cv2.cvtColor(imgWhite, cv2.COLOR_BGR2RGB)
        imgWhite = imgWhite.astype('float32') / 255.0
        imgWhite = np.expand_dims(imgWhite, axis=0)
        
        with self.model_lock:
            prediction = self.model.predict(imgWhite)
        
        index = np.argmax(prediction)
        confidence = float(prediction[0][index])
        
        if confidence < self.min_confidence:
            return {"error": f"Low confidence prediction ({confidence:.2f})"}
        
        # Only return the label for stream
        return {
            "label": self.labels[index]
        }
    
    def _process_two_hands(self, img, hands):
        """Process two hands detection (basic implementation)"""
        # Process each hand separately and combine results
        results = []
        for hand in hands:
            result = self._process_single_hand(img, hand)
            if 'error' in result:
                continue
            results.append(result)
        
        if len(results) == 0:
            return {"error": "Could not process either hand"}
        
        # Return the label from the most confident hand
        best_result = max(results, key=lambda x: self.labels.index(x['label'])) 

        return {"label": results[0]['label']} 
    
    def save_training_data(self, image_data, label):
        """Save training data with improved error handling"""
        try:
            os.makedirs(f"Data/{label}", exist_ok=True)
            
            img = self._decode_image(image_data)
            if img is None:
                return {"error": "Invalid image data"}
            
            filename = f"Data/{label}/{int(time.time())}.jpg"
            cv2.imwrite(filename, img)
            
            return {"message": f"Data saved to {filename}"}
        except Exception as e:
            return {"error": str(e)}
    
    def process_image_async(self, image_data, callback):
        """Process image asynchronously with callback"""
        future = self.executor.submit(self.process_image, image_data)
        future.add_done_callback(lambda f: callback(f.result()))