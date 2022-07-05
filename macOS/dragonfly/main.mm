//
//  main.m
//  dragonfly
//
//  Created by Thomas Liang on 1/13/22.
//

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <sys/stat.h>
#include <sys/types.h>
#include <math.h>

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include <SDL.h>
#include <simd/SIMD.h>
#include "imfilebrowser.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "Modeling/Model.h"
#include "Modeling/Arrow.h"

#include "UserActions/UserAction.h"
#include "UserActions/ModelMoveAction.h"
#include "UserActions/FaceMoveAction.h"
#include "UserActions/EdgeMoveAction.h"
#include "UserActions/VertexMoveAction.h"
#include "UserActions/FaceAddVertexAction.h"
#include "UserActions/EdgeAddVertexAction.h"

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

struct NodeRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    int selected_node;
};

/*struct EdgeRenderUniforms {
    vector_int2 selected_edge = -1;
};*/

// screen variables
int window_width = 1280;
int window_height = 720;
float aspect_ratio = 1280.0/720.0;

int menu_bar_height = 20;
bool using_menu_bar = false;

int scene_window_start_x = 0;
int scene_window_start_y = 19;
int scene_window_width = 1080;
int scene_window_height = 700;

int right_menu_width = 300;
int right_menu_height = 700;

float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
bool show_main_window = true;

// imgui/sdl variables
SDL_Window* window;
SDL_Renderer* renderer;
float fps = 0;

ImGui::FileBrowser fileDialog;
bool importing_model = false;
bool importing_scene = false;
bool saving_model = false;
bool saving_scene = false;

// metal variables
MTLRenderPassDescriptor* render_pass_descriptor;

CAMetalLayer *layer;
id <MTLDevice> device;
id <MTLCommandQueue> command_queue;

std::vector<Face> scene_faces;
std::vector<Node> scene_nodes;
std::vector<NodeVertexLink> nvlinks;
std::vector<uint32> node_modelIDs;
unsigned arrows_vertex_end = 0;
unsigned arrows_face_end = 0;
unsigned arrows_node_end = 0;
unsigned num_vertices = 0;

id <MTLComputePipelineState> scene_compute_reset_state;
id <MTLComputePipelineState> scene_compute_transforms_pipeline_state;
id <MTLComputePipelineState> scene_compute_vertex_pipeline_state;
id <MTLComputePipelineState> scene_compute_projected_vertices_pipeline_state;
id <MTLComputePipelineState> scene_compute_projected_nodes_pipeline_state;

id <MTLRenderPipelineState> scene_render_pipeline_state;
id <MTLRenderPipelineState> scene_edge_render_pipeline_state;
id <MTLRenderPipelineState> scene_point_render_pipeline_state;

id <MTLRenderPipelineState> scene_node_render_pipeline_state;

id <MTLDepthStencilState> depth_state;

id <MTLBuffer> scene_vertex_buffer;
id <MTLBuffer> projected_vertex_buffer;
id <MTLBuffer> scene_face_buffer;

id <MTLBuffer> scene_node_model_id_buffer;

id <MTLBuffer> scene_node_buffer;
id <MTLBuffer> scene_nvlink_buffer;

id <MTLBuffer> scene_camera_buffer;

id <MTLBuffer> rotate_uniforms_buffer;
id <MTLBuffer> vertex_render_uniforms_buffer;
id <MTLBuffer> node_render_uniforms_buffer;
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
NodeRenderUniforms node_render_uniforms;

// input variables
bool left_clicked = false;
bool right_clicked = false;
bool ctrl_down = false;
bool left_mouse_down = false;
bool right_mouse_down = false;

bool render_rightclick_popup = false;
simd_float2 rightclick_popup_loc;
simd_float2 rightclick_popup_size;
bool rightclick_popup_clicked = false;

enum SelectionMode { SM_MODEL, SM_FEV, SM_NODE, SM_NONE };
SelectionMode selection_mode = SM_MODEL;

enum EditMode { EM_MODEL, EM_FEV, EM_NODE };
EditMode edit_mode = EM_MODEL;

//bool potential_vertex_included = false;

int selected_model = -1;

int selected_face = -1;
vector_int2 selected_edge;
int selected_vertex = -1;

int selected_node = -1;

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
bool cmd_modifier = false;
float x_sens = 0.1;
float y_sens = 0.1;

// action variables
UserAction *current_action = NULL;
std::deque<UserAction *> past_actions;

std::vector<float> splitStringToFloats (std::string str) {
    std::vector<float> ret;
    
    std::string curr = "";
    for (int i = 0; i < str.size(); i++) {
        if (str[i] == ' ') {
            ret.push_back(std::stof(curr));
            curr = "";
        } else {
            curr += str[i];
        }
    }
    
    ret.push_back(std::stof(curr));
    
    return ret;
}

bool isFloat( std::string str ) {
    std::istringstream iss(str);
    float f;
    iss >> std::noskipws >> f; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}

bool isUnsignedLong( std::string str ) {
    std::istringstream iss(str);
    unsigned long ul;
    iss >> std::noskipws >> ul; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}

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

bool InTriangle(vector_float2 &point, Vertex v1, Vertex v2, Vertex v3) {
    float d1 = sign(point, v1, v2);
    float d2 = sign(point, v2, v3);
    float d3 = sign(point, v3, v1);

    bool has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    bool has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return (!(has_neg && has_pos));
}

int GetVertexModel(int vid) {
    if (vid == -1) {
        return -1;
    }
    
    int mid = 0;
    
    for (int i = 1; i < models.size(); i++) {
        if (vid < models[i]->VertexStart()) {
            return mid;
        }
        mid++;
    }
    
    return mid;
}

void FaceClicked() {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    Vertex *vertices = (Vertex *) projected_vertex_buffer.contents;
    Face *face_array = (Face *) scene_face_buffer.contents;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    for (int fid = 0; fid < scene_faces.size(); fid++) {
        Face face = face_array[fid];
        Vertex v1 = vertices[face.vertices[0]];
        Vertex v2 = vertices[face.vertices[1]];
        Vertex v3 = vertices[face.vertices[2]];

        if (InTriangle(click_loc, v1, v2, v3)) {
            float z = WeightedZ(click_loc, v1, v2, v3);
            if (minZ == -1 || z < minZ) {
                if (fid < arrows_face_end || selection_mode == SM_FEV || selection_mode == SM_MODEL) {
                    minZ = z;
                    clickedIdx = fid;
                }
            }
        }
    }
    
    if (clickedIdx != -1 && minZ < click_z) {
        if (clickedIdx >= arrows_face_end) {
            selected_face = clickedIdx;
            selected_vertex = -1;
            selected_edge.x = -1;
            selected_edge.y = -1;
            selected_node = -1;
        } else {
            selected_arrow = clickedIdx/ARROW_FACE_SIZE;
        }
        click_z = minZ;
    } else {
        selected_face = -1;
    }
}

