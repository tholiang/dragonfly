CC = gcc
CXX = g++

TARGET = dragonfly

CXXFLAGS = -Wall -ggdb -O3
LINK_FLAGS = -lopengl32 -lglfw3 -lglu32 -lgdi32

glfw = "C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64"
glfw_inc = "C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64\include"
glfw_lib = "C:\Program Files (x86)\glfw-3.4\glfw-3.4.bin.WIN64\lib-mingw-w64"

glad = glad
glad_inc = $(glad)/include

INCLUDES := -I$(glfw_inc) -I$(glad_inc)
LIBRARIES := -L$(glfw_lib)
CXXFLAGS += $(INCLUDES)
CXXFLAGS += $(LIBRARIES)
CFLAGS = $(CXXFLAGS)

SRC := main.cpp
EXE := $(TARGET).exe

ODIR := obj

CFILES := glad/src/glad.c
COBJS := $(addprefix $(ODIR)/, $(notdir $(CFILES:.c=.o)))

CXXFLES :=
CXXOBJS := $(addprefix $(ODIR)/, $(notdir $(CXXFLES:.cpp=.o)))

OBJS := $(COBJS) $(CXXOBJS)

HEADERS = 

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(EXE) $(OBJS) $(SRC) $(LINK_FLAGS)

$(COBJS): $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $(CFILES)

$(CXXOBJS): $(HEADERS)

.PHONY : clean
clean :
	del /F /Q $(ODIR)\*
	del $(EXE)