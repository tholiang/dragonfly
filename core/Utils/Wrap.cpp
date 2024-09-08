//
//  Wrap.cpp
//  dragonfly
//
//  Created by Thomas Liang on 5/16/24.
//

#include "Wrap.h"

using std::pair;
using std::make_pair;
using std::queue;

float DragonflyUtils::float_randomizer(float d, float r) {
    float num = ((float) rand()) / RAND_MAX;
    return (d - r/2) + (r * num);
}

vec_float3 DragonflyUtils::get_a_normal(vec_float3 v) {
    vec_float3 ret = CrossProduct(v, vec_make_float3(1, 0, 0));
    
    if (Magnitude(ret) == 0) {
        ret = CrossProduct(v, vec_make_float3(0, 1, 0));
    }
    
    return unit_vector(ret);
}

vec_float3 DragonflyUtils::find_wrap_start(float step, std::function<bool(vec_float3)> in_model) {
    // TODO: change start later
    vec_float3 origin = vec_make_float3(0, 0, 0);
    vec_float3 vec = unit_vector(vec_make_float3(0, 0, 1));
    vec.x *= step;
    vec.y *= step;
    vec.z *= step;
    
    vec_float3 cur = origin;
    bool cur_in_model = in_model(cur);
    while (dist3to3(cur, origin) < 1000) {
        bool new_in_model = in_model(cur);
        if (new_in_model != cur_in_model) {
            break;
        }
        cur_in_model = new_in_model;
        
        cur = cur + vec;
    }
    return cur;
}

pair<vec_float3, float> DragonflyUtils::find_surface(vec_float3 origin, vec_float3 vector, vec_float3 dir, float step, float starting_angle, std::function<bool(vec_float3)> in_model) {
    float vec_len = Magnitude(vector);
    
    Basis cur_basis;
    cur_basis.x = unit_vector(vector);
    cur_basis.y = unit_vector(dir);
    cur_basis.z = unit_vector(CrossProduct(vector, dir));
    
    RotateBasisOnZ(&cur_basis, starting_angle);
    
    bool cur_in_model = in_model(origin + ScaleVector(cur_basis.x, vec_len));
    float cur_angle = starting_angle;
    while (cur_angle < 2*M_PI) {
        bool new_in_model = in_model(origin + ScaleVector(cur_basis.x, vec_len));
        if (new_in_model != cur_in_model) {
            break;
        }
        cur_in_model = new_in_model;
        
        RotateBasisOnZ(&cur_basis, step);
        cur_angle += step;
    }
    
    return make_pair(origin + ScaleVector(cur_basis.x, vec_len), cur_angle);
}

std::vector<int> DragonflyUtils::near_vertices(Model *m, vec_float3 point, float sep) {
    std::vector<int> ret;
    for (int vid = 0; vid < m->NumVertices(); vid++) {
        vec_float3 vertex = m->GetVertex(vid);
        
        if (dist3to3(vertex, point) < sep) { ret.push_back(vid); }
    }
    
    return ret;
}

bool DragonflyUtils::point_in_face(Model *m, vec_float3 point, float sep) {
    for (int i = 0; i < m->NumFaces(); i++) {
        Face *f = m->GetFace(i);
        vec_float3 v1 = m->GetVertex(f->vertices[0]);
        vec_float3 v2 = m->GetVertex(f->vertices[1]);
        vec_float3 v3 = m->GetVertex(f->vertices[2]);
        if (InTriangle3D(point, v1, v2, v3, sep)) {
            return true;
        }
    }
    
    return false;
}

bool DragonflyUtils::face_overlaps(Model *m, vec_float3 v1, vec_float3 v2, vec_float3 v3, float sep, std::vector<int> ignore_vids) {
    // check if center of given face is in any model faces
    if (point_in_face(m, TriAvg(v1, v2, v3), sep)) {
        return true;
    }
    
    // check if center of any model faces is in given face
    for (int i = 0; i < m->NumFaces(); i++) {
        Face *of = m->GetFace(i);
        vec_float3 ov1 = m->GetVertex(of->vertices[0]);
        vec_float3 ov2 = m->GetVertex(of->vertices[1]);
        vec_float3 ov3 = m->GetVertex(of->vertices[2]);
        
        if (!InIntVector(ignore_vids, of->vertices[0]) && InTriangle3D(ov1, v1, v2, v3, sep)) {
            return true;
        }
        
        if (!InIntVector(ignore_vids, of->vertices[1]) && InTriangle3D(ov2, v1, v2, v3, sep)) {
            return true;
        }
        
        if (!InIntVector(ignore_vids, of->vertices[2]) && InTriangle3D(ov3, v1, v2, v3, sep)) {
            return true;
        }
        
        if (InTriangle3D(TriAvg(ov1, ov2, ov3), v1, v2, v3, sep)) {
            return true;
        }
    }
    
    return false;
}

