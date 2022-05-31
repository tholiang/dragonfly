//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef EdgeMoveAction_h
#define EdgeMoveAction_h

#include "UserAction.h"
#include "../Modeling/Model.h"

class EdgeMoveAction : public UserAction {
public:
    EdgeMoveAction(Model *m, int vid1, int vid2);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~EdgeMoveAction();
private:
    Model *model_;
    int vid1_;
    int vid2_;
    simd_float3 v1_initial_location_;
    simd_float3 movement_vector_;
};

#endif /* EdgeMoveAction_h */
