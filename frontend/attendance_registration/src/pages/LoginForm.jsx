import { useState } from 'react';
import './LoginForm.css';
import logoImage from '../assets/logo.png';
import { useNavigate } from 'react-router-dom';

export default function LoginForm() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    username: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear error when user starts typing
    if (error) setError('');
  };

  const handleLogin = async () => {
    console.log('Login attempt:', formData);
    
    // Basic validation
    if (!formData.username || !formData.password) {
      setError('Please enter both username and password');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await fetch('http://localhost:5000/api/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          username: formData.username,
          password: formData.password
        })
      });

      const data = await response.json();

      if (response.ok && data.success) {
        // Login successful - navigate to home page with username
        console.log('Login successful, username:', data.username);
        + localStorage.setItem('username', data.username); // Save to localStorage
        navigate('/home', {
          state: { username: data.username },
          replace: true
        });
      } 
else {
        // Login failed - show error message
        setError(data.message || 'Login failed');
      }
    } catch (err) {
      console.error('Login error:', err);
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAccount = () => {
    console.log('Create new account clicked');
    navigate('/create-account');
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleLogin();
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        {/* Logo */}
        <div className="logo-icon">
          <img src={logoImage} alt="Company Logo" className="logo-image" />
        </div>

        {/* Header */}
        <div className="login-header">
          <h1>LOGIN</h1>
        </div>

        {/* Error message */}
        {error && <div className="error-message">{error}</div>}

        {/* Login Form */}
        <div className="form-container">
          {/* Username Field */}
          <div className="input-group">
            <label htmlFor="username">Username</label>
            <input
              type="text"
              id="username"
              name="username"
              value={formData.username}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder="Enter your username"
              disabled={loading}
            />
          </div>

          {/* Password Field */}
          <div className="input-group">
            <label htmlFor="password">Enter Password</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder="Enter your password"
              disabled={loading}
            />
          </div>

          {/* Login Button */}
          <button
            onClick={handleLogin}
            className="login-btn"
            disabled={loading}
          >
            {loading ? 'LOGGING IN...' : 'LOGIN'}
          </button>
        </div>

        {/* Create Account Section */}
        <div className="create-account-section">
          <p>Don't have an account?</p>
          <button
            onClick={handleCreateAccount}
            className="create-account-btn"
            disabled={loading}
          >
            Create New Account
          </button>
        </div>
      </div>
    </div>
  );
}