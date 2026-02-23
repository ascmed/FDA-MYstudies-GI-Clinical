// Database initialization script
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: 'postgres', // Connect to default postgres DB to create our database
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

async function initializeDatabase() {
  const client = await pool.connect();

  try {
    console.log('🔧 Initializing GI Clinical Studies database...');

    // Create database if it doesn't exist
    const dbName = process.env.DB_NAME || 'gi_clinical_studies';
    await client.query(`CREATE DATABASE IF NOT EXISTS ${dbName};`);
    console.log(`✅ Database '${dbName}' created/verified`);

    await client.end();

    // Connect to the new database and run schema
    const poolNewDb = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: dbName,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
    });

    const clientNewDb = await poolNewDb.connect();

    // Read and execute schema.sql
    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
    await clientNewDb.query(schema);
    console.log('✅ Schema tables created successfully');

    await clientNewDb.end();
    await poolNewDb.end();

    console.log('🎉 Database initialization complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    process.exit(1);
  }
}

initializeDatabase();
