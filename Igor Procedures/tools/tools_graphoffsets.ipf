// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"doallOffsets", tools_doallOffsets()
	end
end


function tools_doallOffsets([yoffs,xoffs,xmult, ymult])
	variable xoffs,yoffs, xmult, ymult
	xoffs = paramIsDefault(xoffs) ? 0 : xoffs
	yoffs = paramIsDefault(yoffs) ? 0 : yoffs
	xmult = paramIsDefault(xmult) ? 0 : xmult
	ymult = paramIsDefault(ymult) ? 0 : ymult
	string mode  = ""
	
	prompt mode,"mode",popup,"x and y;only x;only y;only x+;x_wave;x_mult"
	prompt xoffs,"enter x-offset"
	prompt yoffs,"enter y-offset"
	prompt xmult,"enter x-multiplier"
	prompt ymult,"enter y-multiplier"
	
	DoPrompt "Decide..", mode, xoffs, yoffs, xmult, ymult
	if(V_flag)
		return -1
	endif
	
	silent 1; pauseupdate 
	variable specnum,delta,x_offset,y_offset
	string graphname,specname
	graphname=WinName(0,1)
	if (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	else
		string tracesInGraph = TraceNameList("", ";",1+4) // only visible normal traces
		variable m = ItemsInList(tracesInGraph)
		for( specnum = 0; specnum < m; specnum += 1 )
			specname=Wavename(graphname,specnum,1)
			print specname
			if(cmpstr(specname,"")==0)
				break
			else
				//x_offset=waveoffset(specname,graphname,"x")
				//y_offset=waveoffset(specname,graphname,"y")
				//print wavemultiplier(specname,graphname,"y")
				//print wavemultiplier(specname,graphname,"x")
				
				strswitch(mode)
					case "x_mult":
						ModifyGraph muloffset[specnum]={xmult,0}
						break
					case "x and y":
						ModifyGraph offset[specnum]={xoffs,delta} 
						delta=delta+yoffs
						break
					case "only x":
						ModifyGraph offset[specnum]={xoffs,y_offset}
						break
					case "only x+":
						ModifyGraph offset[specnum]={delta,y_offset} 
						delta=delta+xoffs
						break
					case "only y":
						ModifyGraph offset[specnum]={x_offset,delta} 
						delta=delta+yoffs
						break
					case "x_wave":
						if (exists("xow")==1) 
							//delta=xow[specnum]
							// print delta 
							//Modify offset[specnum]={delta,y_offset} 
						Else 
							print "Can not find wave \"xow\" with offset value" 
						Endif 
						break
				endswitch
			endif
		endfor
	endif
end
