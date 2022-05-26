//
//  main.m
//  dragonfly
//
//  Created by Thomas Liang on 1/13/22.
//

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <math.h>

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include <SDL.h>
#include <simd/SIMD.h>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "Model.h"
#include "Arrow.h"

struct Camera {
    simd_float3 pos;
    simd_float3 vector;
    simd_float3 up_vector;
    simd_float2 FOV;
};

struct Pixel {
    int x;
    int y;
};

struct ModelUniforms {
    simd_float3 position;
    simd_float3 rotate_origin;
    simd_float3 angle; // euler angles zyx
};

struct Uniforms {
    uint32 modelID;
    uint32 num_faces;
    uint32 selected_face;
    simd_float3 selected_vertex;
};

struct VertexRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    vector_int3 selected_vertices;
};

/*struct EdgeRenderUniforms {
    vector_int2 selected_edge = -1;
};*/

// screen variables
int window_width = 1280;
int window_height = 720;
float aspect_ratio = 1280.0/720.0;

float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
bool show_main_window = true;

// imgui/sdl variables
SDL_Window* window;
SDL_Renderer* renderer;
float fps = 0;

// metal variables
MTLRenderPassDescriptor* render_pass_descriptor;

CAMetalLayer *layer;
id <MTLDevice> device;
id <MTLCommandQueue> command_queue;

std::vector<simd_float3> scene_vertices;
std::vector<Face> scene_faces;
std::vector<uint32> modelIDs;
unsigned arrows_vertex_end = 0;
unsigned arrows_face_end = 0;

id <MTLComputePipelineState> scene_compute_rotated_pipeline_state;
id <MTLComputePipelineState> scene_compute_projected_pipeline_state;

id <MTLComputePipelineState> scene_compute_mouse_click_state;

id <MTLRenderPipelineState> scene_render_pipeline_state;
id <MTLRenderPipelineState> scene_edge_render_pipeline_state;
id <MTLRenderPipelineState> scene_point_render_pipeline_state;

id <MTLDepthStencilState> depth_state;

id <MTLBuffer> scene_vertex_buffer;
id <MTLBuffer> scene_face_buffer;
id <MTLBuffer> scene_model_id_buffer;
id <MTLBuffer> scene_camera_buffer;
id <MTLBuffer> rotate_uniforms_buffer;
id <MTLBuffer> vertex_render_uniforms_buffer;
//id <MTLBuffer> edge_render_uniforms_buffer;

//id <MTLBuffer> selected_model_buffer;
//id <MTLBuffer> click_loc_buffer;
//id <MTLBuffer> click_z_buffer;

id <MTLTexture> depth_texture;

// scene variables
Camera *camera;
Model *cube;
Arrow *z_arrow;
Arrow *x_arrow;
Arrow *y_arrow;
std::vector<Model *> models;
std::vector<ModelUniforms> model_uniforms;
VertexRenderUniforms vertex_render_uniforms;
//EdgeRenderUniforms edge_render_uniforms;

// input variables
bool left_clicked = false;
bool right_clicked = false;
bool ctrl_down = false;
bool left_mouse_down = false;
bool right_mouse_down = false;

bool render_rightclick_popup = false;
simd_float2 rightclick_popup_loc;

enum SelectionMode { SM_ALL, SM_NONE };
SelectionMode selection_mode = SM_ALL;

enum EditMode { EM_DEFAULT, EM_ADD_VERTEX };
EditMode edit_mode = EM_DEFAULT;

//bool potential_vertex_included = false;

int selected_face = -1;
vector_int2 selected_edge;
int selected_vertex = -1;

bool show_arrows = false;
int ARROW_VERTEX_SIZE = 18;
int ARROW_FACE_SIZE = 22;
// z base, z tip, x base, x tip, y base, y tip
simd_float2 arrow_projections [6];
// z, x, y
int selected_arrow = -1;

simd_float2 click_loc;
simd_float2 mouse_loc;
float click_z = 50; // render dist

// w a s d space shift
bool key_presses[6] = { 0 };
float x_sens = 0.1;
float y_sens = 0.1;

simd_float3 TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return simd_make_float3(x, y, z);
}

simd_float3 BiAvg (simd_float3 p1, simd_float3 p2) {
    float x = (p1.x + p2.x)/2;
    float y = (p1.y + p2.y)/2;
    float z = (p1.z + p2.z)/2;
    
    return simd_make_float3(x, y, z);
}

