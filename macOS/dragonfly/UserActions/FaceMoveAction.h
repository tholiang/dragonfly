//
//  FaceMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef FaceMoveAction_h
#define FaceMoveAction_h

#include "UserAction.h"
#include "../Modeling/Model.h"

class FaceMoveAction : public UserAction {
public:
    FaceMoveAction(Model *m, int fid);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~FaceMoveAction();
private:
    Model *model_;
    int fid_;
    simd_float3 v1_initial_location_;
    simd_float3 movement_vector_;
};

#endif /* FaceMoveAction_h */

