# objfw.mk - ObjFW Basic dependency manager

Builds every .m source in a project directory and compile all specified dependencies

## Usage

### Project initialize

```
mkdir objfw_project
cd objfw_project
curl -skLO https://github.com/kozharskyad/objfw.mk/raw/main/objfw.mk
```

Or download with WGET

```
wget https://github.com/kozharskyad/objfw.mk/raw/main/objfw.mk
```

### Project build

```
make
```

OR

```
make build
```

### Generated Makefile

* You can change project name by editing PROJECT_NAME Makefile variable
* You can change project type by editing PROJECT_TYPE Makefile variable. Allowed types: `app` and `lib`. Libraries can be dependencies

### Example

#### First library project

```
PROJECT_NAME=some_library1
PROJECT_TYPE=lib
```

#### Second library project

```
PROJECT_NAME=some_library2
PROJECT_TYPE=lib
```

#### Application project

```
PROJECT_NAME=some_application
PROJECT_TYPE=app
PROJECT_DEPS=some_library1 some_library2
```

### Structure example

Dependency manager automatically search dependencies directories at parent directory. For example:

```
app_complex/some_application
app_complex/some_library1
app_complex/some_library2
```
