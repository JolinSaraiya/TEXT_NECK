"""
============================================================================
Text Neck AI Server — FastAPI + MediaPipe Pose Estimation
============================================================================

This is the core AI backend for the Text Neck posture detection system.
It receives webcam frames via WebSocket, processes them through Google's
MediaPipe PoseLandmarker (v1.0+ Tasks API), calculates the neck
inclination angle, and returns annotated frames with risk assessment.

Architecture:
    Browser (webcam) -> WebSocket -> FastAPI -> MediaPipe -> Annotated Frame
                                                           -> Risk Assessment JSON

NOTE: This uses the MediaPipe Tasks API (v1.0+), NOT the legacy
      mp.solutions.pose API which was removed in MediaPipe 1.0.

Author: Text Neck Internship Project
============================================================================
"""

# ============================================================================
# IMPORTS
# ============================================================================
import base64                     # Encoding/decoding frames as base64 strings
import math                       # For arctan angle calculation
import json                       # JSON serialization for WebSocket messages
import os                         # File path operations
from datetime import datetime     # Timestamping each frame analysis
from pathlib import Path          # Cross-platform path handling

import cv2                        # OpenCV: image decoding, drawing, encoding
import numpy as np                # Numerical arrays for image manipulation

# MediaPipe Tasks API (v1.0+)
# The new API uses a task-based architecture with model files (.task)
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware


# ============================================================================
# FASTAPI APP INITIALIZATION
# ============================================================================
app = FastAPI(
    title="Text Neck AI Server",
    description="Real-time posture detection using MediaPipe Pose estimation",
    version="1.0.0"
)

# Allow CORS from the Vite dev server (localhost:5173)
# This is needed for the initial HTTP handshake before WebSocket upgrade
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],           # In production, restrict to your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# MEDIAPIPE MODEL PATH
# ============================================================================
# The PoseLandmarker requires a .task model file to be downloaded.
# Download it from:
#   https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task
#
# Place it in the same directory as this file, named "pose_landmarker.task"

MODEL_PATH = str(Path(__file__).parent / "pose_landmarker.task")

# Landmark indices from PoseLandmark enum:
#   LEFT_EAR = 7,  LEFT_SHOULDER = 11
#   RIGHT_EAR = 8, RIGHT_SHOULDER = 12
LEFT_EAR = vision.PoseLandmark.LEFT_EAR         # Index 7
LEFT_SHOULDER = vision.PoseLandmark.LEFT_SHOULDER # Index 11
RIGHT_EAR = vision.PoseLandmark.RIGHT_EAR        # Index 8
RIGHT_SHOULDER = vision.PoseLandmark.RIGHT_SHOULDER # Index 12


# ============================================================================
# RISK LEVEL CLASSIFICATION
# ============================================================================
def calculate_risk_percentage(angle: float) -> float:
    """
    Linearly interpolates the CVA angle to a smooth 0% - 100% risk dial percentage.
    - Angle >= 48°: 0% risk
    - Angle <= 43°: 100% risk
    - Angle 45.5°: exactly 50% risk
    """
    if angle >= 48.0:
        return 0.0
    elif angle <= 43.0:
        return 100.0
    else:
        # Linear interpolation between 43° and 48°
        risk = ((48.0 - angle) / 5.0) * 100.0
        return round(risk, 1)

def classify_risk(angle: float) -> dict:
    """
    Classify the posture risk based on clinical CVA thresholds.
    """
    risk_pct = calculate_risk_percentage(angle)
    
    if angle > 48.0:
        return {
            "level": "Normal",               # Maintains frontend compatibility
            "label": "Good Posture",
            "risk_percentage": risk_pct,
            "color_bgr": (0, 255, 100),      # OpenCV Green
            "color_hex": "#22c55e"           # Tailwind Green
        }
    elif 43.0 <= angle <= 48.0:
        return {
            "level": "Mild",                 # Maintains frontend compatibility
            "label": "Fair Posture",
            "risk_percentage": risk_pct,
            "color_bgr": (0, 220, 255),      # OpenCV Yellow
            "color_hex": "#eab308"           # Tailwind Yellow
        }
    else:
        return {
            "level": "Severe",               # Maintains frontend compatibility
            "label": "Bad Posture",
            "risk_percentage": risk_pct,
            "color_bgr": (0, 70, 255),       # OpenCV Red
            "color_hex": "#ef4444"           # Tailwind Red
        }


