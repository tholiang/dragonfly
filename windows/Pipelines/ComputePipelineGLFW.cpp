#include "ComputePipelineGLFW.h"
#include <iostream>
#include <cmath>

ComputePipelineGLFW::ComputePipelineGLFW() {

}

ComputePipelineGLFW::~ComputePipelineGLFW() {
    DeleteContent();

    delete compute_transforms_shader;
    delete compute_vertex_shader;
    delete compute_projected_vertices_shader;
    delete compute_vertex_squares_shader;
    delete compute_scaled_dots_shader;
    delete compute_projected_dots_shader;
    delete compute_projected_nodes_shader;
    delete compute_lighting_shader;
    delete compute_slice_plates_shader;
    delete compute_ui_vertices_shader;
}

void ComputePipelineGLFW::init() {
    // create compute shader objects
    compute_transforms_shader = new ComputeShader("Processing/Compute/CalculateModelNodeTransforms.comp", "Processing/util.glsl");
    compute_vertex_shader = new ComputeShader("Processing/Compute/CalculateVertices.comp", "Processing/util.glsl");
    compute_projected_vertices_shader = new ComputeShader("Processing/Compute/CalculateProjectedVertices.comp", "Processing/util.glsl");
    compute_vertex_squares_shader = new ComputeShader("Processing/Compute/CalculateVertexSquares.comp", "Processing/util.glsl");
    compute_scaled_dots_shader = new ComputeShader("Processing/Compute/CalculateScaledDots.comp", "Processing/util.glsl");
    compute_projected_dots_shader = new ComputeShader("Processing/Compute/CalculateProjectedDots.comp", "Processing/util.glsl");
    compute_projected_nodes_shader = new ComputeShader("Processing/Compute/CalculateProjectedNodes.comp", "Processing/util.glsl");
    compute_lighting_shader = new ComputeShader("Processing/Compute/CalculateFaceLighting.comp", "Processing/util.glsl");
    compute_slice_plates_shader = new ComputeShader("Processing/Compute/CalculateSlicePlates.comp", "Processing/util.glsl");
    compute_ui_vertices_shader = new ComputeShader("Processing/Compute/CalculateUIVertices.comp", "Processing/util.glsl");

    // generate buffer names
    glGenBuffers(1, &window_attributes_buffer);
    glGenBuffers(1, &compiled_buffer_key_indices_buffer);
    glGenBuffers(1, &camera_buffer);
    glGenBuffers(1, &scene_light_buffer);
    glGenBuffers(1, &scene_model_face_buffer);
    glGenBuffers(1, &model_node_buffer);
    glGenBuffers(1, &model_nvlink_buffer);
    glGenBuffers(1, &model_vertex_buffer);
    glGenBuffers(1, &node_model_id_buffer);
    glGenBuffers(1, &model_transform_buffer);
    glGenBuffers(1, &slice_dot_buffer);
    glGenBuffers(1, &slice_attributes_buffer);
    glGenBuffers(1, &slice_transform_buffer);
    glGenBuffers(1, &slice_edit_window_buffer);
    glGenBuffers(1, &dot_slice_id_buffer);
    glGenBuffers(1, &ui_vertex_buffer);
    glGenBuffers(1, &ui_element_transform_buffer);
    glGenBuffers(1, &ui_render_uniforms_buffer);
    glGenBuffers(1, &ui_vertex_element_id_buffer);
    glGenBuffers(1, &compiled_vertex_buffer);
    glGenBuffers(1, &compiled_face_buffer);
    glGenBuffers(1, &compiled_edge_buffer);
}

