import { app } from "./app";
import { env } from "./config/env";

app.listen(Number(env.port), () => {
  console.log(`Server is running on http://localhost:${env.port}`);
});