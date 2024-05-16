//
//  JoinSlices.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/19/23.
//

#include "JoinSlices.h"


Vertex DragonflyUtils::GetStandardVertexFromDot(Slice *s, ModelTransform *mu, int i) {
    Dot *d = s->GetDot(i);
    Vertex v;
    v.x = d->x;// * s->GetAttributes().width / 2;
    v.y = d->y;// * s->GetAttributes().height / 2;
    v.z = 0;
    v = TranslatePointToStandard(&mu->b, v);
    
    return v;
}

void DragonflyUtils::BuildSliceOnModel(Model *m, ModelTransform *mu, Slice *s, ModelTransform *su, int lastslicestart) {
    int newslicestart = m->NumVertices();
    if (newslicestart == 0) {
        *mu = *su;
    }
    
    for (int i = 0; i < s->NumDots(); i++) {
        Vertex v = GetStandardVertexFromDot(s, su, i);
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
        
        m->MakeFace(newslicestart+d1, newslicestart+d2, lastslicestart+d1, vec_make_float4(1, 1, 1, 1));
        m->MakeFace(lastslicestart+d1, lastslicestart+d2, newslicestart+d2, vec_make_float4(1, 1, 1, 1));
    }
}

std::vector<int> DragonflyUtils::LinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu) {
    std::vector<int> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Vertex v1 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d1);
        Vertex v2 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d2);
        
        vec_float3 vec1 = vec_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        vec_float3 vec2 = vec_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
        float p1 = Projection(vec1, bu->b.z);
        float p2 = Projection(vec2, bu->b.z);
        
        if (p1 * p2 < 0) { // different signs
            ret.push_back(i);
        }
    }
    return ret;
}

std::vector<int> DragonflyUtils::LowerDotsOnLinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu) {
    std::vector<int> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Vertex v1 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d1);
        Vertex v2 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d2);
        
        vec_float3 vec1 = vec_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        vec_float3 vec2 = vec_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
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

std::vector<vec_float3> DragonflyUtils::CrossedPointsOnLinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu) {
    std::vector<vec_float3> ret;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Vertex v1 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d1);
        Vertex v2 = GetStandardVertexFromDot(a, au, a->GetLine(i)->d2);
        
        vec_float3 vec1 = vec_make_float3(v1.x - bu->b.pos.x, v1.y - bu->b.pos.y, v1.z - bu->b.pos.z);
        vec_float3 vec2 = vec_make_float3(v2.x - bu->b.pos.x, v2.y - bu->b.pos.y, v2.z - bu->b.pos.z);
        
        float p1 = Projection(vec1, bu->b.z);
        float p2 = Projection(vec2, bu->b.z);
        
        if (p1 * p2 < 0) { // different signs
            vec_float3 vec = vec_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
            float planed = -(bu->b.z.x*bu->b.pos.x + bu->b.z.y*bu->b.pos.y + bu->b.z.z*bu->b.pos.z);
            float intersect = LineAndPlane(v1, vec, vec_make_float4(bu->b.z.x, bu->b.z.y, bu->b.z.z, planed));
            
            vec_float3 point = vec_make_float3(v1.x + intersect * vec.x, v1.y + intersect * vec.y, v1.z + intersect * vec.z);
            ret.push_back(point);
        }
    }
    return ret;
}

