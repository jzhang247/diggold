import React, { useEffect, useState } from 'react';

export default function QuestionView({ id }) {
  const [question, setQuestion] = useState(null);

  useEffect(() => {
    fetch(`/api/questions/${id}`)
      .then(res => res.json())
      .then(setQuestion);
  }, [id]);

  const [response, setResponse] = useState('');
  const [language, setLanguage] = useState('JavaScript');
  const [submissions, setSubmissions] = useState([]);

  const submit = async () => {
    await fetch(`/api/questions/${id}/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ response, language })
    });
    loadSubmissions(); // reload after submit
  };

  const loadSubmissions = () => {
    fetch(`/api/questions/${id}/submissions`)
      .then(res => res.json())
      .then(setSubmissions);
  };

  useEffect(() => {
    loadSubmissions();
  }, [id]);

  if (!question) return <p>Loading...</p>;

  return (
    <div style={{ padding: '2rem' }}>
      <a href="/question">← Back to list</a>
      <h3>[{question.difficulty}]{question.title}</h3>
      <p>{question.body}</p>
      <h4>For dev</h4>
      <p>{question.answer}</p>
      <p>{question.testcases}</p>

      <h3>To make your submission</h3>
      <select value={language} onChange={e => setLanguage(e.target.value)}>
        <option value="JavaScript">JavaScript</option>
        <option value="cpp23">cpp23</option>
        <option value="python">python</option>
      </select>
      <br />
      <textarea
        rows={50}
        style={{ width: '100%' }}
        value={response}
        onChange={e => setResponse(e.target.value)}
      />
      <br />
      <button onClick={submit}>Submit</button>

      <h3>Recent Submissions</h3>
      <ul>
        {submissions.map(sub => (
          <li key={sub.id}>
            [{sub.language}] Status: {sub.status}, Time: {sub.time_used_msec ?? '---'}ms, Failed: {sub.nfailed}
          </li>
        ))}
      </ul>
    </div>
  );
}