void ComputePipelineGLFW::CreateBuffers() {
    ComputePipeline::SetScheme(scheme);
    DeleteContent(); // delete and reset content to NULL
    
    // ---COMPUTE DATA BUFFERS---
    window_attributes_content = (WindowAttributes *) malloc(sizeof(WindowAttributes));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, window_attributes_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(WindowAttributes), scheme->GetWindowAttributes(), GL_STATIC_READ);

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_buffer_key_indices_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(CompiledBufferKeyIndices), &compiled_buffer_key_indices, GL_STATIC_READ);
    
    // ---COMPILED BUFFERS---
    // create compiled vertex buffer - all data to be set by gpu
    compiled_vertex_content = (vec_float3 *) malloc(compiled_vertex_size() * sizeof(vec_float3));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_vertex_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, compiled_vertex_size() * sizeof(vec_float3), compiled_vertex_content, GL_DYNAMIC_READ);

    // create compiled face buffer
    compiled_face_content = (Face *) malloc(compiled_face_size() * sizeof(Face));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_face_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (compiled_face_size() * sizeof(Face)), compiled_face_content, GL_DYNAMIC_READ);
    
    // create compiled edge buffer
    compiled_edge_content = (vec_int2 *) malloc(compiled_edge_size() * sizeof(vec_int2));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_edge_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (compiled_edge_size() * sizeof(vec_int2)), compiled_edge_content, GL_STATIC_READ);
    
    // ---GENERAL BUFFERS---
    // create camera buffer
    Camera *cam = scheme->GetCamera();
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, camera_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(Camera), cam, GL_DYNAMIC_READ);

    // create light buffer
    scene_light_content = (LightBuffer *) malloc(sizeof(int) + sizeof(SimpleLight));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, scene_light_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(int) + sizeof(SimpleLight), scene_light_content, GL_STATIC_READ);
    
    // ---MODEL BUFFERS---
    // create model face buffer - separate from compiled to calculate face lighting
    smfb_content = (FaceBuffer*) malloc(sizeof(int) + ((num_scene_faces)*sizeof(Face)));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, scene_model_face_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + ((num_scene_faces)*sizeof(Face))), smfb_content, GL_STATIC_READ);

    // create model node buffer
    model_node_content = (NodeBuffer *) malloc(sizeof(int) + ((num_scene_nodes+num_controls_nodes)*sizeof(Node)));
    model_node_content->size = num_scene_nodes+num_controls_nodes;
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_node_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + ((num_scene_nodes+num_controls_nodes)*sizeof(Node))), model_node_content, GL_DYNAMIC_READ);
    
    // create node to model id buffer
    node_model_id_content = (uint32_t *) malloc((num_scene_nodes+num_controls_nodes)*sizeof(uint32_t));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, node_model_id_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, ((num_scene_nodes+num_controls_nodes)*sizeof(uint32_t)), node_model_id_content, GL_STATIC_READ);
    
    // create node vertex link buffer
    nvlink_content = (NodeVertexLink *) malloc((num_scene_vertices*2+num_controls_vertices*2) * sizeof(NodeVertexLink));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_nvlink_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, ((num_scene_vertices*2+num_controls_vertices*2) * sizeof(NodeVertexLink)), nvlink_content, GL_STATIC_READ);
    
    // create model vertex buffer - intermediate: data calculated by kernel
    vertex_content = (VertexBuffer *) malloc(sizeof(int) + ((num_scene_vertices+num_controls_vertices)*sizeof(Vertex)));
    vertex_content->size = (num_scene_vertices+num_controls_vertices);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_vertex_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(int) + ((num_scene_vertices+num_controls_vertices)*sizeof(Vertex)), vertex_content, GL_DYNAMIC_READ);
    
    // create model transform buffer
    model_transform_content = (ModelTransform *) malloc((num_scene_models+num_controls_models)*sizeof(ModelTransform));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_transform_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (num_scene_models+num_controls_models)*sizeof(ModelTransform), model_transform_content, GL_DYNAMIC_READ);
    
    
    // ---SLICE BUFFERS---
    // create dot vertex buffer
    dot_content = (DotBuffer *) malloc(sizeof(int) + (num_scene_dots * sizeof(Dot)));
    dot_content->size = num_scene_dots;
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_dot_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (num_scene_dots * sizeof(Dot)), dot_content, GL_STATIC_READ);
    
    // create slice attributes buffer
    slice_attribute_content = (SliceAttributesBuffer *) malloc(sizeof(int) + (num_scene_slices * sizeof(SliceAttributes)));
    slice_attribute_content->size = num_scene_slices;
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_attributes_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (num_scene_slices * sizeof(SliceAttributes))), slice_attribute_content, GL_STATIC_READ);
    
    // create slice transform buffer
    slice_transform_content = (ModelTransform *) malloc(num_scene_slices*sizeof(ModelTransform));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_transform_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (num_scene_slices*sizeof(ModelTransform)), slice_transform_content, GL_DYNAMIC_READ);
    
    // create slice edit window buffer
    vec_float4 slice_edit_window;
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_edit_window_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(vec_float4)), &slice_edit_window, GL_STATIC_READ);
    
    
    // ---UI BUFFERS---
    // create ui vertex buffer
    ui_vertex_content = (UIVertexBuffer *) malloc(sizeof(int) + (num_ui_vertices * sizeof(UIVertex)));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_vertex_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (num_ui_vertices * sizeof(UIVertex))), ui_vertex_content, GL_STATIC_READ);
    
    // create ui transform buffer
    ui_element_transform_content = (UIElementTransform *) malloc(num_ui_elements * sizeof(UIElementTransform));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_element_transform_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (num_ui_elements * sizeof(UIElementTransform)), ui_element_transform_content, GL_DYNAMIC_READ);
    
    // create ui element id buffer
    ui_element_id_content = (uint32_t *) malloc(num_ui_vertices * sizeof(uint32_t));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_vertex_element_id_buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, (num_ui_vertices * sizeof(uint32_t)), ui_element_id_content, GL_STATIC_READ);

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0); // unbind
}


