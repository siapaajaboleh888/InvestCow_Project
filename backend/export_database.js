const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function exportDatabase() {
    const config = {
        host: process.env.DB_HOST || '127.0.0.1',
        port: Number(process.env.DB_PORT || 3306),
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'investcow_app'
    };

    console.log(`--- 📦 InvestCow Database Exporter ---`);
    console.log(`Connecting to: ${config.host}:${config.port} (${config.database})...`);

    const connection = await mysql.createConnection(config);

    try {
        let sqlDump = `-- InvestCow Final Production Export\n-- Generated on: ${new Date().toISOString()}\n\n`;
        sqlDump += `SET NAMES utf8mb4;\n`;
        sqlDump += `SET FOREIGN_KEY_CHECKS = 0;\n`;
        sqlDump += `SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";\n\n`;

        // Get all tables
        const [tables] = await connection.query('SHOW TABLES');
        const tableNames = tables.map(t => Object.values(t)[0]);

        // Prioritize parent tables to avoid any possible constraint issues
        const priorityTables = ['users', 'products', 'portfolios'];
        const otherTables = tableNames.filter(t => !priorityTables.includes(t));
        const sortedTables = [...priorityTables.filter(t => tableNames.includes(t)), ...otherTables];

        for (const tableName of sortedTables) {
            console.log(`- Exporting table: ${tableName}`);

            // Get Create Table syntax
            const [createRows] = await connection.query(`SHOW CREATE TABLE \`${tableName}\``);
            sqlDump += `DROP TABLE IF EXISTS \`${tableName}\`;\n`;
            sqlDump += `${createRows[0]['Create Table']};\n\n`;

            // Get Data
            const [rows] = await connection.query(`SELECT * FROM \`${tableName}\``);
            if (rows.length > 0) {
                const columns = Object.keys(rows[0]).map(c => `\`${c}\``).join(', ');
                const values = rows.map(row => {
                    const rowValues = Object.values(row).map(val => {
                        if (val === null) return 'NULL';
                        if (typeof val === 'string') return `'${val.replace(/'/g, "''")}'`;
                        if (val instanceof Date) return `'${val.toISOString().slice(0, 19).replace('T', ' ')}'`;
                        if (Buffer.isBuffer(val)) return `0x${val.toString('hex')}`;
                        return val;
                    });
                    return `(${rowValues.join(', ')})`;
                }).join(',\n');

                sqlDump += `INSERT INTO \`${tableName}\` (${columns}) VALUES \n${values};\n\n`;
            }
        }

        sqlDump += `SET FOREIGN_KEY_CHECKS = 1;\n`;

        const filename = 'InvestCow_Final_DB_Ready.sql';
        const filepath = path.join(__dirname, filename);
        fs.writeFileSync(filepath, sqlDump);

        console.log(`\n✅ BERHASIL! File backup BARU dibuat: ${filename}`);
        console.log(`Lokasi: ${filepath}`);
        console.log(`--- Silakan IMPORT file ini ke phpMyAdmin Hostinger (Gunakan TAB SQL) ---`);

    } catch (err) {
        console.error(`\n❌ GAGAL eksport:`, err.message);
    } finally {
        await connection.end();
    }
}

exportDatabase();
