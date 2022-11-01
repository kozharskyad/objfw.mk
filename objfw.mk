COMMAND_CHECK=$(shell command -v command)
WHICH_CHECK=$(shell which which)
WHICH=$(if $(COMMAND_CHECK),\
	$(COMMAND_CHECK) -v,\
	$(if $(WHICH_CHECK),\
		$(WHICH_CHECK),\
		$(error command or which command not found)\
	)\
)

OFCFG=$(shell $(WHICH) objfw-config)
$(if $(OFCFG),,$(error objfw-config command not found))

STRIP=$(shell $(WHICH) strip)
$(if $(STRIP),,$(error strip command not found))

RM=$(shell $(WHICH) rm)
$(if $(RM),,$(error rm command not found))

AR=$(or $(shell $(WHICH) llvm-ar),$(shell $(WHICH) ar))
$(if $(AR),,$(error ar command not found))

RL=$(or $(shell $(WHICH) llvm-ranlib),$(shell $(WHICH) ranlib))
$(if $(RL),,$(error ranlib command not found))

MD=$(shell $(WHICH) mkdir)
$(if $(MD),,$(error mkdir command not found))

CP=$(shell $(WHICH) cp)
$(if $(CP),,$(error cp command not found))

TOUCH=$(shell $(WHICH) touch)
$(if $(TOUCH),,$(error touch command not found))

PRINTF=$(shell $(WHICH) printf)
$(if $(PRINTF),,$(error printf command not found))

SED=$(or $(shell $(WHICH) gsed),$(shell $(WHICH) sed))
$(if $(SED),,$(error sed command not found))

GZIP=$(shell $(WHICH) gzip)
TAR=$(shell $(WHICH) tar)

