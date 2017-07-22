// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"XPS SatRem", tools_XPSSatRem()
	end
end


function tools_XPSSatRem()
	string source,show 
	prompt source,"Photon Source",popup,"AlKa;MgKa;HeI;HeII"
	prompt show,"show ?",popup,"Yes;No"

	doprompt "Flags!", source, show
	if(V_flag==1)
		print "Aborted!"
		return -1
	endif

	variable specnum,point_delta,satcount,dlf,lx,rx , tmpD
	string graphname,sn,srn,notestr, tmpS
	silent 1; pauseupdate 

	sprintf notestr,"%s-removed satellite lines",source

	make /FREE/N=2/O delta
	make /FREE/N=2/O factor
	make /FREE/N=2/O sh

	strswitch(source)
		case "AlKa":
			satcount=2
			delta={9.8,11.8}
			factor={0.064,0.032}
			break
		case "MgKa":
			satcount=2 
			delta={8.4,10.2}
			factor={0.08,0.041}
			break
		case "HeI":
			satcount=2 
			delta={1.87,2.52}
			factor={0.015,0.005}
			break
		case "HeII":		// does not work perfectly 
			satcount=1 
			delta={7.56}
			factor={0.07} 	
			break
	endswitch
	
	graphname=WinName(0,1)
	if (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	else
		string tracesInGraph = TraceNameList("", ";",1+4) // only visible normal traces
		variable m = ItemsInList(tracesInGraph)
		for(specnum=0;specnum<m;specnum+=1)
			sn = ""
			
			if(WaveExists(WaveRefIndexed(graphname,specnum,1)))
				sn=GetWavesDataFolder(WaveRefIndexed(graphname,specnum,1),2)
			else
				break
			endif
			if(strlen(sn)==0)
				break
			else
				Wavestats/Q $sn
				if(strsearch(sn[strlen(sn)-1,strlen(sn)],"'",0) ==0)
					srn= sn[0,strlen(sn)-2]+"Sr'"
				else
					srn=sn+"Sr"
				endif
				print srn
//				if(strsearch(sn[strlen(sn)-1,strlen(sn)],"'",0) ==0)
//					sh= sn[0,strlen(sn)-2]+"Sh'"
//				else
//					sh=sn+"Sh"
//				endif

				duplicate/O $sn $srn 
				duplicate/O $sn sh
				wave srnw=$srn
				wave snw=$sn
				srnw=0
				rx=pnt2x($sn,V_npnts-1)
				lx=leftx($sn)
				dlf=1
				do 
					point_delta=abs(round(delta[dlf-1]/(rx-lx)*V_npnts)) 
					sh=snw[1] 
					sh[point_delta,V_npnts-1]+=snw[p-point_delta]-snw[1] 
					sh*=factor[dlf-1] 
					srnw=sh+srnw
					dlf=dlf+1
				while(dlf<=satcount)
				srnw=snw-srnw 
				if (cmpstr(show,"Yes")==0) 
					if (specnum==0) 
						Display srnw 
					else 
						AppendToGraph srnw
					endif  
				endif 
				note srnw,notestr 
			endif 
		endfor
	endif
end
