// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"Normalize	v1", tools_normalize()
	end
end


function tools_normalize()
	string modus,show,minus1,areawave 
	prompt modus,"mode ?",popup,"absMax_absMin;cursA_cursB;absMax;cursAvg;cursMax;cursMaxBL;cursAPos;Area;absMin;XASlindiv;XASlinsub"
	prompt show,"show ?",popup,"No;Yes"
	prompt minus1,"minus 1 ?",popup,"No;Yes"
	
	doprompt "Flags!", modus, show, minus1
	if(V_flag==1)
		print "Aborted!"
		return -1
	endif

	variable specnum=0,cA,cB,factor
	string graphname,sn,srn,notestr   	
	graphname=WinName(0,1)
	if (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	else
		if(strsearch(modus,"curs",0)>-1)
			cA=xcsr(A); cB=xcsr(B) 
		endif  
	
		string tracesInGraph = TraceNameList("", ";",1+4) // only visible normal traces
		variable m = ItemsInList(tracesInGraph)
		for( specnum = 0; specnum < m; specnum += 1 )
			if (specnum == m)
				break
			endif

					
			sn=GetWavesDataFolder(WaveRefIndexed(graphname,specnum,1),2)
			wave snw=$sn
			if (strsearch(sn[strlen(sn)-1,strlen(sn)],"'",0) ==0)
				srn= sn[0,strlen(sn)-2]+"N'"
			else
				srn=sn+"N"
			endif
			duplicate /O snw, $srn
			wave srnw=$srn
			print "Wave to norm: ", srn
			duplicate/O snw srnw 
			
			strswitch(modus)
				case "absMax":
					WaveStats/Q snw
					factor = V_max
					Print "Offset: ", 0
					notestr="|Max| normalized to 1"
					break
				case "absMin":
					WaveStats/Q snw
					Print "Offset: ",V_min
					factor = 1
					srnw -= V_min
					notestr="Min to 0"
					break
				case "absMax_absMin":
					WaveStats/Q snw
					factor = V_max -V_min
					srnw -=V_min
					Print "Offset: ", V_min
					notestr="Normalized 0 .. 1"
					break
				case "cursMax":
					WaveStats/Q/R=(cA,cB) snw
					Print "Offset: ", 0
					factor = V_max
					notestr="Normalized 0 .. 1 between"+num2str(cA)+" and "+num2str(cB) 
					break
				case "cursMaxBL":
					WaveStats/Q/R=(cA,cB) snw
					Print "Offset: ", 0
					factor = ( V_max- ( vcsr(A) + (V_maxloc-cA)*(vcsr(B)-vcsr(A))/(cB-cA) ) ) 
					notestr="Normalize to Max-Baseline between "+num2str(cA)+" and "+num2str(cB) 
					break
				case "cursAvg":
					WaveStats/Q/R=(cA,cB) snw
					factor = V_avg 
					Print "Offset: ", 0
					notestr="Avg to 1 between "+num2str(cA)+" and "+num2str(cB) 
					break
				case "cursApos":
					factor = snw(cA)  
					notestr="Normalized x= "+num2str(cA) +" to 1"
					break
				case "cursA_cursB":
					//factor = ($sn(cA)-$sn(cB)) 
					factor = (snw(cB)-snw(cA)) 
					Print "Offset: ",(snw(cA))
					srnw =srnw-snw(cA)
					notestr="Normalized y(" + num2str(cA) + ")-y(" + num2str(cB) + ") to 1"
					break  
				case "Area":
						print "Not yet done!"
						break
				case "XASlindiv":
					wave w_y = WaveRefIndexed(graphname,specnum,1)
					if(waveexists(WaveRefIndexed(graphname,specnum,2)))
						wave w_x = WaveRefIndexed(graphname,specnum,2)
						CurveFit/Q/M=2/W=0 line, w_y[pcsr(A),pcsr(B)]/X=w_x[pcsr(A),pcsr(B)]
						Wave W_coef
						srnw[] /=(w_coef[0]+w_coef[1]*w_x[p])
					else
						CurveFit/Q/M=2/W=0 line, w_y[pcsr(A),pcsr(B)]
						Wave W_coef
						srnw[] /=(w_coef[0]+w_coef[1]*x)
					endif
					srnw -=1
					minus1 = "No"
					WaveStats/Q snw
					factor = srnw[dimsize(srnw,0)-1]
					break
				case "XASlinsub":
					wave w_y = WaveRefIndexed(graphname,specnum,1)
					if(waveexists(WaveRefIndexed(graphname,specnum,2)))
						wave w_x = WaveRefIndexed(graphname,specnum,2)
						CurveFit/Q/M=2/W=0 line, w_y[pcsr(A),pcsr(B)]/X=w_x[pcsr(A),pcsr(B)]
						Wave W_coef
						srnw[] -=(w_coef[0]+w_coef[1]*w_x[p])
					else
						CurveFit/Q/M=2/W=0 line, w_y[pcsr(A),pcsr(B)]
						Wave W_coef
						srnw[] -=(w_coef[0]+w_coef[1]*x)		
					endif
					//srnw -=1
					//minus1 = "No"
					WaveStats/Q snw
					factor = srnw[dimsize(srnw,0)-1]
					break
			endswitch	

			if (cmpstr(minus1,"Yes")==0) 
					srnw-=1 
			endif 
				
			Print "factor: ",factor
			Print "1/factor: ",(1/factor)
			srnw /= factor
			//notestr = notestr + "; /=" + num2str(factor) 
			//note $srn,notestr 
			if (cmpstr(show,"Yes")==0) 
				if (specnum==0) 
					Display srnw
				else 
					AppendToGraph srnw
				endif  
			endif 
			specnum=specnum+1 
		endfor
	endif
end
