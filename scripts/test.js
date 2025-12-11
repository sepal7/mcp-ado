#!/usr/bin/env node

/**
 * Test script for MCP ADO Server
 */

import dotenv from 'dotenv';
import axios from 'axios';

dotenv.config();

const AZURE_DEVOPS_ORG = process.env.AZURE_DEVOPS_ORG || 'YourOrganization';
const AZURE_DEVOPS_PROJECT = process.env.AZURE_DEVOPS_PROJECT || 'Integration';
const AZURE_DEVOPS_PAT = process.env.AZURE_DEVOPS_PAT;

if (!AZURE_DEVOPS_PAT) {
  console.error('Error: AZURE_DEVOPS_PAT environment variable is required');
  process.exit(1);
}

const ADO_BASE_URL = `https://dev.azure.com/${AZURE_DEVOPS_ORG}/${AZURE_DEVOPS_PROJECT}/_apis`;
const authHeader = Buffer.from(`:${AZURE_DEVOPS_PAT}`).toString('base64');

async function testApiCall(endpoint, description) {
  console.log(`\n🧪 Testing: ${description}...`);
  
  try {
    const url = `${ADO_BASE_URL}${endpoint}?api-version=7.1`;
    const response = await axios.get(url, {
      headers: {
        Authorization: `Basic ${authHeader}`,
        'Content-Type': 'application/json',
      },
    });
    
    console.log('✅ Success!');
    if (response.data.value) {
      console.log(`   Found ${response.data.count || response.data.value.length} items`);
    }
    return true;
  } catch (error) {
    console.error('❌ Error:', error.response?.status, error.response?.statusText);
    if (error.response?.data?.message) {
      console.error('   Message:', error.response.data.message);
    }
    return false;
  }
}

async function runTests() {
  console.log('🚀 Starting MCP ADO Server Tests...');
  console.log(`   Org: ${AZURE_DEVOPS_ORG}`);
  console.log(`   Project: ${AZURE_DEVOPS_PROJECT}`);
  
  const tests = [
    { endpoint: '/git/repositories', desc: 'List Repositories' },
    { endpoint: '/wiki/wikis', desc: 'List Wikis' },
    { endpoint: '/wit/wiql', desc: 'Work Items API (WIQL endpoint)' },
  ];
  
  const results = [];
  for (const test of tests) {
    const result = await testApiCall(test.endpoint, test.desc);
    results.push({ name: test.desc, passed: result });
  }
  
  console.log('\n📊 Test Results:');
  results.forEach(r => {
    console.log(`   ${r.name}: ${r.passed ? '✅ PASS' : '❌ FAIL'}`);
  });
  
  const allPassed = results.every(r => r.passed);
  if (allPassed) {
    console.log('\n🎉 All tests passed!');
    process.exit(0);
  } else {
    console.log('\n⚠️  Some tests failed. Please check your PAT permissions.');
    process.exit(1);
  }
}

runTests();