C_RED=\033[0;31m
C_GRN=\033[0;32m
C_RST=\033[0m
C_PRT=$(info $(shell $(PRINTF) '$(PROJECT_NAME) | $(1)$(2)$(C_RST)\n'))

OFBIN=$(shell dirname "$(OFCFG)")
OFROOT=$(shell dirname "$(OFBIN)")
OFINCL=$(OFROOT)/include
PROJECT_NAME?=$(notdir $(PWD))
PROJECT_TYPE?=app
ARCHIVE_FILE_NAME=$(PROJECT_NAME).tgz
RELEASE?=0
VERBOSE?=0
V=$(if $(filter-out 1,$(VERBOSE)),@,)
O=$(if $(filter-out 1,$(VERBOSE)),>/dev/null 2>&1,)
OBJCC=$(shell $(OFCFG) --objc)
OBJCCFLAGS=$(shell $(OFCFG) --arc --cflags --cppflags --objcflags) -c
LD=$(OBJCC)
LDFLAGS=-Wl,-ObjC $(shell $(OFCFG) --ldflags --libs)
LD_SEARCH_PATHS=$(shell $(LD) $(LDFLAGS) -Wl,-v 2>&1 | $(SED) -rn 's/^\s+?(\/.+?)$$/\1/p')
STRIPFLAGS=-s
RMFLAGS=-rf
ARFLAGS=-crsv
RLFLAGS=
MDFLAGS=-p
TARFLAGS=-cp
GZIPFLAGS=-c9
PACKAGE_FILES=$(strip $(TARGET) $(if $(filter-out lib,$(PROJECT_TYPE)),,*.h))
SRCS=$(strip $(wildcard *.m))
OBJS=$(strip $(patsubst %.m, %.o, $(SRCS)))

ifeq ($(PROJECT_TYPE),lib)
TARGETPREFIX=lib
TARGETSUFFIX=.a
else
ifneq ($(PROJECT_TYPE),app)
$(error PROJECT_TYPE must be "app" or "lib")
endif
endif

ifeq ($(OS),Windows_NT)
OBJCCFLAGS+=-O0
LDFLAGS+=-static
ABSPATH=$(1)

ifeq ($(PROJECT_TYPE),app)
TARGETSUFFIX=.exe
endif
else
UNAME=$(shell uname -s)
ABSPATH=$(abspath $(1))

ifeq ($(UNAME),Linux)
LDFLAGS+=-static-libgcc
endif

ifneq ($(RELEASE),1)
OBJCCFLAGS+=-O0 -g
else
OBJCCFLAGS+=-O2

ifeq ($(UNAME),Darwin)
STRIPFLAGS=
endif
endif
endif

TARGET=$(TARGETPREFIX)$(PROJECT_NAME)$(TARGETSUFFIX)

$(strip $(foreach LDSP,\
	$(LD_SEARCH_PATHS),\
	$(if $(wildcard $(LDSP)/libssl.a)$(wildcard $(LDSP)/libcrypto.a),\
		$(or\
			$(eval SSL_LIB=$(LDSP)/libssl.a),\
			$(eval CRYPTO_LIB=$(LDSP)/libcrypto.a),\
			$(eval SSL_LIBS_FOUND=1)\
		)\
	)\
))

ifeq ($(SSL_LIBS_FOUND),1)
LDSSLFLAGS=-lobjfwtls $(SSL_LIB) $(CRYPTO_LIB)
endif

$(foreach DEP,$(PROJECT_DEPS),$(or\
	$(strip $(if $(PROJECT_DEP_$(DEP)_DIR),\
		$(eval PROJECT_DEP_$(DEP)_DIR=$(call ABSPATH,$(PROJECT_DEP_$(DEP)_DIR))),\
		$(eval PROJECT_DEP_$(DEP)_DIR=$(call ABSPATH,$(PWD)/../$(DEP)))\
	)),\
	$(strip $(if $(wildcard $(PROJECT_DEP_$(DEP)_DIR)/*),,$(or\
		$(eval PROJECT_DEP_$(DEP)_DIR=$(call ABSPATH,$(PWD)/deps/$(DEP))),\
		$(if $(wildcard $(PROJECT_DEP_$(DEP)_DIR)/*),,$(error $(PROJECT_DEP_$(DEP)_DIR) not exists or empty)))\
	)),\
	$(if $(PROJECT_DEP_$(DEP)_INC),,$(eval PROJECT_DEP_$(DEP)_INC=$(PROJECT_DEP_$(DEP)_DIR))),\
	$(if $(PROJECT_DEP_$(DEP)_LIBDIR),,$(eval PROJECT_DEP_$(DEP)_LIBDIR=$(PROJECT_DEP_$(DEP)_DIR))),\
	$(if $(PROJECT_DEP_$(DEP)_LIBS),,$(eval PROJECT_DEP_$(DEP)_LIBS=$(DEP))),\
	$(eval PROJECT_DEPS_DIRS+=$(PROJECT_DEP_$(DEP)_DIR)),\
	$(eval PROJECT_DEPS_INCS+=$(PROJECT_DEP_$(DEP)_INC)),\
	$(foreach DEP_LIB,$(PROJECT_DEP_$(DEP)_LIBS),$(eval PROJECT_DEPS_LIBFILES+=$(PROJECT_DEP_$(DEP)_LIBDIR)/lib$(DEP_LIB).a)),\
	$(eval OBJCC_DEPS_FLAGS+=$(foreach INC,$(PROJECT_DEP_$(DEP)_INC),-I$(INC))),\
	$(eval PROJECT_DEPS_RESOLVED+=$(PROJECT_DEP_$(DEP)_DIR))\
))

$(if $(filter-out $(words $(PROJECT_DEPS)),$(words $(PROJECT_DEPS_RESOLVED))),\
	$(error dependency resolving failed),\
)

ifneq ($(MAKECMDGOALS),clean)
$(call C_PRT,$(C_GRN),BEGIN BUILDING $(C_RED)$(if $(PARENT_PROJECT),DEPENDENCY,PROJECT) $(PROJECT_NAME)$(if $(PARENT_PROJECT), FOR PROJECT $(PARENT_PROJECT),))
endif

all: deps build

package: all
ifneq ($(TAR),)
ifneq ($(GZIP),)
	$(V)$(strip $(TAR) $(TARFLAGS) $(PACKAGE_FILES) | $(GZIP) $(GZIPFLAGS) > $(ARCHIVE_FILE_NAME))
	$(call C_PRT,$(C_GRN),PACKAGED $(PACKAGE_FILES) -> $(C_RED)$(ARCHIVE_FILE_NAME))
else
	$(warning gzip utility unavailable, packaging disabled)
endif
else
	$(warning tar utility unavailable, packaging disabled)
endif

build: $(TARGET)

$(TARGET): $(OBJS)
ifeq ($(PROJECT_TYPE),app)
	$(call C_PRT,$(C_GRN),$(strip Linking $(notdir $(PROJECT_DEPS_LIBFILES)) $(OBJS) -> $(C_RED)$(TARGET)))
	$(V)$(RM) $(RMFLAGS) tmp
	$(V)$(MD) $(MDFLAGS) tmp; cd tmp; $(foreach DEP_LIBFILE,$(PROJECT_DEPS_LIBFILES),ar -xv $(DEP_LIBFILE) $(O) || exit 1;)
	$(V)$(strip $(LD) $(if $(PROJECT_DEPS_LIBFILES),tmp/*.o,) $^ -o $@ $(LDSSLFLAGS) $(LDFLAGS))
	$(V)$(RM) $(RMFLAGS) tmp
ifeq ($(RELEASE),1)
	$(V)$(STRIP) $(STRIPFLAGS) $@
endif
endif
ifeq ($(PROJECT_TYPE),lib)
	$(V)$(RM) $(RMFLAGS) tmp
	$(V)$(MD) $(MDFLAGS) tmp; cd tmp; $(foreach DEP_LIBFILE,$(PROJECT_DEPS_LIBFILES),ar -xv $(DEP_LIBFILE) $(O) || exit 1;)
	$(call C_PRT,$(C_GRN),Creating static library $(strip $(notdir $(PROJECT_DEPS_LIBFILES)) $(OBJS)) -> $(C_RED)$(TARGET))
	$(V)$(strip $(AR) $(ARFLAGS) $@ $^ $(if $(PROJECT_DEPS_LIBFILES),tmp/*.o,) $(O))
	$(V)$(RM) $(RMFLAGS) tmp
	$(V)$(strip $(RL) $(RLFLAGS) $@)
endif
	$(call C_PRT,$(C_GRN),BUILT $(C_RED)$(if $(filter-out app,$(PROJECT_TYPE)),LIBRARY,EXECUTABLE) $@)

init: update Makefile

update: .clangd vscode

vscode: .vscode .vscode/launch.json .vscode/settings.json .vscode/tasks.json

.vscode/launch.json:
	$(V)$(PRINTF) '{\n' > $@
	$(V)$(PRINTF) '  "version": "0.2.0",\n' >> $@
	$(V)$(PRINTF) '  "configurations": [\n' >> $@
	$(V)$(PRINTF) '    {\n' >> $@
	$(V)$(PRINTF) '      "type": "lldb",\n' >> $@
	$(V)$(PRINTF) '      "request": "launch",\n' >> $@
	$(V)$(PRINTF) '      "name": "Debug",\n' >> $@
	$(V)$(PRINTF) '      "program": "$${workspaceFolder}/$(PROJECT_NAME)",\n' >> $@
	$(V)$(PRINTF) '      "args": [],\n' >> $@
	$(V)$(PRINTF) '      "cwd": "$${workspaceFolder}",\n' >> $@
	$(V)$(PRINTF) '      "preLaunchTask": "build"\n' >> $@
	$(V)$(PRINTF) '    }\n' >> $@
	$(V)$(PRINTF) '  ]\n' >> $@
	$(V)$(PRINTF) '}\n' >> $@

.vscode/settings.json:
	$(V)$(PRINTF) '{\n' > $@
	$(V)$(PRINTF) '  "files.associations": {\n' >> $@
	$(V)$(PRINTF) '    "*.h": "objective-c"\n' >> $@
	$(V)$(PRINTF) '  }\n' >> $@
	$(V)$(PRINTF) '}\n' >> $@

.vscode/tasks.json:
	$(V)$(PRINTF) '{\n' > $@
	$(V)$(PRINTF) '  "version": "2.0.0",\n' >> $@
	$(V)$(PRINTF) '  "tasks": [\n' >> $@
	$(V)$(PRINTF) '    {\n' >> $@
	$(V)$(PRINTF) '      "label": "build",\n' >> $@
	$(V)$(PRINTF) '      "type": "shell",\n' >> $@
	$(V)$(PRINTF) '      "command": "make",\n' >> $@
	$(V)$(PRINTF) '      "args": ["clean", "all"]\n' >> $@
	$(V)$(PRINTF) '    }\n' >> $@
	$(V)$(PRINTF) '  ]\n' >> $@
	$(V)$(PRINTF) '}\n' >> $@

.vscode:
	$(V)$(MD) $(MDFLAGS) $@

Makefile:
	$(V)$(PRINTF) 'PROJECT_NAME=$(PROJECT_NAME)\nPROJECT_TYPE=$(PROJECT_TYPE)\n\ninclude objfw.mk\n' > $@

.clangd:
	$(V)$(PRINTF) 'CompileFlags:\n  Add:\n' > $@
	$(V)($(foreach FLAG,$(strip $(OBJCCFLAGS) $(OBJCC_DEPS_FLAGS)),$(PRINTF) '    - $(FLAG)\n';)) >> $@

deps: deps.built

deps.built:
	$(if $(PROJECT_DEPS),$(call C_PRT,$(C_GRN),Building dependenc$(if $(filter-out 1,$(words $(PROJECT_DEPS))),ies,y) $(C_RED)$(PROJECT_DEPS)),)
	$(V)$(foreach DEP_DIR,$(PROJECT_DEPS_DIRS),$(MAKE) -C $(DEP_DIR) all PARENT_PROJECT=$(PROJECT_NAME) || exit 1;)
	$(V)$(TOUCH) $@

%.o: %.m
	$(call C_PRT,$(C_GRN),Compiling $< -> $(C_RED)$@)
	$(V)$(strip $(OBJCC) -c $< -o $@ $(OBJCC_DEPS_FLAGS) $(OBJCCFLAGS))

clean:
	$(if $(PARENT_PROJECT),,$(call C_PRT,$(C_GRN),Cleaning project $(C_RED)$(PROJECT_NAME)))
	$(if $(PROJECT_DEPS),$(call C_PRT,$(C_GRN),Cleaning dependenc$(if $(filter-out 1,$(words $(PROJECT_DEPS))),ies,y) $(C_RED)$(PROJECT_DEPS)),)
	$(V)$(foreach DEP_DIR,$(PROJECT_DEPS_DIRS),$(MAKE) -C $(DEP_DIR) clean PARENT_PROJECT=$(PROJECT_NAME);)
	$(V)$(RM) $(RMFLAGS) $(TARGET) $(TARGET).exe $(PROJECT_NAME) $(ARCHIVE_FILE_NAME) *.o deps.built

.PHONY: all build clean init deps .clangd update vscode .vscode/launch.json .vscode/settings.json .vscode/tasks.json
