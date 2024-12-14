//
//  CalculateModelNodeTransforms.metal
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#include <metal_stdlib>
using namespace metal;
#include "../MetalUtil.h"
#include "../MetalBufferUtil.h"

/*
 transform list of model (scene + control) nodes in Model Space to World Space
 operate per node
 args:
 1. panel_info_buffer - single Buffer object containing PanelInfoBuffer objects
 2. cpt_nodes - packed per-panel Buffers of Nodes to write to - in the same format as pnl_nodes
 2. pnl_nodes - packed per-panel Buffers of Nodes to read from
 3. node_model_ids - packed per-panel Buffers of unsigned ints (indicating the model id for each corresponding node in nodes)
 4. model_transforms - packed per-panel Buffers of ModelTransforms
 */
kernel void CalculateModelNodeTransforms(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device char *cpt_nodes [[buffer(1)]],
    const constant char *pnl_nodes [[buffer(2)]],
    const constant char *node_model_ids [[buffer(3)]],
    const constant char *model_transforms [[buffer(4)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    vec_int2 pid_rnid = GetPanelFromIndex(panel_info_buffer, pnl_nodes, PNL_NODE_OUTBUF_IDX, nid, sizeof(Node));
    int pid = pid_rnid.x;
    int rnid = pid_rnid.y;
    
    constant Node *pnl_node = (constant Node *) GetConstantElementFromRelativeIndex(panel_info_buffer, pnl_nodes, PNL_NODE_OUTBUF_IDX, pid, rnid, sizeof(Node));
    device Node *cpt_node = (device Node *) GetDeviceElementFromRelativeIndex(panel_info_buffer, cpt_nodes, PNL_NODE_OUTBUF_IDX, pid, rnid, sizeof(Node));
    unsigned int rmid = *((constant unsigned int *) GetConstantElementFromRelativeIndex(panel_info_buffer, node_model_ids, PNL_NODEMODELID_OUTBUF_IDX, pid, rnid, sizeof(unsigned int)));
    constant ModelTransform *uniform = (constant ModelTransform *) GetConstantElementFromRelativeIndex(panel_info_buffer, model_transforms, PNL_MODELTRANS_OUTBUF_IDX, pid, rmid, sizeof(ModelTransform));;
    cpt_node->b.pos = TranslatePointToStandard(uniform->b, pnl_node->b.pos);
    cpt_node->b.x = RotatePointToStandard(uniform->b, pnl_node->b.x);
    cpt_node->b.y = RotatePointToStandard(uniform->b, pnl_node->b.y);
    cpt_node->b.z = RotatePointToStandard(uniform->b, pnl_node->b.z);
}
