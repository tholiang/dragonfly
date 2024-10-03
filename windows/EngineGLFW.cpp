#include "EngineGLFW.h"

std::queue<std::pair<int, bool>> EngineGLFW::keyq;
bool EngineGLFW::mouse_moved;
vec_float2 EngineGLFW::last_loc;
vec_float2 EngineGLFW::mouse_loc;
std::queue<std::pair<vec_float2, std::pair<int, bool>>> EngineGLFW::clickq;

EngineGLFW::EngineGLFW() {
}

EngineGLFW::~EngineGLFW() {
    delete compute_pipeline;
    delete render_pipeline;
    
    delete camera;
    delete scene;
    delete scheme;
    delete scheme_controller;
}

void EngineGLFW::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    if (action == GLFW_PRESS) {
        keyq.push(std::make_pair(to_metal_keysym(key), true));
    } else if (action == GLFW_RELEASE) {
        keyq.push(std::make_pair(to_metal_keysym(key), false));
    }
}

void EngineGLFW::mouse_callback(GLFWwindow* window, double xpos, double ypos) {
    mouse_loc = vec_make_float2(xpos, ypos);
    mouse_moved = true;
}

void EngineGLFW::click_callback(GLFWwindow* window, int button, int action, int mods) {
    clickq.push(std::make_pair(mouse_loc, std::make_pair(button, action==GLFW_PRESS)));
}

int EngineGLFW::SetPipelines() {
    render_pipeline = new RenderPipelineGLFW();
    window_id = render_pipeline->init();
    if (window_id < 0) {
        return 1;
    }
    render_pipeline->SetScheme(scheme);
    render_pipeline->SetSchemeController(scheme_controller);

    compute_pipeline = new ComputePipelineGLFW();
    compute_pipeline->init();
    compute_pipeline->SetScheme(scheme);

    compute_pipeline->CreateBuffers();
    compute_pipeline->UpdateBufferCapacities(); // TODO: redundant

    GLFWwindow *window = ((RenderPipelineGLFW *) render_pipeline)->get_window();
    glfwSetKeyCallback(window, key_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetMouseButtonCallback(window, click_callback);
    
    return 0;
}

int EngineGLFW::HandleInputEvents() {
    glfwPollEvents();

    while (!keyq.empty()) {
        Engine::HandleKeyboardEvents(keyq.front().first, keyq.front().second);
        keyq.pop();
    }

    if (mouse_moved) {
        Engine::HandleMouseMovement(mouse_loc.x, mouse_loc.y, mouse_loc.x - last_loc.x, mouse_loc.y - last_loc.y);
        last_loc = mouse_loc;
        mouse_moved = false;
    }

    while (!clickq.empty()) {
        Engine::HandleMouseClick(clickq.front().first, clickq.front().second.first, clickq.front().second.second);
        clickq.pop();
    }

    return 0;
}

int EngineGLFW::to_metal_keysym(int key) {
    switch (key) {
    case 87:
        return 119;
    case 65:
        return 97;
    case 83:
        return 115;
    case 68:
        return 100;
    case 32:
        return 32;
    case 90:
        return 122;
    case 340:
        return 1073742049;
    case 341:
        return 1073742048;
    case 342:
        return 1073742054;
    // command : 1073742055
    default:
        break;
    }
    return -1;
}