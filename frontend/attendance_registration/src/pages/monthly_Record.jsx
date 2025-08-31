import React, { useEffect, useState } from "react";
import { useLocation } from 'react-router-dom';
import SidebarLayout from "./SidebarLayout";
import "./monthly_record.css";

const Monthly = () => {
  const [records, setRecords] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");

  // Sample data (replace with backend API call later)
  const fetchrecords = async() => {
    try{
      const res=await fetch("http://localhost:5000/api/monthlyrecords");
      const data =await res.json();
      console.log("Fetched data:", data);
      setRecords(data);
    }catch(err){
      console.error("Fetch error:",err);
    }
  };

 useEffect(() => {
  fetchrecords();
}, []);

// Filtered records by search
const filteredRecords = records.filter(
  (rec) =>
    rec.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    rec.id.toString().includes(searchQuery) ||
    rec.branch.toLowerCase().includes(searchQuery.toLowerCase())
);

  return (
    <SidebarLayout>
      <div className="Monthly-Records-container">
        <div className="table-container">
          {/* Header row with title + search bar */}
          <div className="table-header">
            <span className="header-title">Monthly Record</span>
            <input
              type="text"
              placeholder="Quick Search..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
          </div>

          {/* Table */}
          <table className="records-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Employee</th>
                <th>Branch</th>
                <th>Month</th>
                <th>Hours Worked</th>
                <th>Leaves Taken</th>
                <th>Overtime Hours</th>
                
              </tr>
            </thead>
            <tbody>
              {filteredRecords.length > 0 ? (
                filteredRecords.map((rec, index) => (
                  <tr key={index}>
                    <td>{rec.id}</td>
                    <td>{rec.name}</td>
                    <td>{rec.branch}</td>
                    <td>{rec.month}</td>
                    <td>{rec.hoursWorked}</td> 
                    <td>{rec.leavesTaken}</td> 
                    <td>{rec.overtime}</td> 
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7" className="no-data">
                    No matching records found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </SidebarLayout>
  );
};

export default Monthly;
