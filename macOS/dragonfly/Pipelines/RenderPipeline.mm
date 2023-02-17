//
//  RenderPipeline.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "RenderPipeline.h"

RenderPipeline::~RenderPipeline() {
    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

int RenderPipeline::init () {
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

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
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

void RenderPipeline::SetScheme(Scheme *sch) {
    scheme = sch;
}

void RenderPipeline::SetSchemeController(SchemeController *sctr) {
    scheme_controller = sctr;
}

void RenderPipeline::SetBuffers(id<MTLBuffer> spv, id<MTLBuffer> sf, id<MTLBuffer> spn, id<MTLBuffer> spd, id<MTLBuffer> ssl, id<MTLBuffer> svru, id<MTLBuffer> ssv, id<MTLBuffer> snru, id<MTLBuffer> cpv, id<MTLBuffer> cf) {
    scene_projected_vertex_buffer = spv;
    scene_face_buffer = sf;
    scene_projected_node_buffer = spn;
    scene_projected_dot_buffer = spd;
    scene_line_buffer = ssl;
    scene_vertex_render_uniforms_buffer = svru;
    scene_selected_vertices_buffer = ssv;
    scene_node_render_uniforms_buffer = snru;
    
    controls_projected_vertex_buffer = cpv;
    controls_faces_buffer = cf;
}

void RenderPipeline::SetPipeline () {
    CGSize drawableSize = layer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:drawableSize.width height:drawableSize.height mipmapped:NO];
    descriptor.storageMode = MTLStorageModePrivate;
    descriptor.usage = MTLTextureUsageRenderTarget;
    depth_texture = [device newTextureWithDescriptor:descriptor];
    depth_texture.label = @"DepthStencil";
    
    MTLRenderPipelineDescriptor *render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"DefaultVertexShader"];
    render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *edge_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    edge_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"VertexEdgeShader"];
    edge_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    edge_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    edge_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *line_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    line_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"LineShader"];
    line_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    line_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    line_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *scene_point_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    scene_point_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"VertexPointShader"];
    scene_point_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    scene_point_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    scene_point_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *scene_node_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    scene_node_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"NodeShader"];
    scene_node_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    scene_node_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    scene_node_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    face_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:render_pipeline_descriptor error:nil];
    scene_edge_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:edge_render_pipeline_descriptor error:nil];
    scene_line_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:line_render_pipeline_descriptor error:nil];
    scene_point_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:scene_point_render_pipeline_descriptor error:nil];
    scene_node_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:scene_node_render_pipeline_descriptor error:nil];
    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    [depth_descriptor setDepthCompareFunction: MTLCompareFunctionLessEqual];
    [depth_descriptor setDepthWriteEnabled: true];
    depth_state = [device newDepthStencilStateWithDescriptor: depth_descriptor];
}

void RenderPipeline::Render() {
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
    
    //render_pass_descriptor.renderTargetWidth = window_width;
    //render_pass_descriptor.renderTargetHeight = window_height;
    id <MTLRenderCommandEncoder> render_encoder = [render_command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];
    [render_encoder pushDebugGroup:@"dragonfly"];
    
    [render_encoder setDepthStencilState: depth_state];
    
    unsigned long num_vertices = scheme->NumSceneVertices();
    unsigned long num_faces = scheme->NumSceneFaces();
    unsigned long num_nodes = scheme->NumSceneNodes();
    
    if (num_vertices > 0 && num_faces > 0 && num_nodes > 0) {
        // rendering scene - the faces
        if (scheme->ShouldRenderFaces()) {
            [render_encoder setRenderPipelineState:face_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
            [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_faces*3];
        }
        
        // rendering the edges
        if (scheme->ShouldRenderEdges()) {
            [render_encoder setRenderPipelineState:scene_edge_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
            //[render_encoder setVertexBuffer:edge_render_uniforms_buffer offset:0 atIndex:2];
            for (int i = 0; i < num_faces*4; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeLineStrip vertexStart:i vertexCount:4];
            }
        }
        
        // rendering the vertex points
        if (scheme->ShouldRenderVertices()) {
            [render_encoder setRenderPipelineState:scene_point_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_vertex_render_uniforms_buffer offset:0 atIndex:1];
            [render_encoder setVertexBuffer:scene_selected_vertices_buffer offset:0 atIndex:2];
            for (int i = 0; i < num_vertices*4; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
            }
        }
        
        // rendering nodes
        if (scheme->ShouldRenderNodes()) {
            [render_encoder setRenderPipelineState:scene_node_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_node_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_node_render_uniforms_buffer offset:0 atIndex:1];
            for (int i = 0; i < num_nodes*40; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
            }
        }
    }
    
    unsigned long num_dots = scheme->NumSceneDots();
    
    if (num_dots > 0) {
        if (scheme->ShouldRenderSlices()) {
            [render_encoder setRenderPipelineState:scene_point_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_dot_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_vertex_render_uniforms_buffer offset:0 atIndex:1];
            [render_encoder setVertexBuffer:scene_selected_vertices_buffer offset:0 atIndex:2];
            for (int i = 0; i < num_dots*4; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
            }
        }
    }
    
    unsigned long num_slice_edges = scheme->NumSceneLines();
    
    if (num_slice_edges > 0) {
        if (scheme->ShouldRenderSlices()) {
            [render_encoder setRenderPipelineState:scene_line_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_projected_dot_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_line_buffer offset:0 atIndex:1];
            [render_encoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:num_slice_edges*2];
        }
    }
    
    unsigned long num_controls_vertices = scheme->NumControlsVertices();
    unsigned long num_controls_faces = scheme->NumControlsFaces();
    
    if (num_controls_vertices > 0 && num_controls_faces > 0) {
        // rendering controls models - the faces
        [render_encoder setRenderPipelineState:face_render_pipeline_state];
        [render_encoder setVertexBuffer:controls_projected_vertex_buffer offset:0 atIndex:0];
        [render_encoder setVertexBuffer:controls_faces_buffer offset:0 atIndex:1];
        [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:num_controls_faces*3];
    }
    
    // Start the Dear ImGui frame
    ImGui_ImplMetal_NewFrame(render_pass_descriptor);
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    
    scheme_controller->BuildUI();
    
    scheme = scheme_controller->GetScheme();
    scheme->BuildUI();
    
    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), render_command_buffer, render_encoder); // ImGui changes the encoders pipeline here to use its shaders and buffers
     
    // End rendering and display
    [render_encoder popDebugGroup];
    [render_encoder endEncoding];
    
    [render_command_buffer presentDrawable:drawable];
    [render_command_buffer commit];
}
