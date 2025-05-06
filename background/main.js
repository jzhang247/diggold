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


(async () => {
    await redisClient.connect();

    const QUEUE_NAME = 'SQ';
    while (true) {
        const submissionId = await redisClient.lPop(QUEUE_NAME);
        if (submissionId === null) {
            await new Promise(resolve => setTimeout(resolve, 500)); // slight wait
            continue;
        }

        console.log("Judging ", submissionId);        

        try {
            // 1. Load submission + question
            const [[submission]] = await mysqlPool.query(
                `SELECT s.id, s.answer, q.body, q.testcases, q.time_allowed_msec
             FROM submissions s
             JOIN questions q ON s.question_id = q.id
             WHERE s.id = ?`,
                [submissionId]
            );

            if (!submission) {
                console.error(`Submission ${submissionId} not found`);
                continue;
            }

            const { answer, body, testcases, time_allowed_msec } = submission;

            // 2. Parse testcases (assume it's a JSON array of strings)
            let tests;
            try {
                tests = JSON.parse(testcases);
                if (!Array.isArray(tests)) throw new Error();
            } catch {
                console.error(`Invalid testcases in question for submission ${submissionId}`);
                await mysqlPool.query(
                    `UPDATE submissions SET status = 'FAILED', nfailed = 0 WHERE id = ?`,
                    [submissionId]
                );
                continue;
            }

            // 3. Dummy judge logic
            let failed = 0;
            const start = Date.now();

            for (let test of tests) {
                console.log(test.toString().length, test.toString());
                const pass = answer.length > (body.length + test.toString().length);
                if (!pass) failed++;
            }

            const duration = Date.now() - start;

            const finalStatus = failed === 0 ? 'PASSED' : 'FAILED';

            // 4. Update DB
            await mysqlPool.query(
                `UPDATE submissions
             SET status = ?, nfailed = ?, time_used_msec = ?
             WHERE id = ?`,
                [finalStatus, failed, duration, submissionId]
            );

            console.log(`Judged submission ${submissionId}: ${finalStatus}`);
        } catch (err) {
            console.error(`Error judging submission ${submissionId}:`, err);
        }
    }

})();



