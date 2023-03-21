//
//  JoinSlices.mm
//  dragonfly
//
//  Created by Thomas Liang on 3/19/23.
//

#include "JoinSlices.h"

void DragonflyUtils::BuildSliceOnModel(Model *m, ModelUniforms *mu, Slice *s, ModelUniforms *su, int lastslicestart) {
    int newslicestart = m->NumVertices();
    if (newslicestart == 0) {
        *mu = *su;
    }
    
    for (int i = 0; i < s->NumDots(); i++) {
        Dot *d = s->GetDot(i);
        Vertex v;
        v.x = d->x * s->GetAttributes().width / 2;
        v.y = d->y * s->GetAttributes().height / 2;
        v.z = 0;
        
        v = TranslatePointToStandard(&su->b, v);
        v = TranslatePointToBasis(&mu->b, v);
        m->MakeVertex(v.x, v.y, v.z);
    }
    
    if (newslicestart == 0) {
        return;
    }
    
    std::vector<int> mergewith;
    for (int i = 0; i < lastslicestart+s->NumDots(); i++) {
        mergewith.push_back(i);
    }
    
    for (int i = 0; i < s->NumLines(); i++) {
        Line *l = s->GetLine(i);
        int d1 = l->d1;
        int d2 = l->d2;
        
        m->MakeFace(newslicestart+d1, newslicestart+d2, lastslicestart+d1, simd_make_float4(0, 1, 1, 1));
        m->MakeFace(lastslicestart+d1, lastslicestart+d2, newslicestart+d2, simd_make_float4(0, 1, 1, 1));
    }
}

std::vector<int> DragonflyUtils::LinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu) {
    std::vector<int> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Dot *d1 = a->GetDot(a->GetLine(i)->d1);
        Vertex v1;
        v1.x = d1->x * a->GetAttributes().width / 2;
        v1.y = d1->y * a->GetAttributes().height / 2;
        v1.z = 0;
        v1 = TranslatePointToStandard(&au->b, v1);
        
        Dot *d2 = a->GetDot(a->GetLine(i)->d2);
        Vertex v2;
        v2.x = d2->x * a->GetAttributes().width / 2;
        v2.y = d2->y * a->GetAttributes().height / 2;
        v2.z = 0;
        v2 = TranslatePointToStandard(&au->b, v2);
        
        simd_float3 vec1 = simd_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        simd_float3 vec2 = simd_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
        float p1 = Projection(vec1, bu->b.z);
        float p2 = Projection(vec2, bu->b.z);
        
        if (p1 * p2 < 0) { // different signs
            ret.push_back(i);
        }
    }
    return ret;
}

std::vector<int> DragonflyUtils::LowerDotsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu) {
    std::vector<int> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Dot *d1 = a->GetDot(a->GetLine(i)->d1);
        Vertex v1;
        v1.x = d1->x * a->GetAttributes().width / 2;
        v1.y = d1->y * a->GetAttributes().height / 2;
        v1.z = 0;
        v1 = TranslatePointToStandard(&au->b, v1);
        
        Dot *d2 = a->GetDot(a->GetLine(i)->d2);
        Vertex v2;
        v2.x = d2->x * a->GetAttributes().width / 2;
        v2.y = d2->y * a->GetAttributes().height / 2;
        v2.z = 0;
        v2 = TranslatePointToStandard(&au->b, v2);
        
        simd_float3 vec1 = simd_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        simd_float3 vec2 = simd_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
        float p1 = Projection(vec1, bu->b.z);
        float p2 = Projection(vec2, bu->b.z);
        
        if (p1 < 0 && p2 > 0) { // different signs
            ret.push_back(a->GetLine(i)->d1);
        } else if (p2 < 0 && p1 > 0) { // different signs
            ret.push_back(a->GetLine(i)->d2);
        }
    }
    return ret;
}

