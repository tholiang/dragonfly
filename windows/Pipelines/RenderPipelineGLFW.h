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
    Shader *face_shader;
    Shader *edge_shader;

    // depth variables for renderer
    
    // ---BUFFERS FOR SCENE RENDER---
    unsigned int VBO, VAO;
    GLuint vertex_buffer;
    GLuint face_buffer;
    GLuint edge_buffer;

    int num_render_vertices;
public:
    RenderPipelineGLFW();
    ~RenderPipelineGLFW();
    
    int init();
    void SetBuffers(GLuint vb, GLuint fb, GLuint eb, unsigned long nf, unsigned long ne);
    
    void SetPipeline();
    
    void Render();

    GLFWwindow *get_window();
};

#endif /* RenderPipelineGLFW_h */
