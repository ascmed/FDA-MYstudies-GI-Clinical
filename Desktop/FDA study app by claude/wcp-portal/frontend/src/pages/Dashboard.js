import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import './Dashboard.css';

function Dashboard() {
  const [studies, setStudies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    studyId: '',
    title: '',
    description: '',
    diseaseArea: 'UC',
    phase: 'Phase III',
    durationWeeks: 24,
  });

  useEffect(() => {
    fetchStudies();
  }, []);

  const fetchStudies = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get('/api/studies', {
        headers: { Authorization: `Bearer ${token}` },
      });
      setStudies(response.data);
      setError('');
    } catch (error) {
      setError('Failed to fetch studies');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleCreateStudy = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      const response = await axios.post('/api/studies', formData, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setStudies([response.data.study, ...studies]);
      setShowForm(false);
      setFormData({
        studyId: '',
        title: '',
        description: '',
        diseaseArea: 'UC',
        phase: 'Phase III',
        durationWeeks: 24,
      });
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to create study');
    }
  };

  const getDiseaseColor = (diseaseArea) => {
    const colors = {
      UC: '#C2410C',
      CD: '#7C3AED',
      NASH: '#0369A1',
    };
    return colors[diseaseArea] || '#1A6B4A';
  };

  if (loading) {
    return (
      <div className="dashboard-loading">
        <div className="loading" />
        <p>Loading studies...</p>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <div>
          <h1>Dashboard</h1>
          <p>Manage your GI Clinical Studies</p>
        </div>
        <button className="btn-primary" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : '+ New Study'}
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {showForm && (
        <div className="card creation-form mb-3">
          <h2>Create New Study</h2>
          <form onSubmit={handleCreateStudy}>
            <div className="form-row">
              <div className="form-group">
                <label>Study ID (e.g., GI-UC-2026)</label>
                <input
                  type="text"
                  name="studyId"
                  value={formData.studyId}
                  onChange={handleInputChange}
                  placeholder="GI-UC-2026"
                  required
                />
              </div>
              <div className="form-group">
                <label>Disease Area</label>
                <select
                  name="diseaseArea"
                  value={formData.diseaseArea}
                  onChange={handleInputChange}
                >
                  <option value="UC">Ulcerative Colitis (UC)</option>
                  <option value="CD">Crohn's Disease (CD)</option>
                  <option value="NASH">Hepatic Steatosis (NASH)</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label>Study Title</label>
              <input
                type="text"
                name="title"
                value={formData.title}
                onChange={handleInputChange}
                placeholder="Study Title"
                required
              />
            </div>

            <div className="form-group">
              <label>Description</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                placeholder="Study Description"
                rows="3"
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Phase</label>
                <select
                  name="phase"
                  value={formData.phase}
                  onChange={handleInputChange}
                >
                  <option value="Phase I">Phase I</option>
                  <option value="Phase II">Phase II</option>
                  <option value="Phase II/III">Phase II/III</option>
                  <option value="Phase III">Phase III</option>
                </select>
              </div>
              <div className="form-group">
                <label>Duration (weeks)</label>
                <input
                  type="number"
                  name="durationWeeks"
                  value={formData.durationWeeks}
                  onChange={handleInputChange}
                  min="1"
                />
              </div>
            </div>

            <button type="submit" className="btn-primary">
              Create Study
            </button>
          </form>
        </div>
      )}

      <div className="studies-grid">
        {studies.length === 0 ? (
          <div className="empty-state">
            <p>No studies yet. Create one to get started!</p>
          </div>
        ) : (
          studies.map((study) => (
            <Link key={study.id} to={`/studies/${study.id}`} className="study-card">
              <div
                className="study-badge"
                style={{ backgroundColor: getDiseaseColor(study.disease_area) }}
              >
                {study.disease_area}
              </div>
              <h3>{study.title}</h3>
              <p className="study-id">{study.study_id}</p>
              <p className="study-description">{study.description}</p>
              <div className="study-meta">
                <span>{study.phase}</span>
                <span>{study.duration_weeks} weeks</span>
                <span className={`status status-${study.status}`}>{study.status}</span>
              </div>
            </Link>
          ))
        )}
      </div>
    </div>
  );
}

export default Dashboard;
