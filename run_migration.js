const fs = require('fs');
const { Client } = require('pg');

const run = async () => {
  const sql = fs.readFileSync('supabase/migrations/20260615134015_seed_courses_table.sql', 'utf8');

  const regions = [
    'eu-west-1',
    'us-east-1',
    'eu-west-2',
    'eu-central-1',
    'us-west-1',
    'us-west-2',
    'ap-southeast-1',
    'ap-northeast-1',
    'ap-south-1',
    'ap-southeast-2',
    'sa-east-1',
    'ca-central-1'
  ];

  for (const region of regions) {
    const connectionString = `postgresql://postgres.qqvzklonfybticckpuvx:Maumau297!@aws-0-${region}.pooler.supabase.com:6543/postgres`;
    const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
    
    try {
      console.log(`Trying ${region}...`);
      await client.connect();
      console.log(`Connected successfully on region: ${region}`);
      console.log('Running SQL...');
      await client.query(sql);
      console.log('SQL Executed successfully!');
      process.exit(0);
    } catch (e) {
      console.log(`Failed on ${region}:`, e.message);
    }
  }
  
  console.log('All regions failed.');
  process.exit(1);
};

run();
