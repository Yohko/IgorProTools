// Licence: GNU General Public License version 2 (GPLv2)
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Macros"
	submenu "Tools"
		"Change Image Color",tools_imagemanipulate("color")
	end
end


function tools_imagemanipulate(mode)
	string mode
	
	wave w_image = tools_checkimage()
	if(!WaveExists(w_image))
		return -1
	endif

	string tmp = ""
	string p_dir
	variable i=0, j=0
	WaveStats /Q w_image
	strswitch(mode)
		case "color":
			tools_updateColorRange(w_image)
			break
		default:
			abort mode+"not supported!"
			break
	endswitch
	
end


static function /wave tools_checkimage()
	string topGraphName = WinName(0, 1, 1)
	if (strlen(topGraphName) == 0)
		return $("") 
	endif
	string imagesInGraph = ImageNameList(topGraphName, ";")
	if (ItemsInList(imagesInGraph) == 0)
		Abort "No image is shown in the top graph"
	endif
	if (ItemsInList(imagesInGraph) > 1)
		Abort "More than one image is present; not yet supported"
	endif

	string imageName = StringFromList(0, imagesInGraph)
	wave imageWave = ImageNameToWaveRef(topGraphName, imageName)
	
	return imagewave
end


Function tools_updateColorRange(imgW,[minVal,maxVal,Range,changeScale])
	wave imgW
	String changeScale
	Variable minVal,maxVal,Range

	string scale =""
	string reversescale = ""
	prompt scale, "Scale: ",popup "Halcyon;Maple;Spectral;Rainbow2;MetroPro;Sky;Warm;Blend2;Warpp-spectral;Warpp-mono;Wyko;Zones;Cold;DFit;BW1;BW2;Saw1;Code-V;Shame;Blend1;Rainbow1"
	prompt reversescale, "Reverse: ", popup "No;Yes"	
	doprompt "Choose Color Scale!", scale, reversescale
	if(V_flag==1)
		print "Aborted!"
		return -1
	endif
	wave ctab = tools_loadGWYRGBA(scale)

	DFREF saveDF = GetDataFolderDFR()	  // Save
	
	string graphName= WinName(0,1,1)
	
	string newctab = addtowavename(nameofwave(imgw), "ct")
	newctab = GetWavesDataFolder(imgW,1)+"'"+UniqueName(newctab, 1,0)+"'"
	duplicate /O ctab, $newctab
	wave ctab = $newctab	
	
	if ( ParamIsDefault(changeScale) )
		changeScale="yes"
	endif
	
	WaveStats /Q imgW
	Variable trueWmin = V_min
	Variable trueWmax = V_max

	if ( ParamIsDefault(Range) )
		Range = trueWmax - trueWmin
	endif
	
	if ( ParamIsDefault(minVal) )
		minVal = trueWmin + 0.1* Range
	endif
	
	if ( ParamIsDefault(maxVal) )
		maxVal = trueWmax - 0.05 * Range
	endif

#if 0	
	if ( cmpstr(changeScale,"no")==0 )
		Variable/G ctabwMin
		Variable/G ctabwMax
	else
		Variable/G ctabwMin = minVal 
		Variable/G ctabwMax = maxVal 
	endif 
#endif

	variable ctabwMin =  0
	variable ctabwMax = 1
	strswitch(reversescale)
		case "Yes":
			ctabwMin = maxVal
			ctabwMax = minVal
			break
		case "No":
			ctabwMin = minVal
			ctabwMax = maxVal
			break
	endswitch

	SetScale/I x ctabwMin, ctabwMax,"", ctab
	
	ModifyImage /W=$graphName $tools_getimagename(0) cindex= ctab

	SetDataFolder saveDF
end