float sign (simd_float2 &p1, simd_float3 &p2, simd_float3 &p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float dist (simd_float2 &p1, simd_float3 &p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

float WeightedZ (simd_float2 &click, simd_float3 &p1, simd_float3 &p2, simd_float3 &p3) {
    float dist1 = dist(click, p1);
    float dist2 = dist(click, p2);
    float dist3 = dist(click, p3);
    
    float total_dist = dist1 + dist2 + dist3;
    float weightedZ = p1.z*(dist1/total_dist);
    weightedZ += p2.z*(dist2/total_dist);
    weightedZ += p3.z*(dist3/total_dist);
    return weightedZ;
}

simd_float3 CrossProduct (simd_float3 p1, simd_float3 p2) {
    simd_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

/*simd_float3 LinePlaneIntersect (simd_float3 line_origin, simd_float3 line_vector, simd_float3 plane1, simd_float3 plane2, simd_float3 plane3) {
    simd_float3 plane_vec1 = simd_make_float3(plane1.x-plane2.x, plane1.y-plane2.y, plane1.z-plane2.z);
    simd_float3 plane_vec2 = simd_make_float3(plane1.x-plane3.x, plane1.y-plane3.y, plane1.z-plane3.z);
    simd_float3 plane_norm = CrossProduct(plane_vec1, plane_vec2);
    
    float k = -(plane_norm.x*plane1.x + plane_norm.y*plane1.y + plane_norm.z*plane1.z);
    
    //std::cout<<plane_norm.x<<"x + "<<plane_norm.y<<"y + "<<plane_norm.z<<"z + "<<k<<" = 0"<<std::endl;
    
    float intersect_const = k + plane_norm.x*line_origin.x + plane_norm.y*line_origin.y + plane_norm.z*line_origin.z;
    float intersect_coeff = plane_norm.x*line_vector.x + plane_norm.y*line_vector.y + plane_norm.z*line_vector.z;
    
    float distto = -intersect_const/intersect_coeff;
    
    //std::cout<<"t = "<<distto<<std::endl;
    
    simd_float3 intersect = simd_make_float3(distto*line_vector.x + line_origin.x, distto*line_vector.y + line_origin.y, distto*line_vector.z + line_origin.z);
    
    //std::cout<<intersect.x<<" "<<intersect.y<<" "<<intersect.z<<std::endl;
    //std::cout<<distto<<std::endl;
    return intersect;
}*/

/*simd_float3 MouseFaceIntercept (simd_float2 &mouse, int fid) {
    Face face = scene_faces.at(fid);
    simd_float3 mouse_angle = simd_make_float3(atan(mouse.x*tan(camera->FOV.x/2)), -atan(mouse.y*tan(camera->FOV.y/2)), 1);
    
    std::cout<<mouse_angle.x<<" "<<mouse_angle.y<<std::endl;
    
    //get current camera angles (phi is vertical and theta is horizontal)
    //get the new change based on the amount the mouse moved
    float cam_phi = atan2(camera->vector.y, camera->vector.x);
    
    float cam_theta = acos(camera->vector.z);
    
    //get mouse phi and theta angles
    float new_phi = cam_phi + mouse_angle.x;
    float new_theta = cam_theta + mouse_angle.y;
    
    //find vector
    simd_float3 mouse_vec = simd_make_float3(sin(new_theta)*cos(new_phi), sin(new_theta)*sin(new_phi), cos(new_theta));
    
    //std::cout<<mouse_vec.x<<" "<<mouse_vec.y<<" "<<mouse_vec.z<<std::endl;
    
    //std::cout<<"x: "<<mouse_vec.x<<"t + "<<camera->pos.x<<std::endl;
    //std::cout<<"y: "<<mouse_vec.y<<"t + "<<camera->pos.y<<std::endl;
    //std::cout<<"z: "<<mouse_vec.z<<"t + "<<camera->pos.z<<std::endl;
    
    return LinePlaneIntersect(camera->pos, mouse_vec, scene_vertices.at(face.vertices[0]), scene_vertices.at(face.vertices[1]), scene_vertices.at(face.vertices[2]));
}*/

bool InTriangle(vector_float2 &point, vector_float3 v1, vector_float3 v2, vector_float3 v3) {
    float d1 = sign(point, v1, v2);
    float d2 = sign(point, v2, v3);
    float d3 = sign(point, v3, v1);

    bool has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    bool has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return (!(has_neg && has_pos));
}

void FaceClicked() {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    vector_float3 *vertices = (vector_float3 *) scene_vertex_buffer.contents;
    Face *face_array = (Face *) scene_face_buffer.contents;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    for (int fid = 0; fid < scene_faces.size(); fid++) {
        Face face = face_array[fid];
        vector_float3 v1 = vertices[face.vertices[0]];
        vector_float3 v2 = vertices[face.vertices[1]];
        vector_float3 v3 = vertices[face.vertices[2]];

        if (InTriangle(click_loc, v1, v2, v3)) {
            float z = WeightedZ(click_loc, v1, v2, v3);
            if (minZ == -1 || z < minZ) {
                minZ = z;
                clickedIdx = fid;
            }
        }
    }
    
    if (clickedIdx != -1 && minZ < click_z) {
        if (clickedIdx >= arrows_face_end) {
            selected_face = clickedIdx;
            selected_vertex = -1;
            selected_edge.x = -1;
            selected_edge.y = -1;
        } else {
            selected_arrow = clickedIdx/ARROW_FACE_SIZE;
        }
        click_z = minZ;
    } else {
        selected_face = -1;
    }
}

void VertexClicked() {
    simd_float3 *vertices = (simd_float3 *) scene_vertex_buffer.contents;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    for (int vid = arrows_vertex_end; vid < scene_vertices.size(); vid++) {
        simd_float3 vertex = vertices[vid];
        float x_min = vertex.x-0.007;
        float x_max = vertex.x+0.007;
        float y_min = vertex.y-0.007 * aspect_ratio;
        float y_max = vertex.y+0.007 * aspect_ratio;
        
        if (click_loc.x <= x_max && click_loc.x >= x_min && click_loc.y <= y_max && click_loc.y >= y_min) {
            if (minZ == -1 || vertex.z < minZ) {
                minZ = vertex.z;
                clickedIdx = vid;
            }
        }
    }
    
    if (clickedIdx != -1 && minZ < click_z) {
        selected_vertex = clickedIdx;
        selected_face = -1;
        selected_edge.x = -1;
        selected_edge.y = -1;
        click_z = minZ;
    } else if (selected_arrow == -1) {
        selected_vertex = -1;
    }
}

void EdgeClicked() {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    simd_float3 *vertices = (simd_float3 *) scene_vertex_buffer.contents;
    Face *face_array = (Face *) scene_face_buffer.contents;
    
    float minZ = -1;
    int clickedv1 = -1;
    int clickedv2 = -1;
    
    for (int fid = arrows_face_end; fid < scene_faces.size(); fid++) {
        Face face = face_array[fid];
        
        for (int vid = 0; vid < 3; vid++) {
            vector_float3 v1 = vertices[face.vertices[vid]];
            vector_float3 v2 = vertices[face.vertices[(vid+1) % 3]];
            
            vector_float2 edgeVec = simd_make_float2(v1.x-v2.x, v1.y-v2.y);
            float mag = sqrt(pow(edgeVec.x, 2) + pow(edgeVec.y, 2));
            if (mag == 0) {
                continue;
            }
            edgeVec.x /= mag;
            edgeVec.y /= mag;
            
            edgeVec.x *= 0.01;
            edgeVec.y *= 0.01;
            
            vector_float3 v1plus = simd_make_float3(v1.x+edgeVec.y, v1.y-edgeVec.x, v1.z);
            vector_float3 v1sub = simd_make_float3(v1.x-edgeVec.y, v1.y+edgeVec.x, v1.z);
            vector_float3 v2plus = simd_make_float3(v2.x+edgeVec.y, v2.y-edgeVec.x, v2.z);
            vector_float3 v2sub = simd_make_float3(v2.x-edgeVec.y, v2.y+edgeVec.x, v2.z);
            
            if (InTriangle(click_loc, v1plus, v1sub, v2plus) || InTriangle(click_loc, v1sub, v2sub, v2plus)) {
                float dist1 = dist(click_loc, v1);
                float dist2 = dist(click_loc, v2);
                
                float total_dist = dist1 + dist2;
                float weightedZ = v1.z*(dist1/total_dist);
                weightedZ += v2.z*(dist2/total_dist);
                float z = weightedZ;
                
                if (minZ == -1 || z < minZ) {
                    minZ = z;
                    clickedv1 = face.vertices[vid];
                    clickedv2 = face.vertices[(vid+1) % 3];
                }
            }
        }
    }
    
    if (clickedv1 != -1 && minZ < click_z) {
        selected_edge = simd_make_int2(clickedv1, clickedv2);
        selected_face = -1;
        selected_vertex = -1;
        click_z = minZ;
    } else if (selected_arrow == -1) {
        selected_edge = simd_make_int2(-1, -1);
    }
}

/*void HandlePotentialVertex() {
    Face f = scene_faces.at(selected_face);
    vector_float3 *vertices = (vector_float3 *) scene_vertex_buffer.contents;
    
    if (InTriangle(mouse_loc, vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]])) {
        simd_float3 new_vertex = MouseFaceIntercept(mouse_loc, selected_face);
        
        //std::cout<<new_vertex.x<<" "<<new_vertex.y<<" "<<new_vertex.z<<std::endl;
        scene_vertices.push_back(new_vertex);
        
        potential_vertex_included = true;
    }
}*/

void AddVertexToFace (int fid) {
    int modelID = modelIDs[scene_faces[fid].vertices[0]];
    Model *model = models[modelID];
    unsigned long modelFaceID = fid - model->FaceStart();
    
    Face *selected = model->GetFace(modelFaceID);
    unsigned vid1 = selected->vertices[0];
    unsigned vid2 = selected->vertices[1];
    unsigned vid3 = selected->vertices[2];
    simd_float3 *v1 = model->GetVertex(vid1);
    simd_float3 *v2 = model->GetVertex(vid2);
    simd_float3 *v3 = model->GetVertex(vid3);
    
    simd_float3 new_v = TriAvg(*v1, *v2, *v3);
    unsigned new_vid = model->MakeVertex(new_v.x, new_v.y, new_v.z);
    
    //1,2,new
    selected->vertices[2] = new_vid;
    
    //2,3,new
    model->MakeFace(vid2, vid3, new_vid, selected->color);
    
    //1,3,new
    model->MakeFace(vid1, vid3, new_vid, selected->color);
}

void CreateScenePipelineStates () {
    CGSize drawableSize = layer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:drawableSize.width height:drawableSize.height mipmapped:NO];
    descriptor.storageMode = MTLStorageModePrivate;
    descriptor.usage = MTLTextureUsageRenderTarget;
    depth_texture = [device newTextureWithDescriptor:descriptor];
    depth_texture.label = @"DepthStencil";
    
    MTLRenderPipelineDescriptor *render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    id <MTLLibrary> library = [device newDefaultLibrary];
    
    render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"DefaultVertexShader"];
    render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *edge_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    edge_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"VertexEdgeShader"];
    edge_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    edge_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    edge_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    MTLRenderPipelineDescriptor *scene_point_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    scene_point_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"VertexPointShader"];
    scene_point_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    scene_point_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    scene_point_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    scene_compute_rotated_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateRotatedVertices"] error:nil];
    scene_compute_projected_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedVertices"] error:nil];
    //scene_compute_mouse_click_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"FaceClicked"] error:nil];
    scene_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:render_pipeline_descriptor error:nil];
    scene_edge_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:edge_render_pipeline_descriptor error:nil];
    scene_point_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:scene_point_render_pipeline_descriptor error:nil];
    
    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    [depth_descriptor setDepthCompareFunction: MTLCompareFunctionLessEqual];
    [depth_descriptor setDepthWriteEnabled: true];
    depth_state = [device newDepthStencilStateWithDescriptor: depth_descriptor];
}

