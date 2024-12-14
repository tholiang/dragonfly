//
//  MetalConstants.h
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#ifndef MetalConstants_h
#define MetalConstants_h

constant float pi = 3.14159265358979;
constant float render_dist = 50;

// panel buffer consts
constant const unsigned long PNL_NUM_OUTBUFS = 17;

constant const unsigned long PNL_CAMERA_OUTBUF_IDX = 0;
constant const unsigned long PNL_LIGHT_OUTBUF_IDX = 1;
constant const unsigned long PNL_FACE_OUTBUF_IDX = 2;
constant const unsigned long PNL_EDGE_OUTBUF_IDX = 3;
constant const unsigned long PNL_NODE_OUTBUF_IDX = 4;
constant const unsigned long PNL_NODEMODELID_OUTBUF_IDX = 5;
constant const unsigned long PNL_NODEVERTEXLNK_OUTBUF_IDX = 6;
constant const unsigned long PNL_MODELTRANS_OUTBUF_IDX = 7;
constant const unsigned long PNL_SLICEDOT_OUTBUF_IDX = 8;
constant const unsigned long PNL_SLICELINE_OUTBUF_IDX = 9;
constant const unsigned long PNL_SLICEATTR_OUTBUF_IDX = 10;
constant const unsigned long PNL_SLICETRANS_OUTBUF_IDX = 11;
constant const unsigned long PNL_DOTSLICEID_OUTBUF_IDX = 12;
constant const unsigned long PNL_UIFACE_OUTBUF_IDX = 13;
constant const unsigned long PNL_UIVERTEX_OUTBUF_IDX = 14;
constant const unsigned long PNL_UIELEMID_OUTBUF_IDX = 15;
constant const unsigned long PNL_UITRANS_OUTBUF_IDX = 16;


// compute buffer consts
constant const unsigned long CPT_NUM_OUTBUFS = 4;

constant const unsigned long CPT_COMPCOMPVERTEX_OUTBUF_IDX = 0;
constant const unsigned long CPT_COMPCOMPFACE_OUTBUF_IDX = 1;
constant const unsigned long CPT_COMPMODELVERTEX_OUTBUF_IDX = 2;
constant const unsigned long CPT_COMPMODELNODE_OUTBUF_IDX = 3;


/* RENDERING VALUES */
constant const unsigned int NUM_VERTEX_SQUARE_VERTICES = 4;
constant const unsigned int NUM_NODE_CIRLCE_VERTICES = 9;
constant const unsigned int NUM_SLICE_PLATE_VERTICES = 4;
constant const unsigned int NUM_VERTEX_SQUARE_FACES = 2;
constant const unsigned int NUM_NODE_CIRLCE_FACES = 8;
constant const unsigned int NUM_SLICE_PLATE_FACES = 2;

#endif /* MetalConstants_h */
