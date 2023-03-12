# GHES / GHEC LFS Auditor

The following Go application is used to audit repositories containing LFS files. This works by iterating through repositories in an organization and locate `.gitattributes` file.

## Prerequisites

- You will need Go 1.17 or later installed on your machine. You can download the installer for Go [here](https://go.dev/dl/).
- You need to create a GitHub Personal Access Token (PAT) with `repo` permission

## Building the application

To build the application, run the following command:

```bash
go build .
```

## Usage

To run an audit against repositories within a GHEC organization, you need to create a GitHub Personal Access Token (PAT) with `repo` permission. Then, run the following:

```bash
./LFSAudit audit --org-name=<org> --pat-token=<pat-token>
```

To run an audit against repositories within a GHES organization, run the following:

```bash
./LFSAudit audit --org-name=<org> --pat-token=<pat-token> --is-enterprise-server=<true or false> --enterprise-server-url=<serverbaseurl/api/v3>
```

## Result

Result will be a text file named `repos_audited.txt` listing URL to repository enabled with LFS