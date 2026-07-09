const mongoose = require('mongoose');

const sessionLogSchema = new mongoose.Schema({
  patient_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true,
  },
  session_date: {
    type: Date,
    required: true,
    default: Date.now,
  },
  average_daily_angle: {
    type: Number,
    required: true,
  },
  time_in_severe_risk: {
    type: Number, // in minutes
    required: true,
  },
  max_angle_recorded: {
    type: Number,
  },
  duration_minutes: {
    type: Number,
  },
});

module.exports = mongoose.model('SessionLog', sessionLogSchema);
