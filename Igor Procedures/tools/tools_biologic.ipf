// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <WaveSelectorWidget>
#include <PopupWaveSelector>


Menu "Macros"
	submenu "Biologic Tools"
		"Select Cycle", Biologic_cyclepanel()
		"Select Freq", Biologic_FREQpanel()
		"Mott-Schottky", Biologic_MottSchottky()
	end
End


strconstant s_wfrq = "0_freq"


function Biologic_MottSchottky()
	string graphname,sn,srn,notestr 
	graphname=WinName(0,1)
	If (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	Else
		if(strlen(CsrInfo(A)) > 0 && strlen(CsrInfo(B)) > 0)
			wave specnamew = CsrWaveRef(A)
			wave specnamewx = CsrXWaveRef(A)
			//print nameofwave(specnameW)
			if(waveexists(specnamewx))
				CurveFit /Q line specnamew[pcsr(A),pcsr(B)] /X=specnamewx[pcsr(A),pcsr(B)] /D
			else
				CurveFit /Q line specnamew[pcsr(A),pcsr(B)] /D			
			endif

			Wave W_coef
			Wave W_sigma
			
			
			variable a1 = W_coef[0]
			variable b1 = W_coef[1]
			variable a1e = W_sigma[0]
			variable b1e = W_sigma[1]

			Variable samplearea=1,epsr=1
			Prompt samplearea, "Enter area [cm^2]: "
			Prompt epsr, "Enter epsilon: "
			DoPrompt "Enter data", samplearea, epsr
			if (V_Flag)
				return -1
			endif
			variable kbeV=8.617e-5
			variable Temp
			variable eps = 8.8541878176E-12 //F/m
			variable echarge = 1.60217662E-19 // coulomb
			
			// y = a+b*x
			// http://currentseparations.com/issues/17-3/cs-17-3d.pdf
			print "Ufb: ",-a1/b1-Temp*kbeV
			print "N: ",2/(echarge*eps*epsr*samplearea*b1/1E-12) // 1E-12 because C is in muF
		else
			print "Expected cursor A and B!"
		endif		
	endif

end


Function Biologic_SetCycle(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval


			string graphname=WinName(0,1,1)
			If (cmpstr(graphname,"")==0)
				print "no graphwindow"
				//doalert 0,"no graphwindow"
			Else 
				if(strlen(CsrInfo(A)) > 0)
					wave specnamew = CsrWaveRef(A, graphname)
					wave specnamew_x = CsrXWaveRef(A, graphname)
				
					DFREF saveDFR = GetDataFolderDFR()
					setdatafolder GetWavesDataFolder(specnamew, 1)
					DFREF DFR = GetDataFolderDFR()

					variable i, cycleid = -1
					
					Variable numWaves = CountObjectsDFR(dfr, 1)
					for(i=0; i<numWaves; i+=1)
						string name = GetIndexedObjNameDFR(dfr, 1, i)
						if(strsearch(name, "cycle", 0) != -1)
							cycleid = i
							break
						endif 
					endfor	

					if(cycleid != -1)
						wave w_cycle =  $(GetIndexedObjNameDFR(dfr, 1, cycleid))


						variable selectedcycle = sva.dval
						if(selectedcycle > w_cycle[DimSize(w_cycle, 0)-1])
							SetVariable select_cycle value= _NUM:w_cycle[DimSize(w_cycle, 0)-1]
							selectedcycle = w_cycle[DimSize(w_cycle, 0)-1]
						endif

						FindValue /V=(selectedcycle) /S=0 /T=0 /Z w_cycle
						variable cyc_start = V_value
						FindValue /V=(selectedcycle+1) /S=0 /T=0 /Z w_cycle
						variable cyc_end = V_value -1
						if(cyc_end == -2)
							cyc_end = DimSize(w_cycle, 0)-1
						endif
						string s_trace = StringFromList(1,StringFromList(0,CsrInfo(A),";"),":")
						ReplaceWave  trace=$(s_trace), specnamew[cyc_start,cyc_end]
						ReplaceWave /X  trace=$(s_trace), specnamew_x[cyc_start,cyc_end]
					else
						print "no cycle wave found!"
					endif
					SetDataFolder saveDFR
				else
					print "expected cursor A"
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function Biologic_cyclepanel() : Panel
	String panelName = "Cycleselector"
	if (WinType(panelName) == 7)
		// if the panel already exists, show it
		DoWindow/F $panelName
	else
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1/N=$panelName/W=(0,0,120,70)  as "Select Cycle to plot..." 
		ModifyPanel fixedSize=1,noEdit=1
		Button B_Done,pos={20.00,34.00},size={50.00,20.00},title="Done",proc=Biologic_presseddonecycle
		SetVariable select_cycle,pos={18.00,10.00},size={84.00,14.00},proc=Biologic_SetCycle,title="cycle"
		SetVariable select_cycle,limits={1,inf,1},value= _NUM:0,noedit= 1
	endif
end


Function Biologic_presseddonecycle(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct	// Igor-defined structure, passed by reference.
	if( bStruct.eventCode != 1 )
		return 0		// we only handle mouse down (code=1)
	endif
	Killwindow Cycleselector
	return 0
end


Function Biologic_FREQpanel() : Panel
	String panelName = "FREQ_Panel"
	if (WinType(panelName) == 7)
		// if the panel already exists, show it
		DoWindow/F $panelName
	else
		NewDatafolder /O root:Packages
		NewDatafolder /O root:Packages:Biologic
		string /G  root:Packages:Biologic:FREQPATH
		SVAR SelectedItem = root:Packages:Biologic:FREQPATH


		NewPanel/K=1/N=$panelName/W=(181,179,430,330) as "Select Freq"
		ModifyPanel fixedSize=1,noEdit=1
		
		SetVariable FRQ_pathselect,pos={-50,10},size={270,15},title="Select Path:"
		SetVariable FRQ_pathselect,bodyWidth= 150
		MakeSetVarIntoWSPopupButton(panelName, "FRQ_pathselect", "Biologic_WaveSelectorNotify", "root:Packages:Biologic:FREQPATH", content=WMWS_DataFolders)
		SelectedItem = "root:"
		
		PopupMenu FRQlistselector,pos={10,30},size={115,20},title="FRQs",fSize=12,mode=1,value=Biologic_getfrqs()
		PopupMenu PlotXselector,pos={10,60},size={115,20},title="X: ",fSize=12,mode=1,value=Biologic_getwavelist()
		PopupMenu PlotYselector,pos={130,60},size={115,20},title="Y: ",fSize=12,mode=1,value=Biologic_getwavelist()
		PopupMenu Plotstylelistselector,pos={10,90},size={115,20},title="Style",fSize=12,mode=1,value="^1;^-2;"
		Button getFRQs,pos={9,120},size={110,20},proc=Biologic_pressedgetfrq,title="Get Frqs"
		Button plotFRQ,pos={130,120},size={110,20},proc=Biologic_pressedplotfrq,title="Plot Frq"
	endif
End


Function Biologic_pressedplotfrq(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct	// Igor-defined structure, passed by reference.
	if( bStruct.eventCode != 1 )
		return 0		// we only handle mouse down (code=1)
	endif
	SVAR SelectedItem = root:Packages:Biologic:FREQPATH
	ControlInfo FRQlistselector
	variable selectedFRQ = str2num(S_Value)
	ControlInfo Plotstylelistselector
	string plotstyle = S_Value


	ControlInfo PlotXselector
	string s_xwave =  S_Value
	ControlInfo PlotYselector
	string s_ywave =  S_Value

	if(numtype(selectedFRQ) == 0)		
		DFREF saveDFR = GetDataFolderDFR()
		setdatafolder $SelectedItem
		DFREF DFR = GetDataFolderDFR()
		wave w_frqs = $s_wfrq
		wave w_x = $s_xwave
		wave w_y = $s_ywave
		
		setdatafolder saveDFR
		make /O/R/N=(0) root:tmp_X /wave=xwave
		make /O/R/N=(0) root:tmp_Y /wave=ywave
		variable i, j
		j = 0
		for(i=0;i<dimsize(w_frqs,0);i+=1)
			//if(w_frqs[i] == selectedFRQ)
			if(cmpstr(num2str(w_frqs[i]),num2str(selectedFRQ))==0)
				j += 1
				Redimension/N=(j) xwave, ywave
				xwave[j-1] = w_x[i]
				ywave[j-1] = w_y[i]

			endif
		endfor

		strswitch(plotstyle)
			case "^-2":
				ywave[] = 1/(ywave[p]^2)
				break		
		endswitch
	endif
	return 0
end


Function Biologic_pressedgetfrq(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct	// Igor-defined structure, passed by reference.
	if( bStruct.eventCode != 1 )
		return 0		// we only handle mouse down (code=1)
	endif
 	PopupMenu FRQlistselector value=Biologic_getfrqs()
	return 0
end


Function Biologic_WaveSelectorNotify(event, wavepath, windowName, ctrlName)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	//print "Selected wave:",wavepath, " using control", ctrlName
end


function /S Biologic_getfrqs()
	SVAR SelectedItem = root:Packages:Biologic:FREQPATH
	if(cmpstr("(no selection)",SelectedItem)==0 ||cmpstr("root",SelectedItem)==0)
		SelectedItem = "root:"
	endif
	DFREF saveDFR = GetDataFolderDFR()
	setdatafolder $SelectedItem
	wave w_frqs = $s_wfrq
	setdatafolder saveDFR
	string s_frqlist = ""
	if(waveexists(w_frqs))
		variable i
		for(i=0;i<dimsize(w_frqs,0);i+=1)
			if(FindListItem(num2str(w_frqs[i]),s_frqlist) == -1)
				s_frqlist=AddListItem(num2str(w_frqs[i]),s_frqlist)
			endif
		endfor
	else
		s_frqlist = "none;"
	endif
	return s_frqlist
end


function /S Biologic_getwavelist()
	SVAR SelectedItem = root:Packages:Biologic:FREQPATH
	if(cmpstr("(no selection)",SelectedItem)==0 ||cmpstr("root",SelectedItem)==0)
		SelectedItem = "root:"
	endif
	DFREF saveDFR = GetDataFolderDFR()
	setdatafolder $SelectedItem
	string s_wavelist = WaveList("*",";","")
	setdatafolder saveDFR
	return s_wavelist
end