void ComputePipelineGLFW::UpdateBufferCapacities() {
    ComputePipeline::SetScheme(scheme);
    glNamedBufferSubData (compiled_buffer_key_indices_buffer, 0, sizeof(compiled_buffer_key_indices), &compiled_buffer_key_indices);

    // ---COMPILED BUFFERS---
    if (compiled_vertex_size() > compiled_vertex_buffer_capacity) {
        compiled_vertex_buffer_capacity = compiled_vertex_size()*2;

        if (compiled_vertex_content != NULL) { free(compiled_vertex_content); }
        compiled_vertex_content = (vec_float3 *) malloc(compiled_vertex_buffer_capacity * sizeof(vec_float3));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_vertex_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, compiled_vertex_buffer_capacity * sizeof(vec_float3), compiled_vertex_content, GL_DYNAMIC_READ);
    }

    if (compiled_face_size() > compiled_face_buffer_capacity) {
        compiled_face_buffer_capacity = compiled_face_size()*2;
        
        if (compiled_face_content != NULL) { free(compiled_face_content); }
        compiled_face_content = (Face *) malloc(compiled_face_buffer_capacity * sizeof(Face));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_face_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (compiled_face_buffer_capacity * sizeof(Face)), compiled_face_content, GL_DYNAMIC_READ);
    }
    
    if (compiled_edge_size() > compiled_edge_buffer_capacity) {
        compiled_edge_buffer_capacity = compiled_edge_size()*2;
        
        if (compiled_edge_content != NULL) { free(compiled_edge_content); }
        compiled_edge_content = (vec_int2 *) malloc(compiled_edge_buffer_capacity * sizeof(vec_int2));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, compiled_edge_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (compiled_edge_buffer_capacity * sizeof(vec_int2)), compiled_edge_content, GL_STATIC_READ);
    }
    
    // ---GENERAL BUFFERS---
    if (num_scene_lights > light_buffer_capacity) {
        light_buffer_capacity = num_scene_lights*2;

        if (scene_light_content != NULL) { free(scene_light_content); }
        scene_light_content = (LightBuffer *) malloc(sizeof(int) + (light_buffer_capacity*sizeof(SimpleLight)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, scene_light_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (light_buffer_capacity*sizeof(SimpleLight))), scene_light_content, GL_STATIC_READ);
    }
    
    // ---MODEL BUFFERS---
    if (num_scene_faces > scene_model_face_buffer_capacity) {
        scene_model_face_buffer_capacity = num_scene_faces*2;
        
        if (smfb_content != NULL) { free(smfb_content); }
        smfb_content = (FaceBuffer*) malloc(sizeof(int) + (scene_model_face_buffer_capacity*sizeof(Face)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, scene_model_face_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (scene_model_face_buffer_capacity*sizeof(Face))), smfb_content, GL_STATIC_READ);
    }

    if (num_scene_nodes+num_controls_nodes > model_node_buffer_capacity) {
        model_node_buffer_capacity = (num_scene_nodes+num_controls_nodes)*2;
        
        if (model_node_content != NULL) { free(model_node_content); }
        model_node_content = (NodeBuffer *) malloc(sizeof(int) + (model_node_buffer_capacity*sizeof(Node)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_node_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (model_node_buffer_capacity*sizeof(Node))), model_node_content, GL_DYNAMIC_READ);
    
        
        if (node_model_id_content != NULL) { free(node_model_id_content); }
        node_model_id_content = (uint32_t *) malloc(model_node_buffer_capacity*sizeof(uint32_t));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, node_model_id_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (model_node_buffer_capacity*sizeof(uint32_t)), node_model_id_content, GL_STATIC_READ);
    }
    
    if (num_scene_vertices+num_controls_vertices > model_vertex_buffer_capacity) {
        model_vertex_buffer_capacity = (num_scene_vertices+num_controls_vertices)*2;

        if (nvlink_content != NULL) { free(nvlink_content); }
        nvlink_content = (NodeVertexLink *) malloc((model_vertex_buffer_capacity*2) * sizeof(NodeVertexLink));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_nvlink_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, ((model_vertex_buffer_capacity*2) * sizeof(NodeVertexLink)), nvlink_content, GL_STATIC_READ);
    
        if (vertex_content != NULL) { free(vertex_content); }
        vertex_content = (VertexBuffer *) malloc(sizeof(int) + (model_vertex_buffer_capacity*sizeof(Vertex)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_vertex_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(int) + (model_vertex_buffer_capacity*sizeof(Vertex)), vertex_content, GL_DYNAMIC_READ);
    }

    if (num_scene_models+num_controls_models > model_buffer_capacity) {
        model_buffer_capacity = num_scene_models+num_controls_models;

        if (model_transform_content != NULL) { free(model_transform_content); }
        model_transform_content = (ModelTransform *) malloc(model_buffer_capacity*sizeof(ModelTransform));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, model_transform_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, model_buffer_capacity*sizeof(ModelTransform), model_transform_content, GL_DYNAMIC_READ);
    }

    
    // ---SLICE BUFFERS---
    if (num_scene_dots > slice_dot_buffer_capacity) {
        slice_dot_buffer_capacity = num_scene_dots*2;

        if (dot_content != NULL) { free(dot_content); }
        dot_content = (DotBuffer *) malloc(sizeof(int) + (slice_dot_buffer_capacity * sizeof(Dot)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_dot_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (slice_dot_buffer_capacity * sizeof(Dot)), dot_content, GL_STATIC_READ);
    }
    
    if (num_scene_slices > slice_buffer_capacity) {
        slice_buffer_capacity = num_scene_slices*2;

        if (slice_attribute_content != NULL) { free(slice_attribute_content); }
        slice_attribute_content = (SliceAttributesBuffer *) malloc(sizeof(int) + (slice_buffer_capacity * sizeof(SliceAttributes)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_attributes_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (slice_buffer_capacity * sizeof(SliceAttributes))), slice_attribute_content, GL_STATIC_READ);
        
        if (slice_transform_content != NULL) { free(slice_transform_content); }
        slice_transform_content = (ModelTransform *) malloc(slice_buffer_capacity*sizeof(ModelTransform));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, slice_transform_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (slice_buffer_capacity*sizeof(ModelTransform)), slice_transform_content, GL_DYNAMIC_READ);
    }
    
    
    // ---UI BUFFERS---
    if (num_ui_vertices > ui_vertex_buffer_capacity) {
        ui_vertex_buffer_capacity = num_ui_vertices*2;

        if (ui_vertex_content != NULL) { free(ui_vertex_content); }
        ui_vertex_content = (UIVertexBuffer *) malloc(sizeof(int) + (ui_vertex_buffer_capacity * sizeof(UIVertex)));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_vertex_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (sizeof(int) + (ui_vertex_buffer_capacity * sizeof(UIVertex))), ui_vertex_content, GL_STATIC_READ);

        if (ui_element_id_content != NULL) { free(ui_element_id_content); }
        ui_element_id_content = (uint32_t *) malloc(ui_vertex_buffer_capacity * sizeof(uint32_t));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_vertex_element_id_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (ui_vertex_buffer_capacity * sizeof(uint32_t)), ui_element_id_content, GL_STATIC_READ);
    }
    
    if (num_ui_elements > ui_element_buffer_capacity) {
        ui_element_buffer_capacity = num_ui_elements*2;

        if (ui_element_transform_content != NULL) { free(ui_element_transform_content); }
        ui_element_transform_content = (UIElementTransform *) malloc(ui_element_buffer_capacity * sizeof(UIElementTransform));
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, ui_element_transform_buffer);
        glBufferData(GL_SHADER_STORAGE_BUFFER, (ui_element_buffer_capacity * sizeof(UIElementTransform)), ui_element_transform_content, GL_DYNAMIC_READ);
    }
    

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0); // unbind
}

