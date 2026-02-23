import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Navbar.css';

function Navbar({ user, onLogout }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          <span className="logo-icon">🔬</span>
          GI Clinical Studies
        </Link>

        <div className="navbar-menu">
          <Link to="/dashboard" className="nav-link">Dashboard</Link>
        </div>

        <div className="navbar-user">
          <span className="user-info">
            {user.email}
            {user.role === 'super_admin' && <span className="badge">Admin</span>}
          </span>
          <button className="btn-logout" onClick={handleLogout}>
            Logout
          </button>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
