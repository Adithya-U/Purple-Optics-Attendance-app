// src/pages/home.jsx
import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import SidebarLayout from '../pages/SidebarLayout';
import { Users, UserCheck, UserX, Clock, Calendar } from 'lucide-react';
import './home.css';

const StatCard = ({ icon: Icon, title, value, onClick }) => (
  <div className="stat-card" onClick={onClick}>
    <div className="stat-card-content">
      <div className="stat-info">
        <h3>{title}</h3>
        <div className="stat-value">{value}</div>
      </div>
      <div className="stat-icon"><Icon /></div>
    </div>
  </div>
);



const Home = () => {
  const location = useLocation();
  const [searchTerm, setSearchTerm] = useState("");
  const [currentTime, setCurrentTime] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [attendanceData, setAttendanceData] = useState([]);
  const [modalVisible, setModalVisible] = useState(false); // stats modal (existing)
  const [modalTitle, setModalTitle] = useState('');
  const [filteredEmployees, setFilteredEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [viewModalVisible, setViewModalVisible] = useState(false);
  const [employees, setEmployees] = useState([]); // all employees
  // NEW: modals for add/remove
  const [addModalVisible, setAddModalVisible] = useState(false);
  const [removeModalVisible, setRemoveModalVisible] = useState(false);

  // Add Employee form state
  const [newEmp, setNewEmp] = useState({
  name: '',
  email: '',
  phone_no: '',
  position: '',
  permanent_location: '',
});
  const [photoFile, setPhotoFile] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [removeId, setRemoveId] = useState('');

  const [stats, setStats] = useState({
    totalEmployees: 0,
    onTime: 0,
    absent: 0,
    lateArrival: 0,
    earlyDepartures: 0,
    timeOff: 0
  });

  const username =
    location.state?.username ||
    localStorage.getItem("username") ||
    "Admin";

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(`http://localhost:5000/api/attendance?date=${selectedDate}`);
        if (!res.ok) throw new Error("Failed to fetch data");
        const data = await res.json();
        setAttendanceData(data);
        calculateStats(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();

    const refreshHandler = () => fetchData();
    window.addEventListener("attendance-updated", refreshHandler);
    return () => window.removeEventListener("attendance-updated", refreshHandler);
  }, [selectedDate]);

  const calculateStats = (data) => {
    setStats({
      totalEmployees: data.length,
      onTime: data.filter(d => d.status === 'Present').length,
      absent: data.filter(d => d.status === 'Absent').length,
      lateArrival: data.filter(d => d.status === 'Late').length,
      earlyDepartures: data.filter(d => d.status === 'Early Departure').length,
      timeOff: data.filter(d => d.status === 'On Leave').length,
    });
  };

  const formatTableDate = (dateString) =>
    new Date(dateString).toLocaleDateString('en-US', { day: 'numeric', month: 'long', year: 'numeric' });

  const formatTimeForTable = (timeString) => {
    if (!timeString || timeString === 'RUNE') return '--';
    const [hours, minutes] = timeString.split(':');
    const hour = parseInt(hours, 10);
    const period = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${minutes} ${period}`;
  };

  const calculateWorkHours = (checkIn, checkOut) => {
    if (!checkIn || !checkOut || checkIn === 'RUNE' || checkOut === 'RUNE') return '--';
    const [h1, m1] = checkIn.split(':').map(Number);
    const [h2, m2] = checkOut.split(':').map(Number);
    const diff = (h2 * 60 + m2) - (h1 * 60 + m1);
    if (diff <= 0) return '--';
    const hrs = Math.floor(diff / 60);
    const mins = diff % 60;
    return `${hrs}h ${mins}m`;
  };

  const handleStatCardClick = (status, title) => {
    const filtered = attendanceData.filter(d => d.status === status);
    setFilteredEmployees(filtered);
    setModalTitle(title);
    setModalVisible(true);
  };

  const closeModal = () => setModalVisible(false);

  // Add employee handlers
  const openAddModal = () => {
    setNewEmp({ name: '', email: '', phone_no: '', position: '', permanent_location: '' });
    setPhotoFile(null);
    setAddModalVisible(true);
  };
  const closeAddModal = () => setAddModalVisible(false);

  const onPhotoChange = (e) => {
    setPhotoFile(e.target.files?.[0] || null);
  };
  const [popupMessage, setPopupMessage] = useState("");
  const handleAddSubmit = async (e) => {
  e.preventDefault();
  console.log("Submitting employee:", newEmp);  
  if (!newEmp.name || !newEmp.email) {
    alert('Please enter at least name and email.');
    return;
  }

  try {
    setSubmitting(true);

    const payload = {
      name: newEmp.name,
      email: newEmp.email,
      phone_no: newEmp.phone_no,
      position: newEmp.position,
      permanent_location: newEmp.permanent_location,
    };

    const res = await fetch('http://localhost:5000/api/employees', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
if (!res.ok || !data.success) {
  throw new Error(data.message || 'Failed to add employee');
}

alert('Employee added successfully.');
closeAddModal();
window.dispatchEvent(new Event('attendance-updated'));
  } catch (err) {
    console.error(err);
    alert('Error adding employee: ' + (err.message || err));
  } finally {
    setSubmitting(false);
  }
};


  // Remove employee handlers
  const openRemoveModal = () => {
    setRemoveId('');
    setRemoveModalVisible(true);
  };
  const closeRemoveModal = () => setRemoveModalVisible(false);

  const handleRemove = async () => {
    if (!removeId) {
      alert('Please enter an employee ID to remove.');
      return;
    }
    if (!confirm(`Remove employee with ID "${removeId}"?`)) return;
    try {
      const res = await fetch(`http://localhost:5000/api/employees/${encodeURIComponent(removeId)}`, {
        method: 'DELETE'
      });
      if (!res.ok) {
        const txt = await res.text();
        throw new Error(txt || 'Failed to remove employee');
      }
      alert('Employee removed.');
      closeRemoveModal();
      window.dispatchEvent(new Event('attendance-updated'));
    } catch (err) {
      console.error(err);
      alert('Error removing employee: ' + (err.message || err));
    }
  };

