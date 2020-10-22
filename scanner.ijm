function extrapolate(x,y,d){
		coord = newArray;
		yStart = 0;
		yEnd = getHeight;
		rectAngle = (d+90)*PI/180;
		xEnd = x-((yEnd-y)/tan(rectAngle));
		xStart = x+((y-yStart)/tan(rectAngle));
		coord[0] = xStart;
		coord[1] = yStart;
		coord[2] = xEnd;
		coord[3] = yEnd;
		return coord;
	};

macro "Scanner [f2]" {
	setBatchMode(true);
	setOption("ExpandableArrays", true);
	roiManager("reset");

	//Read_in_directory
	//-----------------
		dir = getDirectory("");
		allFil = getFileList(dir);
	//-----------------
	
	//Print_colnames
	//--------------
		headline = "source	" + "file	" + "step	" + "x_coord	" + "y_coord	" + "mean";
		print("\\Clear");
		print(headline);
	//--------------

	//Loop_through_all_files
	//----------------------
		for(f=0; f<allFil.length; f++){
			roiManager("reset");
			
			if(endsWith(allFil[f], "_GFP.JPG")){
				
				//Open phase & roi
				//-------------------------
					gfp = allFil[f];
					open(gfp);
							
					run("Split Channels");
					selectWindow(gfp + " (red)");
					close();
					selectWindow(gfp + " (blue)");
					close();
					
					grCh = gfp + " (green)";
					selectWindow(grCh);
		
					roi = dir + replace(gfp, "_GFP.JPG","_Phase.roi");
					if(File.exists(roi)){
						open(roi);
						roiManager("Add");
					} else {
						continue;
					};
				//-------------------------

				//Original_ROI
				//------------
					selectWindow(grCh);
				   	roiManager("Select", 0);
				   	run("Create Mask");
				   	rename("Mask1");
				   	mask1 = getImageID();
				//------------ 

				//Read_out_overview_stats
				//-----------------------
					selectWindow(grCh);
					roiManager("Select", 0);
					getRawStatistics(count, mean, min, max, std);
					row = nResults;
					label = dir + gfp;
					setResult("Label", row, label);
					setResult("Pixels", row, count);
					setResult("Mean ", row, mean);
					setResult("Std ", row, std);
					setResult("Min ", row, min);
					setResult("Max ", row, max);
					updateResults();
				//-----------------------
 				
				//Feret_Diameter
				//--------------
				  	//List.setMeasurements;
				  	//x1 = List.getValue("FeretX");
				  	selectWindow(grCh);
				  	roiManager("Select", 0);
					x1 = getValue("FeretX");
					y1 = getValue("FeretY");
					length = getValue("Feret");
					degrees = getValue("FeretAngle");
					if (degrees>90){
						degrees -= 180; 
					};
					angle = degrees*PI/180;
					x2 = x1 + cos(angle)*length;
					y2 = y1 - sin(angle)*length;
				//--------------

				//Create_coordinate_arrays
				//------------------------
					xLoc = newArray;
					yLoc = newArray;
					sl = (x2-x1)/(y2-y1);
					if (sl>1 || sl<-1){
						ints = x2-x1;
						for(i=0; i<=ints; i++){
							xCur=x1+i;
							yCur=y1-((xCur-x1)*tan(angle));
							yCur=round(yCur);
							xLoc[i] = xCur;
							yLoc[i] = yCur;
						};
					} else if (sl<1 && sl>0){
						ints=y2-y1;
						for(i=0; i<=ints; i++){
							yCur=y1+i;
							xCur=x1+((y1-yCur)/tan(angle));
							xCur=round(xCur);
							xLoc[i] = xCur;
							yLoc[i] = yCur;
						};
					} else if (sl<0 && sl>-1){
						ints=y1-y2;
						for(i=0; i<=ints; i++){
							yCur=y1-i;
							xCur=x1+((y1-yCur)/tan(angle));
							xCur=round(xCur);
							xLoc[i] = xCur;
							yLoc[i] = yCur;
						};
					};
				//------------------------

				//Run_through_all_intersections
				//-----------------------------
					for(j=0; j<xLoc.length; j++){

						output = "" + dir + "	" + gfp + "	" + j + "	" + xLoc[j] + "	" + yLoc[j];
						coord = extrapolate(xLoc[j],yLoc[j],degrees);

						selectWindow(grCh);
						makeRotatedRectangle(coord[0], coord[1], coord[2], coord[3],1);
						roiManager("Add");

						selectWindow(grCh);
						roiManager("Select", 1);
						run("Create Mask");
						rename("Mask2");
						mask2 = getImageID();

						imageCalculator("AND", mask2, mask1);
						run("Create Selection");
						selectWindow(grCh);
						run("Restore Selection");
						roiManager("Add");

						selectWindow(grCh);
						roiManager("Select", 2);
					   	my = getValue("Mean");
					   	output = output + " " + my;
					   	print(output);

					  	roiManager("Select", 2);
					  	roiManager("Delete");
					  	roiManager("Select", 1);
					  	roiManager("Delete");
					  	selectWindow("Mask2");
						close();

					};
				//-----------------------------
				
				//Close_window
				//------------
					selectWindow(grCh);
					roiManager("Select", 0);
					roiManager("Delete");
					selectWindow(grCh);
					close();
					selectWindow("Mask1");
					close();
					continue;
				//------------

			} else {
				continue;
			};

		};
		close("*");
		selectWindow("Log");

	};