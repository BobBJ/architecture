const express = require('express');
const app = express();
const { CosmosClient } = require('@azure/cosmos');
const cors = require('cors');

app.use(express.json());
app.use(cors({
    origin: 'https://lemon-ocean-00b9d9610.5.azurestaticapps.net'  // Allow requests from the frontend origin
}));

const client = new CosmosClient(process.env.COSMOS_CONNECTION_STRING);
const database = client.database('TodoDB');
const container = database.container('Todos');

// Get all todos
app.get('/api/todos', async (req, res) => {
    const { resources: todos } = await container.items.readAll().fetchAll();
    res.json(todos);
});

// Add a new todo
app.post('/api/todos', async (req, res) => {
    const newTodo = req.body;
    const { resource } = await container.items.create(newTodo);
    res.json(resource);
});

// Delete a todo
app.delete('/api/todos/:id', async (req, res) => {
    const id = req.params.id;
    await container.item(id, undefined).delete();
    res.sendStatus(204);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});