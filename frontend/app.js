const apiUrl = '/api/todos';  // Relative path for Azure Static Web Apps

// Fetch todos
function fetchTodos() {
    fetch(apiUrl)
        .then(response => response.json())
        .then(todos => {
            const todoList = document.getElementById('todo-list');
            todoList.innerHTML = '';
            todos.forEach(todo => {
                const li = document.createElement('li');
                li.textContent = todo.text;
                li.onclick = () => deleteTodo(todo.id);
                todoList.appendChild(li);
            });
        });
}

// Add a new todo
function addTodo() {
    const newTodoInput = document.getElementById('new-todo');
    const newTodo = { text: newTodoInput.value };

    fetch(apiUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(newTodo)
    })
        .then(response => response.json())
        .then(() => {
            newTodoInput.value = '';
            fetchTodos();
        });
}

// Delete a todo
function deleteTodo(id) {
    fetch(`${apiUrl}/${id}`, {
        method: 'DELETE'
    })
        .then(() => fetchTodos());
}

// Fetch todos on page load
window.onload = fetchTodos;
