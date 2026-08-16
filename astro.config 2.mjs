import { defineConfig } from "astro/config";
import cloudflare from "@astrojs/cloudflare";

export default defineConfig({
  output: "server",
  adapter: cloudflare(),
  vite: {
    server: {
      host: "0.0.0.0",
      allowedHosts: ["terminal.local"],
    },
  },
});
