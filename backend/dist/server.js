"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const env_1 = require("./config/env");
app_1.app.listen(Number(env_1.env.port), () => {
    console.log(`Server is running on http://localhost:${env_1.env.port}`);
});
