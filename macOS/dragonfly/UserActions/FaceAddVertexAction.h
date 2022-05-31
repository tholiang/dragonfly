//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef FaceAddVertexAction_h
#define FaceAddVertexAction_h

#include "UserAction.h"
#include "../Modeling/Model.h"

class FaceAddVertexAction : public UserAction {
public:
    FaceAddVertexAction(Model *m, int vid, int fid);
    simd_float3 TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~FaceAddVertexAction();
private:
    Model *model_;
    int vid_;
    int fid_;
    int original_vertices_[3];
    int new_fid1_;
    int new_fid2_;
};

#endif /* FaceAddVertexAction_h */
