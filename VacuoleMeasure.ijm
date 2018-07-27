dir = getDirectory("Choose input Original Directory "); 
list = getFileList(dir);  

dir2 = getDirectory("Choose input Output Directory ");
setBatchMode(true);   



for (f=0; f<list.length; f++) 
{
//Block of Code for Meausuring Area of Vacuoloes
showProgress(f, list.length);     // optional progress monitor displayed at top of Fiji
path = dir+list[f]; 

if (!endsWith(path,"/")) open(path);  // if subdirectory, push down into it Still have to open Path				
t=getTitle();
run("Duplicate...", " ");
rename(t);
run("8-bit");
run("Gray Morphology", "radius=18 type=circle operator=open");
//setAutoThreshold("Default dark");
//run("Threshold...");
setThreshold(200, 255);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Analyze Particles...", "size=18-Infinity circularity=0.7-1.00 show=Outlines display summarize add");
selectWindow(t);
roiManager("Show All");
run("Measure");
selectWindow("Results");
saveAs(dir2+"results.txt");
close();
roiManager("reset");

//Block of Code for Measuring Tissue Area 
selectWindow(t);
run("8-bit");
run("Gaussian Blur...", "sigma=10");
setAutoThreshold("Default dark");
//run("Threshold...");
//setThreshold(0, 235);
run("Convert to Mask");
run("Fill Holes");
run("Analyze Particles...", "size=30-Infinity circularity=0.0-1.00 show=Outlines display summarize add");
selectWindow(t);
roiManager("Show All");
run("Measure");
selectWindow("Results");
saveAs(dir2+"results.txt");
close();
roiManager("reset");
}

selectWindow("Results");
saveAs(dir2+"results.txt");
selectWindow("Log");
saveAs(dir2+"log1.txt");
selectWindow("Summary");
saveAs(dir2+"sumamry1.txt");
