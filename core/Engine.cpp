//
//  Engine.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#include "Engine.h"

Engine::Engine() {
}

Engine::~Engine() {
    delete compute_pipeline;
    delete render_pipeline;
    
    delete scene;
    delete window;
}

int Engine::init() {
    srand(time(NULL));
    
    WindowAttributes win_attr;
    win_attr.screen_height = window_height;
    win_attr.screen_width = window_width;
    scene = new Scene(); // TODO: shouldn't be a member variable
    window = new Window(win_attr);
    window->MakeViewWindow(scene);

    if (SetPipelines()) {
        return 1;
    }
    
    return 0;
}

void Engine::run() {
    // Main loop
    while (true) {
        float fps = ImGui::GetIO().Framerate;
        
        if (HandleInputEvents()) {
            std::cout<<"input event handling failed"<<std::endl;
            break;
        }
        
        window->Update(fps);
        
        compute_pipeline->SetBuffers(window);
        compute_pipeline->Compute(window);
        compute_pipeline->SendDataToRenderer(window, render_pipeline);
        compute_pipeline->SendDataToWindow(window);
        
        render_pipeline->Render();
    }
}

void Engine::HandleKeyboardEvents(int key, bool down) {
    window->HandleKeyPresses(key, down);
}

void Engine::HandleMouseClick(vec_float2 loc, int button, bool down) {
    if (button == 0) { // left
        window->HandleMouseClick(loc, true, down);
    } else if (button == 1) { // right
        window->HandleMouseClick(loc, false, down);
    }
}

void Engine::HandleMouseMovement(float x, float y, float dx, float dy) {
    window->HandleMouseMovement(x, y, dx, dy);
}

