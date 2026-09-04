# Android Create

This script aims to address the shortcomings of the new Android command-line tools.

When using the `android create` tool, there is no option to provide an `applicationId`; consequently, once the template is created, both the `applicationId` and the `package` name will be incorrect.

This script updates:

- Sets the correct values for the `namespace` and the `applicationId` in the `build.gradle.kt` file.
- Updates all the `package` and `import` lines for all the project files (including tests).
- Renames the `example` package folder to the correct one (including test folders).

## Usage

### Setup

It requires a `.env` file in the same folder as the script, following this template (a `.env.example` file is provided):

```text
OUTPUT=Output Folder
APP_NAME=My App
APP_ID=com.company.appname
MIN_SDK=26
TEMPLATE=empty-activity
```

> Required values: `OUTPUT`, `APP_NAME`, `APP_ID`  
> Optional values: `MIN_SDK`, `TEMPLATE`

### Running the script

```powershell
sh .\create.sh
```

What it does:

- Uses the `android create` tool using the `APP_NAME` and the `OUTPUT` values of the `.env` file.
- Refactors all the files and folders needed to get the correct project.
