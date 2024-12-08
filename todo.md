## Panel Window - new architecture
- panels are basically the new schemes - the final handler for connecting user input to scene modification
- they are smaller though since schemes have become bloated, so they only have one input type - generally, want to separate direct scene interaction (through controls models) with side panel UI - gives a cleaner and more modular architecture
- panels are arranged in the window - Window class is directly related to the actual window on the screen - is the main handler for directing input to panels and containing final render buffers
- have one single Window object (contained in the Engine) that just changes around its structure/panels

rendering
- each panel should compile (their section) of each needed buffer into a formatted data struct
- the window also contains a conglomeration of all the panel buffers - formatted for the compute/renderer
- the idea is that nothing sees the panels except the window
- compute just copies the window buffers directly into gpu buffers - and renders as before