Function /WAVE tools_loadGWYRGBA(scale) 
	string scale

	variable levels = 65535
	variable range = 300
	make /FREE/O/W/U/N=(range,3) ctab
	
	// color gradients are taken from gwyddion (Gwyddion resource GwyGradient)
	make /O /N=(0) gradient
	strswitch(scale)
		case "BW1":
			note ctab, "Gwyddion BW1"
			gradient={{0,1,1,1},{0.111111,0,0,0},{0.222222,1,1,1},{0.333333,0,0,0},{0.444444,1,1,1},{0.555556,0,0,0},{0.666667,1,1,1},{0.777778,0,0,0},{0.888889,1,1,1},{1,0,0,0}}
			break
		case "BW2":
			note ctab, "Gwyddion BW2"
			gradient={{0,0,0,0},{0.09,0,0,0},{0.11,1,1,1},{0.19,1,1,1},{0.21,0,0,0},{0.29,0,0,0},{0.31,1,1,1},{0.39,1,1,1},{0.41,0,0,0},{0.49,0,0,0},{0.51,1,1,1},{0.59,1,1,1},{0.61,0,0,0},{0.69,0,0,0},{0.71,1,1,1},{0.79,1,1,1},{0.81,0,0,0},{0.89,0,0,0},{0.91,1,1,1},{1,1,1,1}}
			break
		case "Code-V":
			note ctab, "Gwyddion Code-V"
			gradient={{0,0.0196078,0.0196078,0.603922},{0.0894632,0,0.141176,0.752941},{0.17495,0,0.360784,0.835294},{0.264414,0.00392157,0.635294,0.811765},{0.355865,0,0.815686,0.65098},{0.449304,0.00392157,0.827451,0.329412},{0.544732,0.266667,0.839216,0},{0.636183,0.615686,0.866667,0},{0.727634,0.905882,0.886275,0},{0.819085,0.960784,0.635294,0.00392157},{0.916501,0.988235,0.356863,0},{1,0.913725,0.054902,0.0392157}}
			break
		case "Cold":
			note ctab, "Gwyddion Cold"
			gradient={{0,0,0,0},{0.3,0.168223,0.27335,0.488636},{0.5,0.196294,0.404327,0.606061},{0.7,0.3388,0.673882,0.77},{0.9,0.90909,0.909091,0.90909},{1,1,1,1}}
			break
		case "DFit":
			note ctab, "Gwyddion DFit"
			gradient={{0,0,0,0},{0.076923,0.43564,0.135294,0.5},{0.153846,0.87128,0.270588,1},{0.230769,0.93564,0.270588,0.729688},{0.307692,1,0.270588,0.459377},{0.384615,1,0.570934,0.364982},{0.461538,1,0.87128,0.270588},{0.538461,0.601604,0.906715,0.341219},{0.615384,0.203209,0.942149,0.41185},{0.692307,0.207756,0.695298,0.698082},{0.76923,0.212303,0.448447,0.984314},{0.846153,0.561152,0.679224,0.947157},{0.923076,0.90909,0.909091,0.90909},{1,1,1,1}}
			break
		case "Halcyon":
			note ctab, "Gwyddion Halcyon"
			gradient={{0,0,0,0},{0.25,0.010442,0.010442,0.380392},{0.375,0.611,0.200762,0.424466},{0.5,1,0.321569,0.321569},{0.625,1,0.585822,0.322},{0.75,1,0.911834,0.423529},{1,1,1,1}}
			break
		case "Maple":
			note ctab, "Gwyddion Maple"
			gradient={{0,0,0,0},{0.25,0.06976,0.380392,0.028343},{0.5,0.890196,0.844403,0.111711},{0.625,0.987,0.714125,0.209238},{0.75,1,0.523212,0.289},{0.875,1,0.6445,0.6445},{1,1,1,1}}
			break
		case "Spectral":
			note ctab, "Gwyddion Specral"
			gradient={{0,0,0,0},{0.090909,0.885,0.024681,0.017629},{0.181818,1,0.541833,0.015936},{0.272727,0.992157,0.952941,0.015686},{0.363636,0.51164,0.833,0.173365},{0.454545,0.243246,0.705,0.251491},{0.545455,0.332048,0.775843,0.795},{0.636364,0.019608,0.529412,0.819608},{0.727273,0.015686,0.047059,0.619608},{0.818182,0.388235,0.007843,0.678431},{0.909091,0.533279,0.008162,0.536},{1,0,0,0}}
			break
		case "Rainbow1":
			note ctab, "Gwyddion Rainbow1"
			gradient={{0,0,0,0},{0.125,1,0,0},{0.25,1,1,0},{0.375,0,1,1},{0.5,1,0,1},{0.625,0,1,0},{0.75,0,0,1},{0.875,0.5,0.5,0.5},{1,1,1,1}}
			break
		case "Rainbow2":
			note ctab, "Gwyddion Rainbow2"
			gradient={{0,0,0,0},{0.25,1,0,0},{0.5,0,1,0},{0.75,0,0,1},{1,1,1,1}}
			break
		case "MetroPro": // too long
			note ctab, "Gwyddion Rainbow2"
			gradient={{0,0,0.0313725,0.905882},{0.00229095,0,0.0313725,0.905882},{0.0652921,0,0.172549,0.827451},{0.119129,0,0.32549,0.678431},{0.183276,0,0.498039,0.501961},{0.233677,0,0.643137,0.356863},{0.304696,0,0.839216,0.160784},{0.369989,0.0705882,1,0},{0.430699,0.513725,1,0},{0.4937,0.964706,1,0},{0.575029,1,0.741176,0},{0.646048,1,0.529412,0},{0.717068,1,0.298039,0},{0.774341,1,0.121569,0},{0.841924,1,0.137255,0.137255},{0.899198,1,0.380392,0.380392},{0.954181,1,0.396078,0.396078},{1,1,0.396078,0.396078},{1,0.781247,0.316289,0.507591},{1,0.865812,0.347143,0.464485},{1,0.919127,0.366583,0.437308},{1,1,0.396078,0.396078}}
			break
		case "Saw1":
			note ctab, "Gwyddion Saw1"
			gradient={{0,0,0,0},{0.325171,0,0,1},{0.333333,0,0,0},{0.666667,1,0,0},{0.674829,0,0,0},{1,0,1,0}}
			break
		case "Shame":
			note ctab, "Gwyddion Shame"
			gradient={{0,0.031318,0.031318,0.167843},{0.25,0.25,0.25,0.295294},{0.5,0.5,0.285797,0.141000},{0.75,0.729412,0.160185,0.414663},{1,1,1,1}}
			break
		case "Sky":
			note ctab, "Gwyddion Sky"
			gradient={{0,0,0,0},{0.2,0.149112,0.160734,0.396078},{0.4,0.294641,0.391785,0.466667},{0.6,0.792157,0.476975,0.245413},{0.8,0.988235,0.826425,0.333287},{1,1,1,1}}
			break
		case "Warm":
			note ctab, "Gwyddion Warm"
			gradient={{0,0,0,0},{0.25,0.484848,0.188417,0.266572},{0.45,0.76,0.1824,0.1824},{0.6,0.87,0.495587,0.1131},{0.75,0.89,0.751788,0.1068},{0.9,0.90909,0.909091,0.90909},{1,1,1,1}}
			break
		case "Blend1":
			note ctab, "Gwyddion Blend1"
			gradient={{0,0,0,0},{0.2,0.388235,0.187535,0.009135},{0.3,0.329000,0.319111,0.268771},{0.4,0.222991,0.405319,0.490196},{0.6,0.232616,0.617000,0.223354},{0.8,0.925490,0.602476,0.853287},{1,1,1,1}}
			break
		case "Blend2":
			note ctab, "Gwyddion Blend2"
			gradient={{0,0,0,0},{0.053922,0.023529,0.054902,0.494118},{0.166667,0.023529,0.235294,0.360784},{0.279412,0.023529,0.352941,0.066667},{0.392157,0.025405,0.470000,0.025405},{0.504902,0.360784,0.705882,0.082353},{0.561275,0.589000,0.779000,0.057000},{0.617647,0.741176,0.729216,0.023529},{0.730392,0.741176,0.552941,0.023529},{0.843137,0.741176,0.400000,0.023529},{0.955882,0.741176,0.305882,0.023529},{1,0.833333,0.833333,0.833333}}
			break
		case "Warpp-mono":
			note ctab, "Gwyddion Warpp-mono"
			gradient={{0,0,0,0},{0.0874751,0.278431,0.0196078,0},{0.178926,0.545098,0.0784314,0},{0.270378,0.756863,0.172549,0},{0.363817,0.905882,0.290196,0},{0.455268,0.988235,0.431373,0},{0.550696,1,0.572549,0.00784314},{0.640159,1,0.705882,0.0901961},{0.735586,1,0.823529,0.239216},{0.829026,1,0.917647,0.45098},{0.916501,1,0.976471,0.705882},{1,1,0.996078,0.984314}}
			break
		case "Warpp-spectral":
			note ctab, "Gwyddion Warpp-spectral"
			gradient={{0,0.498039,0,0.498039},{0.0874751,0.294118,0.0431373,0.701961},{0.178926,0.121569,0.168627,0.87451},{0.270378,0.0196078,0.356863,0.976471},{0.363817,0.00392157,0.568627,0.992157},{0.457256,0.0745098,0.764706,0.921569},{0.548708,0.231373,0.921569,0.764706},{0.640159,0.427451,0.992157,0.568627},{0.735586,0.639216,0.976471,0.356863},{0.829026,0.823529,0.878431,0.172549},{0.916501,0.94902,0.713725,0.0470588},{1,0.996078,0.505882,0}}
			break
		case "Wyko":
			note ctab, "Gwyddion Wyko"
			gradient={{0,0.00392157,0.0431373,0.419608},{0.0874751,0.0745098,0.121569,0.756863},{0.178926,0.160784,0.286275,0.94902},{0.270378,0.247059,0.52549,0.988235},{0.363817,0.352941,0.788235,0.854902},{0.455268,0.454902,0.980392,0.592157},{0.550696,0.552941,0.988235,0.341176},{0.640159,0.647059,0.8,0.145098},{0.735586,0.733333,0.521569,0.0352941},{0.829026,0.807843,0.290196,0},{0.916501,0.909804,0.121569,0.00392157},{1,0.996078,0.0509804,0.0156863}}
			break
		case "Zones":
			note ctab, "Gwyddion Zones"
			gradient={{0,0,0,0},{0.115573,0.148,0.148,0.148},{0.125,0,0,0.315294},{0.239961,0,0,0.503529},{0.25,0.550196,0,0},{0.365328,0.752,0,0},{0.375,0.503,0,0.503},{0.489716,0.752,0,0.752},{0.5,0,0.597,0.597},{0.615083,0,0.799,0.799},{0.625,0,0.705,0},{0.740451,0,0.872549,0},{0.750,0.866187,0.872,0},{0.864838,0.993333,1,0},{0.875,0.819,0.819,0.819},{1,1,1,1}}
			break
		default:
			note ctab, "Default"
			gradient={{0,0,0,0},{1,1,1,1}}		
			break	
	endswitch
	variable steps = 0
	variable stepoff = 0

	make /FREE /N=(3) off
	make /FREE /N=(3) slope
	variable i = 0, j = 0, k = 0

	for(i=0;i<range;i+=1)
		if(i == round(steps+stepoff) && i< (range-1))
			for(k=0;k<3;k+=1)
				ctab[i][k] =  levels*gradient[k+1][j]
			endfor
			if(gradient[0][j+1] == 1) 
				steps = range - i // because of rounding errors
			else
				steps = round((gradient[0][j+1] - gradient[0][j])*(range))
			endif
			stepoff = i
			off[] = gradient[p+1][j]
			slope[] = (gradient[p+1][j+1]-gradient[p+1][j])/(steps-1)
			j+=1
			continue
		endif
		for(k=0;k<3;k+=1)
			ctab[i][k] =  levels*(off[k] +slope[k]*(i-stepoff))
		endfor
	endfor
	return ctab
end


static function  /S tools_getimagename(number)
	variable number
	string topGraphName = WinName(0, 1, 1)
	if (strlen(topGraphName) == 0)
		return ""
	endif
	string imagesInGraph = ImageNameList(topGraphName, ";")
	if (ItemsInList(imagesInGraph) == 0)
		Abort "No image is shown in the top graph"
	endif

	return StringFromList(number, imagesInGraph)
end
