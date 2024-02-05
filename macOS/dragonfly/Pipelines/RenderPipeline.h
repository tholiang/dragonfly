//
//  RenderPipeline.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef RenderPipeline_h
#define RenderPipeline_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include <SDL.h>

#include "../Schemes/Scheme.h"
#include "../Schemes/SchemeController.h"

class RenderPipeline {
private:
    // rendering specifics
    MTLRenderPassDescriptor* render_pass_descriptor;
    CAMetalLayer *layer;
    
    SDL_Window* window;
    SDL_Renderer* renderer;
    
    int window_width;
    int window_height;
    
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id<MTLLibrary> library;
    
    // ---PIPELINE STATES FOR GPU RENDERER---
    id <MTLRenderPipelineState> default_face_render_pipeline_state;
    id <MTLRenderPipelineState> default_edge_render_pipeline_state;

    // depth variables for renderer
    id <MTLDepthStencilState> depth_state;
    id <MTLTexture> depth_texture;
    
    // ---BUFFERS FOR SCENE RENDER---
    id <MTLBuffer> vertex_buffer;
    id <MTLBuffer> face_buffer;
    id <MTLBuffer> edge_buffer;
    
    // render variables
    unsigned long num_faces = 0;
    unsigned long num_edges = 0;
    
    Scheme *scheme;
    SchemeController *scheme_controller;
public:
    ~RenderPipeline();
    
    int init();
    void SetScheme(Scheme *sch);
    void SetSchemeController(SchemeController *sctr);
    void SetBuffers(id<MTLBuffer> vb, id<MTLBuffer> fb, id<MTLBuffer> eb, unsigned long nf, unsigned long ne);
    
    void SetPipeline();
    
    void Render();
};

#endif /* RenderPipeline_h */