std::vector<simd_float3> DragonflyUtils::CrossedPointsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu) {
    std::vector<simd_float3> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Dot *d1 = a->GetDot(a->GetLine(i)->d1);
        Vertex v1;
        v1.x = d1->x * a->GetAttributes().width / 2;
        v1.y = d1->y * a->GetAttributes().height / 2;
        v1.z = 0;
        v1 = TranslatePointToStandard(&au->b, v1);
        
        Dot *d2 = a->GetDot(a->GetLine(i)->d2);
        Vertex v2;
        v2.x = d2->x * a->GetAttributes().width / 2;
        v2.y = d2->y * a->GetAttributes().height / 2;
        v2.z = 0;
        v2 = TranslatePointToStandard(&au->b, v2);
        
        simd_float3 vec1 = simd_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        simd_float3 vec2 = simd_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
        float p1 = Projection(vec1, bu->b.z);
        float p2 = Projection(vec2, bu->b.z);
        
        if (p1 * p2 < 0) { // different signs
            simd_float3 vec = simd_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
            float planed = -(bu->b.z.x*bu->b.pos.x + bu->b.z.y*bu->b.pos.y + bu->b.z.z*bu->b.pos.z);
            float intersect = LineAndPlane(v1, vec, simd_make_float4(bu->b.z.x, bu->b.z.y, bu->b.z.z, planed));
            
            simd_float3 point = simd_make_float3(v1.x + intersect * vec.x, v1.y + intersect * vec.y, v1.z + intersect * vec.z);
            ret.push_back(point);
        }
    }
    return ret;
}

std::pair<int,int> DragonflyUtils::GetNextMergeDots(std::pair<int, int> curr, bool up, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu) {
    std::pair<int, int> ret;
    if (curr.first == -1) {
        // get first merge dots
        std::vector<int> dids = LowerDotsOnLinesAcross(b, bu, au);
        // get farthest away dots
        float maxdist = 0;
        for (int i = 0; i < dids.size(); i++) {
            Dot *d1 = b->GetDot(dids[i]);
            for (int j = i+1; j < dids.size(); j++) {
                Dot *d2 = b->GetDot(dids[j]);
                float currdist = sqrt(pow(d1->x - d2->x, 2) + pow(d1->y - d2->y, 2));
                
                if (currdist > maxdist) {
                    maxdist = currdist;
                    ret.first = dids[i];
                    ret.second = dids[j];
                }
            }
        }
    } else {
        ret = std::make_pair(-2, -2);
        for (int i = 0; i < b->NumLines(); i++) {
            Line *l = b->GetLine(i);
            
            int other = -1;
            if (l->d1 == curr.first) {
                other = l->d2;
            } else if (l->d2 == curr.first) {
                other = l->d1;
            }
            
            if (other != -1) {
                Dot *d1 = b->GetDot(curr.first);
                Vertex v1;
                v1.x = d1->x * b->GetAttributes().width / 2;
                v1.y = d1->y * b->GetAttributes().height / 2;
                v1.z = 0;
                v1 = TranslatePointToStandard(&bu->b, v1);
                Dot *d2 = b->GetDot(other);
                Vertex v2;
                v2.x = d2->x * b->GetAttributes().width / 2;
                v2.y = d2->y * b->GetAttributes().height / 2;
                v2.z = 0;
                v2 = TranslatePointToStandard(&bu->b, v2);
                
                simd_float3 vec = simd_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
                float proj = Projection(vec, au->b.z);
                
                if ((proj > 0 && up) || (proj < 0 && !up)) {
                    ret.first = other;
                    break;
                }
            }
        }
        
        
        for (int i = 0; i < b->NumLines(); i++) {
            Line *l = b->GetLine(i);
            
            int other = -1;
            if (l->d1 == curr.second) {
                other = l->d2;
            } else if (l->d2 == curr.second) {
                other = l->d1;
            }
            
            if (other != -1) {
                Dot *d1 = b->GetDot(curr.second);
                Vertex v1;
                v1.x = d1->x * b->GetAttributes().width / 2;
                v1.y = d1->y * b->GetAttributes().height / 2;
                v1.z = 0;
                v1 = TranslatePointToStandard(&bu->b, v1);
                Dot *d2 = b->GetDot(other);
                Vertex v2;
                v2.x = d2->x * b->GetAttributes().width / 2;
                v2.y = d2->y * b->GetAttributes().height / 2;
                v2.z = 0;
                v2 = TranslatePointToStandard(&bu->b, v2);
                
                simd_float3 vec = simd_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
                float proj = Projection(vec, au->b.z);
                
                if ((proj > 0 && up) || (proj < 0 && !up)) {
                    ret.second = other;
                    break;
                }
            }
        }
        
        if (ret.first == curr.second) {
            ret.first = -2;
        }
        if (ret.second == curr.first) {
            ret.second = -2;
        }
    }
    
    return ret;
}

