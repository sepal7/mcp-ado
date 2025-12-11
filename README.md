# MCP Server for Azure DevOps

A comprehensive [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that provides AI assistants with full access to Azure DevOps services.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green.svg)](https://nodejs.org/)

## 🚀 Quick Install

Easily install the MCP Server for Azure DevOps:

**VS Code with GitHub Copilot:**
[![Install in VS Code](https://img.shields.io/badge/Install-VS%20Code-blue?logo=visual-studio-code)](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)

**VS Code Insiders:**
[![Install in VS Code Insiders](https://img.shields.io/badge/Install-VS%20Code%20Insiders-purple?logo=visual-studio-code)](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)

**Cursor IDE:**
[![Install in Cursor](https://img.shields.io/badge/Install-Cursor-black?logo=cursor)](https://cursor.sh/)

See [Installation](#-installation) below for detailed setup instructions.

## 📦 Available Tools (25+)

### Wiki (3 tools)
- `get_wiki_page` - Retrieve wiki page by ID or path
- `list_wiki_pages` - List all wiki pages in a project
- `search_wiki_pages` - Search wiki pages by content or title

### Repositories (5 tools)
- `list_repos` - List all repositories
- `get_repo` - Get repository details
- `get_repo_file` - Get file content from repository
- `list_repo_branches` - List branches in a repository
- `search_code` - Search code across repositories

### Work Items (5 tools)
- `get_work_item` - Get work item by ID
- `get_work_items` - Get multiple work items
- `query_work_items` - Query work items using WIQL
- `create_work_item` - Create new work item
- `update_work_item` - Update existing work item

### Pull Requests (3 tools)
- `list_pull_requests` - List pull requests
- `get_pull_request` - Get pull request details
- `get_pr_comments` - Get PR review comments

### Builds & Pipelines (4 tools)
- `list_builds` - List recent builds
- `get_build` - Get build details
- `list_pipelines` - List pipelines
- `get_pipeline_run` - Get pipeline run details

### Releases (2 tools)
- `list_releases` - List releases
- `get_release` - Get release details

### Test Plans (2 tools)
- `list_test_plans` - List test plans
- `get_test_plan` - Get test plan details

### Generic (1 tool)
- `ado_api_call` - Make any Azure DevOps REST API call

## 🌟 Comparison with Similar Projects

| Feature | This Project | Other MCP ADO Servers |
|---------|-------------|----------------------|
| **Total Tools** | 25+ | 5-15 |
| **Wiki Support** | ✅ Yes (3 tools) | ❌ Limited/None |
| **Multi-Project** | ✅ Built-in | ❌ Single project |
| **WIQL Queries** | ✅ Yes | ❌ No |
| **Generic API Tool** | ✅ Yes | ❌ No |
| **Helper Scripts** | ✅ PAT management | ❌ No |
| **Documentation** | ✅ Comprehensive | ⚠️ Basic |

**Key Differentiators:**
- Most comprehensive tool coverage (25+ vs 5-15)
- Multi-project support without reconfiguration
- Advanced features (WIQL queries, generic API tool)
- Better developer experience (helper scripts, comprehensive docs)

## ✨ Features

- **25+ MCP Tools** covering all major Azure DevOps services
- **Multi-Project Support** - Access any project in your organization without reconfiguration
- **WIQL Query Support** - Advanced work item querying using Work Item Query Language
- **Generic API Tool** - Make any Azure DevOps REST API call for future-proof extensibility
- **Helper Scripts** - Automated PAT token management and connection testing
- **Comprehensive Documentation** - Step-by-step guides for Cursor, VS Code, and deployment

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ installed
- Azure DevOps Personal Access Token (PAT) with appropriate permissions

### Installation

```bash
# Clone the repository
git clone https://github.com/sepal7/mcp-ado.git
cd mcp-ado

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with your values:
# AZURE_DEVOPS_ORG=YourOrganization
# AZURE_DEVOPS_PROJECT=YourProject
# AZURE_DEVOPS_PAT=your_pat_token_here

# Test the connection
npm run test-connection
```

### IDE Setup

#### Cursor IDE

Add to `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "ado": {
        "command": "node",
        "args": ["C:\\path\\to\\mcp-ado\\server.js"],
        "env": {
          "AZURE_DEVOPS_ORG": "YourOrganization",
          "AZURE_DEVOPS_PROJECT": "YourProject",
          "AZURE_DEVOPS_PAT": "your_pat_token"
        }
      }
    }
  }
}
```

#### VS Code with GitHub Copilot Chat

Add to `settings.json`:

```json
{
  "chat.mcp.servers": {
    "ado": {
      "command": "node",
      "args": ["C:\\path\\to\\mcp-ado\\server.js"],
      "env": {
        "AZURE_DEVOPS_ORG": "YourOrganization",
        "AZURE_DEVOPS_PROJECT": "YourProject",
        "AZURE_DEVOPS_PAT": "your_pat_token"
      }
    }
  }
}
```

**Important:** Restart VS Code after configuration changes.

For detailed setup instructions, see:
- [Cursor Setup Guide](docs/02-CURSOR-SETUP.md)
- [VS Code Setup Guide](docs/03-VSCODE-SETUP.md)

## 🎯 Usage Examples

Once configured, use natural language to interact with Azure DevOps:

**Default Project:**
- "List all repositories"
- "Get work item #12345"
- "Show me pull requests"

**Other Projects:**
- "List repositories in the [ProjectName] project"
- "Get work items from the [ProjectName] project"

All tools support an optional `project` parameter to access any project in your organization.

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `AZURE_DEVOPS_ORG` | Yes | Your Azure DevOps organization name |
| `AZURE_DEVOPS_PROJECT` | Yes | Default project name |
| `AZURE_DEVOPS_PAT` | Yes | Personal Access Token |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | No | Optional telemetry connection string |

### Multi-Project Support

All MCP tools support an optional `project` parameter. When using Cursor or VS Code, mention the project name in your request:

```
"List repositories in the [ProjectName] project"
```

The AI assistant automatically extracts the project name and passes it to the MCP tool.

## 📁 Project Structure

```
mcp-ado/
├── server.js              # Main MCP server implementation
├── package.json           # Node.js dependencies and scripts
├── .env.example           # Environment variables template
├── README.md              # This file
│
├── docs/                  # Documentation
│   ├── 01-SETUP.md        # General setup guide
│   ├── 02-CURSOR-SETUP.md # Cursor IDE setup
│   ├── 03-VSCODE-SETUP.md # VS Code setup
│   ├── 04-PAT-MANAGEMENT.md # PAT token management
│   ├── 05-RESTART-SERVER.md # How to restart server
│   ├── 07-CHANGELOG.md     # Version history
│   └── 08-ONPREMISE-WINDOWS-IIS.md # On-premise deployment
│
├── scripts/               # Utility scripts
│   ├── test.js            # Basic server tests
│   ├── test-connection.js # Azure DevOps connection tester
│   └── update-pat.ps1     # PAT token updater script
│
└── azure/                 # Azure deployment files
    ├── README.md          # Azure deployment guide
    ├── Dockerfile         # Container image definition
    └── azure-deploy.bicep # Infrastructure as code
```

## 📚 Documentation

- [Setup Guide](docs/01-SETUP.md) - General setup and configuration
- [Cursor Setup](docs/02-CURSOR-SETUP.md) - Cursor IDE configuration
- [VS Code Setup](docs/03-VSCODE-SETUP.md) - VS Code + GitHub Copilot setup
- [PAT Management](docs/04-PAT-MANAGEMENT.md) - Managing Personal Access Tokens
- [Changelog](docs/07-CHANGELOG.md) - Version history

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Credits

- Enhanced with features from [Microsoft's official Azure DevOps MCP Server](https://github.com/mcp/microsoft/azure-devops-mcp)

---

**Made with ❤️ for the MCP community**
