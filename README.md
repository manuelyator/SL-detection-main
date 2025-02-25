

# AI-Powered Real-Time Sign Language Interpreter

### Overview

This project aims to develop an AI-powered real-time sign language interpreter that translates sign language into text. The system leverages computer vision and deep learning techniques to enhance communication for the deaf and hard-of-hearing community.

### Approach

We follow a structured approach for building the interpreter:

**1. Data Collection**

Gathering diverse sign language datasets from various sources.

Capturing video sequences of sign gestures.

**2. Data Annotation**

Labeling collected data for supervised learning.

Utilizing annotation tools to mark keypoints and gestures.

**3. Feature Extraction**

Applying Principal Component Analysis (PCA) to reduce dimensionality.

Using Independent Component Analysis (ICA) for feature selection.

**4. Model Development and Evaluation**

Training deep learning models (CNNs, RNNs, Transformers) for gesture recognition.

Evaluating model performance using accuracy, precision, recall, and F1-score.

**4. Integration and Deployment**

Implementing real-time inference using Python.

Deploying the model on cloud or edge devices for live sign language interpretation.

### Installation
>
1. Clone the github repo
2. Cd into the project folder
3. Create virtual environment ```python -m venv venv```
4. Activate the virtual environment  windows: ```venv/Scripts/activate```

5. Install requirements for the project ``` pip install -r requiremnts.txt```

6. Ready to run
