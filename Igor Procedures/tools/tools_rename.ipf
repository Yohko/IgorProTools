// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"Rename Window ...", tools_renamewin()
	end
end


function tools_renamewin()
	string namew = "NAME"
	Prompt namew, "Give new Window name: "

	DoPrompt "Renaming Window", namew
	if (V_Flag)
		return -1	// User canceled
	endif
	DoWindow/C $namew
end
