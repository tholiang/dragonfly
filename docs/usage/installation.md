# installation
(this is untested)

## MacOS with Metal (native)
**dependencies:**
- xcode
- SDL

**steps:**
1. clone this project
2. open `dragonfly.xcodeproj`
3. run

## Windows with OpenGL + GLFW
**dependencies:**
- opengl3
- glfw
- mingw

**steps:**
1. clone this project
2. navigate to `windows/`
3. edit the `Makefile` paths to your local dependency locations
4. run `$ make`
5. run `$ ./dragonfly`