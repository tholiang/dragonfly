//
//  JoinModels.cpp
//  dragonfly
//
//  Created by Thomas Liang on 1/9/23.
//

#include "JoinModels.h"

bool DragonflyUtils::bpm(std::vector<std::vector<float>> &graph, int i, std::vector<bool> &seen, std::vector<int> &matches) {
    
    for (int j = 0; j < graph.size(); j++) {
        if (graph[i][j] == 0 && !seen[j]) {
            seen[j] = true;
            
            if (matches[j] < 0 || bpm(graph, matches[j], seen, matches)) {
                matches[j] = i;
                return true;
            }
        }
    }
    
    return false;
}

int DragonflyUtils::match(std::vector<std::vector<float>> &graph, std::vector<int> &matches) {
    for (int i = 0; i < matches.size(); i++) {
        matches[i] = -1;
    }
    
    int res = 0;
    for (int i = 0; i < matches.size(); i++) {
        std::vector<bool> seen;
        for (int j = 0; j < matches.size(); j++) {
            seen.push_back(false);
        }
        
        if (bpm(graph, i, seen, matches)) {
            res++;
        }
    }
    
    return res;
}

void DragonflyUtils::alternate(int i, std::vector<std::vector<float>> &graph, std::vector<bool> &visitedi, std::vector<bool> &visitedj, std::vector<int> &matches) {
    visitedi[i] = true;
    for (int j = 0; j < graph.size(); j++) {
        if (graph[i][j] == 0 && !visitedj[j]) {
            visitedj[j] = true;
            if (matches[j] != -1) {
                alternate(matches[j], graph, visitedi, visitedj, matches);
            }
        }
    }
}

void DragonflyUtils::koenig(std::vector<std::vector<float>> &graph, std::vector<int> &matches, std::vector<int> &icover, std::vector<int> &jcover) {
    std::vector<int> imatches(graph.size());
    std::vector<bool> visitedi(graph.size());
    std::vector<bool> visitedj(graph.size());
    for (int i = 0; i < imatches.size(); i++) {
        imatches[i] = -1;
        visitedi[i] = false;
        visitedj[i] = false;
    }
    
    for (int j = 0; j < matches.size(); j++) {
        if (matches[j] != -1) {
            imatches[matches[j]] = j;
        }
    }
    
    for (int i = 0; i < graph.size(); i++) {
        if (matches[i] != -1) {
            alternate(i, graph, visitedi, visitedj, matches);
        }
    }
    
    for (int i = 0; i < visitedi.size(); i++) {
        if (!visitedi[i]) {
            icover.push_back(i);
        }
    }
    
    for (int j = 0; j < visitedj.size(); j++) {
        if (visitedj[j]) {
            jcover.push_back(j);
        }
    }
}

std::vector<int> DragonflyUtils::Hungarian(std::vector<simd_float3> &A, std::vector<simd_float3> &B) {
    std::vector<int> assignments(A.size());
    
    std::vector<std::vector<float>> cost;
    for (int i = 0; i < A.size(); i++) {
        std::vector<float> row;
        for (int j = 0; j < B.size(); j++) {
            row.push_back(dist3to3(A[i], B[j]));
        }
        cost.push_back(row);
    }
    
    
    // step 0A
    for (int i = 0; i < A.size(); i++) {
        float min = cost[i][0];
        for (int j = 1; j < B.size(); j++) {
            if (cost[i][j] < min) {
                min = cost[i][j];
            }
        }
        
        for (int j = 0; j < B.size(); j++) {
            cost[i][j] -= min;
            
            if (cost[i][j] > -0.00001 && cost[i][j] < 0.00001) {
                cost[i][j] = 0;
            }
        }
    }
    
    // step 0B
    for (int j = 0; j < B.size(); j++) {
        float min = cost[0][j];
        for (int i = 1; i < A.size(); i++) {
            if (cost[i][j] < min) {
                min = cost[i][j];
            }
        }
        
        for (int i = 0; i < A.size(); i++) {
            cost[i][j] -= min;
            
            if (cost[i][j] > -0.00001 && cost[i][j] < 0.00001) {
                cost[i][j] = 0;
            }
        }
    }
    
    while (true) {
        // step 1A
        std::vector<int> matches(A.size());
        if (match(cost, matches) == A.size()) {
            for (int i = 0; i < matches.size(); i++) {
                assignments[i] = matches[i];
            }
            break;
        }
        
        // step 1B
        std::vector<int> icover;
        std::vector<int> jcover;
        koenig(cost, matches, icover, jcover);
        
        // step 2
        float mincost = -1;
        for (int i = 0; i < A.size(); i++) {
            if (!InIntVector(icover, i)) {
                for (int j = 0; j < B.size(); j++) {
                    if (!InIntVector(jcover, j)) {
                        if (mincost == -1 || cost[i][j] < mincost) {
                            mincost = cost[i][j];
                        }
                    }
                }
            }
        }
        
        for (int i = 0; i < A.size(); i++) {
            bool iin = InIntVector(icover, i);
            for (int j = 0; j < B.size(); j++) {
                bool jin = InIntVector(jcover, j);
                
                if (!iin && !jin) {
                    cost[i][j] -= mincost;
                } else if (iin && jin) {
                    cost[i][j] += mincost;
                }
            }
        }
    }
    
    return assignments;
}

