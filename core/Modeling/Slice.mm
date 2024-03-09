//
//  Slice.c
//  dragonfly
//
//  Created by Thomas Liang on 2/5/23.
//

#include "Slice.h"

Slice::Slice() {
    attr.width = 2;
    attr.height = 2;
}

Slice::~Slice() {
    for (int i = 0; i < dots.size(); i++) {
        delete dots[i];
    }
    
    for (int i = 0; i < lines.size(); i++) {
        delete lines[i];
    }
}

void Slice::SetWidth(float w) {
    attr.width = w;
}

void Slice::SetHeight(float h) {
    attr.height = h;
}

float Slice::GetWidth() {
    return attr.width;
}

float Slice::GetHeight() {
    return attr.height;
}

SliceAttributes Slice::GetAttributes() {
    return attr;
}

unsigned Slice::MakeDot(float x, float y) {
    Dot *d = new Dot();
    d->x = x;
    d->y = y;
    dots.push_back(d);
    return dots.size()-1;
}

unsigned Slice::MakeLine(int d1, int d2) {
    Line *l = new Line();
    l->d1 = d1;
    l->d2 = d2;
    lines.push_back(l);
    return lines.size()-1;
}

void Slice::AddDotToLine(int lid) {
    Line *l = lines[lid];
    Dot *d1 = dots[l->d1];
    Dot *d2 = dots[l->d2];
    
    float x = (d1->x + d2->x) / 2;
    float y = (d1->y + d2->y) / 2;
    
    MakeDot(x, y);
    MakeLine(l->d2, NumDots()-1);
    
    l->d2 = NumDots()-1;
}

void Slice::MoveDotBy(int did, float dx, float dy) {
    dots[did]->x += dx;
    dots[did]->y += dy;
}

void Slice::MoveDotTo(int did, float x, float y) {
    dots[did]->x = x;
    dots[did]->y = y;
}

void Slice::RemoveDot(int did) {
    delete dots[did];
    dots.erase(dots.begin() + did);
}

void Slice::RemoveLine(int lid) {
    delete lines[lid];
    lines.erase(lines.begin() + lid);
}

void Slice::RemoveDotAndMergeLines(int did) {
    int lid1 = -1;
    int lid2 = -1;
    
    for (int i = 0; i < lines.size(); i++) {
        Line *l = lines.at(i);
        if (l->d1 == did || l->d2 == did) {
            if (lid1 == -1) {
                lid1 = i;
            } else {
                lid2 = i;
                break;
            }
        }
    }
    
    if (lid1 == -1) {
        RemoveDot(did);
    } else if (lid2 == -1) {
        RemoveDot(did);
        RemoveLine(lid1);
    } else {
        Line *l1 = lines.at(lid1);
        Line *l2 = lines.at(lid2);
        if (l1->d1 == did) {
            if (l2->d1 == did) {
                l1->d1 = l2->d2;
            } else {
                l1->d1 = l2->d1;
            }
        } else {
            if (l2->d1 == did) {
                l1->d2 = l2->d2;
            } else {
                l1->d2 = l2->d1;
            }
        }
        
        RemoveLine(lid2);
        RemoveDot(did);
        
        for (int i = 0; i < lines.size(); i++) {
            Line *l = lines.at(i);
            if (l->d1 > did) {
                l->d1--;
            }
            if (l->d2 > did) {
                l->d2--;
            }
        }
    }
}

Dot * Slice::GetDot(unsigned long did) {
    return dots[did];
}

Line * Slice::GetLine(unsigned long lid) {
    return lines[lid];
}

std::vector<Dot*> & Slice::GetDots() {
    return dots;
}

std::vector<Line*> & Slice::GetLines() {
    return lines;
}

unsigned long Slice::NumDots() {
    return dots.size();
}

unsigned long Slice::NumLines() {
    return lines.size();
}

