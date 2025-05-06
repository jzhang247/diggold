import React, { useEffect, useState } from 'react';
import SignupForm from './SignupForm';
import QuestionList from './QuestionList';
import QuestionView from './QuestionView';

export default function App() {
  const [userId, setUserId] = useState(null);

  useEffect(() => {
    const match = document.cookie.match(/userId=(\d+)/);
    if (match) setUserId(match[1]);
  }, []);

  if (!userId) return <SignupForm onLogin={setUserId} />;

  const path = window.location.pathname;
  if (path.startsWith("/question/")) {
    const id = path.split("/").pop();
    return <QuestionView id={id} />;
  }

  return <QuestionList />;

}
