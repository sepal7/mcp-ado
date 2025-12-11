# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2025-12-11

### Changed
- Cleaned up installation instructions - removed NPX references
- Simplified installation to source-only method
- Updated documentation for clarity

## [1.0.0] - 2025-12-11

### Initial Release
- **25+ comprehensive tools** covering all Azure DevOps services:
  - Wiki: get_wiki_page, list_wiki_pages, search_wiki_pages
  - Repositories: list_repos, get_repo, get_repo_file, list_repo_branches, search_code
  - Work Items: get_work_item, get_work_items, query_work_items, create_work_item, update_work_item
  - Pull Requests: list_pull_requests, get_pull_request, get_pr_comments
  - Builds/Pipelines: list_builds, get_build, list_pipelines, get_pipeline_run
  - Releases: list_releases, get_release
  - Test Plans: list_test_plans, get_test_plan
  - Generic: ado_api_call (for any ADO REST API)
- Multi-project support
- WIQL query support
- Helper scripts for PAT management
- Comprehensive documentation

