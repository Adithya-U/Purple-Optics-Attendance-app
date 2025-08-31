import React, { useEffect, useState } from 'react';
import SidebarLayout from '../pages/SidebarLayout';
import './requests.css';

const Requests = () => {
  const [lateRequests, setLateRequests] = useState([]);
  const leaveRequestData = [
    {
      id: '2341421',
      name: 'Ahmed Rashdan',
      role: 'Help Desk Executive',
      branch: 'xxxxx',
      phone: 'xxxxxxxxxx',
      duration: '30 July --- 3 June',
      status: 'Pending',
    },
    {
      id: '3411421',
      name: 'Ali Alhamdan',
      role: 'Senior Executive',
      branch: 'yyyyy',
      phone: 'yyyyyyyyyy',
      range: '1 June --- 2 June',
      status: 'Pending',
    },
    {
      id: '2341121',
      name: 'Mona Alghafar',
      role: 'Senior Manager',
      branch: 'zzzzzz',
      phone: 'zzzzzzzzzz',
      range: '30 July --- 5 June',
      status: 'Pending',
    },
  ];

  const fetchLateArrival = async () => {
    try {
      const res = await fetch("http://localhost:5000/api/late-arrival-requests");
      const data = await res.json();
      setLateRequests(data);
    } catch (err) {
      console.error("Fetch error:", err);
    }
  };

  useEffect(() => {
    fetchLateArrival();
  }, []);

  const handleStatusChange = async (id, newStatus) => {
    try {
      const res = await fetch(`http://localhost:5000/api/late-arrival-requests/${id}/status`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status: newStatus })
      });

      if (!res.ok) throw new Error("Failed to update status");

      window.dispatchEvent(new Event("attendance-updated"));

      await fetchLateArrival();
    } catch (err) {
      console.error("Update error:", err);
      alert("Failed to update status.");
    }
  };

  return (
    <SidebarLayout>
      <div className="requests-page">
        <Section
          title="Late Arrival Requests"
          type="late"
          data={lateRequests}
          onStatusChange={handleStatusChange}
        />
        <Section
          title="Request for Leave"
          type="leave"
          data={leaveRequestData}
        />
      </div>
    </SidebarLayout>
  );
};

const Section = ({ title, data, type, onStatusChange }) => {
  const [confirming, setConfirming] = useState({ id: null, action: null });

  const confirmAction = (id, action) => {
    setConfirming({ id, action });
  };

  const cancelAction = () => {
    setConfirming({ id: null, action: null });
  };

  const confirmStatusChange = () => {
    if (confirming.id && confirming.action) {
      onStatusChange(confirming.id, confirming.action);
      setConfirming({ id: null, action: null });
    }
  };

  return (
    <div className="request-section">
      <div className="section-header">
        <h2>{title}</h2>
        <div className="controls">
          <input type="text" placeholder="🔍 Quick Search..." />
        </div>
      </div>
      <table>
        <thead>
          <tr>
            <th>Request ID</th>
            <th>Employee ID</th>
            <th>Employee</th>
            <th>Role</th>
            <th>Branch</th>
            <th>Phone No.</th>
            <th>Requested at</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {data.length === 0 ? (
            <tr><td colSpan="8">No requests found</td></tr>
          ) : (
            data.map((entry, i) => (
              <tr key={i}>
                <td>{entry.request_id}</td>
                <td>{entry.employee_id}</td>
                <td>{entry.name}</td>
                <td>{entry.role}</td>
                <td>{entry.branch}</td>
                <td>{entry.phone}</td>
                <td className={
                  entry.status === "Accepted"
                    ? "time-accepted"
                    : entry.status === "Rejected"
                    ? "time-rejected"
                    : "time-pending"
                }>
                  {entry.requested_at}
                </td>
                <td>
                  {entry.status === "Accepted" || entry.status === "Rejected" ? (
                    <span className={entry.status === "Accepted" ? "status-accept" : "status-reject"}>
                      {entry.status}
                    </span>
                  ) : confirming.id === entry.request_id ? (
                    <div className="confirm-box">
                      <span>Confirm {confirming.action}?</span>
                      <button
                        className="confirm-btn"
                        onClick={confirmStatusChange}
                      >
                        Yes
                      </button>
                      <button
                        className="cancel-btn"
                        onClick={cancelAction}
                      >
                        No
                      </button>
                    </div>
                  ) : (
                    <>
                      <button
                        className="reject-btn"
                        onClick={() => confirmAction(entry.request_id, "Rejected")}
                      >
                        Reject
                      </button>
                      <button
                        className="accept-btn"
                        onClick={() => confirmAction(entry.request_id, "Accepted")}
                      >
                        Accept
                      </button>
                    </>
                  )}
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
};

export default Requests;
