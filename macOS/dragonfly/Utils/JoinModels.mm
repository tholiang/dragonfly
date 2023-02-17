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

void DragonflyUtils::JoinModels(Model *A, Model *B, ModelUniforms *muA, ModelUniforms *muB, std::vector<int> &A_pts, std::vector<int> &B_pts) {
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
