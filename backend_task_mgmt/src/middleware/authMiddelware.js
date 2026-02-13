const jwt = require("jsonwebtoken");
const { JWT_SECRET } = require("../config/config");

module.exports = (req, res, next) => {
  const header = req.header("Authorization");

  if (!header) {
    return res.status(401).json({ message: "Access denied. No token." });
  }

  const token = header.split(" ")[1]; 

  try {
    const verified = jwt.verify(token, JWT_SECRET);
    req.user = verified;
    next();
  } catch (err) {
    res.status(400).json({ message: "Invalid token" });
  }
};
