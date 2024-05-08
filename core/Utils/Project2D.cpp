//
//  Project2D.cpp
//  dragonfly
//
//  Created by Thomas Liang on 12/18/22.
//

#include "Project2D.h"

DragonflyUtils::PointData *DragonflyUtils::PointDataFromFile(std::string path) {
    std::string line;
    std::ifstream myfile (path);
    if (myfile.is_open()) {
        PointData *pd = new PointData();
        
        getline(myfile, line);
        int num_points;
        sscanf(line.c_str(), "%d", &num_points);
        for (int i = 0; i < num_points; i++) {
            getline(myfile, line);
            float x, y;
            sscanf(line.c_str(), "(%f, %f)", &x, &y);
            pd->points.push_back(vector_make_float2(x, y));
            pd->edges.push_back(std::vector<int>());
        }
        
        getline(myfile, line);
        int num_edges;
        sscanf(line.c_str(), "%d", &num_edges);
        for (int i = 0; i < num_edges; i++) {
            getline(myfile, line);
            int p1, p2;
            sscanf(line.c_str(), "(%d, %d)", &p1, &p2);
            pd->edges[p1].push_back(p2);
            pd->edges[p2].push_back(p1);
        }
        
        return pd;
    }
    
    std::cout<<"invalid path"<<std::endl;
    
    return NULL;
}

std::vector<vector_int3> DragonflyUtils::FindPointDataTriangles(PointData* pd) {
    std::vector<vector_int3> triangles;
    
    // for each point, find 3 length cycles to itself (a triangle)
    for (int i = 0; i < pd->points.size(); i++) {
        int p1 = i;
        for (int j = 0; j < pd->edges[p1].size(); j++) {
            int p2 = pd->edges[p1][j];
            for (int k = 0; k < pd->edges[p2].size(); k++) {
                int p3 = pd->edges[p2][k];
                for (int l = 0; l < pd->edges[p3].size(); l++) {
                    int p4 = pd->edges[p3][l];
                    if (p4 == p1 && p2 > p1 && p3 > p2) { // last two checks to avoid repeats
                        // make sure no other points are inside the triangle
                        bool valid = true;
                        for (int m = 0; m < pd->points.size(); m++) {
                            if (m != p1 && m != p2 && m != p3) {
                                if (InTriangle2D(pd->points[m], pd->points[p1], pd->points[p2], pd->points[p3])) {
                                    valid = false;
                                    break;
                                }
                            }
                        }
                        
                        if (valid) {
                            triangles.push_back(vector_make_int3(p1, p2, p3));
                        }
                    }
                }
            }
        }
    }
    
    return triangles;
}

Model * DragonflyUtils::ModelFromPointData(PointData *pd) {
    std::vector<vector_int3> triangles = FindPointDataTriangles(pd);
    
    Model *m = new Model();
    for (int i = 0; i < pd->points.size(); i++) {
        vector_float2 p = pd->points[i];
        m->MakeVertex(p.x, 0, p.y);
    }
    
    for (int i = 0; i < triangles.size(); i++) {
        vector_int3 triangle = triangles[i];
        m->MakeFace(triangle.x, triangle.y, triangle.z, {1, 1, 1, 1});
    }
    
    return m;
}
