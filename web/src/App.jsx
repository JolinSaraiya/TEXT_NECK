import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import PatientDetail from './pages/PatientDetail';

function App() {
  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/patient/:id" element={<PatientDetail />} />
            {/* Additional routes like /settings could go here */}
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
