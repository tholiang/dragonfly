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
    
    // delete camera;
    delete scene;
    delete window;
    // delete scheme;
    // delete scheme_controller;
}

int Engine::init() {
    srand(time(NULL));
    
    // scheme = new EditFEVScheme();
    // scene = new Scene();
    // scheme->SetCamera(camera);
    // scheme->SetScene(scene);
    
    // scheme_controller = new SchemeController(scheme);
    // scheme->SetController(scheme_controller);
    
    window = new Window(vec_make_int2(window_width, window_height));
    window->MakeViewWindow(scene);

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
        
        for (int i = 0; i < window->NumPanels(); i++) {
            Panel *panel = window->GetPanel(i);
            if (panel->ShouldResetEmptyBuffers()) {
                // compute_pipeline->UpdateBufferCapacities();
                panel->SetResetEmptyBuffers(false);
            }
            if (panel->ShouldResetStaticBuffers()) {
                // compute_pipeline->ResetStaticBuffers();
                panel->SetResetStaticBuffers(false);
            }
            // compute_pipeline->ResetDynamicBuffers();
            
        }

        // if (scheme->ShouldResetEmptyBuffers()) {
        //     compute_pipeline->UpdateBufferCapacities();
        //     scheme->SetResetEmptyBuffers(false);
        // }
        // if (scheme->ShouldResetStaticBuffers()) {
        //     compute_pipeline->ResetStaticBuffers();
        //     scheme->SetResetStaticBuffers(false);
        // }
        // compute_pipeline->ResetDynamicBuffers();

        // compute_pipeline->Compute();
        
        // compute_pipeline->SendDataToScheme();
        // compute_pipeline->SendDataToRenderer(render_pipeline);
        
        // render_pipeline->Render();
        // scheme = scheme_controller->GetScheme();
        // compute_pipeline->SetScheme(scheme);
        // render_pipeline->SetScheme(scheme);
        
        // if (scheme == NULL) {
        //     std::cout<<"where tf is the scheme"<<std::endl;
        //     break;
        // }

        // scheme->Update();
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

