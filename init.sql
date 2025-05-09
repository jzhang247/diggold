

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    nickname VARCHAR(127) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO users (email, nickname) VALUES ('admin@example.com', 'admin');

CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,    
    difficulty ENUM('Easy', 'Medium', 'Hard') NOT NULL,    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    body TEXT NOT NULL,
    answer TEXT NOT NULL,
    testcases TEXT NOT NULL,
    time_allowed_msec INT DEFAULT(5000)
);

INSERT INTO questions (title, difficulty, body, answer, testcases) VALUES 
("Two sum",   'Easy',   "returns the sum of two integers",   " (a, b)=>{return a+b;}",           "[[1,3],[2,4],[1,1]]"),
("Three sum", 'Medium', "returns the sum of three integers", " (a, b, c)=>{return a+b+c;}",      "[[1,3,5],[2,4,6]]"),
("Four sum",  'Hard',   "returns the sum of four integers",  " (a, b, c, d)=>{return a+b+c+d;}", "[[1,3,5,6],[2,4,6,10000000000000000]]");


CREATE TABLE submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    question_id INT NOT NULL,
    user_id INT NOT NULL,
    response TEXT NOT NULL,
    language VARCHAR(50) NOT NULL,
    status ENUM('INQUEUE', 'JUDGING', 'PASSED', 'WRONG_ANSWER', "TIMEOUT", "SERVER_ERROR") NOT NULL,
    nfailed INT NOT NULL,
    time_used_msec INT DEFAULT NULL
);