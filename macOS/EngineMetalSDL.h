//
//  Engine.h
//  dragonfly
//
//  Created by Thomas Liang on 8/1/22.
//

#ifndef EngineMetalSDL_h
#define EngineMetalSDL_h

#include "Engine.h"

#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include "imfilebrowser.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "Pipelines/ComputePipelineMetalSDL.h"
#include "Pipelines/RenderPipelineMetalSDL.h"

class EngineMetalSDL : public Engine {
private:
    // metal
    CAMetalLayer *layer;
    id <MTLCommandQueue> command_queue;
    
    int SetPipelines();
    int HandleInputEvents();

    void HandleSDLEvents(SDL_Event event);
    void HandleSDLKeyboardEvents(SDL_Event event);
    void HandleSDLMouseEvents(SDL_Event event);
public:
    EngineMetalSDL();
    ~EngineMetalSDL();
};

#endif /* EngineMetalSDL_h */