void ComputePipelineGLFW::ResetStaticBuffers() {
    // TODO: this is unoptimized for opengl

    // assume all counts are accurate
    
    // ---COMPILED BUFFERS---
    // add data to compiled face buffer
    glGetNamedBufferSubData (compiled_face_buffer, 0, compiled_face_size() * sizeof(Face), compiled_face_content);
    scheme->SetSceneFaceBuffer(compiled_face_content + compiled_face_scene_start(), compiled_vertex_scene_start()); // scene faces
    scheme->SetControlFaceBuffer(compiled_face_content + compiled_face_control_start(), compiled_vertex_control_start()); // control faces
    scheme->SetUIFaceBuffer(compiled_face_content + compiled_face_ui_start(), compiled_vertex_ui_start()); // ui faces
    // rest will be set by GPU
    glNamedBufferSubData (compiled_face_buffer, 0, compiled_face_size() * sizeof(Face), compiled_face_content);

    // add data to compiled edge buffer
    glGetNamedBufferSubData (compiled_edge_buffer, 0, compiled_edge_size() * sizeof(vec_int2), compiled_edge_content);
    if (scheme->ShouldRenderEdges()) scheme->SetSceneEdgeBuffer(compiled_edge_content + compiled_edge_scene_start(), compiled_vertex_scene_start()); // scene edges
    scheme->SetSliceLineBuffer(compiled_edge_content + compiled_edge_line_start(), compiled_vertex_dot_start()); // slice lines
    glNamedBufferSubData (compiled_edge_buffer, 0, compiled_edge_size() * sizeof(vec_int2), compiled_edge_content);
    
    
    // ---GENERAL BUFFERS---
    // add data to light buffer
    // NEEDS UPDATE
    glGetNamedBufferSubData (scene_light_buffer, 0, sizeof(int) + (light_buffer_capacity*sizeof(SimpleLight)), scene_light_content);
    scene_light_content->size = num_scene_lights;
    SimpleLight *light_data = (SimpleLight *) (((char *) scene_light_content)+sizeof(int));
    scheme->SetSceneLightBuffer(light_data);
    glNamedBufferSubData (scene_light_buffer, 0, sizeof(int) + (num_scene_lights*sizeof(SimpleLight)), scene_light_content);
    
    
    // ---MODEL BUFFERS---
    // actual data set by gpu
    glGetNamedBufferSubData (model_vertex_buffer, 0, sizeof(int), vertex_content);
    vertex_content->size = num_scene_vertices+num_controls_vertices;
    glNamedBufferSubData (model_vertex_buffer, 0, sizeof(int), vertex_content);

    // add data to scene model face buffer
    glGetNamedBufferSubData (scene_model_face_buffer, 0, sizeof(int) + (num_scene_faces*sizeof(Face)), smfb_content);
    smfb_content->size = num_scene_faces;
    Face *smfb_data = (Face *) (((char *) smfb_content)+sizeof(int));
    scheme->SetSceneFaceBuffer(smfb_data, compiled_vertex_scene_start()); // scene faces
    glNamedBufferSubData (scene_model_face_buffer, 0, sizeof(int) + (num_scene_faces*sizeof(Face)), smfb_content);
    
    // add data to node to model id buffer
    glGetNamedBufferSubData (node_model_id_buffer, 0, (num_scene_nodes + num_controls_nodes)*sizeof(uint32_t), node_model_id_content);
    scheme->SetSceneNodeModelIDBuffer(node_model_id_content, 0); // scene nodes
    scheme->SetControlNodeModelIDBuffer(node_model_id_content+num_scene_nodes, num_scene_models); // controls nodes
    glNamedBufferSubData (node_model_id_buffer, 0, (num_scene_nodes + num_controls_nodes)*sizeof(uint32_t), node_model_id_content);
    
    // add data to node vertex link buffer
    glGetNamedBufferSubData (model_nvlink_buffer, 0, 2*(num_scene_vertices + num_controls_vertices)*sizeof(NodeVertexLink), nvlink_content);
    scheme->SetSceneNodeVertexLinkBuffer(nvlink_content, 0); // scene nvlinks
    scheme->SetControlNodeVertexLinkBuffer(nvlink_content+num_scene_vertices*2, num_scene_nodes); // controls nvlinks
    glNamedBufferSubData (model_nvlink_buffer, 0, 2*(num_scene_vertices + num_controls_vertices)*sizeof(NodeVertexLink), nvlink_content);

    // ---SLICE BUFFERS---
    // add data to dot buffer
    glGetNamedBufferSubData (slice_dot_buffer, 0, sizeof(int) + num_scene_dots*sizeof(Dot), dot_content);
    dot_content->size = num_scene_dots;
    Dot *dot_data = (Dot *) (((char *) dot_content)+sizeof(int));
    scheme->SetSliceDotBuffer(dot_data); // dots
    glNamedBufferSubData (slice_dot_buffer, 0, sizeof(int) + num_scene_dots*sizeof(Dot), dot_content);
    
    // add data to slice attributes buffer
    glGetNamedBufferSubData (slice_attributes_buffer, 0, num_scene_slices*sizeof(SliceAttributes), slice_attribute_content);
    SliceAttributes *sa_data = (SliceAttributes *) (((char *) slice_attribute_content)+sizeof(int));
    scheme->SetSliceAttributesBuffer(sa_data); // slice attributes
    glNamedBufferSubData (slice_attributes_buffer, 0, num_scene_slices*sizeof(SliceAttributes), slice_attribute_content);
    
    // add data to slice edit window buffer
    vec_float4 slice_edit_window_content = scheme->GetEditWindow();
    glNamedBufferSubData (slice_edit_window_buffer, 0, sizeof(vec_float4), &slice_edit_window_content);
    
    
    // ---UI BUFFERS---
    // add data to ui vertex buffer
    glGetNamedBufferSubData (ui_vertex_buffer, 0, sizeof(int) + num_ui_vertices*sizeof(UIVertex), ui_vertex_content);
    ui_vertex_content->size = num_ui_vertices;
    UIVertex *uiv_data = (UIVertex *) (((char *) ui_vertex_content)+sizeof(int));
    scheme->SetUIVertexBuffer(uiv_data);
    glNamedBufferSubData (ui_vertex_buffer, 0, sizeof(int) + num_ui_vertices*sizeof(UIVertex), ui_vertex_content);
    
    // add data to ui element id buffer
    glGetNamedBufferSubData (ui_vertex_element_id_buffer, 0, num_ui_vertices*sizeof(uint32_t), ui_element_id_content);
    scheme->SetUIElementIDBuffer(ui_element_id_content);
    glNamedBufferSubData (ui_vertex_element_id_buffer, 0, num_ui_vertices*sizeof(uint32_t), ui_element_id_content);
}