std::pair<int,int> DragonflyUtils::GetNextMergeDots(std::pair<int, int> curr, bool up, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu) {
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
                Vertex v1 = GetStandardVertexFromDot(b, bu, curr.first);
                Vertex v2 = GetStandardVertexFromDot(b, bu, other);
                
                vec_float3 vec = vec_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
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
                Vertex v1 = GetStandardVertexFromDot(b, bu, curr.second);
                Vertex v2 = GetStandardVertexFromDot(b, bu, other);
                
                vec_float3 vec = vec_make_float3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
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

void DragonflyUtils::MoveToMerge(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, std::pair<int, int> bdots) {
    Vertex v1 = GetStandardVertexFromDot(b, bu, bdots.first);
    Vertex v2 = GetStandardVertexFromDot(b, bu, bdots.second);
    
    // float atov1 = dist3to3(v1, au->b.pos);
    // float atov2 = dist3to3(v2, au->b.pos);
    
    // for the edges on a that cross through b, find points on those edges that are closest to b
    std::vector<vec_float3> acrosses = CrossedPointsOnLinesAcross(a, au, bu);
    if (acrosses.size() < 2) {
        return;
    }
    vec_float3 cross1;
    vec_float3 cross2;
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
    
    vec_float3 vmidpoint = BiAvg(v1, v2);
    vec_float3 crossmidpoint = BiAvg(cross1, cross2);
    vec_float3 ashift = vec_make_float3(vmidpoint.x - crossmidpoint.x, vmidpoint.y - crossmidpoint.y, vmidpoint.z - crossmidpoint.z);
    vec_float3 vvec = vec_make_float3(v1.x - vmidpoint.x, v1.y - vmidpoint.y, v1.z - vmidpoint.z);
    vec_float3 cvec = vec_make_float3(cross1.x - crossmidpoint.x, cross1.y - crossmidpoint.y, cross1.z - crossmidpoint.z);
    float vradius = Projection(vvec, cvec);
    float crossradius = Magnitude(cvec);
    float ascale = vradius / crossradius;
    
    // set scale (no rotate)
    SliceAttributes aa = a->GetAttributes();
    a->SetWidth(aa.width * ascale);
    a->SetHeight(aa.height * ascale);
    
    au->b.pos = AddVectors(au->b.pos, ashift);
    
    // get angle
    vec_float3 avec = vec_make_float3(cross2.x-cross1.x, cross2.y-cross1.y, cross2.z-cross1.z);
    vec_float3 bvec = vec_make_float3(v2.x-v1.x, v2.y-v1.y, v2.z-v1.z);
    float angle = AngleBetween(avec, bvec);
    angle = abs(GetAcute(angle));
    ascale /= cos(angle);
    
    float anglex = AngleBetween(au->b.x, avec);
    float angley = AngleBetween(au->b.y, avec);
    anglex = GetAcute(anglex);
    angley = GetAcute(angley);
    if (abs(anglex) < abs(angley)) {
        // check if rotating positive or negative is better
        RotateBasisOnY(&au->b, angle); // positive
        vec_float3 posx = au->b.x;
        RotateBasisOnY(&au->b, -2*angle); //negative
        vec_float3 negx = au->b.x;
        RotateBasisOnY(&au->b, angle); // back to previous
        
        if (abs(AngleBetween(posx, bvec)) < abs(AngleBetween(negx, bvec))) {
            if (angley >= 0) {
                RotateBasisOnY(&au->b, angle);
            } else {
                RotateBasisOnY(&au->b, -angle);
            }
        } else {
            if (angley >= 0) {
                RotateBasisOnY(&au->b, -angle);
            } else {
                RotateBasisOnY(&au->b, angle);
            }
        }
        
        // expand width after rotate
        a->SetWidth(aa.width * ascale);
    } else {
        if (anglex < 0) {
            angle *= -1;
        }
        // check if rotating positive or negative is better
        RotateBasisOnX(&au->b, angle); // positive
        vec_float3 posy = au->b.y;
        RotateBasisOnX(&au->b, -2*angle); //negative
        vec_float3 negy = au->b.y;
        RotateBasisOnX(&au->b, angle); // back to previous
        
        if (abs(AngleBetween(posy, bvec)) < abs(AngleBetween(negy, bvec))) {
            RotateBasisOnX(&au->b, angle);
        } else {
            RotateBasisOnX(&au->b, -angle);
        }
        
        a->SetHeight(aa.height * ascale);
    }
}

void DragonflyUtils::JoinSlices(Model *m, ModelTransform *mu, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu, float merge_threshold) {
    ModelTransform initau = *au;
    SliceAttributes initaa = a->GetAttributes();
    
    // get first dots closest to slice a (going down)
    std::pair<int, int> initdots = GetNextMergeDots(std::make_pair(-1, -1), true, a, b, au, bu);
    MoveToMerge(a, au, b, bu, initdots);
    BuildSliceOnModel(m, mu, a, au, 0); // build first vertices on new model
    
    // build up
    std::pair<int, int> lastdots = initdots;
    std::pair<int, int> nextdots = GetNextMergeDots(initdots, true, a, b, au, bu);
    std::pair<int, int> firstup = nextdots;
    while (nextdots.first != -2 && nextdots.second != -2 && nextdots.first != nextdots.second && nextdots.first != lastdots.second && nextdots.second != lastdots.first) {
        // reset slice uniforms
        *au = initau;
        a->SetWidth(initaa.width);
        a->SetHeight(initaa.height);
        
        MoveToMerge(a, au, b, bu, nextdots);
        BuildSliceOnModel(m, mu, a, au, m->NumVertices() - a->NumDots());
        //nextdots = GetNextMergeDots(nextdots, true, a, b, au, bu);
        std::pair<int, int> temp = nextdots;
        nextdots.first = GetNextDot(b, nextdots.first, lastdots.first);
        nextdots.second = GetNextDot(b, nextdots.second, lastdots.second);
        lastdots = temp;
    }
    
    *au = initau;
    a->SetWidth(initaa.width);
    a->SetHeight(initaa.height);
    
    // build down
    /*lastdots = initdots;
    nextdots = GetNextMergeDots(initdots, false, a, b, au, bu);
    if (nextdots.first != -2 && nextdots.second != -2) {
        MoveToMerge(a, au, b, bu, nextdots);
        BuildSliceOnModel(m, mu, a, au, 0);
        
        while (nextdots.first != -2 && nextdots.second != -2) {
            MoveToMerge(a, au, b, bu, nextdots);
            BuildSliceOnModel(m, mu, a, au, m->NumVertices() - a->NumDots());
            nextdots = GetNextMergeDots(nextdots, false, a, b, au, bu);
        }
    }*/
    		
    nextdots.first = GetNextDot(b, initdots.first, firstup.first);
    nextdots.second = GetNextDot(b, initdots.second, firstup.second);
    lastdots = initdots;
    if (nextdots.first != -2 && nextdots.second != -2 && nextdots.first != nextdots.second && nextdots.first != lastdots.second && nextdots.second != lastdots.first) {
        MoveToMerge(a, au, b, bu, nextdots);
        BuildSliceOnModel(m, mu, a, au, 0);
        std::pair<int, int> temp = nextdots;
        nextdots.first = GetNextDot(b, nextdots.first, lastdots.first);
        nextdots.second = GetNextDot(b, nextdots.second, lastdots.second);
        lastdots = temp;
        
        while (nextdots.first != -2 && nextdots.second != -2 && nextdots.first != nextdots.second && nextdots.first != lastdots.second && nextdots.second != lastdots.first) {
            // reset slice uniforms
            *au = initau;
            a->SetWidth(initaa.width);
            a->SetHeight(initaa.height);
            
            MoveToMerge(a, au, b, bu, nextdots);
            BuildSliceOnModel(m, mu, a, au, m->NumVertices() - a->NumDots());
            //nextdots = GetNextMergeDots(nextdots, true, a, b, au, bu);
            temp = nextdots;
            nextdots.first = GetNextDot(b, nextdots.first, lastdots.first);
            nextdots.second = GetNextDot(b, nextdots.second, lastdots.second);
            lastdots = temp;
        }
    }

    *au = initau;
    a->SetWidth(initaa.width);
    a->SetHeight(initaa.height);
}


int DragonflyUtils::GetNextDot(Slice *s, int cur, int last) {
    for (int i = 0; i < s->NumLines(); i++) {
        Line *l = s->GetLine(i);
        if (l->d1 == cur && l->d2 != last) {
            return l->d2;
        } else if (l->d2 == cur && l->d1 != last) {
            return l->d1;
        }
    }
    
    return -1;
}

float DragonflyUtils::DotDist(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, int adot, int bdot) {
    Vertex av = GetStandardVertexFromDot(a, au, adot);
    Vertex bv = GetStandardVertexFromDot(b, bu, bdot);
    return dist3to3(av, bv);
}

std::pair<std::vector<int>, float> DragonflyUtils::MatchSlicesFrom(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, int a1, int a2, int b1, int b2) {
    std::vector<int> matching;
    for (int i = 0; i < a->NumDots(); i++) {
        matching.push_back(-1);
    }
    
    matching[a1] = b1;
    matching[a2] = b2;
    int numdots = 2;
    
    int alast = a2;
    int blast = b2;
    int acur = GetNextDot(a, a1, a2);
    int bcur = GetNextDot(b, b1, b2);
    while (acur != a1 && acur != -1 && bcur != -1) {
        matching[acur] = bcur;
        numdots++;
        
        int anext = GetNextDot(a, acur, alast);
        int bnext = GetNextDot(b, bcur, blast);
        
        alast = acur;
        blast = bcur;
        
        acur = anext;
        bcur = bnext;
    }
    
    float score = 0;
    
    for (int i = 0; i < matching.size(); i++) {
        if (matching[i] != -1) {
            score += DotDist(a, au, b, bu, i, matching[i]);
        }
    }
    
    score /= numdots;
    
    return std::make_pair(matching, score);
}

std::vector<int> DragonflyUtils::MatchEqualSlices(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu) {
    std::vector<int> bestmatching;
    float bestmatchingscore = -1;
    
    for (int i = 0; i < a->NumLines(); i++) {
        Line *aline = a->GetLine(i);
        for (int j = 0; j < b->NumLines(); j++) {
            Line *bline = b->GetLine(j);
            
            std::pair<std::vector<int>, float> a1b1 = MatchSlicesFrom(a, au, b, bu, aline->d2, aline->d1, bline->d2, bline->d1);
            if (a1b1.second < bestmatchingscore || bestmatchingscore == -1) {
                bestmatching = a1b1.first;
                bestmatchingscore = a1b1.second;
            }
            
            std::pair<std::vector<int>, float> a1b2 = MatchSlicesFrom(a, au, b, bu, aline->d2, aline->d1, bline->d1, bline->d2);
            if (a1b2.second < bestmatchingscore) {
                bestmatching = a1b2.first;
                bestmatchingscore = a1b2.second;
            }
            
            std::pair<std::vector<int>, float> a2b1 = MatchSlicesFrom(a, au, b, bu, aline->d1, aline->d2, bline->d2, bline->d1);
            if (a2b1.second < bestmatchingscore) {
                bestmatching = a2b1.first;
                bestmatchingscore = a2b1.second;
            }
            
            std::pair<std::vector<int>, float> a2b2 = MatchSlicesFrom(a, au, b, bu, aline->d1, aline->d2, bline->d1, bline->d2);
            if (a2b2.second < bestmatchingscore) {
                bestmatching = a2b2.first;
                bestmatchingscore = a2b2.second;
            }
        }
    }
    
    return bestmatching;
}

void DragonflyUtils::BridgeEqualSlices(Model *m, ModelTransform *mu, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu) {
    
    
    std::vector<int> matching = MatchEqualSlices(a, au, b, bu);
    
    *mu = *au;
    
    for (int i = 0; i < a->NumDots(); i++) {
        Vertex sv = GetStandardVertexFromDot(a, au, i);
        Vertex mv = TranslatePointToBasis(&mu->b, sv);
        
        m->MakeVertex(mv.x, mv.y, mv.z);
    }
    
    for (int i = 0; i < b->NumDots(); i++) {
        Vertex sv = GetStandardVertexFromDot(b, bu, i);
        Vertex mv = TranslatePointToBasis(&mu->b, sv);
        
        m->MakeVertex(mv.x, mv.y, mv.z);
    }
    
    for (int i = 0; i < a->NumLines(); i++) {
        Line *l = a->GetLine(i);
        
        int a1 = l->d1;
        int a2 = l->d2;
        int b1 = matching[a1];
        int b2 = matching[a2];
        
        m->MakeFace(a1, a2, b1+a->NumDots(), vec_make_float4(1, 1, 1, 1));
        m->MakeFace(a2, b1+a->NumDots(), b2+a->NumDots(), vec_make_float4(1, 1, 1, 1));
    }
}

/*
 
 std::vector<int> DragonflyUtils::MatchSlicesWithSkip(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int numskips) {
 float bestmatchingscore = -1;
 
 for (int i = 0; i < a->NumLines(); i++) {
 Line *aline = a->GetLine(i);
 for (int j = 0; j < b->NumLines(); j++) {
 Line *bline = b->GetLine(j);
 
 std::pair<std::vector<int>, float> a1b1 = GetBestSkipMatch(a, au, b, bu, aline->d2, aline->d1, bline->d2, bline->d1, aline->d1, numskips);
 if (a1b1.second < bestmatchingscore || bestmatchingscore == -1) {
 bestmatching = a1b1.first;
 bestmatchingscore = a1b1.second;
 }
 
 std::pair<std::vector<int>, float> a1b2 = MatchSlicesFrom(a, au, b, bu, aline->d2, aline->d1, bline->d1, bline->d2);
 if (a1b2.second < bestmatchingscore) {
 bestmatching = a1b2.first;
 bestmatchingscore = a1b2.second;
 }
 
 std::pair<std::vector<int>, float> a2b1 = MatchSlicesFrom(a, au, b, bu, aline->d1, aline->d2, bline->d2, bline->d1);
 if (a2b1.second < bestmatchingscore) {
 bestmatching = a2b1.first;
 bestmatchingscore = a2b1.second;
 }
 
 std::pair<std::vector<int>, float> a2b2 = MatchSlicesFrom(a, au, b, bu, aline->d1, aline->d2, bline->d1, bline->d2);
 if (a2b2.second < bestmatchingscore) {
 bestmatching = a2b2.first;
 bestmatchingscore = a2b2.second;
 }
 }
 }
 
 return bestmatching;
 }
 
 std::pair<std::vector<int>, float> DragonflyUtils::GetBestSkipMatch(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int alast, int acur, int blast, int bcur, int astart, int numskips) {
 Vertex av = GetStandardVertexFromDot(a, au, acur);
 Vertex bv = GetStandardVertexFromDot(b, bu, bcur);
 float curscore = dist3to3(av, bv);
 std::vector<int> skips;
 
 int bnext = GetNextDot(b, bcur, blast);
 
 int anext = GetNextDot(a, acur, alast);
 if (anext == astart) { // base case
 if (numskips > 0) {
 curscore = 100000000000;
 } else {
 Vertex afirstv = GetStandardVertexFromDot(a, au, anext);
 Vertex bfirstv = GetStandardVertexFromDot(b, bu, bnext);
 curscore += dist3to3(av, bv);
 }
 return std::make_pair(std::vector<int>(), curscore);
 }
 std::pair<std::vector<int>, float> bestnext = GetBestSkipMatch(a, au, b, bu, anext, acur, bnext, bcur, astart, numskips);
 
 if (numskips > 0) {
 int askip = GetNextDot(a, anext, acur);
 skips.push_back(anext);
 
 if (askip == astart) { // base case
 if (numskips > 1) {
 curscore = 100000000000;
 } else {
 Vertex afirstv = GetStandardVertexFromDot(a, au, askip);
 Vertex bfirstv = GetStandardVertexFromDot(b, bu, askip);
 curscore += dist3to3(av, bv);
 }
 return std::make_pair(skips, curscore);
 }
 
 std::pair<std::vector<int>, float> bestskip = GetBestSkipMatch(a, au, b, bu, askip, anext, bnext, bcur, astart, numskips-1);
 
 if (bestskip.second < bestnext.second) {
 curscore += bestskip.second;
 for (int i = 0; i < bestskip.first.size(); i++) {
 skips.push_back(bestskip.first.at(i));
 }
 
 return std::make_pair(skips, curscore);
 }
 }
 
 curscore += bestnext.second;
 for (int i = 0; i < bestnext.first.size(); i++) {
 skips.push_back(bestnext.first.at(i));
 }
 return std::make_pair(skips, curscore);
 }
 
 std::vector<int> DragonflyUtils::MatchSlicesWithAdd(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int numadds) {
 
 }
 */