void DragonflyUtils::MoveToMerge(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, std::pair<int, int> bdots) {
    Dot *d1 = b->GetDot(bdots.first);
    Vertex v1;
    v1.x = d1->x * b->GetAttributes().width / 2;
    v1.y = d1->y * b->GetAttributes().height / 2;
    v1.z = 0;
    v1 = TranslatePointToStandard(&bu->b, v1);
    
    Dot *d2 = b->GetDot(bdots.second);
    Vertex v2;
    v2.x = d2->x * b->GetAttributes().width / 2;
    v2.y = d2->y * b->GetAttributes().height / 2;
    v2.z = 0;
    v2 = TranslatePointToStandard(&bu->b, v2);
    
    simd_float3 atov1 = dist3to3(v1, au->b.pos);
    simd_float3 atov2 = dist3to3(v2, au->b.pos);
    
    std::vector<simd_float3> acrosses = CrossedPointsOnLinesAcross(a, au, bu);
    if (acrosses.size() < 2) {
        return;
    }
    simd_float3 cross1;
    simd_float3 cross2;
    float maxcrossdist = 0;
    for (int i = 0; i < acrosses.size(); i++) {
        for (int j = i+1; j < acrosses.size(); j++) {
            float dist = dist3to3(acrosses[i], acrosses[j]);
            if (dist > maxcrossdist) {
                maxcrossdist = dist;
                cross1 = acrosses[i];
                cross2 = acrosses[j];
            }
        }
    }
    
    simd_float3 vmidpoint = BiAvg(v1, v2);
    simd_float3 crossmidpoint = BiAvg(cross1, cross2);
    simd_float3 ashift = simd_make_float3(vmidpoint.x - crossmidpoint.x, vmidpoint.y - crossmidpoint.y, vmidpoint.z - crossmidpoint.z);
    simd_float3 vvec = simd_make_float3(v1.x - vmidpoint.x, v1.y - vmidpoint.y, v1.z - vmidpoint.z);
    simd_float3 cvec = simd_make_float3(cross1.x - crossmidpoint.x, cross1.y - crossmidpoint.y, cross1.z - crossmidpoint.z);
    float vradius = Projection(vvec, cvec);
    float crossradius = Magnitude(cvec);
    float ascale = vradius / crossradius;
    
    au->b.pos = AddVectors(au->b.pos, ashift);
    SliceAttributes aa = a->GetAttributes();
    a->SetWidth(aa.width * ascale);
    a->SetHeight(aa.height * ascale);
}

void DragonflyUtils::JoinSlices(Model *m, ModelUniforms *mu, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu, float merge_threshold) {
    ModelUniforms initau = *au;
    SliceAttributes initaa = a->GetAttributes();
    
    std::pair<int, int> initdots = GetNextMergeDots(std::make_pair(-1, -1), true, a, b, au, bu);
    MoveToMerge(a, au, b, bu, initdots);
    BuildSliceOnModel(m, mu, a, au, 0);
    
    std::pair<int, int> nextdots = GetNextMergeDots(initdots, true, a, b, au, bu);
    while (nextdots.first != -2 && nextdots.second != -2) {
        MoveToMerge(a, au, b, bu, nextdots);
        BuildSliceOnModel(m, mu, a, au, m->NumVertices() - a->NumDots());
        nextdots = GetNextMergeDots(nextdots, true, a, b, au, bu);
    }
    
    *au = initau;
    a->SetWidth(initaa.width);
    a->SetHeight(initaa.height);
    
    nextdots = GetNextMergeDots(initdots, false, a, b, au, bu);
    if (nextdots.first != -2 && nextdots.second != -2) {
        MoveToMerge(a, au, b, bu, nextdots);
        BuildSliceOnModel(m, mu, a, au, 0);
        
        while (nextdots.first != -2 && nextdots.second != -2) {
            MoveToMerge(a, au, b, bu, nextdots);
            BuildSliceOnModel(m, mu, a, au, m->NumVertices() - a->NumDots());
            nextdots = GetNextMergeDots(nextdots, false, a, b, au, bu);
        }
    }

    *au = initau;
    a->SetWidth(initaa.width);
    a->SetHeight(initaa.height);
}
