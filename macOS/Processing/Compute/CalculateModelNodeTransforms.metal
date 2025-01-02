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
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. cpt_nodes - Buffer of packed per-panel data of Nodes to write to - in the same format as pnl_nodes
 2. pnl_nodes - Buffer of packed per-panel data of Nodes to read from
 3. node_model_ids - Buffer of packed per-panel data of unsigned ints (indicating the model id for each corresponding node in nodes)
 4. model_transforms - Buffer of packed per-panel data of ModelTransforms
 */
kernel void CalculateModelNodeTransforms(
    const constant Buffer *panel_info_buffer [[buffer(0)]],
    device Buffer *cpt_nodes [[buffer(1)]],
    const constant Buffer *pnl_nodes [[buffer(2)]],
    const constant Buffer *node_model_ids [[buffer(3)]],
    const constant Buffer *model_transforms [[buffer(4)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    vec_int2 pid_rnid = GlobalToComputeBufIdx(panel_info_buffer, CPT_COMPMODELNODE_OUTBUF_IDX, nid, sizeof(Node));
    int pid = pid_rnid.x;
    int rnid = pid_rnid.y; // 1 to 1 for pnl node outbuf
    
    constant Node *pnl_node = (constant Node *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, pnl_nodes, PNL_NODE_OUTBUF_IDX, pid, rnid, sizeof(Node));
    device Node *cpt_node = (device Node *) GetDeviceComputeBufElementFromRelIdx(panel_info_buffer, cpt_nodes, CPT_COMPMODELNODE_OUTBUF_IDX, pid, rnid, sizeof(Node));
    unsigned int rmid = *((constant unsigned int *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, node_model_ids, PNL_NODEMODELID_OUTBUF_IDX, pid, rnid, sizeof(unsigned int)));
    constant ModelTransform *uniform = (constant ModelTransform *) GetConstantPanelBufElementFromRelIdx(panel_info_buffer, model_transforms, PNL_MODELTRANS_OUTBUF_IDX, pid, rmid, sizeof(ModelTransform));
    cpt_node->b.pos = TranslatePointToStandard(uniform->b, pnl_node->b.pos);
    cpt_node->b.x = RotatePointToStandard(uniform->b, pnl_node->b.x);
    cpt_node->b.y = RotatePointToStandard(uniform->b, pnl_node->b.y);
    cpt_node->b.z = RotatePointToStandard(uniform->b, pnl_node->b.z);
}
