
const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authMiddelware");

const {
  getTasks,
  updateTask,
} = require("../controllers/taskController");

router.get("/tasks", verifyToken, getTasks);
router.put("/tasks/:id", verifyToken, updateTask);

module.exports = router;
