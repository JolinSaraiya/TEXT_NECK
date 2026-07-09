import React from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertCircle, CheckCircle } from 'lucide-react';
import './PatientCard.css';

const PatientCard = ({ patient }) => {
  const navigate = useNavigate();
  
  // Mock logic to determine if latest average angle is severe
  const isSevere = patient.latest_angle > 30;

  return (
    <div 
      className="patient-card glass-panel animate-fade-in"
      onClick={() => navigate(`/patient/${patient.id}`)}
    >
      <div className="card-header">
        <h3>{patient.name}</h3>
        <span className="age-badge">{patient.age} yrs</span>
      </div>
      
      <div className="card-body">
        <div className="metric">
          <span className="metric-label">Latest Avg Angle</span>
          <span className={`metric-value ${isSevere ? 'danger' : 'safe'}`}>
            {patient.latest_angle}°
          </span>
        </div>
        
        <div className="metric">
          <span className="metric-label">Status</span>
          <div className="status-indicator">
            {isSevere ? (
              <><AlertCircle size={16} className="icon-danger" /> Needs Attention</>
            ) : (
              <><CheckCircle size={16} className="icon-safe" /> Improving</>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PatientCard;