void CreateBuffers() {
    if (show_arrows) {
        z_arrow->AddToBuffers(scene_vertices, scene_faces, modelIDs);
        x_arrow->AddToBuffers(scene_vertices, scene_faces, modelIDs);
        y_arrow->AddToBuffers(scene_vertices, scene_faces, modelIDs);
    }
    
    arrows_vertex_end = scene_vertices.size();
    arrows_face_end = scene_faces.size();
    
    for (std::size_t i = 3; i < models.size(); i++) {
        models[i]->AddToBuffers(scene_vertices, scene_faces, modelIDs);
    }
    
    vertex_render_uniforms.selected_vertices = simd_make_int3(-1, -1, -1);
    
    if (selected_face != -1) {
        simd_float3 triavg = TriAvg(scene_vertices[scene_faces[selected_face].vertices[0]], scene_vertices[scene_faces[selected_face].vertices[1]], scene_vertices[scene_faces[selected_face].vertices[2]]);
        model_uniforms[0].position = triavg;
        model_uniforms[1].position = triavg;
        model_uniforms[2].position = triavg;
        model_uniforms[0].rotate_origin = triavg;
        model_uniforms[1].rotate_origin = triavg;
        model_uniforms[2].rotate_origin = triavg;
        //scene_faces.at(selected_face).color = simd_make_float4(1, 0.5, 0, 1);
        
        vertex_render_uniforms.selected_vertices.x = scene_faces[selected_face].vertices[0];
        vertex_render_uniforms.selected_vertices.y = scene_faces[selected_face].vertices[1];
        vertex_render_uniforms.selected_vertices.z = scene_faces[selected_face].vertices[2];
    }
    
    if (selected_edge.x != -1) {
        simd_float3 biavg = BiAvg(scene_vertices[selected_edge.x], scene_vertices[selected_edge.y]);
        model_uniforms[0].position = biavg;
        model_uniforms[1].position = biavg;
        model_uniforms[2].position = biavg;
        model_uniforms[0].rotate_origin = biavg;
        model_uniforms[1].rotate_origin = biavg;
        model_uniforms[2].rotate_origin = biavg;
        
        vertex_render_uniforms.selected_vertices.x = selected_edge.x;
        vertex_render_uniforms.selected_vertices.y = selected_edge.y;
    }
    
    if (selected_vertex != -1) {
        simd_float3 vertex_loc = scene_vertices[selected_vertex];
        model_uniforms[0].position = vertex_loc;
        model_uniforms[1].position = vertex_loc;
        model_uniforms[2].position = vertex_loc;
        model_uniforms[0].rotate_origin = vertex_loc;
        model_uniforms[1].rotate_origin = vertex_loc;
        model_uniforms[2].rotate_origin = vertex_loc;
        
        vertex_render_uniforms.selected_vertices.x = selected_vertex;
    }
    
    /*potential_vertex_included = false;
    if (edit_mode == EM_ADD_VERTEX) {
        HandlePotentialVertex();
    }*/
    
    scene_vertex_buffer = [device newBufferWithBytes:scene_vertices.data() length:(scene_vertices.size() * sizeof(simd_float3)) options:MTLResourceStorageModeShared];
    scene_face_buffer = [device newBufferWithBytes:scene_faces.data() length:(scene_faces.size() * sizeof(Face)) options:MTLResourceStorageModeShared];
    scene_model_id_buffer = [device newBufferWithBytes:modelIDs.data() length:(modelIDs.size() * sizeof(uint32)) options:MTLResourceStorageModeShared];
    scene_camera_buffer = [device newBufferWithBytes:camera length:sizeof(Camera) options:{}];
    rotate_uniforms_buffer = [device newBufferWithBytes: model_uniforms.data() length:(model_uniforms.size() * sizeof(ModelUniforms)) options:{}];
    vertex_render_uniforms_buffer = [device newBufferWithBytes: &vertex_render_uniforms length:(sizeof(VertexRenderUniforms)) options:{}];
    //edge_render_uniforms_buffer = [device newBufferWithBytes: &edge_render_uniforms length:(sizeof(EdgeRenderUniforms)) options:{}];
    
    //selected_face = -1;
    //click_z = -1;
    //selected_model_buffer = [device newBufferWithBytes:&selected_face length:sizeof(int) options:MTLResourceStorageModeShared];
    //click_loc_buffer = [device newBufferWithBytes:&click_loc length:sizeof(simd_float2) options:{}];
    //click_z_buffer = [device newBufferWithBytes:&click_z length:sizeof(float) options:{}];
}

