# 🚗 FPGA Based Parking Sensor System

![Platform](https://img.shields.io/badge/Platform-Basys3%20FPGA-orange)
![Language](https://img.shields.io/badge/Language-VHDL-blue)
![Sensor](https://img.shields.io/badge/Sensor-HC--SR04-green)
![Status](https://img.shields.io/badge/Status-Completed-success)

## 📖 Project Overview
This project is a high-precision digital parking sensor system implemented on the **Digilent Basys 3 FPGA** using **VHDL**. It utilizes an **HC-SR04 ultrasonic sensor** to measure distance and provides real-time feedback through visual indicators (LCD & 7-Segment Display) and auditory warnings (Buzzer).

The system is designed to assist drivers in tight spaces by calculating distance with **0.01 cm precision** and switching between safety modes automatically.

## 🎥 Project Demo
Check out the system in action:

[![Watch the video](https://img.youtube.com/vi/HMlnp5bxW-0/0.jpg)](https://www.youtube.com/watch?v=HMlnp5bxW-0)

## ⚙️ Technical Architecture

### 1. Distance Calculation Logic
The system measures the time of flight for the ultrasonic pulse.
* **Physics:** Sound travels 1 cm in approx. **58 µs**.
* **Logic:** The VHDL counter increments every 58 clock cycles (at 100 MHz).
* **Result:** This allows for a precise measurement resolution of **0.1 mm** without complex floating-point arithmetic.

### 2. Finite State Machine (FSM) - Alert Zones
The system uses a Moore FSM to control warnings based on distance:

| Zone State | Distance Range | LED Output | Buzzer Output |
| :--- | :--- | :--- | :--- |
| **SAFE** | > 10 cm | 🟢 Green (Solid) | 🔇 Silent |
| **WARNING** | 5 cm - 10 cm | 🟡 Yellow (1Hz Blink) | 🔉 Low Beep |
| **DANGER** | 0 cm - 5 cm | 🔴 Red (4Hz Blink) | 🔊 High Alarm |

### 3. Power Control Modes
A single push-button cycles through 4 operational modes to manage power:
* **Mode 1 (Full Active):** All displays and sensors ON.
* **Mode 2 (LCD Only):** 7-Segment OFF (Power Save).
* **Mode 3 (7-Seg Only):** LCD Screen OFF.
* **Mode 4 (Standby):** System completely OFF.

## 🔌 Hardware & Pin Mapping (Basys 3)

| Component | Port | Description |
| :--- | :--- | :--- |
| **Ultrasonic Trig** | JA[0] | Output pulse to sensor |
| **Ultrasonic Echo** | JA[1] | Input pulse from sensor |
| **Buzzer** | JA[2] | PWM Audio Output |
| **LCD Screen** | JB[0-7] | 4-bit Parallel Interface |
| **Status LEDs** | LED[13-15] | RGB Warning Indicators |

*(See `constraints/Basys3_Master.xdc` for full pinout)*

## 👥 Project Team (Group 4)
This project was developed for the **EE2003 Digital Design** course at **Marmara University**.
* **Canberk Suner** (Architecture & VHDL)
* **Ömer Faruk Kocaoğlu** (Simulation)
* **Resul Argın** (Hardware Integration)
* **Yusuf Polat** (Documentation & Presentation)

## 📄 Documentation & Report
For detailed circuit diagrams, simulation waveforms, and the full project report, please view the PDF below:
[📥 **Download Project Report (PDF)**](docs/Group4ProjectReport.pdf)

---
*License: MIT | Created by Ömer Faruk Kocaoğlu & Team*
