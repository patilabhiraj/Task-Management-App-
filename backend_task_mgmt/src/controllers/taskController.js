const { tasks } = require("../data/db");

exports.getTasks = (req, res) => {
  res.json(tasks);
};

exports.updateTask = (req, res) => {
  const { id } = req.params;
  const { status, remarks } = req.body;

  const task = tasks.find((t) => t.id === id);

  if (!task) {
    return res.status(404).json({ message: "Task not found" });
  }

  task.status = status;
  task.remarks = remarks;
  task.updatedAt = new Date();

  res.json({ message: "Task updated", task });
};