int SetupImGui () {
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
    ImGui_ImplMetal_Init(layer.device);
    ImGui_ImplSDL2_InitForMetal(window);
    
    device = layer.device;

    command_queue = [layer.device newCommandQueue];
    render_pass_descriptor = [MTLRenderPassDescriptor new];
    
    return 0;
}

void RightClickPopup() {
    ImGui::SetCursorPos(ImVec2(window_width * (rightclick_popup_loc.x+1)/2, window_height * (2-(rightclick_popup_loc.y+1))/2));
    
    if (edit_mode == EM_DEFAULT) {
        if (ImGui::Button("Add Vertex")) {
            /*selection_mode = SM_NONE;
            edit_mode = EM_ADD_VERTEX;
            
            if (selected_face != -1) {
                selected_face -= ARROW_FACE_SIZE*3;
            }
            if (selected_vertex != -1) {
                selected_vertex -= ARROW_VERTEX_SIZE*3;
            }
            if (selected_edge.x != -1) {
                selected_edge.x -= ARROW_VERTEX_SIZE*3;
                selected_edge.y -= ARROW_VERTEX_SIZE*3;
            }
            show_arrows = false;*/
            render_rightclick_popup = false;
            AddVertexToFace(selected_face);
        }
    } else if (edit_mode == EM_ADD_VERTEX) {
        if (ImGui::Button("Cancel")) {
            selection_mode = SM_ALL;
            edit_mode = EM_DEFAULT;
            render_rightclick_popup = false;
            
            if (selected_face != -1) {
                selected_face += ARROW_FACE_SIZE*3;
            }
            if (selected_vertex != -1) {
                selected_vertex += ARROW_VERTEX_SIZE*3;
            }
            if (selected_edge.x != -1) {
                selected_edge.x += ARROW_VERTEX_SIZE*3;
                selected_edge.y += ARROW_VERTEX_SIZE*3;
            }
            show_arrows = true;
        }
    }
}

