import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import axios from 'axios';
import './StudyBuilder.css';

function StudyBuilder() {
  const { studyId } = useParams();
  const [study, setStudy] = useState(null);
  const [activeTab, setActiveTab] = useState('surveys');
  const [surveys, setSurveys] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showSurveyForm, setShowSurveyForm] = useState(false);
  const [surveyForm, setSurveyForm] = useState({
    title: '',
    description: '',
    surveyType: 'baseline',
    frequency: 'weekly',
  });
  const [consentForm, setConsentForm] = useState({
    title: '',
    content: '',
    requiresSignature: true,
  });

  useEffect(() => {
    fetchStudyData();
  }, [studyId]);

  const fetchStudyData = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`/api/studies/${studyId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setStudy(response.data);
      setSurveys(response.data.surveys || []);
      if (response.data.consentForm) {
        setConsentForm({
          title: response.data.consentForm.title || '',
          content: response.data.consentForm.content || '',
          requiresSignature: response.data.consentForm.requires_signature,
        });
      }
      setError('');
    } catch (error) {
      setError('Failed to fetch study data');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSurvey = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      const response = await axios.post(
        '/api/surveys',
        {
          studyId,
          ...surveyForm,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      setSurveys([...surveys, response.data.survey]);
      setShowSurveyForm(false);
      setSurveyForm({
        title: '',
        description: '',
        surveyType: 'baseline',
        frequency: 'weekly',
      });
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to create survey');
    }
  };

  const handleSaveConsent = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      await axios.post(
        '/api/consent',
        {
          studyId,
          ...consentForm,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      setError('');
      alert('Consent form saved successfully');
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to save consent form');
    }
  };

  if (loading) {
    return (
      <div className="study-builder-loading">
        <div className="loading" />
      </div>
    );
  }

  if (!study) {
    return <div className="alert alert-error">Study not found</div>;
  }

  return (
    <div className="study-builder">
      <div className="builder-header">
        <h1>Study Builder: {study.title}</h1>
        <p className="study-id">{study.study_id}</p>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      <div className="builder-tabs">
        <button
          className={`tab-btn ${activeTab === 'surveys' ? 'active' : ''}`}
          onClick={() => setActiveTab('surveys')}
        >
          Surveys
        </button>
        <button
          className={`tab-btn ${activeTab === 'consent' ? 'active' : ''}`}
          onClick={() => setActiveTab('consent')}
        >
          Consent Form
        </button>
        <button
          className={`tab-btn ${activeTab === 'enrollment' ? 'active' : ''}`}
          onClick={() => setActiveTab('enrollment')}
        >
          Enrollment
        </button>
      </div>

      <div className="tab-content">
        {activeTab === 'surveys' && (
          <div className="surveys-builder">
            <div className="section-header">
              <h2>Survey Management</h2>
              <button
                className="btn-primary"
                onClick={() => setShowSurveyForm(!showSurveyForm)}
              >
                {showSurveyForm ? 'Cancel' : '+ Add Survey'}
              </button>
            </div>

            {showSurveyForm && (
              <div className="card form-card">
                <h3>Create New Survey</h3>
                <form onSubmit={handleCreateSurvey}>
                  <div className="form-group">
                    <label>Survey Title</label>
                    <input
                      type="text"
                      value={surveyForm.title}
                      onChange={(e) =>
                        setSurveyForm({ ...surveyForm, title: e.target.value })
                      }
                      placeholder="e.g., Weekly Symptom Check"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>Description</label>
                    <textarea
                      value={surveyForm.description}
                      onChange={(e) =>
                        setSurveyForm({ ...surveyForm, description: e.target.value })
                      }
                      placeholder="Survey description"
                      rows="3"
                    />
                  </div>

                  <div className="form-row">
                    <div className="form-group">
                      <label>Type</label>
                      <select
                        value={surveyForm.surveyType}
                        onChange={(e) =>
                          setSurveyForm({ ...surveyForm, surveyType: e.target.value })
                        }
                      >
                        <option value="baseline">Baseline</option>
                        <option value="weekly">Weekly</option>
                        <option value="monthly">Monthly</option>
                        <option value="follow_up">Follow-up</option>
                      </select>
                    </div>

                    <div className="form-group">
                      <label>Frequency</label>
                      <select
                        value={surveyForm.frequency}
                        onChange={(e) =>
                          setSurveyForm({ ...surveyForm, frequency: e.target.value })
                        }
                      >
                        <option value="one_time">One time</option>
                        <option value="weekly">Weekly</option>
                        <option value="bi_weekly">Bi-weekly</option>
                        <option value="monthly">Monthly</option>
                      </select>
                    </div>
                  </div>

                  <button type="submit" className="btn-primary">
                    Create Survey
                  </button>
                </form>
              </div>
            )}

            {surveys.length === 0 ? (
              <div className="empty-state">
                <p>No surveys created yet. Add one to get started.</p>
              </div>
            ) : (
              <div className="surveys-list">
                {surveys.map((survey) => (
                  <div key={survey.id} className="card survey-item">
                    <h3>{survey.title}</h3>
                    <p>{survey.description}</p>
                    <div className="survey-meta">
                      <span>{survey.survey_type}</span>
                      <span>{survey.frequency}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'consent' && (
          <div className="consent-builder">
            <h2>Informed Consent Form</h2>
            <form onSubmit={handleSaveConsent} className="card">
              <div className="form-group">
                <label>Consent Form Title</label>
                <input
                  type="text"
                  value={consentForm.title}
                  onChange={(e) =>
                    setConsentForm({ ...consentForm, title: e.target.value })
                  }
                  placeholder="e.g., Study Informed Consent"
                />
              </div>

              <div className="form-group">
                <label>Consent Form Content</label>
                <textarea
                  value={consentForm.content}
                  onChange={(e) =>
                    setConsentForm({ ...consentForm, content: e.target.value })
                  }
                  placeholder="Paste your full consent form text here..."
                  rows="12"
                />
              </div>

              <div className="form-group">
                <label>
                  <input
                    type="checkbox"
                    checked={consentForm.requiresSignature}
                    onChange={(e) =>
                      setConsentForm({
                        ...consentForm,
                        requiresSignature: e.target.checked,
                      })
                    }
                  />
                  Require E-Signature
                </label>
              </div>

              <button type="submit" className="btn-primary">
                Save Consent Form
              </button>
            </form>
          </div>
        )}

        {activeTab === 'enrollment' && (
          <div className="enrollment-builder">
            <h2>Enrollment Configuration</h2>
            <div className="card">
              <p>Enrollment tokens and configuration coming soon...</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default StudyBuilder;
