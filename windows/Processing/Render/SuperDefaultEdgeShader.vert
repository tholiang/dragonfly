// util inserted here

// #version 430 core

layout (location = 0) in float pos;

layout(std430, binding = 1) buffer bufferA
{
    vector_int2 edge_array[];
};

layout(std430, binding = 2) buffer bufferB
{
    vector_float3 vertex_array[];
};

out vec3 pass_color;

void main()
{
    uint vid = gl_VertexID;

    // get current edge - 2 vertices to each edge
    vector_int2 current_edge = edge_array[vid/2];
    
    // get vertex and output
    vector_float3 currentVertex;
    if (vid % 2 == 0) currentVertex = vertex_array[current_edge.x];
    else currentVertex = vertex_array[current_edge.y];

    if (currentVertex.z < 0) {
        gl_Position = vec4(0, 0, 0, 1.0);
    } else {
        gl_Position = vec4(currentVertex.x, currentVertex.y, currentVertex.z+0.099, 1);
        pass_color = vec3(0, 0, 1);
    }
}