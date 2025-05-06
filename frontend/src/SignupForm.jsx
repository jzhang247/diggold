import React, { useState } from 'react';

export default function SignupForm({ onSignup }) {
  const [email, setEmail] = useState('');
  const [nickname, setNickname] = useState('');
  const [error, setError] = useState(null);

  const submit = async () => {
    setError(null);
    try {
      const res = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, nickname }),
      });
      const data = await res.json();
      if (res.ok) onSignup(data.userId);
      else setError(data.error || 'Signup failed');
    } catch (e) {
      setError('Network error');
    }
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h2>Sign up</h2>
      <input placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} />
      <input placeholder="Nickname" value={nickname} onChange={e => setNickname(e.target.value)} />
      <button onClick={submit}>Submit</button>
      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
