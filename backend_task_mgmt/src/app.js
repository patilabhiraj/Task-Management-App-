
// const express = require("express");
// const cors = require("cors");

// const authRoutes = require("./routes/authRoutes");
// const taskRoutes = require("./routes/taskRoutes");

// const app = express();

// app.use(cors());
// app.use(express.json());

// // public route
// app.use("/api", authRoutes);

// // protected routes
// app.use("/api", taskRoutes);

// module.exports = app;
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const taskRoutes = require("./routes/taskRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", authRoutes);
app.use("/api", taskRoutes);

module.exports = app;