void RenderUI() {
    // scene window
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(window_width, window_height));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_main_window, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);

    // Display FPS
    ImGui::SetCursorPos(ImVec2(window_width - 80, 10));
    ImGui::Text("%.1f FPS", ImGui::GetIO().Framerate);
    ImGui::PopStyleColor();
    
    if (render_rightclick_popup) {
        RightClickPopup();
    }
    
    ImGui::End();
}

void HandleKeyboardEvents(SDL_Event event) {
    if (event.type == SDL_KEYDOWN) {
        SDL_Keysym keysym = event.key.keysym;
        switch (keysym.sym) {
            case 119:
                // w
                key_presses[0] = true;
                break;
            case 97:
                // a
                key_presses[1] = true;
                break;
            case 115:
                // s
                key_presses[2] = true;
                break;
            case 100:
                // d
                key_presses[3] = true;
                break;
            case 32:
                // spacebar
                key_presses[4] = true;
                break;
            case 1073742049:
                // shift
                key_presses[5] = true;
                break;
            case 1073742048:
                // control
                ctrl_down = true;
        }
    } else if (event.type == SDL_KEYUP) {
        SDL_Keysym keysym = event.key.keysym;
        switch (keysym.sym) {
            case 119:
                key_presses[0] = false;
                break;
            case 97:
                key_presses[1] = false;
                break;
            case 115:
                key_presses[2] = false;
                break;
            case 100:
                key_presses[3] = false;
                break;
            case 32:
                key_presses[4] = false;
                break;
            case 1073742049:
                key_presses[5] = false;
                break;
            case 1073742048:
                ctrl_down = false;
            default:
                break;
        }
    }
}

