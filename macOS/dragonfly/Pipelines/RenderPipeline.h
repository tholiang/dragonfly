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
    MTLRenderPassDescriptor* render_pass_descriptor;
    CAMetalLayer *layer;
    
    SDL_Window* window;
    SDL_Renderer* renderer;
    
    int window_width;
    int window_height;
    
    id <MTLDevice> device;
    id <MTLCommandQueue> command_queue;
    id<MTLLibrary> library;
    
    id <MTLRenderPipelineState> triangle_render_pipeline_state;
    id <MTLRenderPipelineState> face_render_pipeline_state;
    id <MTLRenderPipelineState> scene_edge_render_pipeline_state;
    id <MTLRenderPipelineState> scene_line_render_pipeline_state;
    id <MTLRenderPipelineState> scene_point_render_pipeline_state;
    id <MTLRenderPipelineState> scene_dot_render_pipeline_state;

    id <MTLRenderPipelineState> scene_node_render_pipeline_state;

    id <MTLDepthStencilState> depth_state;
    id <MTLTexture> depth_texture;
    
    // buffers for scene render
    id <MTLBuffer> scene_projected_vertex_buffer;
    id <MTLBuffer> scene_face_buffer;
    
    id <MTLBuffer> scene_projected_node_buffer;
    
    id <MTLBuffer> scene_projected_dot_buffer;
    id <MTLBuffer> scene_line_buffer;
    id <MTLBuffer> scene_slice_plates_buffer;
    
    id <MTLBuffer> scene_vertex_render_uniforms_buffer;
    id <MTLBuffer> scene_selected_vertices_buffer;
    id <MTLBuffer> scene_node_render_uniforms_buffer;
    
    // buffers for controls models compute
    id <MTLBuffer> controls_projected_vertex_buffer;
    id <MTLBuffer> controls_faces_buffer;
    
    Scheme *scheme;
    SchemeController *scheme_controller;
public:
    ~RenderPipeline();
    
    int init();
    void SetScheme(Scheme *sch);
    void SetSchemeController(SchemeController *sctr);
    void SetBuffers(id<MTLBuffer> spv, id<MTLBuffer> sf, id<MTLBuffer> spn, id<MTLBuffer> spd, id<MTLBuffer> ssl, id<MTLBuffer> ssp, id<MTLBuffer> svru, id<MTLBuffer> ssv, id<MTLBuffer> snru, id<MTLBuffer> cpv, id<MTLBuffer> cf);
    
    void SetPipeline();
    
    void Render();
};

#endif /* RenderPipeline_h */
