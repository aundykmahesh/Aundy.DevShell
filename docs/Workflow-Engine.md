# Developer Workflow Engine

The Workflow Engine owns developer-operation definitions, lookup, validation, planning, dependency ordering, invocation, caching, results, and diagnostics. It consumes the Workspace Engine only through `Get-Workspace`; it does not discover repositories, solutions, or projects. The Prompt Engine never loads or invokes workflows.

## Supported source and trust boundary

Sprint 5 registers four built-in workflows: `Restore`, `Build`, `Test`, and `Validate`. Definitions contain executable names and discrete argument tokens. Repository and user definition files are intentionally unsupported because the current settings model defines neither a file location nor a trust policy. No definition is dot-sourced, no script text is accepted, and execution never uses `Invoke-Expression` or a shell wrapper.

Built-ins use `dotnet`, require a workspace from `Get-Workspace`, and run from its root. A future repository-independent built-in may declare `RequiresWorkspace = $false`; it will run in the caller's current directory without repository discovery.

## Definition and parameter model

Definitions are structured `Aundy.DevShell.WorkflowDefinition` objects with identity, display metadata, category, executable, argument tokens, working-directory policy, declared parameters, prerequisites, dependencies, timeout, tags, source, version, enabled state, and metadata. The public contract is descriptive and loading it never executes code.

`Build` and `Test` accept `Configuration` (`Debug` or `Release`) and `NoRestore`. `Validate` accepts `Configuration`. Undeclared parameters and disallowed values are terminating usage errors. Parameter values remain separate native argument tokens.

```powershell
Get-DevWorkflow
Get-DevWorkflow -Name Build
Get-DevWorkflow -Category Test
Get-DevWorkflow -Tag dotnet
Invoke-DevWorkflow -Name Test -Parameter @{ Configuration = 'Release' }
```

## Planning and invocation

`Resolve-DevWorkflow` returns an `Aundy.DevShell.WorkflowPlan` without starting a process. It exposes the executable, argument list, working directory, effective parameters, dependencies, deterministic execution order, timeout, validation state, problems, and planning duration.

```powershell
Resolve-DevWorkflow -Name Build -Parameter @{ Configuration = 'Release' }
Invoke-DevWorkflow -Name Validate -WhatIf
```

`Invoke-DevWorkflow` supports `ShouldProcess`. `-WhatIf` returns a `Planned` result and starts no process. Normal invocation runs each dependency once, stops at the first failure, and returns an `Aundy.DevShell.WorkflowResult` containing its plan and `Aundy.DevShell.WorkflowStepResult` entries. Native exit codes, stdout, stderr, UTC timestamps, and duration are preserved. Status values used in Sprint 5 are `Planned`, `Succeeded`, `Failed`, `TimedOut`, and `Blocked`. Output and error output are each limited to 1 MiB and marked when truncated.

The runner sets its working directory on the child process and does not change caller location or environment. A timeout kills only the process tree it started. Definitions cannot override environment variables in Sprint 5, avoiding accidental secret leakage or persistent process state.

## Cache and diagnostics

The built-in registry initializes lazily on the first workflow command and is reused in memory. `Get-DevWorkflow -Refresh`, `Resolve-DevWorkflow -Refresh`, and `Invoke-DevWorkflow -Refresh` rebuild it; refresh also passes through to `Get-Workspace` during planning. Module re-import naturally invalidates the cache. Invocation results and secrets are never cached.

`Test-DevWorkflow` returns a read-only `Aundy.DevShell.WorkflowDiagnosticResult`. It checks registry availability, each definition, missing or circular dependencies, named executable availability, public contracts, and cache state. It never invokes a workflow. Checks include actionable recommendations and duration, making the contract suitable for a future aggregate `Test-DevShell` implementation without private coupling.

Future engines may contribute workflows through a public registration/source contract once its lifecycle and trust rules are designed. They must not mutate the private registry or couple to Workflow Engine internals.
