# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-01-27

### Added
- **25+ comprehensive tools** covering all Azure DevOps services:
  - Wiki: get_wiki_page, list_wiki_pages, search_wiki_pages
  - Repositories: list_repos, get_repo, get_repo_file, list_repo_branches, search_code
  - Work Items: get_work_item, get_work_items, query_work_items, create_work_item, update_work_item
  - Pull Requests: list_pull_requests, get_pull_request, get_pr_comments
  - Builds/Pipelines: list_builds, get_build, list_pipelines, get_pipeline_run
  - Releases: list_releases, get_release
  - Test Plans: list_test_plans, get_test_plan
  - Generic: ado_api_call (for any ADO REST API)

### Enhanced
- Enhanced with features from Microsoft's official Azure DevOps MCP Server
- Improved error handling and response formatting
- Better parameter validation
- Support for expand options in work items
- Support for include options in pull requests

### Azure Deployment
- Optimized for team sharing (deploy once, everyone uses it)
- Scales to zero when not in use (cost optimization)
- Max 2 replicas for team sharing
- External ingress option for direct HTTP access
- Comprehensive deployment scripts and Bicep templates

### Documentation
- Updated README with comprehensive feature list
- Added team sharing instructions
- Enhanced SETUP.md with Azure deployment guide
- Added cost monitoring commands

## [1.0.0] - 2025-01-27

### Initial Release
- Basic MCP server for Azure DevOps
- Wiki, Repository, Work Item, PR, Build tools
- Generic API call tool
- Azure deployment automation
- Cost-optimized for Visual Studio credits

