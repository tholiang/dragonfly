## Panel Window - new architecture
- panels are basically the new schemes - the final handler for connecting user input to scene modification
- they are smaller though since schemes have become bloated, so they only have one input type - generally, want to separate direct scene interaction (through controls models) with side panel UI - gives a cleaner and more modular architecture
- panels are arranged in the window - Window class is directly related to the actual window on the screen - is the main handler for directing input to panels and containing final render buffers
- have one single Window object (contained in the Engine) that just changes around its structure/panels
- rendering per panel or the whole window ???