void HandleMouseEvents(SDL_Event event) {
    int x;
    int y;
    SDL_GetMouseState(&x, &y);
    mouse_loc.x = ((float) x / (float) window_width)*2 - 1;
    mouse_loc.y = -(((float) y / (float) window_height)*2 - 1);
    
    left_clicked = false;
    right_clicked = false;
    if (event.type == SDL_MOUSEBUTTONDOWN) {
        click_loc = mouse_loc;
        switch (event.button.button) {
            case SDL_BUTTON_LEFT:
                left_clicked = true;
                left_mouse_down = true;
                break;
            case SDL_BUTTON_RIGHT:
                right_clicked = true;
                right_mouse_down = true;
                break;
            default:
                break;
        }
    } else if (event.type == SDL_MOUSEBUTTONUP) {
        switch (event.button.button) {
            case SDL_BUTTON_LEFT:
                left_mouse_down = false;
                selected_arrow = -1;
                break;
            case SDL_BUTTON_RIGHT:
                right_mouse_down = false;
                break;
            default:
                break;
        }
    }
    
    if (event.type == SDL_MOUSEMOTION) {
        if (ctrl_down) {
            //get current camera angles (phi is vertical and theta is horizontal)
            //get the new change based on the amount the mouse moved
            float curr_phi = atan2(camera->vector.y, camera->vector.x);
            float phi_change = x_sens*event.motion.xrel*(M_PI/180);
            
            float curr_theta = acos(camera->vector.z);
            float theta_change = y_sens*event.motion.yrel*(M_PI/180);
            
            //get new phi and theta angles
            float new_phi = curr_phi + phi_change;
            float new_theta = curr_theta + theta_change;
            //set the camera "pointing" vector to spherical -> cartesian
            camera->vector.x = sin(new_theta)*cos(new_phi);
            camera->vector.y = sin(new_theta)*sin(new_phi);
            camera->vector.z = cos(new_theta);
            //set the camera perpendicular "up" vector the same way but adding pi/2 to theta
            camera->up_vector.x = sin(new_theta-M_PI_2)*cos(new_phi);
            camera->up_vector.y = sin(new_theta-M_PI_2)*sin(new_phi);
            camera->up_vector.z = cos(new_theta-M_PI_2);
        }
        
        if (edit_mode == EM_DEFAULT) {
            if (left_mouse_down && selected_arrow != -1) {
                // find the projected location of the tip and the base
                simd_float2 base = arrow_projections[selected_arrow*2];
                simd_float2 tip = arrow_projections[selected_arrow*2+1];
                
                // find direction to move
                float xDiff = tip.x-base.x;
                float yDiff = tip.y-base.y;
                
                float mvmt = xDiff * event.motion.xrel + yDiff * (-event.motion.yrel);
                
                // move
                ModelUniforms arrow_uniform = model_uniforms[selected_arrow];
                float x_vec = 0;
                float y_vec = 0;
                float z_vec = 1;
                // gimbal locked
                
                // around z axis
                //x_vec = x_vec*cos(arrow_uniform.angle.z)-y_vec*sin(arrow_uniform.angle.z);
                //y_vec = x_vec*sin(arrow_uniform.angle.z)+y_vec*cos(arrow_uniform.angle.z);
                
                // around y axis
                float newx = x_vec*cos(arrow_uniform.angle.y)+z_vec*sin(arrow_uniform.angle.y);
                z_vec = -x_vec*sin(arrow_uniform.angle.y)+z_vec*cos(arrow_uniform.angle.y);
                x_vec = newx;
                
                // around x axis
                float newy = y_vec*cos(arrow_uniform.angle.x)-z_vec*sin(arrow_uniform.angle.x);
                z_vec = y_vec*sin(arrow_uniform.angle.x)+z_vec*cos(arrow_uniform.angle.x);
                y_vec = newy;
                
                x_vec *= 0.01*mvmt;
                y_vec *= 0.01*mvmt;
                z_vec *= 0.01*mvmt;
                
                if (selected_face != -1) {
                    int modelID = modelIDs[scene_faces[selected_face].vertices[0]];
                    Model *model = models[modelID];
                    unsigned long modelFaceID = selected_face - model->FaceStart();
                    Face *selected = model->GetFace(modelFaceID);
                    simd_float3 *v1 = model->GetVertex(selected->vertices[0]);
                    simd_float3 *v2 = model->GetVertex(selected->vertices[1]);
                    simd_float3 *v3 = model->GetVertex(selected->vertices[2]);
                    
                    v1->x += x_vec;
                    v1->y += y_vec;
                    v1->z += z_vec;
                    
                    v2->x += x_vec;
                    v2->y += y_vec;
                    v2->z += z_vec;
                    
                    v3->x += x_vec;
                    v3->y += y_vec;
                    v3->z += z_vec;
                } else if (selected_vertex != -1) {
                    int modelID = modelIDs[selected_vertex];
                    Model *model = models[modelID];
                    unsigned long modelVertexID = selected_vertex - model->VertexStart();
                    simd_float3 *v = model->GetVertex(modelVertexID);
                    v->x += x_vec;
                    v->y += y_vec;
                    v->z += z_vec;
                } else if (selected_edge.x != -1) {
                    int modelID = modelIDs[selected_edge.x];
                    Model *model = models[modelID];
                    unsigned long modelVertex1ID = selected_edge.x - model->VertexStart();
                    unsigned long modelVertex2ID = selected_edge.y - model->VertexStart();
                    simd_float3 *v1 = model->GetVertex(modelVertex1ID);
                    simd_float3 *v2 = model->GetVertex(modelVertex2ID);
                    v1->x += x_vec;
                    v1->y += y_vec;
                    v1->z += z_vec;
                    
                    v2->x += x_vec;
                    v2->y += y_vec;
                    v2->z += z_vec;
                }
            }
        }
    }
}

