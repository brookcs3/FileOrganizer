# Architecture Notes

This project is intentionally lightweight.  The `analyze_dependencies.py` script generates a dependency graph and summary in `architecture_summary.md`.  Below is a placeholder Mermaid diagram of the high level flow.

```mermaid
flowchart TD
    A[User selects folder] --> B[FileProcessor scans directory]
    B --> C{FoundationModelsManager}
    C -->|new session| D[Analyze file]
    D --> E[OrganizationPlan]
    E --> F[Move files]
    C --> G[DirectorySummarySession]
    G --> H[Advice & memory]
```