void ComputePipelineGLFW::ResetDynamicBuffers() {
    // TODO: this is unoptimized for opengl

    // assume all counts are accurate
    
    // ---COMPUTE DATA BUFFERS---
    // add data to window attribute buffer
    *window_attributes_content = *scheme->GetWindowAttributes();
    glNamedBufferSubData (window_attributes_buffer, 0, sizeof(WindowAttributes), window_attributes_content);
    
    
    // ---GENERAL BUFFERS---
    // add data to camera buffer
    Camera *camera_content = scheme->GetCamera();
    glNamedBufferSubData (camera_buffer, 0, sizeof(Camera), camera_content);
    
    
    // ---MODEL BUFFERS---
    // add data to model node buffer
    glGetNamedBufferSubData (model_node_buffer, 0, sizeof(int)+(num_scene_nodes+num_controls_nodes)*sizeof(Node), model_node_content);
    model_node_content->size = (num_scene_nodes+num_controls_nodes);
    Node *node_data = (Node *) (((char *) model_node_content)+sizeof(int));
    scheme->SetSceneNodeBuffer(node_data); // scene nodes
    scheme->SetControlNodeBuffer(node_data+num_scene_nodes); // controls nodes
    glNamedBufferSubData (model_node_buffer, 0, sizeof(int)+(num_scene_nodes+num_controls_nodes)*sizeof(Node), model_node_content);
    
    // add data to model transform buffer
    glGetNamedBufferSubData (model_transform_buffer, 0, (num_scene_models+num_controls_models)*sizeof(ModelTransform), model_transform_content);
    scheme->SetSceneModelTransformBuffer(model_transform_content); // scene transforms
    scheme->SetControlModelTransformBuffer(model_transform_content+num_scene_models); // controls transforms
    glNamedBufferSubData (model_transform_buffer, 0, (num_scene_models+num_controls_models)*sizeof(ModelTransform), model_transform_content);
    
    
    // ---SLICE BUFFERS---
    // add data to slice transform buffer
    glGetNamedBufferSubData (slice_transform_buffer, 0, (num_scene_slices)*sizeof(ModelTransform), slice_transform_content);
    scheme->SetSliceTransformBuffer(slice_transform_content);
    glNamedBufferSubData (slice_transform_buffer, 0, (num_scene_slices)*sizeof(ModelTransform), slice_transform_content);
    
    
    // ---UI BUFFERS---
    // add data to ui element transform buffer
    glGetNamedBufferSubData (ui_element_transform_buffer, 0, (num_ui_elements)*sizeof(UIElementTransform), ui_element_transform_content);
    scheme->SetUITransformBuffer(ui_element_transform_content);
    glNamedBufferSubData (ui_element_transform_buffer, 0, (num_ui_elements)*sizeof(UIElementTransform), ui_element_transform_content);
}

