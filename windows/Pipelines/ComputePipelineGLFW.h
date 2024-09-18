#ifndef ComputePipelineGLFW_h
#define ComputePipelineGLFW_h

#include <stdio.h>
#include <vector>
#include <string>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include "Utils/Vec.h"
using namespace Vec;

#include "ShaderProcessor.h"

#include "ComputePipeline.h"
#include "RenderPipelineGLFW.h"

class ComputePipelineGLFW : public ComputePipeline {
private:
    // glfw specifics
    
    // ---PIPELINE STATES FOR GPU COMPUTE KERNELS---
    ComputeShader *compute_transforms_shader = NULL;
    ComputeShader *compute_vertex_shader = NULL;
    ComputeShader *compute_projected_vertices_shader = NULL;
    ComputeShader *compute_vertex_squares_shader = NULL;
    ComputeShader *compute_scaled_dots_shader = NULL;
    ComputeShader *compute_projected_dots_shader = NULL;
    ComputeShader *compute_projected_nodes_shader = NULL;
    ComputeShader *compute_lighting_shader = NULL;
    ComputeShader *compute_slice_plates_shader = NULL;
    ComputeShader *compute_ui_vertices_shader = NULL;

    ComputeShader *test_compute;

    // ---CPU BUFFER DATA---
    struct VertexBuffer { int size; Vertex data[1]; };
    struct FaceBuffer { int size; Face data[1]; };
    struct EdgeBuffer { int size; vec_int2 data[1]; };
    struct NodeBuffer { int size; Node data[1]; };
    struct DotBuffer { int size; Dot data[1]; };
    struct UIVertexBuffer { int size; UIVertex data[1]; };
    struct SliceAttributesBuffer { int size; SliceAttributes data[1]; };

    // cpu used buffer contents
    WindowAttributes *window_attributes_content = NULL;
    // compiled buffer key indices content exists in parent
    // camera content exists in scheme
    vec_float3 *scene_light_content = NULL;
    FaceBuffer *smfb_content = NULL;
    NodeBuffer *model_node_content = NULL;
    NodeVertexLink *nvlink_content = NULL;
    VertexBuffer *vertex_content = NULL;
    uint32_t *node_model_id_content = NULL;
    ModelTransform *model_transform_content = NULL;
    DotBuffer *dot_content = NULL;
    SliceAttributesBuffer *slice_attribute_content = NULL; 
    ModelTransform *slice_transform_content = NULL;
    uint32_t *dot_slice_id_content = NULL; // TODO
    UIVertexBuffer *ui_vertex_content = NULL;
    UIElementTransform *ui_element_transform_content = NULL;
    // ui render uniforms??
    uint32_t *ui_element_id_content = NULL;
    vec_float3 *compiled_vertex_content = NULL;
    Face *compiled_face_content = NULL;
    vec_int2 *compiled_edge_content = NULL;
    
    // ---BUFFERS FOR SCENE COMPUTE---
    // compute data
    GLuint window_attributes_buffer;
    GLuint compiled_buffer_key_indices_buffer;
    
    // general scene data
    GLuint camera_buffer;
    GLuint scene_light_buffer;
    
    // model data (from both scene and controls models)
    GLuint scene_model_face_buffer; // only scene (not controls) models - buffer is only used for lighting
    GLuint model_node_buffer;
    GLuint model_nvlink_buffer;
    GLuint model_vertex_buffer;
    GLuint node_model_id_buffer;
    GLuint model_transform_buffer;
    
    // slice data
    GLuint slice_dot_buffer;
    GLuint slice_attributes_buffer;
    GLuint slice_transform_buffer;
    GLuint slice_edit_window_buffer;
    GLuint dot_slice_id_buffer;
    
    // ui data
    GLuint ui_vertex_buffer;
    GLuint ui_element_transform_buffer;
    GLuint ui_render_uniforms_buffer;
    GLuint ui_vertex_element_id_buffer;
    
    // ---COMPILED BUFFERS TO SEND TO RENDERER---
    GLuint compiled_vertex_buffer;
    GLuint compiled_face_buffer;
    GLuint compiled_edge_buffer;

    GLuint testssbo;

    void DeleteContent();
    void DeletePtr(void **ptr);
public:
    ComputePipelineGLFW();
    ~ComputePipelineGLFW();
    void init();
    
    // call on start, when scheme changes, or when counts change
    // does not set any values, only creates buffers and sets size
    void CreateBuffers();
    
    // call when static data changes
    void ResetStaticBuffers();
    
    // call every frame
    void ResetDynamicBuffers();
    
    // pipeline
    void Compute();
    void SendDataToRenderer(RenderPipeline *renderer);
    void SendDataToScheme();
};

#endif /* ComputePipelineGLFW_h */