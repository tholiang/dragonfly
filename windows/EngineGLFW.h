#ifndef EngineGLFW_h
#define EngineGLFW_h

#include <queue>

#include "Engine.h"

#include "imfilebrowser.h"

#include "Pipelines/ComputePipelineGLFW.h"
#include "Pipelines/RenderPipelineGLFW.h"

class EngineGLFW : public Engine {
private:
    // GLFW
    static std::queue<std::pair<int, bool>> keyq;
    static bool mouse_moved;
    static vec_float2 last_loc;
    static vec_float2 mouse_loc;
    static std::queue<std::pair<vec_float2, std::pair<int, bool>>> clickq; // loc, button, down
    
    int SetPipelines();
    int HandleInputEvents();

    static int to_metal_keysym(int key);
    static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
    static void mouse_callback(GLFWwindow* window, double xpos, double ypos);
    static void click_callback(GLFWwindow* window, int button, int action, int mods);
public:
    EngineGLFW();
    ~EngineGLFW();
};

#endif /* EngineGLFW_h */