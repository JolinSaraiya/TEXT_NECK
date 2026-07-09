export class PostureMonitor {
  private angleBuffer: number[] = [];
  private readonly bufferSize: number = 15;
  private readonly angleThreshold: number = 30; // degrees
  private readonly timeThresholdMs: number = 5 * 60 * 1000; // 5 minutes
  
  private lastSafeTimestamp: number = Date.now();
  private isNotified: boolean = false;

  /**
   * Processes a new frame angle, maintains a rolling average, and determines if a notification is needed.
   * 
   * @param angle The latest calculated cervical angle
   * @returns The current rolling average, whether the posture is severe, and if a notification should be triggered.
   */
  public processFrame(angle: number): { currentAverage: number, isSevere: boolean, triggerNotification: boolean } {
    this.angleBuffer.push(angle);
    if (this.angleBuffer.length > this.bufferSize) {
      this.angleBuffer.shift();
    }
    
    // Calculate rolling average
    const currentAverage = this.angleBuffer.reduce((sum, val) => sum + val, 0) / this.angleBuffer.length;
    
    // Check if the average exceeds the safe threshold
    const isSevere = currentAverage > this.angleThreshold;
    const now = Date.now();
    
    if (!isSevere) {
      // If posture is good, update the last safe timestamp and reset notification state
      this.lastSafeTimestamp = now;
      this.isNotified = false;
    }
    
    let triggerNotification = false;
    
    // If posture has been severe continuously for longer than the time threshold
    if (isSevere && !this.isNotified && (now - this.lastSafeTimestamp >= this.timeThresholdMs)) {
      triggerNotification = true;
      this.isNotified = true; // Prevent spamming notifications
    }
    
    return { currentAverage, isSevere, triggerNotification };
  }

  /**
   * Clears the current session data
   */
  public resetSession() {
    this.angleBuffer = [];
    this.lastSafeTimestamp = Date.now();
    this.isNotified = false;
  }
}
