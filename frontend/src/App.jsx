import React, { useEffect, useState } from 'react';
import SignupForm from './SignupForm';
import QuestionList from './QuestionList';
import QuestionView from './QuestionView';

export default function App() {
  const [userId, setUserId] = useState(null);

  useEffect(() => {
    console.log("effect fired");
    console.log(document.cookie);
    const match = document.cookie.match(/userId=(\d+)/);
    console.log(match);
    console.log(match ? "match" : "nomatch");
    if (match) setUserId(match[1]);
  }, []);

  if (!userId) return <SignupForm onSignup={setUserId} />;

  const path = window.location.pathname;
  if (path.startsWith("/question/")) {
    const id = path.split("/").pop();
    return <QuestionView id={id} />;
  }

  return <QuestionList />;

}
