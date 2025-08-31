import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Search, User, Clock, FileText, LogOut } from 'lucide-react';
import logoImage from '../assets/logo.png'; // ✅ Correct image import
import '../pages/SidebarLayout.css';

const SidebarLayout = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const [currentTime, setCurrentTime] = useState(new Date());

  const username =
    location.state?.username ||
    localStorage.getItem("username") ||
    "Admin";

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTime = date => date.toLocaleTimeString('en-US', {
    hour12: true,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });

  const formatDate = date => date.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  const handleLogout = () => {
    navigate('/', { replace: true });
  };

  return (
    <div className="dashboard-container expanded">
      <header className="header">
        <div className="header-content">
          <div className="logo">
            <img 
              src={logoImage} 
              alt="Company Logo" 
              className="logo-image"
            />
          </div>

          
          <div className="header-actions">
            <div className="user-profile">
              <div className="user-info">
                <div className="user-details">
                  <User size={20} />
                  <h4>{username}</h4>
                </div>
                <button onClick={handleLogout} className="logout-btn" title="Logout">
                  <LogOut size={16} />
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main className="main-content expanded">
        <aside className="sidebar expanded">
          <div className="sidebar-card">
            <h2 className="sidebar-title">Navigation</h2>
            <div className="nav-menu">
              <button 
                className={`nav-item ${location.pathname === '/dashboard' ? 'active' : ''}`}
                onClick={() => navigate('/dashboard')}
              >
                <div className="nav-dot"></div>
                <span>Dashboard</span>
              </button>
              <button 
                className={`nav-item ${location.pathname === '/requests' ? 'active' : ''}`}
                onClick={() => navigate('/requests')}
              >
                <FileText size={20} />
                <span>Requests</span>
              </button>
              <button 
                className={`nav-item ${location.pathname === '/Monthly-Records' ? 'active' : ''}`}
                onClick={() => navigate('/Monthly-Records')}
              >
                <Clock size={20} />
                <span>Monthly Record</span>
              </button>
            </div>

            <div className="time-widget">
              <div className="time-display">
                <Clock size={32} color="#9ca3af" />
              </div>
              <p className="current-time">{formatTime(currentTime)}</p>
              <p className="time-label">Realtime Insight</p>
              <div className="date-info">
                <p>Today:</p>
                <p>{formatDate(currentTime)}</p>
              </div>
            </div>
          </div>
        </aside>

        <div className="dashboard-content expanded">
          {children}
        </div>
      </main>
    </div>
    
  );
};

export default SidebarLayout;
