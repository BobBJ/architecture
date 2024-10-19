const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Configure AWS SDK
AWS.config.update({ region: 'us-east-1' });  // Update to your region
const dynamoDb = new AWS.DynamoDB.DocumentClient();
const tableName = process.env.TABLE_NAME || 'TodoTable';

// Get all todos
app.get('/api/todos', async (req, res) => {
    const params = {
        TableName: tableName
    };
    try {
        const data = await dynamoDb.scan(params).promise();
        res.json(data.Items);
    } catch (error) {
        res.status(500).json({ error: 'Could not load todos' });
    }
});

// Add a new todo
app.post('/api/todos', async (req, res) => {
    const newTodo = {
        id: Date.now().toString(),
        text: req.body.text
    };
    const params = {
        TableName: tableName,
        Item: newTodo
    };
    try {
        await dynamoDb.put(params).promise();
        res.json(newTodo);
    } catch (error) {
        res.status(500).json({ error: 'Could not create todo' });
    }
});

// Delete a todo
app.delete('/api/todos/:id', async (req, res) => {
    const params = {
        TableName: tableName,
        Key: {
            id: req.params.id
        }
    };
    try {
        await dynamoDb.delete(params).promise();
        res.sendStatus(204);
    } catch (error) {
        res.status(500).json({ error: 'Could not delete todo' });
    }
});

module.exports = app;