#!/usr/bin/env node

/**
 * Quick test script to verify Azure DevOps connection
 * Run: node test-connection.js
 */

import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const AZURE_DEVOPS_ORG = process.env.AZURE_DEVOPS_ORG || 'YourOrganization';
const AZURE_DEVOPS_PROJECT = process.env.AZURE_DEVOPS_PROJECT || 'YourProject';
const AZURE_DEVOPS_PAT = process.env.AZURE_DEVOPS_PAT;

if (!AZURE_DEVOPS_PAT) {
  console.error('❌ Error: AZURE_DEVOPS_PAT not found in .env file');
  process.exit(1);
}

const authHeader = Buffer.from(`:${AZURE_DEVOPS_PAT}`).toString('base64');
const baseUrl = `https://dev.azure.com/${AZURE_DEVOPS_ORG}/${AZURE_DEVOPS_PROJECT}/_apis`;

console.log('🔍 Testing Azure DevOps connection...\n');
console.log(`Organization: ${AZURE_DEVOPS_ORG}`);
console.log(`Project: ${AZURE_DEVOPS_PROJECT}`);
console.log(`PAT Token: ${AZURE_DEVOPS_PAT.substring(0, 10)}...${AZURE_DEVOPS_PAT.substring(AZURE_DEVOPS_PAT.length - 5)}\n`);

// Test 1: Get project info
try {
  console.log('Test 1: Getting project information...');
  const response = await axios.get(`${baseUrl}/projects/${AZURE_DEVOPS_PROJECT}`, {
    headers: {
      Authorization: `Basic ${authHeader}`,
    },
    params: {
      'api-version': '7.1',
    },
  });
  
  console.log('✅ Project connection successful!');
  console.log(`   Project Name: ${response.data.name}`);
  console.log(`   Project ID: ${response.data.id}\n`);
} catch (error) {
  if (error.response?.status === 401) {
    console.error('❌ Authentication failed - PAT token is invalid or expired');
    console.error('\n📝 To fix this:');
    console.error(`1. Generate a new PAT at: https://dev.azure.com/${AZURE_DEVOPS_ORG}/_usersSettings/tokens`);
    console.error('2. Run: .\\update-pat.ps1 -NewPAT "your_new_token"');
    console.error('3. Restart Cursor/VS Code\n');
  } else {
    console.error(`❌ Error: ${error.message}`);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Details: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
  process.exit(1);
}

// Test 2: Get a work item (if available)
try {
  console.log('Test 2: Testing work item access...');
  const response = await axios.get(`${baseUrl}/wit/workitems/481154`, {
    headers: {
      Authorization: `Basic ${authHeader}`,
    },
    params: {
      'api-version': '7.1',
      '$expand': 'all',
    },
  });
  
  console.log('✅ Work item access successful!');
  console.log(`   Work Item ID: ${response.data.id}`);
  console.log(`   Title: ${response.data.fields['System.Title']}`);
  console.log(`   Type: ${response.data.fields['System.WorkItemType']}\n`);
} catch (error) {
  if (error.response?.status === 401) {
    console.error('❌ Authentication failed - PAT token is invalid or expired');
  } else if (error.response?.status === 404) {
    console.log('⚠️  Work item 481154 not found (this is OK - token is valid)');
  } else {
    console.error(`⚠️  Could not access work item: ${error.message}`);
  }
}

console.log('✅ Connection test completed!');
console.log('\n💡 If you see errors above, update your PAT token using:');
console.log('   .\\update-pat.ps1 -NewPAT "your_new_token"');

