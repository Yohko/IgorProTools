// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#include "tools_utils"

Menu "Macros"
	submenu "Tools"
		"Diffspec B-A", tools_DIFFspec()
	end
end

strconstant DIFFspec_directory = "root:Packages:DIFFspec:"

function tools_DIFFspec()
	
	variable specnum,scaling
	string graphname,specname,diffname,hstr, tmps


	NewDatafolder /O root:Packages
	NewDatafolder /O root:Packages:DIFFspec
	
	variable /G $(DIFFspec_directory+"yscaling_dg")
	NVAR yscaling_dg = $(DIFFspec_directory+"yscaling_dg")
	
	variable /G $(DIFFspec_directory+"yoffset_dg")
	NVAR yoffset_dg = $(DIFFspec_directory+"yoffset_dg")

	variable /G $(DIFFspec_directory+"xshift_dg")
	NVAR xshift_dg = $(DIFFspec_directory+"xshift_dg")
	
	variable /G $(DIFFspec_directory+"x_incdg")
	NVAR x_incdg = $(DIFFspec_directory+"x_incdg")
	
	variable /G $(DIFFspec_directory+"y_incdg")
	NVAR y_incdg = $(DIFFspec_directory+"y_incdg")

	variable /G $(DIFFspec_directory+"diff_finish")
	NVAR diff_finish = $(DIFFspec_directory+"diff_finish")

	variable /G $(DIFFspec_directory+"dxmin_dg")
	NVAR dxmin_dg = $(DIFFspec_directory+"dxmin_dg")

	string /G $(DIFFspec_directory+"targetname")
	SVAR targetname = $(DIFFspec_directory+"targetname")

	silent 1; pauseupdate
	dxmin_dg = 1e-4 

	graphname=WinName(0,1)
	If (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	Else 
		wave specnamew= CsrWaveRef(B)
		specname=GetWavesDataFolder(specnamew,1)+"'"+csrwave(B)+"'"
		wave targetnamew=csrwaveref(A)
		targetname=GetWavesDataFolder(targetnamew,1)+"'"+csrwave(A)+"'"


		if((cmpstr(specname,"")==0) %| (cmpstr(targetname,"")==0)) 
			//	break
		else
			diffname=specname
			diffname = tools_addtowavename(diffname, "minus")
			diffname = tools_mycleanupstr(diffname)

			make /O $diffname 
			wave diffnamew=$diffname

			duplicate/O specnamew, diffnamew
			sprintf hstr, "wave = %s - %s; ",specname,targetname 
			note diffnamew, hstr 
			diff_finish=0 
			differencespec(specnamew,diffnamew,targetnamew)
		endif
	endif
end


static function differencespec(specname, diffname, targetname) 
	wave specname, diffname, targetname 
	string hstr
	
	make /O $( GetWavesDataFolder(targetname,1)+"tw2") /wave=tw2
	Duplicate/O targetname,tw2  

	NVAR yscaling_dg = $(DIFFspec_directory+"yscaling_dg")
	NVAR xshift_dg = $(DIFFspec_directory+"xshift_dg")
	NVAR x_incdg = $(DIFFspec_directory+"x_incdg")
	NVAR y_incdg = $(DIFFspec_directory+"y_incdg")
	NVAR diff_finish = $(DIFFspec_directory+"diff_finish")
	//NVAR dxmin_dg = $(DIFFspec_directory+"dxmin_dg")
	NVAR yoffset_dg = $(DIFFspec_directory+"yoffset_dg")

	variable  lyscaling_dg=1 
	variable  lxshift_dg=0.01
	variable  ly_incdg=0.01
	variable  lx_incdg=tools_round_dec( abs(deltax(specname)),10)/10
	variable lyoffset_dg = 0
	prompt lyscaling_dg, "Y scaling:"
	prompt lxshift_dg, "xshift_dg:"
	prompt ly_incdg, "y_incdg:"
	prompt lyoffset_dg, "y_offset:"
	prompt lx_incdg, "x_incdg:"
	doprompt "Diff Spec?", lyscaling_dg, lxshift_dg, ly_incdg, lyoffset_dg, lx_incdg
	yscaling_dg = lyscaling_dg
	xshift_dg = lxshift_dg
	y_incdg = ly_incdg
	x_incdg = lx_incdg
	yoffset_dg = lyoffset_dg
		
		
	display specname,diffname,tw2
	string windowname = S_name
	string tracesInGraph = TraceNameList(windowname, ";",1)
	ModifyGraph width=500,height=400

		
	controlbar 50  

	ModifyGraph rgb($StringFromList(0, tracesInGraph))=(0,0,65535),lsize($StringFromList(1, tracesInGraph))=2,rgb($StringFromList(1, tracesInGraph))=(3,52428,1);DelayUpdate
	//ModifyGraph rgb(specname)=(0,0,65535),lsize(diffname)=2,rgb(diffname)=(3,52428,1);DelayUpdate
	//ModifyGraph mode(tw2)=2,lsize(tw2)=2,zero(left)=1; delayupdate  
	ModifyGraph mode($StringFromList(2, tracesInGraph))=2,lsize($StringFromList(2, tracesInGraph))=2,zero(left)=1; delayupdate  
	sprintf hstr, "\\s(%s) reference Spectrum \r\\s(tw2) background spectrum\r\\s(%s) difference", StringFromList(0, tracesInGraph),StringFromList(1, tracesInGraph)
	Textbox/N=text0/F=0  hstr  
	SetVariable yfak,pos={5,27},size={130,20},title="y-scaling",format="%.4f" , limits={-INF,INF,y_incdg},proc=DiffVar,value=yscaling_dg
	SetVariable xshi,pos={140,27},size={120,20},title="x-shift",format="%.3f" , limits={-INF,INF,x_incdg},proc=DiffVar,value=xshift_dg
	SetVariable yoffset,pos={280,27},size={120,20},title="y-offset",format="%.3f" , limits={-INF,INF,y_incdg},proc=DiffVar,value=yoffset_dg
	Button fine pos={5,5},proc=DiffButtons,title="fine"
	Button coarse pos={65,5},proc=DiffButtons,title="coarse"
	Button finish pos={125,5},proc=DiffButtons,title="Save" 
	Button cancel, pos={185,5},proc=DiffButtons,title="Cancel" 
		
	diff_finish = wavedifference(specname,diffname,targetname,tw2,xshift_dg,yscaling_dg,yoffset_dg)
end


static function wavedifference(sw,dw,tw1,tw2,xs,yf,yoffset)  	
	wave sw,dw,tw1,tw2
	variable xs, yf, yoffset

	NVAR dxmin_dg = $(DIFFspec_directory+"dxmin_dg")
	variable xa_1, xa_2, xe_1, xe_2, xmin, xmax, xanf, xend, npt, dx, cx, cn   
	xa_1=leftx(sw) 
	xa_2=leftx(tw1) 
	xe_1=rightx(sw)
	xe_2=rightx(tw1)
	dx=tools_round_dec(deltax(sw),10) 
	xs=tools_round_dec(xs,10) 
	
	if(   ((xa_1>xe_1)*(xa_2>xe_2))   |   ((xa_1<xe_1)*(xa_2<xe_2)) )
	
		if (dx<0) 			
			xmax=xa_1 + dx* ceil(   - tools_round_dec( (xa_1-min(xa_1,xa_2+xs))/dx,10 )   )
			xmin=max(xe_1,xe_2+xs) 
			npt=ceil( dxmin_dg/10 + (xmin-xmax)/dx ) 
			xanf=xmax 
		else
			xmax=min(xe_1,xe_2+xs)
			xmin=xa_1 + dx* ceil(   tools_round_dec( (max(xa_1,xa_2+xs)-xa_1)/dx,10 )    ) 
			npt=ceil( dxmin_dg/10 + (xmax-xmin)/dx )  
			xanf=xmin 
		endif 
	
		xend=xanf+(npt-1)*dx
		
		Redimension/N=(npt) dw,tw2 
		SetScale/I x xanf,xend,"", dw,tw2  
		
		cn=0 
		do 
			tw2[cn]=yf*tw1(xanf-xs+cn*dx) + yoffset
			dw[cn]=sw(xanf+cn*dx)-tw2[cn] 
			cn+=1 
		while(cn < npt-1) 
		

	else 
		print "Error: different scaling of waves"
		dw=0 
	endif 
	
	return 0
end 


function DiffVar(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	NVAR yscaling_dg = $(DIFFspec_directory+"yscaling_dg")
	NVAR xshift_dg = $(DIFFspec_directory+"xshift_dg")
	SVAR targetname = $(DIFFspec_directory+"targetname")
	NVAR yoffset_dg = $(DIFFspec_directory+"yoffset_dg")
	string specname = getwavepathfromgraph(WaveRefIndexed("",0,1))
	string dname = getwavepathfromgraph(WaveRefIndexed("",1,1)) 
	string tw2 = getwavepathfromgraph(WaveRefIndexed("",2,1))
	wavedifference($specname,$dname,$targetname,$tw2,xshift_dg,yscaling_dg,yoffset_dg)
end


Function DiffButtons(ctrlName) : ButtonControl
	String ctrlName 

	NVAR yscaling_dg = $(DIFFspec_directory+"yscaling_dg")
	NVAR xshift_dg = $(DIFFspec_directory+"xshift_dg")
	NVAR x_incdg = $(DIFFspec_directory+"x_incdg")
	NVAR y_incdg = $(DIFFspec_directory+"y_incdg")
	NVAR diff_finish = $(DIFFspec_directory+"diff_finish")
	NVAR dxmin_dg = $(DIFFspec_directory+"dxmin_dg")
	NVAR yoffset_dg = $(DIFFspec_directory+"yoffset_dg")

	string wn = WinName(0,1)
	string specname = getwavepathfromgraph(WaveRefIndexed("",0,1))
	string dname = getwavepathfromgraph(WaveRefIndexed("",1,1))
	string tw2 = getwavepathfromgraph(WaveRefIndexed("",2,1))

	string hstr

	strswitch(ctrlname)
		case "fine":
			y_incdg/=10 
			x_incdg/=10 
			if (x_incdg<dxmin_dg) 
				x_incdg=dxmin_dg 
				print "minimal step size dx_min =",dxmin_dg  
			endif 
			SetVariable yfak limits={-INF,INF,y_incdg}
			SetVariable xshi limits={-INF,INF,x_incdg}
			SetVariable yoffset limits={-INF,INF,y_incdg}
			break
		case "coarse":
			y_incdg*=10 
			x_incdg*=10
			SetVariable yfak limits={-INF,INF,y_incdg}
			SetVariable xshi limits={-INF,INF,x_incdg}
			SetVariable yoffset limits={-INF,INF,y_incdg}
			break
		case "finish":
			diff_finish=0
			print dname 
			sprintf hstr, "y_scaling: %f;  x_shift: %f; y_offset: %f", yscaling_dg,xshift_dg, yoffset_dg
			note $dname, hstr
			diff_finish=0
			Dowindow/K $wn
			killwaves $tw2  
			break
		case "cancel":
			diff_finish=0
			diff_finish=0 
			Dowindow/K $wn 
			killwaves $tw2, $dname
			break
	endswitch
end