void DragonflyUtils::JoinModels(Model *A, Model *B, ModelTransform *muA, ModelTransform *muB, std::vector<int> &A_pts, std::vector<int> &B_pts) {
    std::vector<simd_float3> A_vals;
    std::vector<simd_float3> B_vals;
    
    for (int i = 0; i < A_pts.size(); i++) {
        A_vals.push_back(A->GetVertex(A_pts[i]));
    }
    
    for (int j = 0; j < B_pts.size(); j++) {
        B_vals.push_back(B->GetVertex(B_pts[j]));
    }
    
    int prevAvertices = A->NumVertices();
    
    simd_float3 modeldiff = simd_make_float3(muB->b.pos.x - muA->b.pos.x, muB->b.pos.y - muA->b.pos.y, muB->b.pos.z - muA->b.pos.z);
    
    std::vector<int> assignments = Hungarian(A_vals, B_vals);
    for (int j = 0; j < B->NumVertices(); j++) {
        if (!InIntVector(B_pts, j)) {
            Vertex v = B->GetVertex(j);
            A->MakeVertex(v.x + modeldiff.x, v.y + modeldiff.y, v.z + modeldiff.z);
        }
    }
    
    for (int j = 0; j < B->NumFaces(); j++) {
        Face *f = B->GetFace(j);
        
        int newvids[3];
        
        for (int k = 0; k < 3; k++) {
            int vid = f->vertices[k];
            
            int numunder = 0;
            for (int l = 0; l < B_pts.size(); l++) {
                if (B_pts[l] < vid) {
                    numunder++;
                } else if (B_pts[l] == vid) {
                    numunder = -l - 1; // avoid -0
                    break;
                }
            }
            
            if (numunder < 0) {
                newvids[k] = A_pts[assignments[-(numunder + 1)]];
            } else {
                newvids[k] = prevAvertices + vid - numunder;
            }
        }
        
        A->MakeFaceWithLighting(newvids[0], newvids[1], newvids[2], f->color, f->normal_reversed, f->lighting_offset, f->shading_multiplier);
    }
}