# ============================================================================
# NECK ANGLE CALCULATION
# ============================================================================

def calculate_neck_angle(ear_x: float, ear_y: float,
                          shoulder_x: float, shoulder_y: float) -> float:
    """
    Calculate the Craniovertebral Angle (CVA) using ear and shoulder coordinates.
    CVA is measured from the horizontal plane passing through the shoulder 
    to the line connecting the shoulder and the ear. 
    Higher angles indicate better posture.
    """
    delta_x = abs(ear_x - shoulder_x)
    delta_y = abs(ear_y - shoulder_y)
    
    # Prevent division by zero if ear is perfectly aligned vertically
    if delta_x == 0:
        return 90.0  # Perfectly upright (90 degrees from horizontal)
        
    # Arctangent of (vertical displacement / horizontal displacement)
    angle_rad = math.atan(delta_y / delta_x)
    angle_deg = math.degrees(angle_rad)
    
    return round(angle_deg, 1)


# ============================================================================
# FRAME PROCESSING PIPELINE
# ============================================================================

def process_frame(frame: np.ndarray, landmarker: vision.PoseLandmarker) -> dict:
    """
    Process a single video frame through the MediaPipe PoseLandmarker pipeline.

    Pipeline steps:
        1. Convert BGR OpenCV frame -> MediaPipe Image
        2. Run pose detection to get 33 body landmarks
        3. Extract ear and shoulder coordinates (auto-detect best side)
        4. Calculate neck inclination angle
        5. Annotate the frame with skeleton lines and risk indicators
        6. Encode annotated frame back to base64

    Args:
        frame: OpenCV image (BGR numpy array) from the webcam.
        landmarker: Initialized MediaPipe PoseLandmarker instance.

    Returns:
        dict with keys: angle, risk_level, risk_color, annotated_frame,
        landmarks, timestamp. Returns error dict if no pose detected.
    """
    # Get frame dimensions for converting normalized coords to pixel coords
    h, w, _ = frame.shape

    # ---- Step 1: Convert BGR to RGB for MediaPipe ----
    # OpenCV captures frames in BGR format, but MediaPipe expects RGB
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # Create a MediaPipe Image object from the numpy array
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)

    # ---- Step 2: Run MediaPipe PoseLandmarker detection ----
    # The detect() method returns a PoseLandmarkerResult containing
    # pose_landmarks (list of NormalizedLandmark lists, one per detected person)
    results = landmarker.detect(mp_image)

    # Create a copy of the original frame for annotation
    annotated_frame = frame.copy()

    # ---- Check if any pose was detected ----
    if not results.pose_landmarks or len(results.pose_landmarks) == 0:
        # No human pose detected in this frame
        cv2.putText(
            annotated_frame, "No Pose Detected",
            (int(w * 0.25), int(h * 0.5)),
            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (100, 100, 255), 2
        )
        _, buffer = cv2.imencode('.jpg', annotated_frame,
                                  [cv2.IMWRITE_JPEG_QUALITY, 80])
        encoded_frame = base64.b64encode(buffer).decode('utf-8')

        return {
            "angle": None,
            "risk_level": "No Pose",
            "risk_color": "#6b7280",
            "annotated_frame": encoded_frame,
            "landmarks": None,
            "timestamp": datetime.now().isoformat()
        }

    # ---- Step 3: Extract ear and shoulder landmarks ----
    # In MediaPipe Tasks API, pose_landmarks is a list of lists.
    # Each inner list contains NormalizedLandmark objects for one person.
    # We use the first detected person.
    landmarks = results.pose_landmarks[0]

    # Get visibility scores to auto-detect the more visible side
    # In the Tasks API, each landmark has x, y, z, visibility, presence
    left_ear_vis = landmarks[LEFT_EAR].visibility
    right_ear_vis = landmarks[RIGHT_EAR].visibility

    # Choose the side with higher visibility for more accurate detection
    if left_ear_vis >= right_ear_vis:
        ear = landmarks[LEFT_EAR]
        shoulder = landmarks[LEFT_SHOULDER]
        side = "Left"
    else:
        ear = landmarks[RIGHT_EAR]
        shoulder = landmarks[RIGHT_SHOULDER]
        side = "Right"

    # Extract normalized coordinates (0.0 to 1.0 range)
    ear_x, ear_y = ear.x, ear.y
    shoulder_x, shoulder_y = shoulder.x, shoulder.y

    # Convert to pixel coordinates for drawing on the frame
    ear_px = (int(ear_x * w), int(ear_y * h))
    shoulder_px = (int(shoulder_x * w), int(shoulder_y * h))

    # ---- Step 4: Calculate neck inclination angle ----
    angle = calculate_neck_angle(ear_x, ear_y, shoulder_x, shoulder_y)
    risk = classify_risk(angle)

    # ---- Step 5: Annotate the frame ----
    color = risk["color_bgr"]

    # Draw a line connecting ear to shoulder (the "neck line")
    cv2.line(annotated_frame, ear_px, shoulder_px, color, 3)

    # Draw a vertical reference line from the shoulder (ideal posture line)
    # This shows where the ear SHOULD be for perfect posture
    vertical_ref = (shoulder_px[0], shoulder_px[1] - 150)
    cv2.line(annotated_frame, shoulder_px, vertical_ref, (150, 150, 150), 2,
             cv2.LINE_AA)

    # Draw circles on ear and shoulder landmarks
    cv2.circle(annotated_frame, ear_px, 8, color, -1)       # Filled circle on ear
    cv2.circle(annotated_frame, shoulder_px, 8, color, -1)   # Filled circle on shoulder
    cv2.circle(annotated_frame, ear_px, 12, color, 2)        # Ring around ear
    cv2.circle(annotated_frame, shoulder_px, 12, color, 2)   # Ring around shoulder

    # Draw the angle value near the ear landmark
    angle_text = f"{angle:.1f} deg"
    cv2.putText(
        annotated_frame, angle_text,
        (ear_px[0] + 15, ear_px[1] - 15),
        cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2
    )

    # Draw the risk level badge at the top-left corner
    badge_text = f"{risk['level']} Risk"
    cv2.putText(
        annotated_frame, badge_text,
        (20, 40),
        cv2.FONT_HERSHEY_SIMPLEX, 1.0, color, 2
    )

    # Draw the detected side info
    cv2.putText(
        annotated_frame, f"Side: {side}",
        (20, 70),
        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 180, 180), 1
    )

    # Draw all 33 pose landmarks as small dots for the full skeleton view
    for lm in landmarks:
        px = int(lm.x * w)
        py = int(lm.y * h)
        cv2.circle(annotated_frame, (px, py), 3, (80, 80, 80), -1)

    # Draw skeleton connections (simplified — key body connections)
    # Define pairs of landmark indices for drawing lines
    skeleton_connections = [
        (11, 12),  # Left shoulder - Right shoulder
        (11, 13), (13, 15),  # Left arm
        (12, 14), (14, 16),  # Right arm
        (11, 23), (12, 24),  # Torso
        (23, 24),  # Hips
        (23, 25), (25, 27),  # Left leg
        (24, 26), (26, 28),  # Right leg
    ]
    for (i, j) in skeleton_connections:
        pt1 = (int(landmarks[i].x * w), int(landmarks[i].y * h))
        pt2 = (int(landmarks[j].x * w), int(landmarks[j].y * h))
        cv2.line(annotated_frame, pt1, pt2, (60, 60, 60), 1)

    # ---- Step 6: Encode annotated frame to base64 JPEG ----
    _, buffer = cv2.imencode('.jpg', annotated_frame,
                              [cv2.IMWRITE_JPEG_QUALITY, 80])
    encoded_frame = base64.b64encode(buffer).decode('utf-8')

    # ---- Return the complete analysis result ----
    return {
        "angle": angle,
        "risk_level": risk["level"],
        "risk_color": risk["color_hex"],
        "risk_percentage": risk.get("risk_percentage", 0.0),
        "risk_label": risk.get("label", risk["level"]),
        "annotated_frame": encoded_frame,
        "landmarks": {
            "side": side,
            "ear": {"x": round(ear_x, 4), "y": round(ear_y, 4)},
            "shoulder": {"x": round(shoulder_x, 4), "y": round(shoulder_y, 4)}
        },
        "timestamp": datetime.now().isoformat()
    }


