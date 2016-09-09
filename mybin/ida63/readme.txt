-Completely replaced the code that loads the loader modules, removing the PE/ELF/Mach-O limitation.
-Removed the check restricting which processor modules are allowed.
-Created a custum loader to re-enable support for loading Binary files.
-Removed the experation check.
-Removed the nags when opening and closing projects.
-Disabled the thread that would open a nag after some time. In the past it would force the program to close, but I guess that was broken in the transition to QT.
-Removed the checks preventing self-disassembly.
-Removed a limitation preventing large large amounts of data from being copied to the clipboard.
-Some options were removed from the Help menu for cosmetics.

No database saving or loading, so you will have to use IDC files to save your work.