Model *DragonflyUtils::Wrap(float a_r, float l_r, float l_d, float step, float sep, bool should_simplify, std::function<bool(vec_float3)> in_model) {
    Model *m = new Model();
    // queue of edges: edge, vector to other vertex edge belongs to
    queue<vec_int2> q;
    
    // get starting points
    vec_float3 sp1, sp2, sp3;
    bool valid = false;
    int iterations_left = 1;
    while (!valid && iterations_left > 0) {
        iterations_left--;
        sp1 = find_wrap_start(l_d*sin(step), in_model);
        pair<vec_float3, float> fs_ret = find_surface(
            sp1,
            vec_make_float3(0, 0, float_randomizer(l_d, l_r)),
            vec_make_float3(1, 0, 0),
            step,
            0,
            in_model);
        if (fs_ret.second > 2*M_PI) { continue; }
        sp2 = fs_ret.first;
        
        valid = true;
    }
    
    // add points to model and make face
    int svid1 = m->MakeVertex(sp1.x, sp1.y, sp1.z);
    int svid2 = m->MakeVertex(sp2.x, sp2.y, sp2.z);
    
    // add starting edges to queue
    q.push(vec_make_int2(svid1, svid2));
    
    int total_face_iterations = 10000;
    iterations_left = total_face_iterations;
    // build model
    while (!q.empty() && iterations_left > 0) {
        iterations_left--;
        
        // get top edge
        vec_int2 e = q.front();
        q.pop();
        
        // if edge is already part of two faces, continue
        if (m->GetEdgeFaces(e.x, e.y).size() >= 2) {
            continue;
        }
        
        vec_float3 v1 = m->GetVertex(e.x);
        vec_float3 v2 = m->GetVertex(e.y);
        vec_float3 edge_vec = v2 - v1;
        
        // midpoint is new origin
        vec_float3 origin = BiAvg(v1, v2);
        
        // make starting vector
        // start somewhere perpendicular to the edge
        vec_float3 vector = CrossProduct(edge_vec, vec_make_float3(1,0,0));
        if (Magnitude(vector) == 0) {
            vector = CrossProduct(edge_vec, vec_make_float3(0,1,0));
        }
        float scale = (float_randomizer(l_d, l_r)*sqrt(3)/2)/Magnitude(vector);
        vector.x *= scale;
        vector.y *= scale;
        vector.z *= scale;
        
        // find direction vector
        vec_float3 dir = CrossProduct(edge_vec, vector);
        
        // try to find new surface point
        pair<vec_float3, float> sp_ret = find_surface(origin, vector, dir, step, 0, in_model);
        
        // get all candidates for both existing vertices and new ones
        std::vector<vec_float3> new_candidates; // possible new vertices
        while (sp_ret.second < 2*M_PI) {
            vec_float3 nv = sp_ret.first;
            new_candidates.push_back(nv);
            sp_ret = find_surface(origin, vector, dir, step, sp_ret.second+step, in_model);
        }
        
        std::vector<int> existing_candidates; // possible existing vertices for a new face
        
        std::vector<int> overlap_ignore_vids;
        overlap_ignore_vids.push_back(e.x);
        overlap_ignore_vids.push_back(e.y);
        
        // remove all invalid new candidates
        for (int i = ((int) new_candidates.size())-1; i >= 0; i--) {
            vec_float3 v = new_candidates[i];
            // if near existing vertex, add to vector
            std::vector<int> near_vs = near_vertices(m, v, sep);
            if (!near_vs.empty()) {
                new_candidates.erase(new_candidates.begin() + i);
                for (int i = 0; i < near_vs.size(); i++) {
                    existing_candidates.push_back(near_vs[i]);
                }
                continue;
            }
            
            if (point_in_face(m, v, sep)) {
                continue;
            }
            
            // if face overlaps
            if (face_overlaps(m, v1, v2, v, sep, overlap_ignore_vids)) {
                new_candidates.erase(new_candidates.begin() + i);
                continue;
            }
        }
        
        // remove all invalid existing candidates
        for (int i = ((int) existing_candidates.size())-1; i >= 0; i--) {
            // if face exists
            if (m->FaceExists(e.x, e.y, existing_candidates[i])) {
                existing_candidates.erase(existing_candidates.begin() + i);
                continue;
            }
            
            std::vector<int> new_overlap_ignore_vids = overlap_ignore_vids;
            new_overlap_ignore_vids.push_back(existing_candidates[i]);
            // if face overlaps
            vec_float3 v = m->GetVertex(existing_candidates[i]);
            if (face_overlaps(m, v1, v2, v, sep, new_overlap_ignore_vids)) {
                existing_candidates.erase(existing_candidates.begin() + i);
                continue;
            }
        }
        
        // make face
        int fid = -1;
        if (!existing_candidates.empty()) {
            int chosen = existing_candidates[0];
            
            // make face
            fid = m->MakeFace(e.x, e.y, chosen, vec_make_float4(1, 1, 1, 1));
            
            // add new edges to queue
            q.push(vec_make_int2(e.x, chosen));
            q.push(vec_make_int2(e.y, chosen));
        } else if (!new_candidates.empty()) {
            // if no near vertices, make a new one
            vec_float3 nv = new_candidates[0];
                        
            // make new vertex and face
            int nvid = m->MakeVertex(nv.x, nv.y, nv.z);
            fid = m->MakeFace(e.x, e.y, nvid, vec_make_float4(1, 1, 1, 1));
            
            // add new edges to queue
            q.push(vec_make_int2(e.x, nvid));
            q.push(vec_make_int2(e.y, nvid));
        } else {
            continue;
        }
        
        // find face normals
        if (fid > -1) {
            Face *f = m->GetFace(fid);
            vec_float3 fv1 = m->GetVertex(f->vertices[0]);
            vec_float3 fv2 = m->GetVertex(f->vertices[1]);
            vec_float3 fv3 = m->GetVertex(f->vertices[2]);
            vec_float3 face_norm = GetNormal(fv1, fv2, fv3); // default normal is unreversed
            
            if (in_model(TriAvg(fv1, fv2, fv3) + face_norm)) {
                f->normal_reversed = true;
            }
        }
    }
    
    std::cout<<"iterations left: "<<iterations_left<<std::endl;
    
    return m;
}
