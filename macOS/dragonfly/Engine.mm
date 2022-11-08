//
//  Engine.m
//  dragonfly
//
//  Created by Thomas Liang on 8/1/22.
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
    
    compute_pipeline = new ComputePipeline();
    compute_pipeline->init();
    compute_pipeline->SetScheme(scheme);
    
    render_pipeline = new RenderPipeline();
    window_id = render_pipeline->init();
    if (window_id < 0) {
        return -1;
    }
    render_pipeline->SetScheme(scheme);
    render_pipeline->SetSchemeController(scheme_controller);
    
    compute_pipeline->ResetStaticBuffers();
    compute_pipeline->SetEmptyBuffers();
    
    return 0;
}

void Engine::run() {
    // Main loop
    bool done = false;
    while (!done)
    {
        @autoreleasepool
        {
            SDL_Event event;
            while (SDL_PollEvent(&event))
            {
                ImGui_ImplSDL2_ProcessEvent(&event);
                if (event.type == SDL_QUIT)
                    done = true;
                if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == window_id)
                    done = true;
                
                HandleKeyboardEvents(event);
                HandleMouseEvents(event);
            }
            
            if (scheme->ShouldResetStaticBuffers()) {
                compute_pipeline->ResetStaticBuffers();
                scheme->SetResetStaticBuffers(false);
            }
            if (scheme->ShouldResetEmptyBuffers()) {
                compute_pipeline->SetEmptyBuffers();
                scheme->SetResetEmptyBuffers(false);
            }
            compute_pipeline->ResetDynamicBuffers();

            compute_pipeline->Compute();
            
            compute_pipeline->SendDataToScheme();
            compute_pipeline->SendDataToRenderer(render_pipeline);
            
            //RenderUI();
            render_pipeline->Render();
            scheme = scheme_controller->GetScheme();
            compute_pipeline->SetScheme(scheme);
            
            scheme->Update();
        }
    }
}

void Engine::HandleKeyboardEvents(SDL_Event event) {
    if (event.type == SDL_KEYDOWN) {
        SDL_Keysym keysym = event.key.keysym;
        scheme->HandleKeyPresses(keysym.sym, true);
    } else if (event.type == SDL_KEYUP) {
        SDL_Keysym keysym = event.key.keysym;
        scheme->HandleKeyPresses(keysym.sym, false);
    }
}

void Engine::HandleMouseEvents(SDL_Event event) {
    int x;
    int y;
    SDL_GetMouseState(&x, &y);
    
    simd_float2 loc;
    
    loc.x = (float) x;
    loc.y = (float) y;
    
    if (event.type == SDL_MOUSEBUTTONDOWN) {
        switch (event.button.button) {
            case SDL_BUTTON_LEFT:
                scheme->HandleMouseDown(loc, true);
                break;
            case SDL_BUTTON_RIGHT:
                scheme->HandleMouseDown(loc, false);
                break;
            default:
                break;
        }
    } else if (event.type == SDL_MOUSEBUTTONUP) {
        switch (event.button.button) {
            case SDL_BUTTON_LEFT:
                scheme->HandleMouseUp(loc, true);
                break;
            case SDL_BUTTON_RIGHT:
                scheme->HandleMouseUp(loc, false);
                break;
            default:
                break;
        }
    }
    
    if (event.type == SDL_MOUSEMOTION) {
        scheme->HandleMouseMovement(x, y, event.motion.xrel, event.motion.yrel);
    }
}
