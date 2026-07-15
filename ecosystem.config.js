module.exports = {
  apps: [
    {
      name: "ferfit",
      script: "dist/index.js",
      cwd: __dirname,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },
      instances: 1,
      autorestart: true,
      max_memory_restart: "500M",
    },
  ],
};
