//
//  EditScheme.h
//  dragonfly
//
//  Created by Thomas Liang on 7/12/22.
//

#ifndef EditScheme_h
#define EditScheme_h

class EditScheme : public Scheme {
protected:
    std::vector<Model *> controls_models;
    std::vector<ModelUniforms> controls_model_uniforms;
    unsigned long controls_vertex_length;
    unsigned long controls_face_length;
    unsigned long controls_node_length;
    Vertex * control_models_projected_vertices_;
    Face * control_models_faces_;
    // z base, z tip, x base, x tip, y base, y tip
    simd_float2 arrow_projections [6];
public:
    
}

#endif /* EditScheme_h */
