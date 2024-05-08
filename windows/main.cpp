#include <iostream>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include "EngineGLFW.h"

#include "ShaderProcessor.h"

int main() {
    Engine *engine = new EngineGLFW();
    
    if (engine->init() == 0) {
        engine->run();
    }
    
    delete engine;
    
    return 0;
}