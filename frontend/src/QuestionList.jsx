import React, { useEffect, useState } from 'react';

export default function QuestionList() {
  const [questions, setQuestions] = useState([]);

  useEffect(() => {
    fetch('/api/questions')
      .then(res => res.json())
      .then(setQuestions);
  }, []);

  return (
    <div style={{ padding: '2rem' }}>
      <h2>All Questions</h2>
      <ul>
        {questions.map(q => (
          <li key={q.id}>
            <a href={`/question/${q.id}`}>
              [{q.difficulty}] {q.title}
            </a>
          </li>
        ))}
      </ul>
    </div>
  );
}
