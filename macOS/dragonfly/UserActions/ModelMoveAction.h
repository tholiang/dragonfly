//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef ModelMoveAction_h
#define ModelMoveAction_h

#include <vector>

#include "UserAction.h"
#include "../Modeling/Model.h"

class ModelMoveAction : public UserAction {
public:
    ModelMoveAction(std::vector<ModelUniforms> *uniforms, int mid);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~ModelMoveAction();
private:
    std::vector<ModelUniforms> *uniforms_;
    int mid_;
    simd_float3 initial_location_;
    simd_float3 movement_vector_;
};

#endif /* ModelMoveAction_h */
