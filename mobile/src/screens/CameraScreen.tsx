import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View } from 'react-scale-stylesheet'; // mock import for now
// In a real app we'd use react-native StyleSheet, but we just want the structure
import { StyleSheet as RNStyleSheet, Text as RNText, View as RNView } from 'react-native';
import { PostureMonitor } from '../services/PostureMonitor';
// import { Camera, useFrameProcessor } from 'react-native-vision-camera'; // Commented out to avoid errors without install

export default function CameraScreen() {
  const [hasPermission, setHasPermission] = useState<boolean>(false);
  const [currentAngle, setCurrentAngle] = useState<number>(0);
  const [isSevere, setIsSevere] = useState<boolean>(false);
  
  // Initialize the monitor once
  const [postureMonitor] = useState(() => new PostureMonitor());

  useEffect(() => {
    // In a real scenario, request camera permission here
    // Camera.requestCameraPermission().then(status => setHasPermission(status === 'granted'));
    setHasPermission(true); // Mock permission granted
  }, []);

  /*
  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    // 1. Run MediaPipe model on the frame
    // const landmarks = runMediaPipePose(frame);
    
    // 2. Extract shoulder and ear
    // const shoulder = landmarks[11];
    // const ear = landmarks[7];
    
    // 3. Calculate angle (using the JS utility, or directly in C++ for performance)
    // const angle = calculateCervicalAngle(shoulder, ear);
    
    // 4. Update the rolling average
    // const result = postureMonitor.processFrame(angle);
    // runOnJS(setCurrentAngle)(result.currentAverage);
    // runOnJS(setIsSevere)(result.isSevere);
  }, []);
  */

  if (!hasPermission) {
    return (
      <RNView style={styles.container}>
        <RNText>No access to camera</RNText>
      </RNView>
    );
  }

  return (
    <RNView style={styles.container}>
      {/* Mocking the Camera view for now */}
      <RNView style={styles.cameraPlaceholder}>
        <RNText style={styles.placeholderText}>Camera Feed Here</RNText>
      </RNView>

      <RNView style={[styles.overlay, isSevere ? styles.overlaySevere : styles.overlaySafe]}>
        <RNText style={styles.angleText}>
          Angle: {currentAngle.toFixed(1)}°
        </RNText>
        <RNText style={styles.statusText}>
          {isSevere ? '⚠️ POOR POSTURE' : '✅ GOOD POSTURE'}
        </RNText>
      </RNView>
    </RNView>
  );
}

const styles = RNStyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  cameraPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#333',
  },
  placeholderText: {
    color: '#fff',
    fontSize: 18,
  },
  overlay: {
    position: 'absolute',
    bottom: 50,
    alignSelf: 'center',
    padding: 20,
    borderRadius: 15,
    width: '80%',
    alignItems: 'center',
  },
  overlaySafe: {
    backgroundColor: 'rgba(76, 175, 80, 0.8)', // Green
  },
  overlaySevere: {
    backgroundColor: 'rgba(244, 67, 54, 0.8)', // Red
  },
  angleText: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
  },
  statusText: {
    fontSize: 18,
    marginTop: 5,
    color: '#fff',
    fontWeight: '600',
  },
});