// new state for view employees modal

const openViewModal = async () => {
  try {
    const res = await fetch("http://localhost:5000/api/viewemployees");
    
    const data = await res.json();
    if (!data.success) throw new Error(data.message || "Failed to load employees");
    setEmployees(data.employees);
    setViewModalVisible(true);
  } catch (err) {
    alert("Error fetching employees: " + err.message);
  }
};

const closeViewModal = () => setViewModalVisible(false);

  return (
    <SidebarLayout currentTime={currentTime} username={username}>
      {/* Stats Cards */}
      <div className="stats-grid">
        <StatCard icon={UserX} title="Absent" value={stats.absent} onClick={() => handleStatCardClick('Absent', 'Absent Employees')} />
        <StatCard icon={UserCheck} title="On Time" value={stats.onTime} onClick={() => handleStatCardClick('Present', 'On Time Employees')} />
        <StatCard icon={Clock} title="Late Arrival" value={stats.lateArrival} onClick={() => handleStatCardClick('Late', 'Late Arrivals')} />
        <StatCard icon={Users} title="Early Departures" value={stats.earlyDepartures} onClick={() => handleStatCardClick('Early Departure', 'Early Departures')} />
        <StatCard icon={Calendar} title="Time-off" value={stats.timeOff} onClick={() => handleStatCardClick('On Leave', 'On Leave Employees')} />
      </div>

      {/* Stats modal (existing listing modal) */}
      {modalVisible && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{modalTitle}</h3>
              <button className="close-btn" onClick={closeModal}>✕</button>
            </div>
            <div className="modal-body">
              {filteredEmployees.length === 0 ? (
                <p>No employees found.</p>
              ) : (
                <ul className="employee-list">
                  {filteredEmployees.map(emp => (
                    <li key={emp.attendance_id}>
                      <strong>{emp.employee_id}</strong> - {emp.emp_name}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Employee Management Section */}
      <div className="employee-management">
        <div className="employee-card add-employee" onClick={openAddModal}>
          <h3>Add Employee</h3>
          <button className="action-btn" type="button">+ Add</button>
        </div>
        <div className="employee-card remove-employee" onClick={openRemoveModal}>
          <h3>Remove Employee</h3>
          <button className="action-btn" type="button">- Remove</button>
        </div>
        <div className="employee-card view-employee" onClick={openViewModal}>
          <h3>View Employees</h3>
          <button className="action-btn" type="button">👁 View</button>
        </div>
      </div>

      {/* ADD EMPLOYEE Modal (custom styled like your mock) */}
      {addModalVisible && (
        <div className="modal-overlay" onClick={closeAddModal}>
          <div className="add-employee-modal" onClick={(e) => e.stopPropagation()}>
            <div className="add-modal-header">
              <h2>New Employee INFO</h2>
              <button className="close-btn" onClick={closeAddModal}>✕</button>
            </div>

            <form className="add-modal-body" onSubmit={handleAddSubmit}>
              <label className="form-field">
                <span className="label-text">Name</span>
                <input
                  type="text"
                  value={newEmp.name}
                  onChange={(e) => setNewEmp(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Full name"
                  required
                />
              </label>

              <label className="form-field">
                <span className="label-text">email id</span>
                <input
                  type="email"
                  value={newEmp.email}
                  onChange={(e) => setNewEmp(prev => ({ ...prev, email: e.target.value }))}
                  placeholder="email@example.com"
                  required
                />
              </label>

              <label className="form-field">
                <span className="label-text">phone no.</span>
                <input
                  type="tel"
                  value={newEmp.phone_no}
                  onChange={(e) => setNewEmp(prev => ({ ...prev, phone_no: e.target.value }))}
                  placeholder="+91 55555 55555"
                />
              </label>

              <label className="form-field">
                <span className="label-text">position</span>
                <input
                  type="text"
                  value={newEmp.position}
                  onChange={(e) => setNewEmp(prev => ({ ...prev, position: e.target.value }))}
                />
              </label>

              <label className="form-field">
                <span className="label-text">Branch</span>
                 <input
    type="text"
    value={newEmp.permanent_location}
    onChange={(e) => setNewEmp(prev => ({ ...prev, permanent_location: e.target.value }))}
    placeholder="Enter branch location"
  />
</label>

              <label className="form-field upload-field">
                <span className="label-text">Upload Photo</span>
                <input type="file" accept="image/*" onChange={onPhotoChange} />
              </label>

              <div className="add-modal-actions">
                <button type="button" className="btn-secondary" onClick={closeAddModal} disabled={submitting}>Cancel</button>
                <button type="submit" className="btn-primary" disabled={submitting}>
                  {submitting ? 'Saving...' : 'Save Employee'}
                </button>
              </div>
              
            </form>
            
          </div>
          
        </div>
      )}

      {/* REMOVE EMPLOYEE Modal */}
      {removeModalVisible && (
        <div className="modal-overlay" onClick={closeRemoveModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Remove Employee</h3>
              <button className="close-btn" onClick={closeRemoveModal}>✕</button>
            </div>
            <div className="modal-body">
              <label style={{display:'block', marginBottom: '10px'}}>
                Employee ID
                <input
                  type="text"
                  value={removeId}
                  onChange={(e) => setRemoveId(e.target.value)}
                  placeholder="Enter employee ID to remove"
                  style={{ display: 'block', width: '100%', padding: '8px', marginTop: '6px', borderRadius: '6px', border: '1px solid #ddd' }}
                />
              </label>
              <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 12 }}>
                <button className="btn-secondary" onClick={closeRemoveModal}>Cancel</button>
                <button className="btn-primary" onClick={handleRemove}>Remove</button>
              </div>
            </div>
          </div>
        </div>
      )}
{viewModalVisible && (
  <div className="modal-overlay" onClick={closeViewModal}>
    <div className="modal large-modal" onClick={(e) => e.stopPropagation()}>
      <div className="modal-header">
        <h3>All Employees</h3>
        <button className="close-btn" onClick={closeViewModal}>✕</button>
      </div>
      <div className="modal-body">
        {employees.length === 0 ? (
          <p>No employees found.</p>
        ) : (
          <table className="employees-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Position</th>
                <th>Branch</th>
                <th>Date Joined</th>
              </tr>
            </thead>
            <tbody>
              {employees.map(emp => (
                <tr key={emp.employee_id}>
                  <td>{emp.employee_id}</td>
                  <td>{emp.name}</td>
                  <td>{emp.email}</td>
                  <td>{emp.phone_no || "--"}</td>
                  <td>{emp.position || "--"}</td>
                  <td>{emp.permanent_location || "--"}</td>
                  <td>{emp.date_joined ? new Date(emp.date_joined).toLocaleDateString() : "--"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  </div>
)}

      {/* Attendance Table */}
      <div className="table-container">
        <div className="table-header">
          <h3 className="table-title">
            Attendance Overview
            <span className="employee-count">({stats.totalEmployees} Employees)</span>
          </h3>
          <div className="table-actions">
            <input
              type="text"
              placeholder="🔍 Search employee..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="search-input-small"
            />
          </div>
        </div>

        <div className="table-wrapper">
          <table className="attendance-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Employee</th>
                <th>Current Location</th>
                <th>Date</th>
                <th>Status</th>
                <th>Check-in</th>
                <th>Check-out</th>
                <th>Work Hours</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan="8">Loading...</td></tr>
              ) : error ? (
                <tr><td colSpan="8">{error}</td></tr>
              ) : attendanceData.length === 0 ? (
                <tr><td colSpan="8">No data found for {formatTableDate(selectedDate)}</td></tr>
              ) : (
                attendanceData
                  .filter(e => e.emp_name.toLowerCase().includes(searchTerm.toLowerCase()))
                  .map(e => (
                    <tr key={e.attendance_id}>
                      <td>{e.employee_id}</td>
                      <td>{e.emp_name}</td>
                      <td>{e.current_location || '--'}</td>
                      <td>{formatTableDate(e.date)}</td>
                      <td>
                        <span className={`status-badge ${e.status.toLowerCase().replace(' ', '-')}`}>
                          {e.status}
                        </span>
                      </td>
                      <td>{formatTimeForTable(e.check_in)}</td>
                      <td>{formatTimeForTable(e.check_out)}</td>
                      <td>{calculateWorkHours(e.check_in, e.check_out)}</td>
                    </tr>
                  ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </SidebarLayout>
  );
};

export default Home;
