//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef VertexMoveAction_h
#define VertexMoveAction_h

#include "UserAction.h"
#include "../Modeling/Model.h"

class VertexMoveAction : public UserAction {
public:
    VertexMoveAction(Model *m, int vid);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~VertexMoveAction();
private:
    Model *model_;
    int vid_;
    simd_float3 initial_location_;
    simd_float3 movement_vector_;
};

#endif /* VertexMoveAction_h */
