# panels

a panel is, in essence, a mechanism to edit a scene. different panel types allow for different types of editing

panel handle much of the input and rendering flow between the datatypes and kernel pipelines - facilitating the user-data relationship

panel reference a single scene that is being edited. all access and changes made to the scene are done through panels, so that scenes are sheltered from direct change

panel provide buffer data for both scenes and some additional information, like controls models and UI elements. with this, rendering is divided per panel

blah blah blah...

## windows

a full window is generally comprised of multiple panels. e.g. a vertex editing window will have a scene vertex view panel along with a UI edit panel

windows contain the organization of these panels, while also facilitating the share of information across them