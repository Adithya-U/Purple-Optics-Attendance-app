import { useState } from 'react';
import './CreateAccount.css';
import logoImage from '../assets/logo.png'; // Adjust path if needed
import { useNavigate } from 'react-router-dom';

export default function CreateAccount() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    confirmPassword: ''
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleCreateAccount = async () => {
    console.log('Create account attempt:', formData);

    if (formData.password !== formData.confirmPassword) {
      alert('Passwords do not match!');
      return;
    }

    try {
      const response = await fetch('http://localhost:5000/api/create-account', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: formData.username,
          password: formData.password
        })
      });

      const result = await response.json();

      if (response.ok) {
        alert('Account created successfully!');
        navigate('/login');
      } else {
        alert(result.message);
      }

    } catch (error) {
      console.error('Error:', error);
      alert('Something went wrong. Try again later.');
    }
  };

  const handleBackToLogin = () => {
    navigate('/login');
  };

  return (
    <div className="create-account-container">
      <div className="create-account-card">
        {/* Logo */}
        <div className="logo-icon">
          <img src={logoImage} alt="Company Logo" className="logo-image" />
        </div>

        {/* Header */}
        <div className="create-account-header">
          <h1>CREATE ACCOUNT</h1>
        </div>

        {/* Form */}
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
              placeholder=""
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
              placeholder=""
            />
          </div>

          {/* Confirm Password Field */}
          <div className="input-group">
            <label htmlFor="confirmPassword">Re-Enter Password</label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              value={formData.confirmPassword}
              onChange={handleInputChange}
              placeholder=""
            />
          </div>

          {/* Create Account Button */}
          <div className="button-container">
            <button
              onClick={handleCreateAccount}
              className="create-account-btn"
            >
              Create Account
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
