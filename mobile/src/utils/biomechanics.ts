export interface Landmark {
  x: number;
  y: number;
  z?: number;
  visibility?: number;
}

/**
 * Calculates the cervical inclination angle (Forward Head Posture).
 * This is the angle between the vertical y-axis and the vector connecting 
 * the shoulder (Node 11/12) to the ear (Node 7/8).
 * 
 * In screen coordinates, Y points downwards. Therefore, the upward vertical vector is (0, -1).
 * 
 * @param shoulder The 3D landmark of the shoulder
 * @param ear The 3D landmark of the ear on the same side
 * @returns The inclination angle in degrees
 */
export function calculateCervicalAngle(shoulder: Landmark, ear: Landmark): number {
  // Vector from shoulder to ear
  const dx = ear.x - shoulder.x;
  const dy = ear.y - shoulder.y;
  
  const magnitude = Math.sqrt(dx * dx + dy * dy);
  
  if (magnitude === 0) return 0;
  
  // Angle with the vertical Y-axis pointing upwards (0, -1)
  // cos(theta) = (dx*0 + dy*(-1)) / (magnitude * 1)
  const cosTheta = -dy / magnitude;
  
  // Calculate angle in radians
  const angleRads = Math.acos(cosTheta);
  
  // Convert to degrees
  const angleDegrees = angleRads * (180 / Math.PI);
  
  return angleDegrees;
}