void VertexClicked() {
    Vertex *vertices = (Vertex *) projected_vertex_buffer.contents;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    for (int vid = arrows_vertex_end; vid < num_vertices; vid++) {
        Vertex vertex = vertices[vid];
        float x_min = vertex.x-0.007;
        float x_max = vertex.x+0.007;
        float y_min = vertex.y-0.007 * aspect_ratio;
        float y_max = vertex.y+0.007 * aspect_ratio;
        
        if (click_loc.x <= x_max && click_loc.x >= x_min && click_loc.y <= y_max && click_loc.y >= y_min) {
            if (minZ == -1 || vertex.z < minZ) {
                minZ = vertex.z-0.001;
                clickedIdx = vid;
            }
        }
    }
    
    if (clickedIdx != -1 && minZ < click_z) {
        selected_vertex = clickedIdx;
        selected_face = -1;
        selected_edge.x = -1;
        selected_edge.y = -1;
        selected_node = -1;
        click_z = minZ;
    } else if (selected_arrow == -1) {
        selected_vertex = -1;
    }
}

void EdgeClicked() {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    Vertex *vertices = (Vertex *) projected_vertex_buffer.contents;
    Face *face_array = (Face *) scene_face_buffer.contents;
    
    float minZ = -1;
    int clickedv1 = -1;
    int clickedv2 = -1;
    
    for (int fid = arrows_face_end; fid < scene_faces.size(); fid++) {
        Face face = face_array[fid];
        
        for (int vid = 0; vid < 3; vid++) {
            Vertex v1 = vertices[face.vertices[vid]];
            Vertex v2 = vertices[face.vertices[(vid+1) % 3]];
            
            vector_float2 edgeVec = simd_make_float2(v1.x-v2.x, v1.y-v2.y);
            float mag = sqrt(pow(edgeVec.x, 2) + pow(edgeVec.y, 2));
            if (mag == 0) {
                continue;
            }
            edgeVec.x /= mag;
            edgeVec.y /= mag;
            
            edgeVec.x *= 0.01;
            edgeVec.y *= 0.01;
            
            Vertex v1plus = simd_make_float3(v1.x+edgeVec.y, v1.y-edgeVec.x, v1.z);
            Vertex v1sub = simd_make_float3(v1.x-edgeVec.y, v1.y+edgeVec.x, v1.z);
            Vertex v2plus = simd_make_float3(v2.x+edgeVec.y, v2.y-edgeVec.x, v2.z);
            Vertex v2sub = simd_make_float3(v2.x-edgeVec.y, v2.y+edgeVec.x, v2.z);
            
            if (InTriangle(click_loc, v1plus, v1sub, v2plus) || InTriangle(click_loc, v1sub, v2sub, v2plus)) {
                float dist1 = dist(click_loc, v1);
                float dist2 = dist(click_loc, v2);
                
                float total_dist = dist1 + dist2;
                float weightedZ = v1.z*(dist1/total_dist);
                weightedZ += v2.z*(dist2/total_dist);
                float z = weightedZ;
                
                if (minZ == -1 || z < minZ) {
                    minZ = z-0.0001;
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
        selected_node = -1;
        click_z = minZ;
    } else if (selected_arrow == -1) {
        selected_edge = simd_make_int2(-1, -1);
    }
}

void NodeClicked() {
    Node *nodes = (Node *) scene_node_buffer.contents;
    float minZ = -1;
    int clickedIdx = -1;
    
    for (int i = arrows_node_end; i < scene_nodes.size(); i++) {
        float radius = (1/nodes[i].pos.z) / 500;
        radius = radius * window_width;
        
        simd_float2 scaled_click = simd_make_float2(click_loc.x * window_width, click_loc.y * window_height);
        simd_float3 scaled_node = simd_make_float3(nodes[i].pos.x * window_width, nodes[i].pos.y * window_height, nodes[i].pos.z);
        
        float d = dist(scaled_click, scaled_node);
        
        if (d <= radius) {
            if (minZ == -1 || nodes[i].pos.z < minZ) {
                clickedIdx = i;
                minZ = nodes[i].pos.z;
            }
        }
    }
    
    if (clickedIdx != -1 && minZ < click_z) {
        selected_node = clickedIdx;
        selected_vertex = -1;
        selected_face = -1;
        selected_edge.x = -1;
        selected_edge.y = -1;
        click_z = minZ;
    } else if (selected_arrow == -1) {
        selected_node = -1;
    }
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
    
    MTLRenderPipelineDescriptor *scene_node_render_pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    scene_node_render_pipeline_descriptor.vertexFunction = [library newFunctionWithName:@"NodeShader"];
    scene_node_render_pipeline_descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentShader"];
    scene_node_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    scene_node_render_pipeline_descriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
    
    scene_compute_reset_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"ResetVertices"] error:nil];
    scene_compute_transforms_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateModelNodeTransforms"] error:nil];
    scene_compute_vertex_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateVertices"] error:nil];
    scene_compute_projected_vertices_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedVertices"] error:nil];
    scene_compute_projected_nodes_pipeline_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"CalculateProjectedNodes"] error:nil];
    //scene_compute_mouse_click_state = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"FaceClicked"] error:nil];
    scene_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:render_pipeline_descriptor error:nil];
    scene_edge_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:edge_render_pipeline_descriptor error:nil];
    scene_point_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:scene_point_render_pipeline_descriptor error:nil];
    scene_node_render_pipeline_state = [device newRenderPipelineStateWithDescriptor:scene_node_render_pipeline_descriptor error:nil];
    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    [depth_descriptor setDepthCompareFunction: MTLCompareFunctionLessEqual];
    [depth_descriptor setDepthWriteEnabled: true];
    depth_state = [device newDepthStencilStateWithDescriptor: depth_descriptor];
}