void HandleCameraInput() {
    // find unit vector of xy camera vector
    float magnitude = sqrt(pow(camera->vector.x, 2)+pow(camera->vector.y, 2));
    float unit_x = camera->vector.x/magnitude;
    float unit_y = camera->vector.y/magnitude;
    
    if (key_presses[0]) {
        camera->pos.x += (3.0/fps)*unit_x;
        camera->pos.y += (3.0/fps)*unit_y;
    }
    if (key_presses[1]) {
        camera->pos.y -= (3.0/fps)*unit_x;
        camera->pos.x += (3.0/fps)*unit_y;
    }
    if (key_presses[2]) {
        camera->pos.x -= (3.0/fps)*unit_x;
        camera->pos.y -= (3.0/fps)*unit_y;
    }
    if (key_presses[3]) {
        camera->pos.y += (3.0/fps)*unit_x;
        camera->pos.x -= (3.0/fps)*unit_y;
    }
    if (key_presses[4]) {
        camera->pos.z += (3.0/fps);
    }
    if (key_presses[5]) {
        camera->pos.z -= (3.0/fps);
    }
}

void SetArrowProjections() {
    simd_float3 * contents = (simd_float3 *) scene_vertex_buffer.contents;
    arrow_projections[0].x = contents[0].x;
    arrow_projections[0].y = contents[0].y;
    arrow_projections[1].x = contents[12].x;
    arrow_projections[1].y = contents[12].y;
    
    arrow_projections[2].x = contents[ARROW_VERTEX_SIZE].x;
    arrow_projections[2].y = contents[ARROW_VERTEX_SIZE].y;
    arrow_projections[3].x = contents[ARROW_VERTEX_SIZE+12].x;
    arrow_projections[3].y = contents[ARROW_VERTEX_SIZE+12].y;
    
    arrow_projections[4].x = contents[ARROW_VERTEX_SIZE*2].x;
    arrow_projections[4].y = contents[ARROW_VERTEX_SIZE*2].y;
    arrow_projections[5].x = contents[ARROW_VERTEX_SIZE*2+12].x;
    arrow_projections[5].y = contents[ARROW_VERTEX_SIZE*2+12].y;
}