void ComputePipelineGLFW::Compute() {
    // RUN COMPUTE

    // if any models to display, calculate values from kernel
    if (num_scene_vertices > 0 && num_scene_faces > 0 && num_scene_nodes > 0) {
        // calculate nodes (scene and control) in world space from model space
        glUseProgram(compute_transforms_shader->ID);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, model_node_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, node_model_id_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, model_transform_buffer);
        glDispatchCompute( std::ceil(((float) (num_scene_nodes+num_controls_nodes))/128), 1, 1 );

        // memory barrier for transforms
        glMemoryBarrier(GL_ALL_BARRIER_BITS);
        
        // calculate vertices (scene and control) in world space from node-ish space
        glUseProgram(compute_vertex_shader->ID);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, model_vertex_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, model_nvlink_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, model_node_buffer);
        glDispatchCompute( std::ceil(((float) (num_scene_vertices+num_controls_vertices))/128), 1, 1 );

        // memory barrier for transforms
        glMemoryBarrier(GL_ALL_BARRIER_BITS);
        
        // calculate projected vertices from world space vertices
        glUseProgram(compute_projected_vertices_shader->ID);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, model_vertex_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, camera_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, compiled_buffer_key_indices_buffer);
        glDispatchCompute( std::ceil(((float) (num_scene_vertices+num_controls_vertices))/128), 1, 1 );

        // memory barrier for transforms
        glMemoryBarrier(GL_ALL_BARRIER_BITS);
        
        // calculate vertex squares from projected vertices if needed
        if (scheme->ShouldRenderVertices()) {
            glUseProgram(compute_vertex_squares_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, model_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, compiled_buffer_key_indices_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, window_attributes_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_vertices)/128), 1, 1 );
        }
        
        // calculate projected scene nodes if needed
        if (scheme->ShouldRenderNodes()) {
            glUseProgram(compute_projected_nodes_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, model_node_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, camera_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, window_attributes_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 6, compiled_buffer_key_indices_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_nodes)/128), 1, 1 );
        }
        
        // if lighting is enabled calculate scene face lighting
        if (scheme->LightingEnabled() && num_scene_lights > 0) {
            glUseProgram(compute_lighting_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, scene_model_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, model_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, scene_light_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, compiled_buffer_key_indices_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_faces)/128), 1, 1 );
        }
    }
    
    // if any slices to display, calculate values from kernel
    if (num_scene_dots > 0) {
        if (scheme->GetType() == SchemeType::EditSlice) {
            // scale dots if editing slice
            glUseProgram(compute_scaled_dots_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, slice_dot_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, slice_attributes_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, window_attributes_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 6, slice_edit_window_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 7, compiled_buffer_key_indices_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_dots)/128), 1, 1 );
        } else {
            // project dots otherwise
            glUseProgram(compute_projected_dots_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, slice_dot_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, slice_transform_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, camera_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 6, dot_slice_id_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 7, window_attributes_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 8, compiled_buffer_key_indices_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_dots)/128), 1, 1 );
            
            // make slice plates
            glUseProgram(compute_slice_plates_shader->ID);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, compiled_face_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, slice_transform_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, slice_attributes_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, camera_buffer);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 6, compiled_buffer_key_indices_buffer);
            glDispatchCompute( std::ceil(((float) num_scene_slices)/128), 1, 1 );
        }
    }

    if (num_ui_vertices > 0) {
        // make ui vertices
        glUseProgram(compute_ui_vertices_shader->ID);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compiled_vertex_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, ui_vertex_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, ui_vertex_element_id_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, ui_element_transform_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 5, window_attributes_buffer);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 6, compiled_buffer_key_indices_buffer);
        glDispatchCompute( std::ceil(((float) num_ui_vertices)/128), 1, 1 );
    }

    // Synchronize the managed buffers for scheme
    glMemoryBarrier(GL_ALL_BARRIER_BITS);
}

