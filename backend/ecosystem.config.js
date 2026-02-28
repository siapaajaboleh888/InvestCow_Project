module.exports = {
    apps: [
        {
            name: 'investcow-api',
            script: 'src/server.js',
            instances: 'max', // Use maximum CPU cores
            exec_mode: 'cluster',
            autorestart: true,
            watch: false,
            max_memory_restart: '1G',
            env: {
                NODE_ENV: 'development',
            },
            env_production: {
                NODE_ENV: 'production',
                PORT: 8081,
            },
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            error_file: 'logs/pm2-error.log',
            out_file: 'logs/pm2-out.log',
            combine_logs: true,
            merge_logs: true,
        },
    ],
};
