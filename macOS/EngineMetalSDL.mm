//
//  EngineMetalSDL.m
//  dragonfly
//
//  Created by Thomas Liang on 8/1/22.
//

#include "EngineMetalSDL.h"

EngineMetalSDL::EngineMetalSDL() {
}

EngineMetalSDL::~EngineMetalSDL() {
}

int EngineMetalSDL::SetPipelines() {
    compute_pipeline = new ComputePipelineMetalSDL();
    compute_pipeline->init();
    
    render_pipeline = new RenderPipelineMetalSDL();
    window_id = render_pipeline->init();
    if (window_id < 0) {
        return 1;
    }
    
    return 0;
}

int EngineMetalSDL::HandleInputEvents() {
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        ImGui_ImplSDL2_ProcessEvent(&event);
        if (event.type == SDL_QUIT)
            return 1;
        if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == window_id)
            return 1;
        
        HandleSDLKeyboardEvents(event);
        HandleSDLMouseEvents(event);
    }
    
    return 0;
}

void EngineMetalSDL::HandleSDLKeyboardEvents(SDL_Event event) {
//    if (window->IsInputEnabled()) {
        if (event.type == SDL_KEYDOWN) {
            SDL_Keysym keysym = event.key.keysym;
            Engine::HandleKeyboardEvents(keysym.sym, true);
        } else if (event.type == SDL_KEYUP) {
            SDL_Keysym keysym = event.key.keysym;
            Engine::HandleKeyboardEvents(keysym.sym, false);
        }
//    }
}

void EngineMetalSDL::HandleSDLMouseEvents(SDL_Event event) {
//    if (scheme->IsInputEnabled()) {
        int x;
        int y;
        SDL_GetMouseState(&x, &y);
        
        vec_float2 loc;
        
        loc.x = (float) x;
        loc.y = (float) y;
        
        if (event.type == SDL_MOUSEBUTTONDOWN) {
            switch (event.button.button) {
                case SDL_BUTTON_LEFT:
                    Engine::HandleMouseClick(loc, 0, true);
                    break;
                case SDL_BUTTON_RIGHT:
                    Engine::HandleMouseClick(loc, 1, true);
                    break;
                default:
                    break;
            }
        } else if (event.type == SDL_MOUSEBUTTONUP) {
            switch (event.button.button) {
                case SDL_BUTTON_LEFT:
                    Engine::HandleMouseClick(loc, 0, false);
                    break;
                case SDL_BUTTON_RIGHT:
                    Engine::HandleMouseClick(loc, 1, false);
                    break;
                default:
                    break;
            }
        }
        
        if (event.type == SDL_MOUSEMOTION) {
            Engine::HandleMouseMovement(x, y, event.motion.xrel, event.motion.yrel);
        }
//    }
}
