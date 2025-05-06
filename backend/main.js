const { createClient } = require('redis');
const redisClient = createClient({
  url: 'redis://redis:6379'
});
redisClient.on('error', (err) => console.error('Redis error:', err));

require('dotenv').config();
const mysql = require('mysql2/promise');
const mysqlPool = mysql.createPool({
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const app = express();

app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.get('/api/hello', (req, res) => {
  res.send('Hello, world! Ver2\n');
});

// LOGIN SIGNUP
// app.get('/api/users/emails', async (req, res) => {
//   try {
//     // const pool = req.app.locals.pool;
//     const [rows] = await mysqlPool.query('SELECT * FROM users');

//     const emails = rows.map(row => row.email);
//     res.json({ emails });
//   } catch (err) {
//     console.error('Error fetching user emails:', err.message);
//     res.status(500).json({ error: 'Internal Server Error' });
//   }
// });

const defaultCookieAttr = {
  path: '/',
  maxAge: 1000 * 60 * 60 * 24 * 30,
  httpOnly: false,
  secure: false,
  sameSite: 'lax'
};

app.post('/api/signup', async (req, res) => {
  const { email, nickname } = req.body;
  if (!email || !nickname) return res.status(400).json({ error: 'email and nickname required' });

  try {
    const [result] = await mysqlPool.query(
      'INSERT INTO users (email, nickname) VALUES (?, ?)',
      [email, nickname]
    );
    const userId = result.insertId;
    res.cookie('userId', userId, defaultCookieAttr);
    res.json({ success: true, userId });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') {
      res.status(409).json({ error: 'Email or nickname already used' });
    } else {
      res.status(500).json({ error: 'Internal error' });
    }
  }
});

app.post('/api/login', async (req, res) => {
  const { nickname } = req.body;

  if (!nickname) return res.status(400).json({ error: 'nickname required' });

  const [rows] = await mysqlPool.query('SELECT * FROM users WHERE nickname = ?', [nickname]);
  if (rows.length === 0) return res.status(404).json({ error: 'User not found' });

  res.cookie('userId', rows[0].id, defaultCookieAttr);
  res.json({ success: true, userId });
});



app.get('/api/questions', async (req, res) => {
  const [rows] = await mysqlPool.query('SELECT * FROM questions');
  res.json(rows);
});
app.get('/api/questions/:id', async (req, res) => {
  const [rows] = await mysqlPool.query('SELECT * FROM questions WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});


app.post('/api/questions/:id/submit', async (req, res) => {
  const userId = req.cookies.userId;
  const { answer, language } = req.body;
  const questionId = parseInt(req.params.id);

  if (!userId || !answer || !language) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const [result] = await mysqlPool.query(
    `INSERT INTO submissions (question_id, user_id, answer, language, status, nfailed, time_used_msec)
     VALUES (?, ?, ?, ?, 'INQUEUE', 0, NULL)`,
    [questionId, userId, answer, language]
  );

  const submissionId = result.insertId;

  const QUEUE_NAME = 'SQ';
  await redisClient.rPush(QUEUE_NAME, submissionId.toString());

  res.json({ success: true, submissionId });
});

app.get('/api/questions/:id/submissions', async (req, res) => {
  const userId = req.cookies.userId;
  const questionId = parseInt(req.params.id);

  const [rows] = await mysqlPool.query(
    `SELECT id, language, status, nfailed, time_used_msec, created_at
     FROM submissions
     WHERE user_id = ? AND question_id = ?
     ORDER BY id DESC`,
    [userId, questionId]
  );

  res.json(rows);
});

(async () => {
  await redisClient.connect();

  const port = 3000;
  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
  });
})();