void MoveArrows () {
    if (!show_arrows) {
        simd_float3 behind_camera;
        behind_camera.x = camera->pos.x - camera->vector.x*10;
        behind_camera.y = camera->pos.y - camera->vector.y*10;
        behind_camera.z = camera->pos.z - camera->vector.z*10;
        
        model_uniforms[0].position = behind_camera;
        model_uniforms[1].position = behind_camera;
        model_uniforms[2].position = behind_camera;
        model_uniforms[0].rotate_origin = behind_camera;
        model_uniforms[1].rotate_origin = behind_camera;
        model_uniforms[2].rotate_origin = behind_camera;
    }
    
    if (selected_model != -1 && selection_mode == SM_MODEL) {
        model_uniforms[0].position = model_uniforms[selected_model].rotate_origin;
        model_uniforms[1].position = model_uniforms[selected_model].rotate_origin;
        model_uniforms[2].position = model_uniforms[selected_model].rotate_origin;
        model_uniforms[0].rotate_origin = model_uniforms[selected_model].rotate_origin;
        model_uniforms[1].rotate_origin = model_uniforms[selected_model].rotate_origin;
        model_uniforms[2].rotate_origin = model_uniforms[selected_model].rotate_origin;
    }
    
    if (selected_face != -1 && selection_mode == SM_FEV) {
        Vertex * scene_vertices = (Vertex *) scene_vertex_buffer.contents;
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
    
    if (selected_edge.x != -1 && selection_mode == SM_FEV) {
        Vertex * scene_vertices = (Vertex *) scene_vertex_buffer.contents;
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
    
    if (selected_vertex != -1 && selection_mode == SM_FEV) {
        Vertex * scene_vertices = (Vertex *) scene_vertex_buffer.contents;
        Vertex vertex_loc = scene_vertices[selected_vertex];
        model_uniforms[0].position = vertex_loc;
        model_uniforms[1].position = vertex_loc;
        model_uniforms[2].position = vertex_loc;
        model_uniforms[0].rotate_origin = vertex_loc;
        model_uniforms[1].rotate_origin = vertex_loc;
        model_uniforms[2].rotate_origin = vertex_loc;
        
        vertex_render_uniforms.selected_vertices.x = selected_vertex;
    }
    
    if (selected_node != -1 && selection_mode == SM_NODE) {
        int mid = node_modelIDs.at(selected_node);
        if (models[mid]->NodeStart() != selected_node) {
            simd_float3 node_loc = scene_nodes[selected_node].pos;
            node_loc.x += model_uniforms[mid].rotate_origin.x;
            node_loc.y += model_uniforms[mid].rotate_origin.y;
            node_loc.z += model_uniforms[mid].rotate_origin.z;
            model_uniforms[0].position = node_loc;
            model_uniforms[1].position = node_loc;
            model_uniforms[2].position = node_loc;
            model_uniforms[0].rotate_origin = node_loc;
            model_uniforms[1].rotate_origin = node_loc;
            model_uniforms[2].rotate_origin = node_loc;
        }
        
        node_render_uniforms.selected_node = selected_node;
    }
}

void SetEmptyBuffers() {
    std::vector<Vertex> empty_vertices;
    for (int i = 0; i < num_vertices; i++) {
        empty_vertices.push_back(simd_make_float3(0, 0, 0));
    }
    
    
    
    scene_vertex_buffer = [device newBufferWithBytes:empty_vertices.data() length:(num_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
    projected_vertex_buffer = [device newBufferWithBytes:empty_vertices.data() length:(num_vertices * sizeof(Vertex)) options:MTLResourceStorageModeShared];
}

void ResetStaticBuffers() {
    scene_faces.clear();
    scene_nodes.clear();
    node_modelIDs.clear();
    nvlinks.clear();
    num_vertices = 0;
    
    z_arrow->AddToBuffers(scene_faces, scene_nodes, nvlinks, node_modelIDs, num_vertices);
    x_arrow->AddToBuffers(scene_faces, scene_nodes, nvlinks, node_modelIDs, num_vertices);
    y_arrow->AddToBuffers(scene_faces, scene_nodes, nvlinks, node_modelIDs, num_vertices);
    
    arrows_vertex_end = num_vertices;
    arrows_face_end = scene_faces.size();
    arrows_node_end = scene_nodes.size();
    
    for (std::size_t i = 3; i < models.size(); i++) {
        models[i]->AddToBuffers(scene_faces, scene_nodes, nvlinks, node_modelIDs, num_vertices);
    }
    
    scene_face_buffer = [device newBufferWithBytes:scene_faces.data() length:(scene_faces.size() * sizeof(Face)) options:MTLResourceStorageModeShared];
    scene_nvlink_buffer = [device newBufferWithBytes:nvlinks.data() length:(nvlinks.size() * sizeof(NodeVertexLink)) options:MTLResourceStorageModeShared];
    scene_node_model_id_buffer = [device newBufferWithBytes:node_modelIDs.data() length:(node_modelIDs.size() * sizeof(uint32)) options:MTLResourceStorageModeShared];
}

void ResetDynamicBuffers() {
    vertex_render_uniforms.selected_vertices = simd_make_int3(-1, -1, -1);
    node_render_uniforms.selected_node = -1;
    
    MoveArrows();
    
    for (int i = 0; i < models.size(); i++) {
        models[i]->UpdateNodeBuffers(scene_nodes);
    }
    
    scene_camera_buffer = [device newBufferWithBytes:camera length:sizeof(Camera) options:{}];
    rotate_uniforms_buffer = [device newBufferWithBytes: model_uniforms.data() length:(model_uniforms.size() * sizeof(ModelUniforms)) options:{}];
    vertex_render_uniforms_buffer = [device newBufferWithBytes: &vertex_render_uniforms length:(sizeof(VertexRenderUniforms)) options:{}];
    node_render_uniforms_buffer = [device newBufferWithBytes: &node_render_uniforms length:(sizeof(NodeRenderUniforms)) options:{}];
    scene_node_buffer = [device newBufferWithBytes:scene_nodes.data() length:(scene_nodes.size() * sizeof(Node)) options:MTLResourceStorageModeShared];
}

void AddVertexToFace (int fid) {
    int modelID = GetVertexModel(scene_faces[fid].vertices[0]);
    Model *model = models[modelID];
    unsigned long modelFaceID = fid - model->FaceStart();
    
    Face *selected = model->GetFace(modelFaceID);
    Vertex* vertices = (Vertex *)scene_vertex_buffer.contents;
    int vid1 = selected->vertices[0];
    int vid2 = selected->vertices[1];
    int vid3 = selected->vertices[2];
    Vertex v1 = vertices[vid1 + model->VertexStart()];
    Vertex v2 = vertices[vid2 + model->VertexStart()];
    Vertex v3 = vertices[vid3 + model->VertexStart()];
    
    Vertex new_v = TriAvg(v1, v2, v3);
    unsigned new_vid = model->MakeVertex(new_v.x, new_v.y, new_v.z);
    
    //1,2,new
    selected->vertices[2] = new_vid;
    
    //2,3,new
    model->MakeFace(vid2, vid3, new_vid, selected->color);
    
    //1,3,new
    model->MakeFace(vid1, vid3, new_vid, selected->color);
    
    SetEmptyBuffers();
    ResetStaticBuffers();
}

void AddVertexToEdge (int vid1, int vid2) {
    int modelID = GetVertexModel(vid1);
    Model *model = models[modelID];
    
    int model_vid1 = vid1 - model->VertexStart();
    int model_vid2 = vid2 - model->VertexStart();
    
    std::vector<unsigned long> fids = model->GetEdgeFaces(model_vid1, model_vid2);
    
    Vertex * vertices = (Vertex *) scene_vertex_buffer.contents;
    Vertex v1 = vertices[vid1];
    Vertex v2 = vertices[vid2];
    Vertex new_v = BiAvg(v1, v2);
    unsigned new_vid = model->MakeVertex(new_v.x, new_v.y, new_v.z);
    
    for (std::size_t i = 0; i < fids.size(); i++) {
        unsigned long fid = fids[i];
        Face *f = model->GetFace(fid);
        unsigned long fvid1 = f->vertices[0];
        unsigned long fvid2 = f->vertices[1];
        unsigned long fvid3 = f->vertices[2];
        
        long long other_vid = -1;
        
        if (model_vid1 == fvid1) {
            if (model_vid2 == fvid2) {
                other_vid = fvid3;
            } else if (model_vid2 == fvid3) {
                other_vid = fvid2;
            }
        } else if (model_vid1 == fvid2) {
            if (model_vid2 == fvid1) {
                other_vid = fvid3;
            } else if (model_vid2 == fvid3) {
                other_vid = fvid1;
            }
        } else if (model_vid1 == fvid3) {
            if (model_vid2 == fvid1) {
                other_vid = fvid2;
            } else if (model_vid2 == fvid2) {
                other_vid = fvid1;
            }
        }
        
        if (other_vid != -1) {
            f->vertices[0] = model_vid1;
            f->vertices[1] = new_vid;
            f->vertices[2] = other_vid;
            
            model->MakeFace(model_vid2, new_vid, other_vid, f->color);
        }
    }
    
    SetEmptyBuffers();
    ResetStaticBuffers();
}

void Undo() {
    if (!past_actions.empty()) {
        UserAction *action = past_actions.front();
        past_actions.pop_front();
        action->Undo();
        delete action;
        
        SetEmptyBuffers();
        ResetStaticBuffers();
    }
}

void SaveModelToFile(int mid, std::string name) {
    /*std::ofstream myfile;
    Model *m = models.at(mid);
    myfile.open (name + ".drgn");
    for (int i = 0; i < m->NumVertices(); i++) {
        simd_float3 *v = m->GetVertex(i);
        myfile << v->x << " " << v->y << " " << v->z << std::endl;
    }
    
    myfile << "f" << std::endl;
    for (int i = 0; i < m->NumFaces(); i++) {
        Face *f = m->GetFace(i);
        myfile << f->vertices[0] << " " << f->vertices[1] << " " << f->vertices[2] << " ";
        myfile << f->color.x << " " << f->color.y << " " << f->color.z << " " << f->color.w << std::endl;
    }
    
    myfile.close();*/
}

void SaveSceneToFolder(std::string path) {
    if(mkdir(path.c_str(), 0777) == -1) {
        rmdir(path.c_str());
        mkdir(path.c_str(), 0777);
    }
    
    if(mkdir((path+"/Models").c_str(), 0777) == -1) {
        rmdir((path+"/Models").c_str());
        mkdir((path+"/Models").c_str(), 0777);
    }
    
    std::ofstream myfile;
    myfile.open ((path+"/uniforms.lair").c_str());
    
    for (int i = 3; i < model_uniforms.size(); i++) {
        SaveModelToFile(i, path+"/Models/"+models.at(i)->GetName());
        
        ModelUniforms mu = model_uniforms.at(i);
        myfile << models.at(i)->GetName() << ".drgn ";
        myfile << mu.position.x << " " << mu.position.y << " " << mu.position.z << " ";
        myfile << mu.rotate_origin.x << " " << mu.rotate_origin.y << " " << mu.rotate_origin.z << " ";
        myfile << mu.angle.x << " " << mu.angle.y << " " << mu.angle.z << std::endl;
    }
    
    myfile.close();
}

Model * GetModelFromFile(std::string path) {
    std::string line;
    std::ifstream myfile (path);
    if (myfile.is_open()) {
        Model *m = new Model(models.size());
        
        bool getting_vertices = true;
        while ( getline (myfile,line) ) {
            if (line == "f") {
                getting_vertices = false;
            } else {
                std::vector<float> vals = splitStringToFloats(line);
                
                if (getting_vertices) {
                    m->InsertVertex(vals[0], vals[1], vals[2], m->NumVertices());
                } else {
                    Face f;
                    f.vertices[0] = (int) vals[0];
                    f.vertices[1] = (int) vals[1];
                    f.vertices[2] = (int) vals[2];
                    
                    f.color = simd_make_float4(vals[3], vals[4], vals[5], vals[6]);
                    m->InsertFace(f, m->NumFaces());
                }
            }
        }
        
        myfile.close();
        
        return m;
    } else {
        std::cout<<"invalid path"<<std::endl;
    }
    
    return NULL;
}

void GetSceneFromFolder(std::string path) {
    for (int i = models.size()-1; i >= 3; i--) {
        delete models.at(i);
        models.erase(models.begin()+i);
    }
    
    for (int i = model_uniforms.size()-1; i >= 3; i--) {
        model_uniforms.erase(model_uniforms.begin()+i);
    }
    
    std::string line;
    std::ifstream myfile (path+"/uniforms.lair");
    if (myfile.is_open()) {
        while ( getline (myfile,line) ) {
            std::string model_file = line.substr(0, line.find(' '));
            line = line.substr(line.find(' ')+1);
            
            std::vector<float> vals = splitStringToFloats(line);
            
            ModelUniforms mu;
            mu.position.x = vals[0];
            mu.position.y = vals[1];
            mu.position.z = vals[2];
            
            mu.rotate_origin.x = vals[3];
            mu.rotate_origin.y = vals[4];
            mu.rotate_origin.z = vals[5];
            
            mu.angle.x = vals[6];
            mu.angle.y = vals[7];
            mu.angle.z = vals[8];
            
            model_uniforms.push_back(mu);
            
            Model *m = GetModelFromFile(path+"/Models/"+model_file);
            models.push_back(m);
        }
        
        myfile.close();
    } else {
        std::cout<<"invalid path"<<std::endl;
    }
    
    ResetStaticBuffers();
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

void MainMenuBar() {
    if (ImGui::BeginMainMenuBar()) {
        using_menu_bar = false;
        
        if (ImGui::BeginMenu("File")) {
            using_menu_bar = true;
            if (ImGui::MenuItem("New Model", "")) {
                Model *m = new Model(models.size());
                m->MakeCube();
                models.push_back(m);
                ModelUniforms new_uniform;
                new_uniform.position = simd_make_float3(0, 0, 0);
                new_uniform.rotate_origin = simd_make_float3(0, 0, 0);
                new_uniform.angle = simd_make_float3(0, 0, 0);
                
                model_uniforms.push_back(new_uniform);
                
                SetEmptyBuffers();
                ResetStaticBuffers();
            }
            if (ImGui::MenuItem("Save Selected Model", "")) {
                if (selected_model != -1) {
                    saving_model = true;
                    
                    fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_EnterNewFilename | ImGuiFileBrowserFlags_CloseOnEsc);
                    fileDialog.SetTitle("Saving Model");
                    fileDialog.Open();
                }
            }
            if (ImGui::MenuItem("Save Scene", ""))   {
                saving_scene = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_EnterNewFilename | ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Saving Scene");
                fileDialog.Open();
            }
            if (ImGui::MenuItem("Import Model", ""))   {
                importing_model = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Importing Model");
                fileDialog.SetTypeFilters({ ".drgn" });
                fileDialog.Open();
            }
            if (ImGui::MenuItem("Import Scene", ""))   {
                importing_scene = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_SelectDirectory | ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Importing Scene");
                fileDialog.Open();
            }
            ImGui::EndMenu();
        }
        
        if (ImGui::BeginMenu("Edit")) {
            using_menu_bar = true;
            if (ImGui::MenuItem("Edit by Model", "")) {
                selection_mode = SM_MODEL;
                edit_mode = EM_MODEL;
            }
            if (ImGui::MenuItem("Edit by Face, Edge, and Vertex", ""))   {
                selection_mode = SM_FEV;
                edit_mode = EM_FEV;
            }
            if (ImGui::MenuItem("Edit by Node", ""))   {
                selection_mode = SM_NODE;
                edit_mode = EM_NODE;
            }
            ImGui::EndMenu();
        }
        ImGui::EndMainMenuBar();
    }
}

std::string TextField(std::string input, std::string name) {
    char buf [128] = "";
    std::strcpy (buf, input.c_str());
    ImGui::InputText(name.c_str(), buf, IM_ARRAYSIZE(buf));
    
    return std::string(buf);
}

void ModelEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    
    ImGui::SetCursorPos(ImVec2(30, 30));
    ImGui::Text("Location: ");
    
    ImGui::SetCursorPos(ImVec2(50, 50));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 50));
    std::string x_input = TextField(std::to_string(model_uniforms[selected_model].position.x), "##modelx");
    if (isFloat(x_input)) {
        float new_x = std::stof(x_input);
        model_uniforms[selected_model].position.x = new_x;
        model_uniforms[selected_model].rotate_origin.x = new_x;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 80));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 80));
    std::string y_input = TextField(std::to_string(model_uniforms[selected_model].position.y), "##modely");
    if (isFloat(y_input)) {
        float new_y = std::stof(y_input);
        model_uniforms[selected_model].position.y = new_y;
        model_uniforms[selected_model].rotate_origin.y = new_y;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 110));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 110));
    std::string z_input = TextField(std::to_string(model_uniforms[selected_model].position.z), "##modelz");
    if (isFloat(z_input)) {
        float new_z = std::stof(z_input);
        model_uniforms[selected_model].position.z = new_z;
        model_uniforms[selected_model].rotate_origin.z = new_z;
    }
}

