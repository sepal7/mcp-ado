# Release v1.0.0 - Initial Release

## 🎉 First Public Release

This is the initial release of the MCP Server for Azure DevOps - a comprehensive Model Context Protocol server that provides AI assistants with full access to Azure DevOps services.

## 🎉 First Public Release

This is the initial release of the MCP Server for Azure DevOps - a comprehensive Model Context Protocol server that provides AI assistants with full access to Azure DevOps services.

## ✨ Features

### 25+ MCP Tools
- **Wiki** (3 tools): Get, list, and search wiki pages
- **Repositories** (5 tools): List repos, get files, branches, and search code
- **Work Items** (5 tools): Get, query, create, and update work items with WIQL support
- **Pull Requests** (3 tools): List PRs, get details, and review comments
- **Builds & Pipelines** (4 tools): List builds, pipelines, and get run details
- **Releases** (2 tools): List and get release details
- **Test Plans** (2 tools): List and get test plan details
- **Generic API Tool**: Make any Azure DevOps REST API call

### Key Highlights

- ✅ **Multi-Project Support** - Access any project in your organization without reconfiguration
- ✅ **WIQL Query Support** - Advanced work item querying using Work Item Query Language
- ✅ **Generic API Tool** - Make any Azure DevOps REST API call for future-proof extensibility
- ✅ **Comprehensive Documentation** - Step-by-step guides for Cursor, VS Code, and deployment options
- ✅ **Helper Scripts** - Automated PAT token management (`update-pat.ps1`) and connection testing

## 📦 Installation

```bash
git clone https://github.com/sepal7/mcp-ado.git
cd mcp-ado
npm install
cp .env.example .env
# Edit .env with your Azure DevOps credentials
```

## 📚 Documentation

- [Setup Guide](docs/01-SETUP.md)
- [Cursor Setup](docs/02-CURSOR-SETUP.md)
- [VS Code Setup](docs/03-VSCODE-SETUP.md)
- [PAT Management](docs/04-PAT-MANAGEMENT.md)

## 🔗 Links

- Repository: https://github.com/sepal7/mcp-ado
- Issues: https://github.com/sepal7/mcp-ado/issues

## 📄 License

MIT License

---

**Made with ❤️ for the MCP community**

