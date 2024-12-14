#include "RenderPipelineGLFW.h"

RenderPipelineGLFW::RenderPipelineGLFW() {
    
}

RenderPipelineGLFW::~RenderPipelineGLFW() {
    // Cleanup
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glfwTerminate();
}

int RenderPipelineGLFW::init () {
    // Setup ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // Setup IO
    io.WantCaptureKeyboard = true;

    // Setup style
    ImGui::StyleColorsDark();

    // glfw: initialize and configure
    // ------------------------------
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // glfw window creation
    // --------------------
    window = glfwCreateWindow(width, height, "Dragonfly", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    //glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 460");
    
    SetPipeline();
    
    return 0;
}

void RenderPipelineGLFW::SetPipeline() {
    // glad: load all OpenGL function pointers
    // ---------------------------------------
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return;
    }

    // build and compile our shader program
    // ------------------------------------
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);
    face_shader = new Shader("Processing/Render/DefaultFaceShader.vert", "Processing/Render/FragmentShader.frag", "Processing/util.glsl");
    edge_shader = new Shader("Processing/Render/SuperDefaultEdgeShader.vert", "Processing/Render/FragmentShader.frag", "Processing/util.glsl");
}

void RenderPipelineGLFW::SetBuffer(unsigned long idx, GLuint buf, unsigned long cap) {
    compute_buffers[idx] = buf;
    compute_buffer_capacities[idx] = cap;
}

void RenderPipelineGLFW::Render() {
    // render
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS); 

    // if there are faces to render, render
    if (num_faces > 0) {
        face_shader->use();
        glBindVertexArray(VAO);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, compute_buffers[CPT_COMPCOMPFACE_OUTBUF_IDX]);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, compute_buffers[CPT_COMPCOMPVERTEX_OUTBUF_IDX]);
        glDrawArrays(GL_TRIANGLES, 0, num_faces*3);
    }
    
    // TODO: edges
    // if there are edges to render, render
    // if (num_edges > 0) {
    //     edge_shader->use();
    //     glBindVertexArray(VAO);
    //     glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, edge_buffer);
    //     glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, vertex_buffer);
    //     glDrawArrays(GL_LINES, 0, num_edges*2);
    // }

    // Start the Dear ImGui frame
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
    
    // scheme_controller->BuildUI();
    
    // scheme = scheme_controller->GetScheme();
    // scheme->BuildUI();

    ImGui::Render();
    int display_w, display_h;
    glfwGetFramebufferSize(window, &display_w, &display_h);
    glViewport(0, 0, display_w, display_h);

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

    // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    // -------------------------------------------------------------------------------
    glfwSwapBuffers(window);
}

GLFWwindow *RenderPipelineGLFW::get_window() {
    return window;
}