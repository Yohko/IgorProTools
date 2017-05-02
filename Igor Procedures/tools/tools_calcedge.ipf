// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"Calculate edge position AB, CD", tools_calcedge()
	end
end


function tools_calcedge()
	string graphname,sn,srn,notestr
	graphname=WinName(0,1)
	If (cmpstr(graphname,"")==0)
		doalert 0,"no graphwindow"
	Else
		if(strlen(CsrInfo(A)) > 0 && strlen(CsrInfo(B)) > 0 && strlen(CsrInfo(C)) > 0 && strlen(CsrInfo(D)) > 0)
			wave specnamew = CsrWaveRef(A)
			wave specnamewx = CsrXWaveRef(A)
			print nameofwave(specnameW)
			if(waveexists(specnamewx))
				CurveFit /Q line specnamew[pcsr(A),pcsr(B)] /X=specnamewx[pcsr(A),pcsr(B)] /D
			else
				CurveFit /Q line specnamew[pcsr(A),pcsr(B)] /D
			endif
			duplicate /O $("fit_"+nameofwave(specnameW)), $("fitedge_01")
			Wave W_coef
			Wave W_sigma
			
			
			variable a1 = W_coef[0]
			variable b1 = W_coef[1]
			variable a1e = W_sigma[0]
			variable b1e = W_sigma[1]
			if(waveexists(specnamewx))
				CurveFit /Q line specnamew[pcsr(C),pcsr(D)] /X=specnamewx[pcsr(C),pcsr(D)] /D
			else
				CurveFit /Q line specnamew[pcsr(C),pcsr(D)] /D
			endif
			duplicate /O $("fit_"+nameofwave(specnameW)), $("fitedge_02")
			variable a2 = W_coef[0]
			variable b2 = W_coef[1]
			variable a2e = W_sigma[0]
			variable b2e = W_sigma[1]

			
			print "edge position:",(a1-a2)/(b2-b1)
			print "error:",(abs((a1e)/(b2-b1))+abs((a2e)/(b2-b1))+abs((a1-a2)*b2e/(b2-b1)^2)+abs((a1-a2)*b1e/(b2-b1)^2))
			
			
			variable stretch = 0
			DrawAction /W=$graphname getgroup=calcedge, delete	
			SetDrawEnv /W=$graphname gstart,gname=calcedge
			SetDrawEnv /W=$graphname xcoord=bottom, ycoord = left
			
			if(hcsr(A)>hcsr(B))
				DrawLine /W=$graphname hcsr(A)*(1-stretch), a1+b1*hcsr(A)*(1-stretch), hcsr(B)*(1+stretch), a1+b1*hcsr(B)*(1+stretch)		
			else
				DrawLine /W=$graphname hcsr(B)*(1-stretch), a1+b1*hcsr(B)*(1-stretch), hcsr(A)*(1+stretch), a1+b1*hcsr(A)*(1+stretch)
			endif

			SetDrawEnv /W=$graphname xcoord=bottom, ycoord = left
			
			if(hcsr(C)>hcsr(D))
				DrawLine /W=$graphname hcsr(C)*(1-stretch), a2+b2*hcsr(C)*(1-stretch), hcsr(D)*(1+stretch), a2+b2*hcsr(D)*(1+stretch)
			else
				DrawLine /W=$graphname hcsr(D)*(1-stretch), a2+b2*hcsr(D)*(1-stretch), hcsr(C)*(1+stretch), a2+b2*hcsr(C)*(1+stretch)
			endif	
			SetDrawEnv /W=$graphname gstop
		else
			print "Expected cursor A, B, C and D!"
		endif		
	endif
end
