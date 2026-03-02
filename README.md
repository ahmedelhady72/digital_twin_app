# 🚀 Digital Twin App

A Digital Twin prototype that streams aircraft engine sensor data using MQTT, buffers data in a Flutter dashboard, and performs AI-based predictions using a trained Keras model.

---

## 📌 Project Description

`digital_twin_app` simulates real-time engine telemetry and builds a predictive maintenance pipeline using:

- MQTT for data streaming  
- Flutter for real-time visualization  
- Python backend for AI inference  
- TensorFlow / Keras for prediction  

This project demonstrates a simplified Digital Twin architecture for predictive maintenance systems.

---

## 🏗️ System Architecture

The system consists of three main components:

### 1️⃣ Engine Data Publisher

- Reads engine sensor data from:

- Publishes data via MQTT protocol
- Simulates real-time engine behavior

---

### 2️⃣ Flutter Application

- Subscribes to MQTT topic
- Buffers **30 sensor records**
- Sends buffered data to backend for prediction
- Displays AI prediction results on dashboard

---

### 3️⃣ AI Backend

- Located in:

- Loads trained model:

- Runs inference on incoming buffered data
- Returns prediction results to Flutter app

---

## 🔄 Data Flow

Engine Data (test_fd004.txt)  
↓  
MQTT Publisher  
↓  
Flutter App (buffer 30 records)  
↓  
Backend (main.py)  
↓  
Keras Model (calibrated_model.keras)  
↓  
Prediction → Flutter Dashboard  

---

## 🛠️ Technologies Used

- MQTT Protocol  
- Flutter  
- Python  
- TensorFlow / Keras  
- Real-Time Data Streaming  
- AI Predictive Modeling  

---

## ▶️ How to Run the Project

### 1️⃣ Start MQTT Broker

You can use a public broker such as:


Or run a local MQTT broker.

---

### 2️⃣ Run the Publisher


---

### 3️⃣ Run the Backend

---

### 4️⃣ Run the Flutter App

---

## 📊 Project Purpose

This project showcases:

- Real-time data streaming architecture  
- MQTT integration with Flutter  
- AI model deployment for inference  
- End-to-end Digital Twin pipeline  

---

