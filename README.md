# objfw.mk - ObjFW Basic dependency manager

Builds every .m source in a project directory and compile all specified dependencies

## Usage

### Project initialize

```
mkdir objfw_project
cd objfw_project
curl -skLO https://github.com/kozharskyad/objfw.mk/raw/main/objfw.mk
make -f objfw.mk init
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

With optimization

```
make RELEASE=1
```

With verbose output

```
make VERBOSE=1
```

TGZ packaging

```
make package
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
PROJECT_DEP_some_library2_DIR=/path/to/some_library2
```

### Structure example

Dependency manager automatically search dependencies directories at parent directory. For example:

```
app_complex/some_application
app_complex/some_library1
/path/to/some_library2
```

You can set absolute path to every dependency in format `PROJECT_DEP_<dependency_name>_DIR=/path/to/dependency`.

#### See [example](https://github.com/kozharskyad/objfw.mk/blob/main/example/)
