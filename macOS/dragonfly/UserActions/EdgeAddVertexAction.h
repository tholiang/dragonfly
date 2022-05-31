//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef EdgeAddVertexAction_h
#define EdgeAddVertexAction_h

#include <iostream>
#include "UserAction.h"
#include "../Modeling/Model.h"

class EdgeAddVertexAction : public UserAction {
public:
    EdgeAddVertexAction(Model *m, int vid_new, int vid1, int vid2);
    simd_float3 BiAvg (simd_float3 p1, simd_float3 p2);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~EdgeAddVertexAction();
private:
    Model *model_;
    int vid_new_;
    int vid1_;
    int vid2_;
    int original_face_size_;
    std::vector<unsigned long> fids_;
    std::vector<unsigned long> new_fids_;
};

#endif /* FaceAddVertexAction_h */
