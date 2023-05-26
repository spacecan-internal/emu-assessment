# Shell
​
## Problem Statement
​
### Mid Term/Strategic ⭐
​
Shell is evaluating to migrate from GitHub Enterprise Cloud (GHEC) to GitHub Enterprise Cloud with Enterprise Managed (GHEC+EMU) Users, using the [GitHub Enterprise Importer](https://docs.github.com/en/enterprise-cloud@latest/migrations/using-github-enterprise-importer).
​
As part of this evaluation, Shell needs to understand the current state of the GitHub Enterprise Cloud organizations and their repositories.
​
Currently, the data documented at https://docs.github.com/en/enterprise-cloud@latest/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/migration-support-for-github-enterprise-importer#githubcom-migration-support is not migrated.
​
To ensure that Shell can evaluate the impact of this migration to GHEC+EMU, they are asking us to assist them in reporting their current GitHub Enterprise Cloud organizations (7 today) to determine the current state of each organization including all repositories.
​
### Immediate ��
​
Shell wants to change SAML/SSO from individual organizations to GitHub Enterprise Cloud level.
​
To ensure that Shell can evaluate the impact of this change, they are asking us to assist them in reporting their current GitHub Enterprise Cloud organizations (7 today) to determine the current state of each organization including all repositories.
​
## Requirements
​
Create a script that will query a given GitHub Enterprise Cloud organization and report on the following:
​
```[tasklist]
### Organization level
​
- [x] List of webhooks ⭐
- [x] List of GitHub Secrets (GitHub Actions, GitHub Codespaces, @dependabot) ⭐ 🛑
- [x] List of GitHub Apps installed at the organization level ⭐
- [-] List of OAuth Apps installed at the organization level ⭐ 🛑
- [x] List of Projects (Classic) ⭐
- [x] List of Projects (Next) ⭐
- [x] List of GitHub Packages ⭐
```
​
```[tasklist]
### Repository level
​
- [x] List of repositories' visibility ⭐ 🛑
- [x] List of forked repositories ⭐
- [x] List of webhooks ⭐
- [x] List of GitHub Secrets (GitHub Actions, GitHub Codespaces, @dependabot) ⭐ 🛑
- [x] List of GitHub Actions environments (name, secrets, protection rules, ...) ⭐ 🛑
- [-] List of GitHub Apps installed at the repository level ⭐
- [x] List of discussions ⭐
- [x] List of user access to the repositories (teams, direct users) ⭐
- [x] List of branch protection rules (branch name, required status checks, required pull request reviews, required linear history, required commit signatures, required commit message, restrictions, ...) ⭐
- [?] List of GitHub Packages ⭐
- [-] List of GitHub Actions used in the repository workflows 🛑 (optional)
- [?] List of GitHub Actions workflow runs (path, last executed times) 🛑
- [-] List of GitHub Actions workflows using `schedule` events (path, cron, last executed times) 🛑 (optional)
- [x] List of LFS usage 🛑
```
​
### Info
​
The script should
​
- be able to be run via GitHub Actions and/or IssueOps.
- be capable of being run against multiple organizations.
- scale to run on organizations with 7000+ repositories.
- be capable of leveraging a GitHub App to authenticate to the GitHub Enterprise Cloud organizations.
​
**Soft Requirement**: Shell has Python skills themselves, so if the script could be written in Python, that would be a plus as they will then be able to maintain and extend it themselves long term for other reporting needs.
​
## Resources
​
- https://github.com/sparlant-demo/gei-assessment ��
- https://github.com/stoe-actions-playground/gh-enterprise-reporting ⭐ ��
- https://gist.github.com/stoe/eecba90c74269f3a16680495e320cb1f ⭐ ��
- https://github.com/stoe/action-reporting-cli ⭐ ��
Collapse