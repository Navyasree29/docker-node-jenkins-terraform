const express = require("express");
const bodyParser = require("body-parser");
const app = express();

app.set("view engine", "ejs");
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

let tasks = [];

// Home Route
app.get("/", (req, res) => {
  res.render("index", { todoTasks: tasks });
});

// Add Task
app.post("/add", (req, res) => {
  const newTask = req.body.newTask;
  if (newTask.trim() !== "") {
    tasks.push(newTask);
  }
  res.redirect("/");
});

// Delete Task
app.post("/delete", (req, res) => {
  const index = req.body.index;
  tasks.splice(index, 1);
  res.redirect("/");
});

// Start Server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});