std::vector<int> DragonflyUtils::GetNeighborsIn(Model *m, std::vector<int> vertices, int curr) {
    std::vector<int> ret;
    
    for (int i = 0; i < m->NumFaces(); i++) {
        Face *f = m->GetFace(i);
        int curridx = -1;
        for (int j = 0; j < 3; j++) {
            if (f->vertices[j] == curr) {
                curridx = j;
                break;
            }
        }
        
        if (curridx >= 0) {
            for (int k = 0; k < vertices.size(); k++) {
                if (vertices[k] != curr) {
                    for (int j = 0; j < 3; j++) {
                        if (f->vertices[j] == vertices[k]) {
                            ret.push_back(vertices[k]);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    return ret;
}

void DragonflyUtils::CapModel(Model *m, std::vector<int> vertices) {
    Vertex avg = simd_make_float3(0, 0, 0);
    for (int i = 0; i < vertices.size(); i++) {
        Vertex v = m->GetVertex(vertices[i]);
        avg.x += v.x;
        avg.y += v.y;
        avg.z += v.z;
    }
    
    avg.x /= vertices.size();
    avg.y /= vertices.size();
    avg.z /= vertices.size();
    int newid = m->MakeVertex(avg.x, avg.y, avg.z);
    
    std::vector<std::pair<int,int>> alreadylinked;
    for (int i = 0; i < vertices.size(); i++) {
        int vid = vertices[i];
        
        std::vector<int> neighbors = GetNeighborsIn(m, vertices, vid);
        for (int j = 0; j < neighbors.size(); j++) {
            int neighbor = neighbors[j];
            
            bool prevlinked = false;
            for (int k = 0; k < alreadylinked.size(); k++) {
                if (alreadylinked[k].first == vid && alreadylinked[k].second == neighbor) {
                    prevlinked = true;
                    break;
                }
                if (alreadylinked[k].first == neighbor && alreadylinked[k].second == vid) {
                    prevlinked = true;
                    break;
                }
            }
            
            if (!prevlinked) {
                m->MakeFace(vid, neighbor, newid, simd_make_float4(1, 1, 1, 1));
                alreadylinked.push_back(std::make_pair(vid, neighbor));
            }
        }
    }
}


std::vector<int> DragonflyUtils::GetNeighbors(Model *m, std::vector<int> &vertices, int cur) {
    std::vector<int> neighbors;
    for (int i = 0; i < vertices.size(); i++) {
        if (vertices[i] == cur) {
            continue;
        }
        
        std::vector<unsigned long> shared_faces = m->GetEdgeFaces(cur, vertices[i]);
        if (shared_faces.size() > 0) {
            neighbors.push_back(vertices[i]);
        }
    }
    
    return neighbors;
}

std::vector<int> DragonflyUtils::GetNeighborsIdx(Model *m, std::vector<int> &vertices, int cur) {
    std::vector<int> neighbors;
    for (int i = 0; i < vertices.size(); i++) {
        if (vertices[i] == vertices[cur]) {
            continue;
        }
        
        std::vector<unsigned long> shared_faces = m->GetEdgeFaces(vertices[cur], vertices[i]);
        if (shared_faces.size() > 0) {
            neighbors.push_back(i);
        }
    }
    
    return neighbors;
}

int DragonflyUtils::GetNextVertex(Model *m, std::vector<int> &vertices, int cur, int last) {
    std::vector<int> neighbors = GetNeighbors(m, vertices, cur);
    for (int i = 0; i < neighbors.size(); i++) {
        if (neighbors[i] == last) {
            continue;
        }
        
        return neighbors[i];
    }
    
    return -1;
}

int DragonflyUtils::GetNextVertexIdx(Model *m, std::vector<int> &vertices, int cur, int last) {
    std::vector<int> neighborsidx = GetNeighborsIdx(m, vertices, cur);
    for (int i = 0; i < neighborsidx.size(); i++) {
        if (vertices[neighborsidx[i]] == vertices[last]) {
            continue;
        }
        
        return neighborsidx[i];
    }
    
    return -1;
}

float DragonflyUtils::VertexDist(Model *a, ModelTransform *au, Model *b, ModelTransform *bu, int avid, int bvid) {
    Vertex av = TranslatePointToStandard(&au->b, a->GetVertex(avid));
    Vertex bv = TranslatePointToStandard(&bu->b, b->GetVertex(bvid));
    return dist3to3(av, bv);
}

std::pair<std::vector<int>, float> DragonflyUtils::MatchModelsFrom(Model *a, ModelTransform *au, std::vector<int> &avertices, Model *b, ModelTransform *bu, std::vector<int> &bvertices, int a1, int a2, int b1, int b2) {
    std::vector<int> matching;
    for (int i = 0; i < avertices.size(); i++) {
        matching.push_back(-1);
    }
    
    matching[a1] = b1;
    matching[a2] = b2;
    int numdots = 2;
    
    int alast = a1;
    int blast = b1;
    int acur = GetNextVertexIdx(a, avertices, a1, a2);
    int bcur = GetNextVertexIdx(b, bvertices, b1, b2);
    while (acur != a1 && acur != -1 && bcur != -1) {
        matching[acur] = bcur;
        numdots++;
        
        int anext = GetNextVertexIdx(a, avertices, acur, alast);
        int bnext = GetNextVertexIdx(b, bvertices, bcur, blast);
        
        alast = acur;
        blast = bcur;
        
        acur = anext;
        bcur = bnext;
    }
    
    float score = 0;
    
    for (int i = 0; i < matching.size(); i++) {
        if (matching[i] != -1) {
            score += VertexDist(a, au, b, bu, avertices[i], bvertices[matching[i]]);
        }
    }
    
    score /= numdots;
    if (numdots < avertices.size()) {
        score = 1000000000;
    }
    
    return std::make_pair(matching, score);
}

std::vector<int> DragonflyUtils::MatchEqualModels(Model *a, ModelTransform *au, std::vector<int> &avertices, Model *b, ModelTransform *bu, std::vector<int> &bvertices) {
    std::vector<int> bestmatching;
    float bestmatchingscore = -1;
    
    for (int i = 0; i < avertices.size(); i++) {
        for (int j = 0; j < bvertices.size(); j++) {
            std::vector<int> aneighbors = GetNeighborsIdx(a, avertices, i);
            std::vector<int> bneighbors = GetNeighborsIdx(b, bvertices, j);
            
            for (int k = 0; k < aneighbors.size(); k++) {
                for (int l = 0; l < aneighbors.size(); l++) {
                    std::pair<std::vector<int>, float> ab = MatchModelsFrom(a, au, avertices, b, bu, bvertices, i, aneighbors[k], j, bneighbors[l]);
                    if (ab.second < bestmatchingscore || bestmatchingscore == -1) {
                        bestmatching = ab.first;
                        bestmatchingscore = ab.second;
                    }
                }
            }
        }
    }
    
    return bestmatching;
}

void DragonflyUtils::AddModels(Model *a, ModelTransform *au, Model *b, ModelTransform *bu) {
    int bnodestart = a->NumNodes();
    for (int i = 0; i < b->NumNodes(); i++) {
        Node *n = b->GetNode(i);
        Vertex v = n->b.pos;
        v = TranslatePointToStandard(&bu->b, v);
        v = TranslatePointToBasis(&au->b, v);
        
        int nid = a->MakeNode(v.x, v.y, v.z);
        Node *newn = a->GetNode(nid);
        newn->b = n->b;
        newn->b.pos = v;
        newn->locked_to = n->locked_to;
    }
    
    int bvertexstart = a->NumVertices();
    for (int i = 0; i < b->NumVertices(); i++) {
        Vertex v = b->GetVertex(i);
        v = TranslatePointToStandard(&bu->b, v);
        v = TranslatePointToBasis(&au->b, v);
        a->MakeVertex(v.x, v.y, v.z);
        
        std::vector<unsigned long> nids = b->GetLinkedNodes(i);
        a->LinkNodeAndVertex(i+bvertexstart, nids[0]+bnodestart);
        a->UnlinkNodeAndVertex(i+bvertexstart, 0);
        if (nids.size() > 1) {
            a->LinkNodeAndVertex(i+bvertexstart, nids[1]+bnodestart);
        }
    }
    
    for (int i = 0; i < b->NumFaces(); i++) {
        Face *f = b->GetFace(i);
        
        a->MakeFace(f->vertices[0]+bvertexstart, f->vertices[1]+bvertexstart, f->vertices[2]+bvertexstart, f->color);
    }
}

void DragonflyUtils::BridgeEqualModels(Model *a, ModelTransform *au, std::vector<int> &avertices, Model *b, ModelTransform *bu, std::vector<int> &bvertices) {
    // if any face contains 3 vertices in arrays: error
    if (a->HasFaceWith(avertices) || b->HasFaceWith(bvertices)) {
        std::cout<<"cant have face between vertices"<<std::endl;
        return;
    }
    
    std::vector<int> matching = MatchEqualModels(a, au, avertices, b, bu, bvertices);
    
    for (int i = 0; i < matching.size(); i++) {
        if (matching[i] == -1) {
            std::cout<<"no possible matching"<<std::endl;
            return;
        }
    }
    
    int bvertexstart = a->NumVertices();
    AddModels(a, au, b, bu);
    
    int a1 = 0;
    std::vector<int> neighbors = GetNeighborsIdx(a, avertices, a1);
    if (neighbors.size() == 0) {
        std::cout<<"error occurred"<<std::endl;
        return;
    }
    int a2 = neighbors[0];
    
    while (true) {
        int b1 = matching[a1];
        int b2 = matching[a2];
        
        int avid1 = avertices[a1];
        int avid2 = avertices[a2];
        int bvid1 = bvertices[b1];
        int bvid2 = bvertices[b2];
        
        a->MakeFace(avid1, avid2, bvid1+bvertexstart, simd_make_float4(1, 1, 1, 1));
        a->MakeFace(avid2, bvid1+bvertexstart, bvid2+bvertexstart, simd_make_float4(1, 1, 1, 1));
        
        int temp = a2;
        a2 = GetNextVertexIdx(a, avertices, a2, a1);
        a1 = temp;
        
        if (a1 == 0) {
            break;
        }
    }
}