# ============================================================================
# HEALTH CHECK ENDPOINT
# ============================================================================

@app.get("/health")
async def health_check():
    """
    Simple health check endpoint to verify the server is running.
    Useful for monitoring and debugging during development.

    Usage: curl http://localhost:8000/health
    """
    model_exists = os.path.exists(MODEL_PATH)
    return {
        "status": "healthy",
        "service": "Text Neck AI Server",
        "version": "1.0.0",
        "model_loaded": model_exists,
        "model_path": MODEL_PATH,
        "timestamp": datetime.now().isoformat()
    }


# ============================================================================
# WEBSOCKET ENDPOINT — REAL-TIME VIDEO PROCESSING
# ============================================================================

@app.websocket("/ws/video")
async def video_websocket(websocket: WebSocket):
    """
    WebSocket endpoint for real-time video frame processing.

    Protocol:
        1. Client connects to ws://localhost:8000/ws/video
        2. Client sends JSON: {"frame": "<base64-encoded-JPEG>"}
        3. Server processes the frame through MediaPipe PoseLandmarker
        4. Server returns JSON: {
               "angle": 23.5,
               "risk_level": "Mild",
               "risk_color": "#eab308",
               "annotated_frame": "<base64-encoded-annotated-JPEG>",
               "landmarks": { "side": "Left", "ear": {...}, "shoulder": {...} },
               "timestamp": "2026-09-09T20:30:00"
           }
        5. Repeat steps 2-4 for each frame (~10 FPS)
        6. Connection closes when client disconnects

    Each connection gets its own PoseLandmarker model instance to avoid
    thread-safety issues with concurrent users.
    """
    # Accept the WebSocket connection
    await websocket.accept()
    print(f"[WS] Client connected: {websocket.client}")

    # Check that the model file exists before proceeding
    if not os.path.exists(MODEL_PATH):
        await websocket.send_json({
            "error": f"Model file not found at {MODEL_PATH}. "
                     "Download it from: https://storage.googleapis.com/mediapipe-models/"
                     "pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"
        })
        await websocket.close()
        return

    # Create a dedicated PoseLandmarker instance for this connection
    # Using IMAGE running mode for synchronous single-frame detection
    base_options = mp_python.BaseOptions(model_asset_path=MODEL_PATH)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.IMAGE,   # Process one frame at a time
        num_poses=1,                              # Detect only one person
        min_pose_detection_confidence=0.5,        # 50% confidence threshold
        min_tracking_confidence=0.5               # 50% tracking threshold
    )
    landmarker = vision.PoseLandmarker.create_from_options(options)

    try:
        while True:
            # ---- Receive frame from the frontend ----
            raw_data = await websocket.receive_text()
            data = json.loads(raw_data)

            # Extract the base64-encoded frame
            frame_b64 = data.get("frame", "")

            if not frame_b64:
                await websocket.send_json({"error": "No frame data received"})
                continue

            # ---- Decode the base64 frame to an OpenCV image ----
            # The frontend sends: "data:image/jpeg;base64,<actual-data>"
            # We need to strip the data URI prefix if present
            if "," in frame_b64:
                frame_b64 = frame_b64.split(",")[1]

            # Decode base64 -> bytes -> numpy array -> OpenCV image
            frame_bytes = base64.b64decode(frame_b64)
            np_array = np.frombuffer(frame_bytes, dtype=np.uint8)
            frame = cv2.imdecode(np_array, cv2.IMREAD_COLOR)

            if frame is None:
                await websocket.send_json({"error": "Failed to decode frame"})
                continue

            # ---- Process the frame through our pipeline ----
            result = process_frame(frame, landmarker)

            # ---- Send the result back to the frontend ----
            await websocket.send_json(result)

    except WebSocketDisconnect:
        print(f"[WS] Client disconnected: {websocket.client}")
    except Exception as e:
        print(f"[WS] Error: {e}")
        try:
            await websocket.send_json({"error": str(e)})
        except Exception:
            pass
    finally:
        # Clean up the PoseLandmarker instance
        landmarker.close()
        print(f"[WS] PoseLandmarker closed for client: {websocket.client}")


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================
# Run with: python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("  Text Neck AI Server — Starting...")
    print("  WebSocket endpoint: ws://localhost:8000/ws/video")
    print("  Health check:       http://localhost:8000/health")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
