#ifndef RenderPipelineGLFW_h
#define RenderPipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Constants.h"
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
    Shader *face_shader;
    Shader *edge_shader;

    // depth variables for renderer
    
    // ---BUFFERS FOR SCENE RENDER---
    unsigned long compute_buffer_capacities[CPT_NUM_OUTBUFS];
    GLuint compute_buffers[CPT_NUM_OUTBUFS];
public:
    RenderPipelineGLFW();
    ~RenderPipelineGLFW();
    
    int init();
    void SetBuffer(unsigned long idx, GLuint buf, unsigned long cap);
    
    void SetPipeline();
    
    void Render();

    GLFWwindow *get_window();
};

#endif /* RenderPipelineGLFW_h */