void ComputePipelineGLFW::SendDataToRenderer(RenderPipeline *renderer) {
    RenderPipelineGLFW *renderer_glfw = (RenderPipelineGLFW *) renderer;
    renderer_glfw->SetBuffers(compiled_vertex_buffer, compiled_face_buffer, compiled_edge_buffer, compiled_face_size(), compiled_edge_size());
}

void ComputePipelineGLFW::SendDataToScheme() {
    glGetNamedBufferSubData (compiled_vertex_buffer, 0, compiled_vertex_size()*sizeof(vec_float3), compiled_vertex_content);
    glGetNamedBufferSubData (compiled_face_buffer, 0, compiled_face_size()*sizeof(Face), compiled_face_content);
    glGetNamedBufferSubData (model_vertex_buffer, 0, sizeof(int) + ((num_scene_vertices+num_controls_vertices)*sizeof(Vertex)), vertex_content);
    glGetNamedBufferSubData (model_node_buffer, 0, (sizeof(int) + ((num_scene_nodes+num_controls_nodes)*sizeof(Node))), model_node_content);

    Vertex *cmv = (Vertex *) (((char *) vertex_content) + sizeof(int));
    Node *cmn = (Node *) (((char *) model_node_content) + sizeof(int));
    
    scheme->SetBufferContents(&compiled_buffer_key_indices, compiled_vertex_content, compiled_face_content, cmv, cmn);
}