void VertexEditMenu() {
    Model *model = models[selected_model];
    
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Vertex ID: %lu", selected_vertex - model->VertexStart());
    
    int current_y = 60;
    
    std::vector<unsigned long> linked_nodes = model->GetLinkedNodes(selected_vertex - model->VertexStart());
    for (int i = 0; i < linked_nodes.size(); i++) {
        ImGui::SetCursorPos(ImVec2(30, current_y));
        ImGui::Text("Linked to node %lu", linked_nodes[i]);
        
        if (linked_nodes.size() > 1) {
        ImGui::SetCursorPos(ImVec2(150, current_y));
            if (ImGui::Button("Unlink")) {
                model->UnlinkNodeAndVertex(selected_vertex - model->VertexStart(), linked_nodes[i]);
                ResetStaticBuffers();
            }
        }
        
        current_y += 30;
    }
    
    ImGui::SetCursorPos(ImVec2(30, current_y));
    ImGui::Text("Link to node: ");
    char buf [128] = "";
    ImGui::SetCursorPos(ImVec2(130, current_y));
    if (ImGui::InputText("##linknode", buf, IM_ARRAYSIZE(buf), ImGuiInputTextFlags_EnterReturnsTrue)) {
        if (isUnsignedLong(buf)) {
            unsigned long nid = std::stoul(buf);
            model->LinkNodeAndVertex(selected_vertex - model->VertexStart(), nid);
            ResetStaticBuffers();
        }
    }
    
}

void EdgeEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Edge Vertex IDs: %lu %lu", selected_edge.x - models[selected_model]->VertexStart(), selected_edge.y - models[selected_model]->VertexStart());
}

void FaceEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Face ID: %lu", selected_face - models[selected_model]->FaceStart());
}

void NodeEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Node ID: %lu", selected_node - models[selected_model]->NodeStart());
    
    Model *model = models[selected_model];
    Node *node = model->GetNode(selected_node - model->NodeStart());
    
    ImGui::SetCursorPos(ImVec2(30, 50));
    ImGui::Text("Position");
    
    ImGui::SetCursorPos(ImVec2(50, 80));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 80));
    std::string x_input = TextField(std::to_string(node->pos.x), "##nodex");
    if (isFloat(x_input) && selected_node != model->NodeStart()) {
        float new_x = std::stof(x_input);
        node->pos.x = new_x;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 110));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 110));
    std::string y_input = TextField(std::to_string(node->pos.y), "##nodey");
    if (isFloat(y_input) && selected_node != model->NodeStart()) {
        float new_y = std::stof(y_input);
        node->pos.y = new_y;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 140));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 140));
    std::string z_input = TextField(std::to_string(node->pos.z), "##nodez");
    if (isFloat(z_input) && selected_node != model->NodeStart()) {
        float new_z = std::stof(z_input);
        node->pos.z = new_z;
    }
    
    
    ImGui::SetCursorPos(ImVec2(30, 170));
    ImGui::Text("Angle");
    
    ImGui::SetCursorPos(ImVec2(50, 200));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 200));
    std::string xa_input = TextField(std::to_string(node->angle.x * 180 / M_PI), "##nodeax");
    if (isFloat(xa_input) && selected_node != model->NodeStart()) {
        float new_x = std::stof(xa_input);
        node->angle.x = new_x * M_PI / 180;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 230));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 230));
    std::string ya_input = TextField(std::to_string(node->angle.y * 180 / M_PI), "##nodeay");
    if (isFloat(ya_input) && selected_node != model->NodeStart()) {
        float new_y = std::stof(ya_input);
        node->angle.y = new_y * M_PI / 180;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 260));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 260));
    std::string za_input = TextField(std::to_string(node->angle.z * 180 / M_PI), "##nodeaz");
    if (isFloat(za_input) && selected_node != model->NodeStart()) {
        float new_z = std::stof(za_input);
        node->angle.z = new_z * M_PI / 180;
    }
}

