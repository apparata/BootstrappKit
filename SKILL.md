---
name: bootstrapp
description: Instantiate a project from a Bootstrapp template bundle
user-invocable: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Bootstrapp Template Instantiation

You are a skill that instantiates projects from Bootstrapp template bundles using the `bootstrapp-cli` tool.

## Steps

1. **Determine the template path.** The user provides it as the skill argument. If not provided, ask for it.

2. **Read the template specification.** Read `Bootstrapp.json` from the template bundle directory to discover the parameters and packages.

3. **Confirm every parameter value with the user.** This is CRITICAL: you MUST ask about ALL parameters, not just a few. Do NOT skip any parameter, even if it has a reasonable-looking default. Do NOT silently assume defaults for any parameter.

   Ask the user to confirm or change values using `AskUserQuestion`. Since `AskUserQuestion` supports at most 4 questions per call, you MUST make **multiple sequential calls** to cover all parameters — batch them 4 at a time until every single parameter has been addressed.

   For each parameter question:
   - For **Option** type: use the spec's options list as the `AskUserQuestion` options (up to 4; mark the default with "(default)").
   - For **Bool** type: offer "true" and "false" as options, marking the default.
   - For **String** type: show the default value and offer "Keep default" vs "Change" — if the user picks "Change" (or "Other"), use their custom input. Mention the validation regex if one exists.

   If a parameter has `dependsOn`, note which parameter it depends on.

   Do NOT proceed to step 4 until you have confirmed values for EVERY parameter.

4. **Package selection.** If the spec defines packages (the `packages` array in `Bootstrapp.json`), show the user the list of spec-defined packages (name, URL, version) and ask which ones, if any, they want to **exclude**. Use `AskUserQuestion` with multi-select. Any packages the user wants to exclude will be passed via `--exclude-package NAME` flags. IMPORTANT: First ask if the user wishes to include all of the packages, and if the user answers "yes", don't ask the user about what packages to exclude.

5. **Build and execute the CLI command.** Construct:
   ```bash
   swift run --package-path /Users/martinjohannesson/Projekt/git/Frameworks/BootstrappKit bootstrapp-cli \
     "<template-path>" \
     --param KEY1=VALUE1 \
     --param KEY2=VALUE2 \
     --exclude-package EXCLUDED1 \
     --verbose
   ```

   For string values with spaces, quote the entire `KEY=VALUE` like: `--param "COPYRIGHT_HOLDER=Apparata AB"`

   For Option parameters, pass the option name (e.g. `--param LICENSE_TYPE=MIT`).

   For Bool parameters, pass `true` or `false` (e.g. `--param GIT_INIT=false`).

6. **Report the result.** The CLI prints the output path as the last line. Tell the user where the generated project is located.

## Notes

- The first build may take a while as Swift resolves and compiles dependencies.
- Template files use `<{ }>` delimiters for variable substitution, conditionals, and loops.
- The output goes to `/tmp/Results/YYYY-MM-DD/<project-name>/` by default.
- Import paths in templates (e.g. `<{ import "../../Common/Licenses/MIT.txt" }>`) resolve relative to the template's Content directory, so the surrounding directory structure matters.
