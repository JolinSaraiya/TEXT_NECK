import React from 'react';
import PatientCard from '../components/PatientCard';

// Mock data for Phase 2
const mockPatients = [
  { id: '1', name: 'John Doe', age: 34, latest_angle: 35 },
  { id: '2', name: 'Jane Smith', age: 28, latest_angle: 22 },
  { id: '3', name: 'Robert Johnson', age: 45, latest_angle: 41 },
  { id: '4', name: 'Emily Davis', age: 31, latest_angle: 18 }
];

const Dashboard = () => {
  return (
    <div className="dashboard-container">
      <h1 className="animate-fade-in">Patient Overview</h1>
      <p className="subtitle animate-fade-in" style={{ animationDelay: '0.1s' }}>
        Monitor real-time posture metrics and progress
      </p>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '2rem' }}>
        {mockPatients.map((patient, index) => (
          <div key={patient.id} style={{ animationDelay: `${0.2 + index * 0.1}s` }} className="animate-fade-in">
            <PatientCard patient={patient} />
          </div>
        ))}
      </div>
    </div>
  );
};

export default Dashboard;
