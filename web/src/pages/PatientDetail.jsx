import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import PostureChart from '../components/PostureChart';

// Mock session logs
const mockSessionData = [
  { date: 'Mon', average_angle: 42, time_in_severe: 15 },
  { date: 'Tue', average_angle: 38, time_in_severe: 12 },
  { date: 'Wed', average_angle: 35, time_in_severe: 8 },
  { date: 'Thu', average_angle: 31, time_in_severe: 5 },
  { date: 'Fri', average_angle: 28, time_in_severe: 2 },
  { date: 'Sat', average_angle: 25, time_in_severe: 0 },
  { date: 'Sun', average_angle: 22, time_in_severe: 0 },
];

const PatientDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  return (
    <div className="patient-detail-container">
      <button 
        onClick={() => navigate(-1)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem',
          background: 'none',
          border: 'none',
          color: 'var(--text-secondary)',
          cursor: 'pointer',
          marginBottom: '2rem',
          fontSize: '1rem'
        }}
        className="animate-fade-in"
      >
        <ArrowLeft size={20} /> Back to Dashboard
      </button>

      <h1 className="animate-fade-in" style={{ animationDelay: '0.1s' }}>Patient Profile {id}</h1>
      <p className="subtitle animate-fade-in" style={{ animationDelay: '0.2s' }}>
        Detailed posture analytics and session logs
      </p>

      <div style={{ marginTop: '3rem', animationDelay: '0.3s' }} className="animate-fade-in">
        <PostureChart data={mockSessionData} />
      </div>

      {/* Additional stats could go here */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginTop: '2rem' }}>
        <div className="glass-panel animate-fade-in" style={{ padding: '1.5rem', animationDelay: '0.4s' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '1rem', color: 'var(--text-secondary)' }}>
            Weekly Summary
          </h2>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '1rem' }}>Total Severe Time</span>
            <span style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--danger-red)' }}>42 mins</span>
          </div>
        </div>
        
        <div className="glass-panel animate-fade-in" style={{ padding: '1.5rem', animationDelay: '0.5s' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '1rem', color: 'var(--text-secondary)' }}>
            Current Status
          </h2>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '1rem' }}>Improvement Trend</span>
            <span style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--success-green)' }}>+15%</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PatientDetail;
