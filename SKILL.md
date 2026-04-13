---
name: bootstrapp
description: "Scaffold a new project from a Bootstrapp template bundle. Reads the template's Bootstrapp.json specification, interactively confirms every parameter (string, boolean, option) with the user, selects Swift packages, then runs bootstrapp-cli to generate the fully rendered project. Use when the user wants to create a new project from a template, scaffold an app, instantiate a starter, bootstrap a codebase, or generate boilerplate from a Bootstrapp bundle."
allowed-tools: Bash, Read, AskUserQuestion
metadata:
  user-invocable: true
---

# Bootstrapp Template Instantiation

Scaffold new projects from Bootstrapp template bundles using `bootstrapp-cli`.

## Steps

1. **Determine the template path.** The user provides it as the skill argument. If not provided, ask for it.

2. **Read the template specification.** Read `Bootstrapp.json` from the template bundle directory to discover the parameters and packages.

3. **Confirm every parameter value with the user.** CRITICAL: ask about ALL parameters — do not skip any, even those with reasonable-looking defaults.

   Use `AskUserQuestion` to confirm or change values. Since it supports at most 4 questions per call, make **multiple sequential calls** (batched 4 at a time) until every parameter is addressed.

   Per parameter type:
   - **Option**: use the spec's options list (up to 4; mark the default with "(default)")
   - **Bool**: offer "true" and "false" as options, marking the default
   - **String**: show the default value and offer "Keep default" vs "Change" — if the user picks "Change", use their custom input. Mention the validation regex if one exists.

   Note any `dependsOn` relationships between parameters.

   Do NOT proceed to step 4 until every parameter is confirmed.

4. **Package selection.** If the spec defines a `packages` array, first ask whether the user wants to include all packages. If yes, skip exclusion. Otherwise, show the list (name, URL, version) and ask which to exclude via `AskUserQuestion`. Excluded packages are passed as `--exclude-package NAME` flags.

5. **Build and execute the CLI command.** Construct:
   ```bash
   swift run --package-path <path-to-BootstrappKit> bootstrapp-cli \
     "<template-path>" \
     --param KEY1=VALUE1 \
     --param KEY2=VALUE2 \
     --exclude-package EXCLUDED1 \
     --verbose
   ```

   Replace `<path-to-BootstrappKit>` with the actual path to the BootstrappKit package on the local machine.

   Quoting rules:
   - String values with spaces: `--param "COPYRIGHT_HOLDER=Apparata AB"`
   - Option parameters: pass the option name, e.g. `--param LICENSE_TYPE=MIT`
   - Bool parameters: pass `true` or `false`, e.g. `--param GIT_INIT=false`

6. **Report the result.** The CLI prints the output path as the last line. Tell the user where the generated project is located.

7. **Handle errors.** If the CLI fails:
   - Verify the template path exists and contains `Bootstrapp.json`
   - Check Swift build output for dependency resolution or compilation errors (the first build may be slow)
   - Validate that string parameter values match any regex constraints from the spec
   - Report the error clearly and suggest corrective action

## Notes

- Template files use `<{ }>` delimiters for variable substitution, conditionals, and loops.
- Output defaults to `/tmp/Results/YYYY-MM-DD/<project-name>/`.
- Import paths in templates resolve relative to the template's Content directory.
