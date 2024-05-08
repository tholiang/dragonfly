// util inserted here

// #version 430 core

layout(std430, binding = 1) buffer bufferA
{
    Face face_array[];
};

layout(std430, binding = 2) buffer bufferB
{
    vector_float3 vertex_array[];
};

out vec3 pass_color;

void main()
{
    uint vid = gl_VertexID;

    // get current face - 3 vertices per face
    Face currentFace = face_array[vid/3];
    // get current vertex in face
    vector_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    
    // make and return output vertex
    if (currentVertex.z < 0) {
        gl_Position = vec4(0, 0, 0, 1.0);
    } else {
        gl_Position = vec4(currentVertex.x, currentVertex.y, currentVertex.z+0.1, 1.0);
        pass_color = vec3(currentFace.color.x, currentFace.color.y, currentFace.color.z);
    }
}