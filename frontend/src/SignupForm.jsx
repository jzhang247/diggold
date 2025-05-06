import React, { useState } from 'react';

export default function SignupForm({ onLogin }) {
  const [email, setEmail] = useState('');
  const [nickname, setNickname] = useState('');
  const [error, setError] = useState(null);

  const signup = async () => {
    setError(null);
    try {
      const res = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, nickname }),
      });
      const data = await res.json();
      if (res.ok) onLogin(data.userId);
      else setError(data.error || 'Signup failed');
    } catch (e) {
      setError('Network error');
    }
  };
  const login = async () => {
    setError(null);
    try {
      const res = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nickname }),
      });
      const data = await res.json();
      if (res.ok) onLogin(data.userId);
      else setError(data.error || 'Login failed');
    } catch (e) {
      setError('Network error');
    }
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h2>Sign up</h2>
      <input placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} />
      <input placeholder="Nickname" value={nickname} onChange={e => setNickname(e.target.value)} />

      <button onClick={signup}>Signup</button>
      <button onClick={login}>Login</button>

      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