int main(int, char**) {
    if (SetupImGui() != 0) {
        return -1;
    }
    
    selected_edge = simd_make_int2(-1, -1);
    
    z_arrow = new Arrow(0);
    
    ModelUniforms z_arrow_uniform;
    z_arrow_uniform.position = simd_make_float3(0, 0, 1);
    z_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    z_arrow_uniform.angle = simd_make_float3(0, 0, 0);
    
    model_uniforms.push_back(z_arrow_uniform);
    arrow_projections[0] = simd_make_float2(0,0);
    arrow_projections[1] = simd_make_float2(0,1);
    
    models.push_back(z_arrow);
    
    x_arrow = new Arrow(1, simd_make_float4(0, 1, 0, 1));
    
    ModelUniforms x_arrow_uniform;
    x_arrow_uniform.position = simd_make_float3(0, 0, 1);
    x_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    x_arrow_uniform.angle = simd_make_float3(M_PI_2, 0, 0);
    
    model_uniforms.push_back(x_arrow_uniform);
    arrow_projections[2] = simd_make_float2(0,0);
    arrow_projections[3] = simd_make_float2(0,0);
    
    models.push_back(x_arrow);
    
    y_arrow = new Arrow(2, simd_make_float4(0, 0, 1, 1));
    
    ModelUniforms y_arrow_uniform;
    y_arrow_uniform.position = simd_make_float3(0, 0, 1);
    y_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    y_arrow_uniform.angle = simd_make_float3(0, -M_PI_2, 0);
    
    model_uniforms.push_back(y_arrow_uniform);
    arrow_projections[4] = simd_make_float2(0,0);
    arrow_projections[5] = simd_make_float2(1,0);
    
    models.push_back(y_arrow);
    
    cube = new Model(3);
    cube->MakeCube();
    
    ModelUniforms cube_uniform;
    cube_uniform.position = simd_make_float3(0, 0, 0);
    cube_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    cube_uniform.angle = simd_make_float3(0, 0, 0);
    
    model_uniforms.push_back(cube_uniform);
    
    models.push_back(cube);
    
    camera = new Camera();
    camera->pos = {-2, 0, 0};
    camera->vector = {1, 0, 0};
    camera->up_vector = {0, 0, 1};
    camera->FOV = {M_PI_2, M_PI_2};

    CreateScenePipelineStates();
    
    // workaround for weird resizing bug
    SDL_SetWindowSize(window, window_width, window_height);
    
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
                if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
                    done = true;
                HandleKeyboardEvents(event);
                HandleMouseEvents(event);
            }
            
            HandleCameraInput();
            CreateBuffers();
            
            SDL_GetRendererOutputSize(renderer, &window_width, &window_height);
            aspect_ratio = ((float) window_width)/((float) window_height);
            vertex_render_uniforms.screen_ratio = aspect_ratio;
            //SDL_GetWindowSize(window, &window_width, &window_height);
            
            layer.drawableSize = CGSizeMake(window_width, window_height);
            id<CAMetalDrawable> drawable = [layer nextDrawable];

            id<MTLCommandBuffer> compute_command_buffer = [command_queue commandBuffer];
            
            // calculate rotated vertices
            id<MTLComputeCommandEncoder> compute_encoder = [compute_command_buffer computeCommandEncoder];
            [compute_encoder setComputePipelineState: scene_compute_rotated_pipeline_state];
            [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: scene_model_id_buffer offset:0 atIndex:1];
            [compute_encoder setBuffer: rotate_uniforms_buffer offset:0 atIndex:2];
            int vertices_length = (int) scene_vertices.size();
            /*if (potential_vertex_included) {
                vertices_length -= 1;
            }*/
            MTLSize gridSize = MTLSizeMake(vertices_length, 1, 1);
            NSUInteger threadGroupSize = scene_compute_rotated_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (threadGroupSize > vertices_length) threadGroupSize = vertices_length;
            MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
            [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
            
            // calculate projected vertex in kernel function
            [compute_encoder setComputePipelineState: scene_compute_projected_pipeline_state];
            [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
            [compute_encoder setBuffer: scene_camera_buffer offset:0 atIndex:1];
            vertices_length = (int) scene_vertices.size();
            gridSize = MTLSizeMake(vertices_length, 1, 1);
            threadGroupSize = scene_compute_projected_pipeline_state.maxTotalThreadsPerThreadgroup;
            if (threadGroupSize > vertices_length) threadGroupSize = vertices_length;
            [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
            
            [compute_encoder endEncoding];
            [compute_command_buffer commit];
            [compute_command_buffer waitUntilCompleted];
            
            if (left_clicked || right_clicked) {
                click_z = 50;
                
                if (selection_mode == SM_ALL) {
                    FaceClicked();
                    VertexClicked();
                    EdgeClicked();
                }
                
                if (right_clicked) {
                    render_rightclick_popup = (selected_vertex != -1 || selected_edge.x != -1 || selected_face != -1);
                    rightclick_popup_loc = click_loc;
                }
                
                show_arrows = edit_mode == EM_DEFAULT && (selected_vertex != -1 || selected_edge.x != -1 || selected_face != -1);
            }
            
            SetArrowProjections();
            
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
            
            
            // rendering scene - the faces
            [render_encoder setRenderPipelineState:scene_render_pipeline_state];
            [render_encoder setDepthStencilState: depth_state];
            [render_encoder setVertexBuffer:scene_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
            [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:scene_faces.size()*3];
            
            // rendering the edges
            [render_encoder setRenderPipelineState:scene_edge_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
            //[render_encoder setVertexBuffer:edge_render_uniforms_buffer offset:0 atIndex:2];
            for (int i = arrows_face_end*4; i < scene_faces.size()*4; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeLineStrip vertexStart:i vertexCount:4];
            }
            
            // rendering the vertex points
            [render_encoder setRenderPipelineState:scene_point_render_pipeline_state];
            [render_encoder setVertexBuffer:scene_vertex_buffer offset:0 atIndex:0];
            [render_encoder setVertexBuffer:vertex_render_uniforms_buffer offset:0 atIndex:1];
            for (int i = arrows_vertex_end*4; i < scene_vertices.size()*4; i+=4) {
                [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
            }
            
            // Start the Dear ImGui frame
            ImGui_ImplMetal_NewFrame(render_pass_descriptor);
            ImGui_ImplSDL2_NewFrame();
            ImGui::NewFrame();
            
            window_width = ImGui::GetIO().DisplaySize.x;
            window_height = ImGui::GetIO().DisplaySize.y;
            aspect_ratio = ((float) window_width)/((float) window_height);
            
            camera->FOV = {M_PI_2, 2*(atanf((float)window_height/(float)window_width))};
            
            // Rendering UI
            RenderUI();
            
            ImGui::Render();
            ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), render_command_buffer, render_encoder); // ImGui changes the encoders pipeline here to use its shaders and buffers
             
            // End rendering and display
            [render_encoder popDebugGroup];
            [render_encoder endEncoding];
            
            [render_command_buffer presentDrawable:drawable];
            [render_command_buffer commit];
            
            fps = ImGui::GetIO().Framerate;
            
            scene_vertices.clear();
            scene_faces.clear();
            modelIDs.clear();
        }
    }

    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    
    delete camera;
    delete cube;
    delete z_arrow;
    delete x_arrow;
    delete y_arrow;

    return 0;
}

