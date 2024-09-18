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
    
    delete camera;
    delete scene;
    delete scheme;
    delete scheme_controller;
}

int Engine::init() {
    srand(time(NULL));
    
    camera = new Camera();
    camera->pos = {-2, 0, 0};
    camera->vector = {1, 0, 0};
    camera->up_vector = {0, 0, 1};
    camera->FOV = {M_PI_2, M_PI_2};
    
    scheme = new EditFEVScheme();
    scene = new Scene();
    scheme->SetCamera(camera);
    scheme->SetScene(scene);
    
    scheme_controller = new SchemeController(scheme);
    scheme->SetController(scheme_controller);
    
    if (SetPipelines()) {
        return 1;
    }
    
    return 0;
}

void Engine::run() {
    // Main loop
    while (true) {
        if (HandleInputEvents()) {
            std::cout<<"input event handling failed"<<std::endl;
            break;
        }
        
        if (scheme->ShouldResetEmptyBuffers()) {
            compute_pipeline->CreateBuffers();
            scheme->SetResetEmptyBuffers(false);
        }
        if (scheme->ShouldResetStaticBuffers()) {
            compute_pipeline->ResetStaticBuffers();
            scheme->SetResetStaticBuffers(false);
        }
        compute_pipeline->ResetDynamicBuffers();

        compute_pipeline->Compute();
        
        compute_pipeline->SendDataToScheme();
        compute_pipeline->SendDataToRenderer(render_pipeline);
        
        render_pipeline->Render();
        scheme = scheme_controller->GetScheme();
        compute_pipeline->SetScheme(scheme);
        render_pipeline->SetScheme(scheme);
        
        if (scheme == NULL) {
            std::cout<<"where tf is the scheme"<<std::endl;
            break;
        }

        scheme->Update();
        
    }
}

void Engine::HandleKeyboardEvents(int key, bool down) {
    scheme->HandleKeyPresses(key, down);
}

void Engine::HandleMouseClick(vec_float2 loc, int button, bool down) {
    if (button == 0) { // left
        if (down) {
            scheme->HandleMouseDown(loc, true);
        } else {
            scheme->HandleMouseUp(loc, true);
        }
    } else if (button == 1) { // right
        if (down) {
            scheme->HandleMouseDown(loc, false);
        } else {
            scheme->HandleMouseUp(loc, false);
        }
    }
}

void Engine::HandleMouseMovement(float x, float y, float dx, float dy) {
    scheme->HandleMouseMovement(x, y, dx, dy);
}

