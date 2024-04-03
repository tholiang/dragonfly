define uniq =
  $(eval seen :=)
  $(foreach _,$1,$(if $(filter $_,${seen}),,$(eval seen += $_)))
  ${seen}
endef

CC = gcc
CXX = g++

TARGET = dragonfly

empty :=

CXXFLAGS = -Wall -ggdb -O3
LINK_FLAGS = -lopengl32 -lglfw3 -lglu32 -lgdi32

ROOT := ..
ODIR := obj
CODIR := $(ODIR)/cobj
CXXODIR := $(ODIR)/cppobj

glfw = "C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64"
glfw_inc = -I"C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64\include"
glfw_lib = -L"C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64\lib-mingw-w64"

imgui = $(ROOT)/imgui
imgui_inc = -I$(imgui)/ -I$(imgui)/backends/
imgui_src = $(wildcard $(imgui)/*.cpp) $(imgui)/backends/imgui_impl_glfw.cpp $(imgui)/backends/imgui_impl_opengl3.cpp

glad = $(ROOT)/windows/glad
glad_inc = -I$(glad)/include
glad_src = $(glad)/src/glad.c

core = $(ROOT)/core
core_inc = -I$(core) -I$(core)/Modeling -I$(core)/Pipelines -I$(core)/Schemes -I$(core)/UI -I$(core)/UserActions -I$(core)/Utils
core_src = $(core)/Engine.cpp $(wildcard $(core)/*/*.cpp)

INCLUDES := $(glfw_inc) $(glad_inc) $(imgui_inc) $(core_inc)
LIBRARIES := $(glfw_lib)
CXXFLAGS += $(INCLUDES)
CXXFLAGS += $(LIBRARIES)
CFLAGS = $(CXXFLAGS)

SRC := main.cpp
EXE := $(TARGET).exe


CFILES := $(glad_src)
COBJS := $(addprefix $(CODIR)/, $(subst $(ROOT)/,$(empty), $(CFILES:.c=.o)))

CXXFILES := $(imgui_src) $(core_src)
CXXOBJS := $(addprefix $(CXXODIR)/, $(subst $(ROOT)/,$(empty), $(CXXFILES:.cpp=.o)))

OBJS := $(COBJS) $(CXXOBJS)

OBJ_DIRS_DUPS := $(addprefix $(CODIR)/, $(subst $(ROOT)/,$(empty), $(dir $(CFILES)))) $(addprefix $(CXXODIR)/, $(subst $(ROOT)/,$(empty), $(dir $(CXXFILES))))
OBJ_DIRS := $(strip $(call uniq,$(OBJ_DIRS_DUPS))) # remove duplicate directories

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(EXE) $(OBJS) $(SRC) $(LINK_FLAGS)

$(CODIR)/%.o: $(ROOT)/%.c | $(OBJ_DIRS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(CXXODIR)/%.o: $(ROOT)/%.cpp | $(OBJ_DIRS)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(OBJ_DIRS):
	mkdir "$@"


.PHONY : clean
clean :
	del /F /Q $(ODIR)\*
	del $(EXE)