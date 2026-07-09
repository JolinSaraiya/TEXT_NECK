const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  firebase_uid: {
    type: String,
    required: true,
    unique: true,
  },
  doctor_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
  },
  name: {
    type: String,
    required: true,
  },
  age: {
    type: Number,
  },
  baseline_angle: {
    type: Number,
  },
  created_at: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Patient', patientSchema);
