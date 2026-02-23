import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import './StudyDetail.css';

function StudyDetail() {
  const { studyId } = useParams();
  const navigate = useNavigate();
  const [study, setStudy] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('surveys');

  useEffect(() => {
    fetchStudy();
  }, [studyId]);

  const fetchStudy = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`/api/studies/${studyId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setStudy(response.data);
      setError('');
    } catch (error) {
      setError('Failed to fetch study details');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handlePublish = async () => {
    try {
      const token = localStorage.getItem('token');
      await axios.post(`/api/studies/${studyId}/publish`, {}, {
        headers: { Authorization: `Bearer ${token}` },
      });
      fetchStudy();
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to publish study');
    }
  };

  if (loading) {
    return <div className="loading" style={{ margin: '2rem' }} />;
  }

  if (!study) {
    return <div className="alert alert-error">Study not found</div>;
  }

  return (
    <div className="study-detail">
      <div className="study-header">
        <div className="study-info">
          <h1>{study.title}</h1>
          <p className="study-id">{study.study_id}</p>
          <div className="study-badges">
            <span className="badge">{study.disease_area}</span>
            <span className="badge">{study.phase}</span>
            <span className={`badge status-${study.status}`}>{study.status}</span>
          </div>
        </div>
        <div className="study-actions">
          {study.status === 'draft' && (
            <button className="btn-primary" onClick={handlePublish}>
              Publish Study
            </button>
          )}
          <Link to={`/studies/${study.id}/builder`} className="btn-primary">
            Edit Study
          </Link>
        </div>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      <div className="study-tabs">
        <button
          className={`tab-btn ${activeTab === 'surveys' ? 'active' : ''}`}
          onClick={() => setActiveTab('surveys')}
        >
          Surveys ({study.surveys?.length || 0})
        </button>
        <button
          className={`tab-btn ${activeTab === 'consent' ? 'active' : ''}`}
          onClick={() => setActiveTab('consent')}
        >
          Consent Form
        </button>
        <button
          className={`tab-btn ${activeTab === 'details' ? 'active' : ''}`}
          onClick={() => setActiveTab('details')}
        >
          Details
        </button>
      </div>

      <div className="tab-content">
        {activeTab === 'surveys' && (
          <div className="surveys-section">
            <h2>Surveys</h2>
            {!study.surveys || study.surveys.length === 0 ? (
              <p className="text-center">No surveys yet. Create one in the Study Builder.</p>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Type</th>
                    <th>Frequency</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {study.surveys.map((survey) => (
                    <tr key={survey.id}>
                      <td>{survey.title}</td>
                      <td>{survey.survey_type}</td>
                      <td>{survey.frequency}</td>
                      <td>{survey.is_active ? '✓ Active' : 'Inactive'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}

        {activeTab === 'consent' && (
          <div className="consent-section">
            <h2>Informed Consent Form</h2>
            {study.consentForm ? (
              <div className="card">
                <h3>{study.consentForm.title}</h3>
                <div className="consent-preview">
                  {study.consentForm.content}
                </div>
              </div>
            ) : (
              <p>No consent form configured. Create one in the Study Builder.</p>
            )}
          </div>
        )}

        {activeTab === 'details' && (
          <div className="details-section">
            <div className="card">
              <h2>Study Details</h2>
              <dl className="detail-list">
                <dt>Study ID</dt>
                <dd>{study.study_id}</dd>

                <dt>Disease Area</dt>
                <dd>{study.disease_area}</dd>

                <dt>Phase</dt>
                <dd>{study.phase}</dd>

                <dt>Duration</dt>
                <dd>{study.duration_weeks} weeks</dd>

                <dt>Description</dt>
                <dd>{study.description || 'Not provided'}</dd>

                <dt>Status</dt>
                <dd>
                  <span className={`badge status-${study.status}`}>{study.status}</span>
                </dd>

                <dt>Created</dt>
                <dd>{new Date(study.created_at).toLocaleDateString()}</dd>
              </dl>
            </div>

            {study.enrollmentConfig && (
              <div className="card mt-3">
                <h2>Enrollment Configuration</h2>
                <dl className="detail-list">
                  <dt>Requires Token</dt>
                  <dd>{study.enrollmentConfig.requires_token ? 'Yes' : 'No'}</dd>

                  <dt>Max Participants</dt>
                  <dd>{study.enrollmentConfig.max_participants || 'Unlimited'}</dd>

                  <dt>Current Participants</dt>
                  <dd>{study.enrollmentConfig.current_participants}</dd>
                </dl>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default StudyDetail;
