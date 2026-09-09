import React from 'react';
import { NavLink } from 'react-router-dom';
import { Activity, Users, Camera, Settings, LogOut } from 'lucide-react';
import './Sidebar.css';

const Sidebar = () => {
  return (
    <aside className="sidebar glass-panel">
      <div className="sidebar-brand">
        <Activity className="brand-icon" size={32} />
        <h2>TextNeck</h2>
      </div>
      
      <nav className="sidebar-nav">
        <NavLink 
          to="/" 
          className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
          end
        >
          <Users size={20} />
          <span>Patients</span>
        </NavLink>
        {/* Live Monitor — real-time posture detection with camera + AI */}
        <NavLink 
          to="/monitor" 
          className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
        >
          <Camera size={20} />
          <span>Live Monitor</span>
        </NavLink>
        <NavLink 
          to="/settings" 
          className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
        >
          <Settings size={20} />
          <span>Settings</span>
        </NavLink>
      </nav>

      <div className="sidebar-footer">
        <button className="nav-item logout-btn">
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
