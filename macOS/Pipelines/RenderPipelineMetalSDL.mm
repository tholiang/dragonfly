//
//  RenderPipeline.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "RenderPipelineMetalSDL.h"

RenderPipelineMetalSDL::~RenderPipelineMetalSDL() {
    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

int RenderPipelineMetalSDL::init () {
    // Setup ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // Setup IO
    io.WantCaptureKeyboard = true;

    // Setup style
    ImGui::StyleColorsDark();

    // Setup SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
    {
        printf("Error: %s\n", SDL_GetError());
        return -1;
    }

    // Inform SDL that we will be using metal for rendering. Without this hint initialization of metal renderer may fail.
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    
    // get screen size
    SDL_DisplayMode DM;
    SDL_GetCurrentDisplayMode(0, &DM);
    auto width = DM.w;
    auto height = DM.h;
    
    std::cout<<width<<" "<<height<<std::endl;
    window = SDL_CreateWindow("dragonfly", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    if (window == NULL)
    {
        printf("Error creating window: %s\n", SDL_GetError());
        return -2;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED/* | SDL_RENDERER_PRESENTVSYNC*/);
    if (renderer == NULL)
    {
        printf("Error creating renderer: %s\n", SDL_GetError());
        return -3;
    }

    // Setup Platform/Renderer backends
    layer = (__bridge CAMetalLayer*)SDL_RenderGetMetalLayer(renderer);
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    device = layer.device;
    
    ImGui_ImplMetal_Init(device);
    ImGui_ImplSDL2_InitForMetal(window);

    command_queue = [layer.device newCommandQueue];
    render_pass_descriptor = [MTLRenderPassDescriptor new];
    library = [device newDefaultLibrary];
    
    SetPipeline();
    
    SDL_SetWindowSize(window, 1080, 700);
    
    return SDL_GetWindowID(window);
}

void RenderPipelineMetalSDL::SetBuffer(unsigned long idx, id <MTLBuffer> buf, unsigned long cap) {
    compute_buffers[idx] = buf;
    compute_buffer_capacities[idx] = cap;
}

void RenderPipelineMetalSDL::SetPipeline () {
    // drawable and depth texture
    CGSize drawableSize = layer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:drawableSize.width height:drawableSize.height mipmapped:NO];
    descriptor.storageMode = MTLStorageModePrivate;
    descriptor.usage = MTLTextureUsageRenderTarget;
    depth_texture = [device newTextureWithDescriptor:descriptor];
    depth_texture.label = @"DepthStencil";
    
    // make default face render pipeline
    MTLRenderPipelineDescriptor *default_face_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    default_face_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"DefaultFaceShader"];
    default_face_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    default_face_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    default_face_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    default_face_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:default_face_render_pipeline_descriptor error:nil];
    
    // make default edge render pipeline
    MTLRenderPipelineDescriptor *default_edge_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    default_edge_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"SuperDefaultEdgeShader"];
    default_edge_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    default_edge_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    default_edge_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    default_edge_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:default_edge_render_pipeline_descriptor error:nil];
    
    // make depth state
    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    [depth_descriptor setDepthCompareFunction: MTLCompareFunctionLessEqual];
    [depth_descriptor setDepthWriteEnabled: true];
    depth_state = [device newDepthStencilStateWithDescriptor: depth_descriptor];
}

void RenderPipelineMetalSDL::Render() {
    // get/set render variables
    SDL_GetRendererOutputSize(renderer, &window_width, &window_height);
    
    layer.drawableSize = CGSizeMake(window_width, window_height);
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    
    id<MTLCommandBuffer> render_command_buffer = [command_queue commandBuffer];
    render_pass_descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.6, 0.6, 0.6, 1);
    render_pass_descriptor.colorAttachments[0].texture = drawable.texture;
    render_pass_descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    render_pass_descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    render_pass_descriptor.depthAttachment.texture = depth_texture;
    render_pass_descriptor.depthAttachment.clearDepth = 1.0;
    render_pass_descriptor.depthAttachment.loadAction = MTLLoadActionClear;
    render_pass_descriptor.depthAttachment.storeAction = MTLStoreActionStore;
    
    id <MTLRenderCommandEncoder> render_encoder = [render_command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];
    [render_encoder pushDebugGroup:@"dragonfly"];
    [render_encoder setDepthStencilState: depth_state];
    
    // if there are faces to render, render
    if (num_faces > 0) {
        [render_encoder setRenderPipelineState:default_face_render_pipeline_state];
        [render_encoder setVertexBuffer:compute_buffers[CPT_COMPCOMPVERTEX_OUTBUF_IDX] offset:0 atIndex:0];
        [render_encoder setVertexBuffer:compute_buffers[CPT_COMPCOMPFACE_OUTBUF_IDX] offset:0 atIndex:1];
        [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:compute_buffer_capacities[CPT_COMPCOMPFACE_OUTBUF_IDX]*3]; // TODO: might be wrong
    }
    
    // TODO: edges
    // if there are edges to render, render
//    if (num_edges > 0) {
//        [render_encoder setRenderPipelineState:default_edge_render_pipeline_state];
//        [render_encoder setVertexBuffer:compute_buffers[CPT_COMPCOMPVERTEX_OUTBUF_IDX] offset:0 atIndex:0];
//        [render_encoder setVertexBuffer:compute_buffers[CPT_] offset:0 atIndex:1];
//        [render_encoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:num_edges*2];
//    }
    
    // Start the Dear ImGui frame
    ImGui_ImplMetal_NewFrame(render_pass_descriptor);
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    
//    scheme_controller->BuildUI();
//
//    scheme = scheme_controller->GetScheme();
//    scheme->BuildUI();
    
    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), render_command_buffer, render_encoder); // ImGui changes the encoders pipeline here to use its shaders and buffers
    
    // End rendering and display
    [render_encoder popDebugGroup];
    [render_encoder endEncoding];
    
    [render_command_buffer presentDrawable:drawable];
    [render_command_buffer commit];
}