void ComputePipelineGLFW::DeleteContent() {
    if (window_attributes_content != NULL) {
        free(window_attributes_content);
        window_attributes_content = NULL;
    }
    if (scene_light_content != NULL) {
        free(scene_light_content);
        scene_light_content = NULL;
    }
    if (smfb_content != NULL) {
        free(smfb_content);
        smfb_content = NULL;
    }
    if (model_node_content != NULL) {
        free(model_node_content);
        model_node_content = NULL;
    }
    if (nvlink_content != NULL) {
        free(nvlink_content);
        nvlink_content = NULL;
    }
    if (vertex_content != NULL) {
        free(vertex_content);
        vertex_content = NULL;
    }
    if (node_model_id_content != NULL) {
        free(node_model_id_content);
        node_model_id_content = NULL;
    }
    if (model_transform_content != NULL) {
        free(model_transform_content);
        model_transform_content = NULL;
    }
    if (dot_content != NULL) {
        free(dot_content);
        dot_content = NULL;
    }
    if (slice_transform_content != NULL) {
        free(slice_transform_content);
        slice_transform_content = NULL;
    }
    if (dot_slice_id_content != NULL) {
        free(dot_slice_id_content);
        dot_slice_id_content = NULL;
    }
    if (ui_vertex_content != NULL) {
        free(ui_vertex_content);
        ui_vertex_content = NULL;
    }
    if (ui_element_transform_content != NULL) {
        free(ui_element_transform_content);
        ui_element_transform_content = NULL;
    }
    if (ui_element_id_content != NULL) {
        free(ui_element_id_content);
        ui_element_id_content = NULL;
    }
    if (compiled_vertex_content != NULL) {
        free(compiled_vertex_content);
        compiled_vertex_content = NULL;
    }
    if (compiled_face_content != NULL) {
        free(compiled_face_content);
        compiled_face_content = NULL;
    }
    if (compiled_edge_content != NULL) {
        free(compiled_edge_content);
        compiled_edge_content = NULL;
    }
}