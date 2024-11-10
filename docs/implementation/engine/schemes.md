# Schemes

a scheme is, in essence, a mechanism to edit a scene

scheme handle much of the input and rendering flow between the datatypes and kernel pipelines - facilitating the user-data relationship

schemes reference a single scene that is being edited. all access and changes made to the scene are done through schemes, so that scenes are sheltered from direct change

schemes provide buffer data for both scenes and some additional information, like controls models and UI elements

blah blah blah...

## paneling

schemes are divided (physically on the screen) into panels

different panels are generally used for different input types (e.g. a panel for directly clicking on vertices and another for UI input)

because of this, rendering is divided per panel

schemes contain a list of panels, along with their bounding boxes

each panel contains:
- its own camera
- information on what to render (faces, vertices, edges, UI)
- controls models and related information
- UI elements and related information
- some scene viewing settings (like if lighting is enabled)
- some selection data

data can be shared across panels via the scheme. e.g. a side text panel can see what vertices and selected in another panel