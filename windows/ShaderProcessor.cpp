#include "ShaderProcessor.h"

ComputeShader::ComputeShader(const char* path, const char* helperPath)
{
    // std::cout<<"reading "<<path<<std::endl;

    // 1. retrieve the vertex/fragment source code from filePath
    std::string code;
    std::ifstream shaderFile;
    std::ifstream hShaderFile;
    // ensure ifstream objects can throw exceptions:
    shaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
    hShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);

    // open files
    shaderFile.open(path);
    hShaderFile.open(helperPath);
    std::stringstream shaderStream, hShaderStream;
    // insert util file
    shaderStream << '\n';
    shaderStream << hShaderFile.rdbuf();
    // read file's buffer contents into streams
    shaderStream << '\n';
    shaderStream << shaderFile.rdbuf();
    // read helper into shader
    // close file handlers
    shaderFile.close();
    hShaderFile.close();
    // convert stream into string and insert version header
    code   = "#version 430 core\n" + shaderStream.str();
    
    const char* shaderCode = code.c_str();
    // 2. compile shaders
    unsigned int compute;
    compute = glCreateShader(GL_COMPUTE_SHADER);
    glShaderSource(compute, 1, &shaderCode, NULL);
    glCompileShader(compute);
    checkCompileErrors(compute, "COMPUTE");

    // shader Program
    ID = glCreateProgram();
    glAttachShader(ID, compute);
    glLinkProgram(ID);
    checkCompileErrors(ID, "PROGRAM");
    // delete the shaders as they're linked into our program now and no longer necessary
    glDeleteShader(compute);
}
// activate the shader
// ------------------------------------------------------------------------
void ComputeShader::use() 
{ 
    glUseProgram(ID); 
}
// utility uniform functions
// ------------------------------------------------------------------------
void ComputeShader::setBool(const std::string &name, bool value) const
{         
    glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value); 
}
// ------------------------------------------------------------------------
void ComputeShader::setInt(const std::string &name, int value) const
{ 
    glUniform1i(glGetUniformLocation(ID, name.c_str()), value); 
}
// ------------------------------------------------------------------------
void ComputeShader::setFloat(const std::string &name, float value) const
{ 
    glUniform1f(glGetUniformLocation(ID, name.c_str()), value); 
}

void ComputeShader::checkCompileErrors(unsigned int shader, std::string type)
{
    int success;
    char infoLog[1024];
    if (type != "PROGRAM")
    {
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success)
        {
            glGetShaderInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
        }
    }
    else
    {
        glGetProgramiv(shader, GL_LINK_STATUS, &success);
        if (!success)
        {
            glGetProgramInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
        }
    }
}



Shader::Shader(const char* vertexPath, const char* fragmentPath, const char* helperPath)
{
    // std::cout<<"reading "<<vertexPath<<std::endl;

    // get source code
    std::string vertexCode;
    std::string fragmentCode;
    std::ifstream vShaderFile;
    std::ifstream fShaderFile;
    std::ifstream hShaderFile;
    // ensure ifstream objects can throw exceptions:
    /*vShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
    fShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
    hShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);*/

    // open files
    vShaderFile.open(vertexPath);
    fShaderFile.open(fragmentPath);
    hShaderFile.open(helperPath);
    std::stringstream vShaderStream, fShaderStream, hShaderStream;
    // insert util file to vertex
    vShaderStream << hShaderFile.rdbuf();
    // read file's buffer contents into streams
    vShaderStream << '\n';
    vShaderStream << vShaderFile.rdbuf();

    fShaderStream << fShaderFile.rdbuf();

    // close file handlers
    vShaderFile.close();
    fShaderFile.close();
    hShaderFile.close();
    // convert stream into string
    vertexCode   = "#version 430 core\n" + vShaderStream.str();
    fragmentCode = "#version 430 core\n" + fShaderStream.str();

    // std::cout<<vertexCode<<std::endl;

    const char* vShaderCode = vertexCode.c_str();
    const char * fShaderCode = fragmentCode.c_str();
    // 2. compile shaders
    unsigned int vertex, fragment;
    // vertex shader
    vertex = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex, 1, &vShaderCode, NULL);
    glCompileShader(vertex);
    checkCompileErrors(vertex, "VERTEX");
    // fragment Shader
    fragment = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment, 1, &fShaderCode, NULL);
    glCompileShader(fragment);
    checkCompileErrors(fragment, "FRAGMENT");
    // shader Program
    ID = glCreateProgram();
    glAttachShader(ID, vertex);
    glAttachShader(ID, fragment);
    glLinkProgram(ID);
    checkCompileErrors(ID, "PROGRAM");
    // delete the shaders as they're linked into our program now and no longer necessary
    glDeleteShader(vertex);
    glDeleteShader(fragment);
}
// activate the shader
// ------------------------------------------------------------------------
void Shader::use() 
{ 
    glUseProgram(ID); 
}
// utility uniform functions
// ------------------------------------------------------------------------
void Shader::setBool(const std::string &name, bool value) const
{         
    glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value); 
}
// ------------------------------------------------------------------------
void Shader::setInt(const std::string &name, int value) const
{ 
    glUniform1i(glGetUniformLocation(ID, name.c_str()), value); 
}
// ------------------------------------------------------------------------
void Shader::setFloat(const std::string &name, float value) const
{ 
    glUniform1f(glGetUniformLocation(ID, name.c_str()), value); 
}

void Shader::checkCompileErrors(unsigned int shader, std::string type)
{
    int success;
    char infoLog[1024];
    if (type != "PROGRAM")
    {
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success)
        {
            glGetShaderInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
        }
    }
    else
    {
        glGetProgramiv(shader, GL_LINK_STATUS, &success);
        if (!success)
        {
            glGetProgramInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
        }
    }
}