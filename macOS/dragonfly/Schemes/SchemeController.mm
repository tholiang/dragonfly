//
//  SchemeController.m
//  dragonfly
//
//  Created by Thomas Liang on 8/1/22.
//

#import <Foundation/Foundation.h>
#include "SchemeController.h"

SchemeController::SchemeController(Scheme *scheme) {
    scheme_ = scheme;
}

SchemeController::~SchemeController() {
    
}

void SchemeController::BuildUI() {
    MenuBar();
    FileDialog();
}

void SchemeController::SetScheme(Scheme *scheme) {
    scheme_ = scheme;
}

Scheme *SchemeController::GetScheme() {
    return scheme_;
}

void SchemeController::MenuBar() {
    if (ImGui::BeginMainMenuBar()) {
        using_menu_bar = false;
        
        if (ImGui::BeginMenu("File")) {
            using_menu_bar = true;
            if (ImGui::MenuItem("New Model", "")) {
                scheme_->CreateNewModel();
            }
            if (ImGui::MenuItem("Save Selected Model", "")) {
                if (scheme_->GetType() == SchemeType::EditModel) {
                    scheme_->EnableInput(false);
                    saving_model = true;
                    
                    fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_EnterNewFilename | ImGuiFileBrowserFlags_CloseOnEsc);
                    fileDialog.SetTitle("Saving Model");
                    fileDialog.Open();
                }
            }
            if (ImGui::MenuItem("Save Scene", ""))   {
                saving_scene = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_EnterNewFilename | ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Saving Scene");
                fileDialog.Open();
            }
            if (ImGui::MenuItem("Import Model", ""))   {
                importing_model = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Importing Model");
                fileDialog.SetTypeFilters({ ".drgn" });
                fileDialog.Open();
            }
            if (ImGui::MenuItem("Import Scene", ""))   {
                importing_scene = true;
                
                fileDialog = ImGui::FileBrowser(ImGuiFileBrowserFlags_SelectDirectory | ImGuiFileBrowserFlags_CloseOnEsc);
                fileDialog.SetTitle("Importing Scene");
                fileDialog.Open();
            }
            ImGui::EndMenu();
        }
        
        if (ImGui::BeginMenu("Edit")) {
            using_menu_bar = true;
            if (ImGui::MenuItem("Edit by Model", "")) {
                Scene *scene = scheme_->GetScene();
                Camera *camera = scheme_->GetCamera();
                
                delete scheme_;
                scheme_ = new EditModelScheme();
                scheme_->SetScene(scene);
                scheme_->SetCamera(camera);
            }
            if (ImGui::MenuItem("Edit by Face, Edge, and Vertex", ""))   {
                Scene *scene = scheme_->GetScene();
                Camera *camera = scheme_->GetCamera();
                
                delete scheme_;
                scheme_ = new EditFEVScheme();
                scheme_->SetScene(scene);
                scheme_->SetCamera(camera);
            }
            if (ImGui::MenuItem("Edit by Node", ""))   {
                Scene *scene = scheme_->GetScene();
                Camera *camera = scheme_->GetCamera();
                
                delete scheme_;
                scheme_ = new EditNodeScheme();
                scheme_->SetScene(scene);
                scheme_->SetCamera(camera);
            }
            ImGui::EndMenu();
        }
        ImGui::EndMainMenuBar();
    }
}

void SchemeController::FileDialog() {
    if (importing_model || importing_scene || saving_model || saving_scene) {
        fileDialog.Display();
    }
    
    if(fileDialog.HasSelected()) {
        if (saving_model) {
            EditModelScheme *casted = (EditModelScheme *) scheme_;
            casted->SaveSelectedModelToFile(fileDialog.GetSelected().string());
            scheme_->EnableInput(true);
        }
        if (saving_scene) {
            scheme_->SaveSceneToFolder(fileDialog.GetSelected().string());
        }
        if (importing_model) {
            std::cout << "Selected filename" << fileDialog.GetSelected().string() << std::endl;
            
            scheme_->NewModelFromFile(fileDialog.GetSelected().string());
            
            fileDialog.ClearSelected();
            fileDialog.Close();
            importing_model = false;
        } else if (importing_scene) {
            /*std::cout << "Selected scene" << fileDialog.GetSelected().string() << std::endl;
            
            GetSceneFromFolder(fileDialog.GetSelected().string());*/
            
            fileDialog.ClearSelected();
            fileDialog.Close();
            importing_scene = false;
        }
    }
    
    if(!fileDialog.IsOpened()) {
        importing_model = false;
        importing_scene = false;
        saving_model = false;
        saving_scene = false;
    }
}