void RightMenu() {
    ImGui::SetNextWindowPos(ImVec2(window_width - right_menu_width, scene_window_start_y));
    ImGui::SetNextWindowSize(ImVec2(right_menu_width, window_height));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 255.0f));
    ImGui::Begin("side", &show_main_window, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    ImGui::SetCursorPos(ImVec2(20, 10));
    if (selected_model != -1 && selection_mode == SM_MODEL) {
        ModelEditMenu();
    } else if (selected_vertex != -1 && selection_mode == SM_FEV) {
        VertexEditMenu();
    } else if (selected_edge.x != -1 && selection_mode == SM_FEV) {
        EdgeEditMenu();
    } else if (selected_face != -1 && selection_mode == SM_FEV) {
        FaceEditMenu();
    } else if (selected_node != -1 && selection_mode == SM_NODE) {
        NodeEditMenu();
    } else {
        ImGui::Text("Nothing Selected");
    }
    
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void FileDialog() {
    if (importing_model || importing_scene || saving_model || saving_scene) {
        fileDialog.Display();
    }
    
    if(fileDialog.HasSelected()) {
        if (saving_model) {
            SaveModelToFile(selected_model, fileDialog.GetSelected().string());
        }
        if (saving_scene) {
            SaveSceneToFolder(fileDialog.GetSelected().string());
        }
        if (importing_model) {
            std::cout << "Selected filename" << fileDialog.GetSelected().string() << std::endl;
            
            Model *m = GetModelFromFile(fileDialog.GetSelected().string());
            if (m != NULL) {
                models.push_back(m);
                ModelUniforms new_uniform;
                new_uniform.position = simd_make_float3(0, 0, 0);
                new_uniform.rotate_origin = simd_make_float3(0, 0, 0);
                new_uniform.angle = simd_make_float3(0, 0, 0);
                
                model_uniforms.push_back(new_uniform);
                
                ResetStaticBuffers();
            }
            
            fileDialog.ClearSelected();
            fileDialog.Close();
            importing_model = false;
        } else if (importing_scene) {
            std::cout << "Selected scene" << fileDialog.GetSelected().string() << std::endl;
            
            GetSceneFromFolder(fileDialog.GetSelected().string());
            
            fileDialog.ClearSelected();
            fileDialog.Close();
            importing_scene = false;
        }
    }
    
    if(!fileDialog.IsOpened()) {
        importing_model = false;
        importing_scene = false;
        saving_model = false;
        saving_scene = false;
    }
}

void RightClickPopup() {
    ImGui::SetCursorPos(ImVec2(window_width * (rightclick_popup_loc.x+1)/2, window_height * (2-(rightclick_popup_loc.y+1))/2 - menu_bar_height));
    
    ImVec2 button_size = ImVec2(window_width * rightclick_popup_size.x/2, window_height * rightclick_popup_size.y/2);
    
    if (edit_mode == EM_FEV) {
        if (selected_face != -1 || selected_edge.x != -1) {
            if (ImGui::Button("Add Vertex", ImVec2(button_size.x, button_size.y))) {
                render_rightclick_popup = false;
                if (selected_face != -1) {
                    Model* m = models.at(selected_model);
                    current_action = new FaceAddVertexAction(m, m->NumVertices(), selected_face - m->FaceStart());
                    
                    current_action->BeginRecording();
                    AddVertexToFace(selected_face);
                    current_action->EndRecording();
                    
                    past_actions.push_front(current_action);
                    
                    current_action = NULL;
                } else if (selected_edge.x != -1) {
                    Model* m = models.at(selected_model);
                    current_action = new EdgeAddVertexAction(m, m->NumVertices(), selected_edge.x - m->VertexStart(), selected_edge.y - m->VertexStart());
                    
                    current_action->BeginRecording();
                    AddVertexToEdge(selected_edge.x, selected_edge.y);
                    current_action->EndRecording();
                    
                    past_actions.push_front(current_action);
                    
                    current_action = NULL;
                }
            }
        }
    } else if (edit_mode == EM_NODE) {
        if (ImGui::Button("Add Node", ImVec2(button_size.x, button_size.y))) {
            Model* m = models.at(selected_model);
            m->MakeNode(1, 0, 0);
            
            ResetStaticBuffers();
        }
    }
}

void MainWindow() {
    // scene window
    ImGui::SetNextWindowPos(ImVec2(scene_window_start_x, scene_window_start_y));
    ImGui::SetNextWindowSize(ImVec2(scene_window_width, scene_window_height));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_main_window, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    // Display FPS
    ImGui::SetCursorPos(ImVec2(scene_window_width - 80, 10));
    ImGui::Text("%.1f FPS", ImGui::GetIO().Framerate);
    ImGui::PopStyleColor();
    
    if (render_rightclick_popup) {
        RightClickPopup();
    }
    
    ImGui::End();
}

void RenderUI() {
    // menu bar
    MainMenuBar();
    
    MainWindow();
    
    RightMenu();
    
    FileDialog();
}

bool InRightClickPopup(simd_float2 loc) {
    return loc.x >= rightclick_popup_loc.x && loc.x < rightclick_popup_loc.x+rightclick_popup_size.x && loc.y >= rightclick_popup_loc.y-rightclick_popup_size.y && loc.y < rightclick_popup_loc.y;
}

bool ClickOnScene(simd_float2 loc) {
    if (importing_model || importing_scene || saving_model || saving_scene) {
        return false;
    }
    
    if (using_menu_bar) {
        return false;
    }
    
    if (render_rightclick_popup && InRightClickPopup(loc)) {
        return false;
    }
    
    int pixelX = window_width * (loc.x+1)/2;
    int pixelY = window_height * (loc.y+1)/2 ;
    
    if (pixelX < scene_window_start_x || pixelX > scene_window_start_x + scene_window_width) {
        return false;
    }
    
    if (pixelY < scene_window_start_y || pixelY > scene_window_start_y + scene_window_height) {
        return false;
    }
    
    return true;
}

void HandleKeyboardEvents(SDL_Event event) {
    if (event.type == SDL_KEYDOWN) {
        SDL_Keysym keysym = event.key.keysym;
        //std::cout<<keysym.sym<<std::endl;
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
            case 122:
                // z
                if (cmd_modifier) {
                    Undo();
                }
                break;
            case 1073742049:
                // shift
                key_presses[5] = true;
                break;
            case 1073742048:
                // control
                ctrl_down = true;
                break;
            case 1073742055:
                // command
                cmd_modifier = true;
                break;
            default:
                break;
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
                break;
            case 1073742055:
                cmd_modifier = false;
                break;
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
                if (ClickOnScene(click_loc)) {
                    left_clicked = true;
                    left_mouse_down = true;
                    render_rightclick_popup = false;
                }
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
                
                if (current_action != NULL && current_action->IsRecording()) {
                    current_action->EndRecording();
                    past_actions.push_front(current_action);
                    current_action = NULL;
                }
                
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
            //get current camera angles (phi is horizontal and theta is vertical)
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
        
        if (edit_mode == EM_MODEL || edit_mode == EM_FEV || edit_mode == EM_NODE) {
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
                
                if (selected_model != -1 && selection_mode == SM_MODEL) {
                    simd_float3 loc = model_uniforms.at(selected_model).position;
                    loc.x += x_vec;
                    loc.y += y_vec;
                    loc.z += z_vec;
                    model_uniforms.at(selected_model).position = loc;
                    
                    simd_float3 rot = model_uniforms.at(selected_model).rotate_origin;
                    rot.x += x_vec;
                    rot.y += y_vec;
                    rot.z += z_vec;
                    model_uniforms.at(selected_model).rotate_origin = rot;
                } else if (selected_face != -1 && selection_mode == SM_FEV) {
                    int modelID = GetVertexModel(scene_faces[selected_face].vertices[0]);
                    Model *model = models[modelID];
                    unsigned long modelFaceID = selected_face - model->FaceStart();
                    Face *selected = model->GetFace(modelFaceID);
                    
                    model->MoveVertex(selected->vertices[0], x_vec, y_vec, z_vec);
                    model->MoveVertex(selected->vertices[1], x_vec, y_vec, z_vec);
                    model->MoveVertex(selected->vertices[2], x_vec, y_vec, z_vec);
                    
                    ResetStaticBuffers();
                } else if (selected_vertex != -1 && selection_mode == SM_FEV) {
                    int modelID = GetVertexModel(selected_vertex);
                    Model *model = models[modelID];
                    unsigned long modelVertexID = selected_vertex - model->VertexStart();
                    model->MoveVertex(modelVertexID, x_vec, y_vec, z_vec);
                    
                    ResetStaticBuffers();
                } else if (selected_edge.x != -1 && selection_mode == SM_FEV) {
                    int modelID = GetVertexModel(selected_edge.x);
                    Model *model = models[modelID];
                    unsigned long modelVertex1ID = selected_edge.x - model->VertexStart();
                    unsigned long modelVertex2ID = selected_edge.y - model->VertexStart();
                    model->MoveVertex(modelVertex1ID, x_vec, y_vec, z_vec);
                    model->MoveVertex(modelVertex2ID, x_vec, y_vec, z_vec);
                    
                    ResetStaticBuffers();
                } else if (selected_node != -1 && selection_mode == SM_NODE) {
                    int modelID = node_modelIDs[selected_node];
                    Model *model = models[modelID];
                    unsigned long modelNodeID = selected_node - model->NodeStart();
                    Node *n = model->GetNode(modelNodeID);
                    n->pos.x += x_vec;
                    n->pos.y += y_vec;
                    n->pos.z += z_vec;
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

void HandleSelections() {
    if (left_clicked || right_clicked) {
        click_z = 50;
        
        if (selection_mode == SM_MODEL) {
            FaceClicked();
            
            if (selected_face != -1) {
                selected_model = GetVertexModel(scene_faces.at(selected_face).vertices[0]);
            } else if (selected_arrow == -1) {
                selected_model = -1;
            }
            
            if (selected_arrow != -1) {
                if (selected_model != -1) {
                    current_action = new ModelMoveAction(&model_uniforms, selected_model);
                    current_action->BeginRecording();
                    
                    if (past_actions.size() > 20) {
                        UserAction *last_action = past_actions.back();
                        past_actions.pop_back();
                        delete last_action;
                    }
                }
            }
            
            show_arrows = edit_mode == EM_MODEL && (selected_model != -1);
            
            selected_face = -1;
            selected_vertex = -1;
            selected_edge = simd_make_int2(-1, -1);
        } else if (selection_mode == SM_FEV) {
            FaceClicked();
            VertexClicked();
            EdgeClicked();
            
            selected_model = -1;
            
            if (selected_face != -1) {
                selected_model = GetVertexModel(scene_faces.at(selected_face).vertices[0]);
                if (selected_arrow != -1) {
                    Model* m = models.at(selected_model);
                    current_action = new FaceMoveAction(m, selected_face - m->FaceStart());
                    current_action->BeginRecording();
                    
                    if (past_actions.size() > 20) {
                        UserAction *last_action = past_actions.back();
                        past_actions.pop_back();
                        delete last_action;
                    }
                }
            } else if (selected_edge.x != -1) {
                selected_model = GetVertexModel(selected_edge.x);
                if (selected_arrow != -1) {
                    Model* m = models.at(selected_model);
                    current_action = new EdgeMoveAction(m, selected_edge.x - m->VertexStart(), selected_edge.y - m->VertexStart());
                    current_action->BeginRecording();
                    
                    if (past_actions.size() > 20) {
                        UserAction *last_action = past_actions.back();
                        past_actions.pop_back();
                        delete last_action;
                    }
                }
            } else if (selected_vertex != -1) {
                selected_model = GetVertexModel(selected_vertex);
                if (selected_arrow != -1) {
                    Model* m = models.at(selected_model);
                    current_action = new VertexMoveAction(m, selected_vertex - m->VertexStart());
                    current_action->BeginRecording();
                    
                    if (past_actions.size() > 20) {
                        UserAction *last_action = past_actions.back();
                        past_actions.pop_back();
                        delete last_action;
                    }
                }
            }
            
            if (right_clicked) {
                render_rightclick_popup = (selected_vertex != -1 || selected_edge.x != -1 || selected_face != -1);
                rightclick_popup_loc = click_loc;
                rightclick_popup_size = simd_make_float2(90/(float)(window_width/2), 20/(float)(window_height/2));
            }
            
            show_arrows = edit_mode == EM_FEV && (selected_vertex != -1 || selected_edge.x != -1 || selected_face != -1);
        } else if (selection_mode == SM_NODE) {
            FaceClicked();
            
            selected_face = -1;
            click_z = 50;
            
            NodeClicked();
            if (selected_node != -1) {
                selected_model = node_modelIDs.at(selected_node);
            }
            
            if (right_clicked) {
                render_rightclick_popup = (selected_node != -1);
                rightclick_popup_loc = click_loc;
                rightclick_popup_size = simd_make_float2(90/(float)(window_width/2), 20/(float)(window_height/2));
            }
        }
    }
}

void SetArrowProjections() {
    Vertex * contents = (Vertex *) projected_vertex_buffer.contents;
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
    
    node_render_uniforms.screen_ratio = aspect_ratio;
    node_render_uniforms.selected_node = -1;

    CreateScenePipelineStates();
    
    // workaround for weird resizing bug
    SDL_SetWindowSize(window, window_width, window_height);
    
    ResetStaticBuffers();
    SetEmptyBuffers();
    
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
            ResetDynamicBuffers();
            
            SDL_GetRendererOutputSize(renderer, &window_width, &window_height);
            aspect_ratio = ((float) window_width)/((float) window_height);
            vertex_render_uniforms.screen_ratio = aspect_ratio;
            node_render_uniforms.screen_ratio = aspect_ratio;
            
            scene_window_width = window_width - right_menu_width;
            scene_window_height = window_height - menu_bar_height;
            
            layer.drawableSize = CGSizeMake(window_width, window_height);
            id<CAMetalDrawable> drawable = [layer nextDrawable];

            id<MTLCommandBuffer> compute_command_buffer = [command_queue commandBuffer];
            id<MTLComputeCommandEncoder> compute_encoder = [compute_command_buffer computeCommandEncoder];
            
            if (num_vertices > 0 && scene_nodes.size() > 0) {
                // reset vertices to 0
                [compute_encoder setComputePipelineState: scene_compute_reset_state];
                [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
                MTLSize gridSize = MTLSizeMake(num_vertices, 1, 1);
                NSUInteger threadGroupSize = scene_compute_reset_state.maxTotalThreadsPerThreadgroup;
                if (threadGroupSize > num_vertices) threadGroupSize = num_vertices;
                MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
                [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
                
                // calculate rotated/transformed nodes
                 [compute_encoder setComputePipelineState: scene_compute_transforms_pipeline_state];
                [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:0];
                [compute_encoder setBuffer: scene_node_model_id_buffer offset:0 atIndex:1];
                [compute_encoder setBuffer: rotate_uniforms_buffer offset:0 atIndex:2];
                int node_length = (int) scene_nodes.size();
                gridSize = MTLSizeMake(node_length, 1, 1);
                threadGroupSize = scene_compute_transforms_pipeline_state.maxTotalThreadsPerThreadgroup;
                if (threadGroupSize > node_length) threadGroupSize = node_length;
                threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
                [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
                
                // calculate vertices from nodes
                [compute_encoder setComputePipelineState:scene_compute_vertex_pipeline_state];
                [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:0];
                [compute_encoder setBuffer: scene_nvlink_buffer offset:0 atIndex:1];
                [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:2];
                gridSize = MTLSizeMake(num_vertices, 1, 1);
                threadGroupSize = scene_compute_vertex_pipeline_state.maxTotalThreadsPerThreadgroup;
                if (threadGroupSize > num_vertices) threadGroupSize = num_vertices;
                threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
                [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
                
                // calculate projected vertex in kernel function
                [compute_encoder setComputePipelineState: scene_compute_projected_vertices_pipeline_state];
                [compute_encoder setBuffer: projected_vertex_buffer offset:0 atIndex:0];
                [compute_encoder setBuffer: scene_vertex_buffer offset:0 atIndex:1];
                [compute_encoder setBuffer: scene_camera_buffer offset:0 atIndex:2];
                gridSize = MTLSizeMake(num_vertices, 1, 1);
                threadGroupSize = scene_compute_projected_vertices_pipeline_state.maxTotalThreadsPerThreadgroup;
                if (threadGroupSize > num_vertices) threadGroupSize = num_vertices;
                [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
                
                // calculate projected nodes in kernel function
                [compute_encoder setComputePipelineState: scene_compute_projected_nodes_pipeline_state];
                [compute_encoder setBuffer: scene_node_buffer offset:0 atIndex:0];
                [compute_encoder setBuffer: scene_camera_buffer offset:0 atIndex:2];
                int nodes_length = (int) scene_nodes.size();
                gridSize = MTLSizeMake(nodes_length, 1, 1);
                threadGroupSize = scene_compute_projected_nodes_pipeline_state.maxTotalThreadsPerThreadgroup;
                if (threadGroupSize > nodes_length) threadGroupSize = nodes_length;
                [compute_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
            }
            
            [compute_encoder endEncoding];
            [compute_command_buffer commit];
            [compute_command_buffer waitUntilCompleted];
            
            if (num_vertices > 0 && scene_nodes.size() > 0) {
                HandleSelections();
                
                SetArrowProjections();
            }
            
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
            
            if (num_vertices > 0 && scene_nodes.size() > 0) {
                // rendering scene - the faces
                if (selection_mode == SM_MODEL || selection_mode == SM_FEV || selection_mode == SM_NODE || selection_mode == SM_NONE) {
                    int end_face = scene_faces.size();
                    if (selection_mode == SM_NODE) end_face = arrows_face_end;
                    
                    [render_encoder setRenderPipelineState:scene_render_pipeline_state];
                    [render_encoder setVertexBuffer:projected_vertex_buffer offset:0 atIndex:0];
                    [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
                    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:end_face*3];
                }
                
                // rendering the edges
                if (selection_mode == SM_MODEL || selection_mode == SM_FEV || selection_mode == SM_NODE) {
                    [render_encoder setRenderPipelineState:scene_edge_render_pipeline_state];
                    [render_encoder setVertexBuffer:projected_vertex_buffer offset:0 atIndex:0];
                    [render_encoder setVertexBuffer:scene_face_buffer offset:0 atIndex:1];
                    //[render_encoder setVertexBuffer:edge_render_uniforms_buffer offset:0 atIndex:2];
                    for (int i = arrows_face_end*4; i < scene_faces.size()*4; i+=4) {
                        [render_encoder drawPrimitives:MTLPrimitiveTypeLineStrip vertexStart:i vertexCount:4];
                    }
                }
                
                // rendering the vertex points
                if (selection_mode == SM_FEV) {
                    [render_encoder setRenderPipelineState:scene_point_render_pipeline_state];
                    [render_encoder setVertexBuffer:projected_vertex_buffer offset:0 atIndex:0];
                    [render_encoder setVertexBuffer:vertex_render_uniforms_buffer offset:0 atIndex:1];
                    for (int i = arrows_vertex_end*4; i < num_vertices*4; i+=4) {
                        [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
                    }
                }
                
                // rendering nodes
                if (selection_mode == SM_NODE) {
                    [render_encoder setRenderPipelineState:scene_node_render_pipeline_state];
                    [render_encoder setVertexBuffer:scene_node_buffer offset:0 atIndex:0];
                    [render_encoder setVertexBuffer:node_render_uniforms_buffer offset:0 atIndex:1];
                    for (int i = arrows_node_end * 40; i < scene_nodes.size()*40; i+=4) {
                        [render_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i vertexCount:4];
                    }
                }
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
    for (int i = 0; i < models.size(); i++) {
        delete models.at(i);
    }

    return 0;
}

