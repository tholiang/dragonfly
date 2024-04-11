#ifndef RenderPipelineGLFW_h
#define RenderPipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"

#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include "ShaderProcessor.h"

#include "RenderPipeline.h"

class RenderPipelineGLFW : public RenderPipeline {
private:
    // settings
    const unsigned int width = 1080;
    const unsigned int height = 720;

    // rendering specifics
    GLFWwindow* window;
    
    // ---SHADER OBJECTS FOR GPU RENDERER---
    Shader *test_shader;

    // depth variables for renderer
    
    // ---BUFFERS FOR SCENE RENDER---
    unsigned int VBO, VAO;

public:
    RenderPipelineGLFW();
    ~RenderPipelineGLFW();
    
    int init();
    void SetBuffers();
    
    void SetPipeline();
    
    void Render();
};

#endif /* RenderPipelineGLFW_h */
