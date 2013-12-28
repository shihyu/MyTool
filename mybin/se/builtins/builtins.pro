;   The PV-WAVE compiler will not compile this file.
;   This file is here to proved Auto Function Help for
;   built-ins PV-WAVE functions
;
;   For better documentation, we allow some minor deviations from
;   the PV-WAVE language.  Our deviations are as follows
;
;        Any argument may be in quotes
;        ...              Means this is the last argument
;        ...variable      Means this is the last argument
;        ...,variable     Does not work
;        [argument_list]  Indicates optional arguments.
;            Example
;                 FUNCTION F,array[,dim]
;                 FUNCTION F,[array[,dim]]
;
;            The following is NOT VALID because the [
;            appears before the function name
;
;
;                 FUNCTION F[,array[,dim]]    <-- Does not work
;
;
;
FUNCTION abs,x
END
FUNCTION acos,x
END
PRO ADDVAR,name,local
END
FUNCTION ALOG,x
END
FUNCTION ALOG10,x
END
FUNCTION ASARR,key1,value1,key2,value2,...
END
FUNCTION ASARR,keys_arr,values_arr
END
FUNCTION ASIN,x
END
FUNCTION ASKEYS,asarr
END
FUNCTION ASSOC,unit,array_structure[,offset]
END
FUNCTION ATAN,y[,x]
END
;FUNCTION AVG,array[,dim]
;END
PRO AXIS,[[[x],y],z],XAxis=XAxis,YAxis=YAxis,ZAxis=ZAxis
END
FUNCTION BESELI,x [, n]
END
FUNCTION BESELJ,x[,n]
END
FUNCTION BESELY,x[,n]
END
;FUNCTION BILINEAR,array, x, y
;END
FUNCTION BINDGEN,dim1[,dim2,...dimN]
END
PRO BREAKPOINT,file, line,Allclear=Allclear,Clear=Clear,Set=Set
END
FUNCTION BUILD_TABLE,' var1 [alias1], ..., varN [aliasN] '
END
;FUNCTION BUILDRESOURCEFILENAME,file,Appdir=Appdir,Subdir=Subdir
;END
FUNCTION BYTARR,dim1[,dim2,dir3,...dirN]
END
FUNCTION BYTE,expr
END
FUNCTION BYTE,expr,offset[,dim1,dim2,...dimN]
END
PRO BYTEORDER,variable1, variable2,...variableN,Htonl=Htonl,Htons=Htons,Lswap=LSwap,Ntohl=Ntohs,Sswap=Sswap
END
FUNCTION BYTSCL,array,Max=Max,Min=Min,Top=Top
END
FUNCTION CALL_UNIX,p1[,p2,...p30]
END
;PRO C_EDIT,colors_out,Hls=Hls,Hsv=Hsv
;END
PRO CD,directory,Current=Current
END
;PRO CENTER_VIEW,Ax=Ax,Ay=Ay,Az=Az,Persp=Persp,Winx=Winx,Winy=Winy,Xr=Xr,Yr=Yr,Zr=Zr,Zoom=Zoom
;END
;FUNCTION CHEBYSHEV,data, ntype
;END
FUNCTION CHECK_MATH,[print_flag, message_inhibit],Trap=Trap
END
FUNCTION CHECKFILE,filename,FullName=FullName,Is_Dir=Is_Dir,Read=Read,Size=Size,Write=Write
END
FUNCTION CINDGEN,dim1[,dim2,...dimN]
END
PRO CLOSE,[unit1,unit2,...unitN],All=All,Files=Files
END
PRO COLOR_CONVERT,i0, i1, i2, o0, o1, o2, keyword,CMY_RGB=CMY_RGB,HLS_RGB=HLS_RGB,HSV_RGB=HSV_RGB,RGB_CMY=RGB_CMY,RGB_HLS=RGB_HLS,RGB_HSV=RGB_HSV
END
;PRO COLOR_EDIT,[colors_out],HLS=HLS,HSV=HSV
;END
;PRO COLOR_PALETTE,
;END
PRO COMPILE,routine1[routine2,...routineN],All=All,Filename=Filename,Verbose=Verbose
END
FUNCTION COMPLEX,real[, imaginary]
END
FUNCTION COMPLEX,expr,offset[,dim1,dim2,...dimN]
END
FUNCTION COMPLEXARR,dim1[,dim2,...dimn],Nozero=Nozero
END
;FUNCTION CONE,Color=Color,Decal=Decal,Kamb=Kamb,Kdiff=Kdiff,Ktran=Ktran,Radius=Radius,Transform=Transform
;END
;FUNCTION CONGRID,image,col,row,Interp=Interp
;END
FUNCTION CONJ,x
END
PRO CONTOUR,z[,x,y],Background=Background,Channel=Channel,Charsize=Charsize,Charthick=Charthick,Clip=Clip,Color=Color,C_Annotation=C_Annotation,C_Charsize=C_Charsize,C_Colors=C_Colors,C_Labels=C_Labels,C_Linestyle=C_Linestyle,C_Thick=C_Thick,Data=Data,Device=Device,Follow=Follow,Font=Font,Gridstyle=Gridstyle,Levels=Levels,Max_Value=Max_Value,NLevels=NLevels,Noclip=Noclip,Nodata=Nodata,Noerase=Noerase,Normal=Normal,Overplot=Overplot,Path_Filename=Path_Filename,Position=Position,Spline=Spline,Subtitle=Subtitle,T3d=T3d,Thick=Thick,Tickformat=Tickformat,Ticklen=Ticklen,Title=Title,[XYZ]Charsize=[XYZ]Charsize,[XYZ]Gridstyle=[XYZ]Gridstyle,[XYZ]Margin=[XYZ]Margin,[XYZ]Minor=[XYZ]Minor,[XYZ]Range=[XYZ]Range,[XYZ]Style=[XYZ]Style,[XYZ]Tickformat=[XYZ]Tickformat,[XYZ]Ticklen=[XYZ]Ticklen,[XYZ]Tickname=[XYZ]Tickname,[XYZ]Ticks=[XYZ]Ticks,[XYZ]Tickv=[XYZ]Tickv,[XYZ]Title=[XYZ]Title,[XYZ]Type=[XYZ]Type,ZAxis=ZAxis,ZValue=ZValue,
END
;PRO CONTOURFILL,filename,z[,x,y],Color_Index=Color_Index,Delete_File=Delete_File,XRange=XRange,YRange=YRange,
;END
;FUNCTION CONV_FROM_RECT,vec1,vec2,vec3,Cylin=Cylin,Degrees=Degrees,Global=Global,Polar=Polar,Sphere=Sphere
;END
;FUNCTION CONV_TO_RECT,vec1,vec2,vec3,Cylin=Cylin,Degrees=Degrees,Global=Global,Polar=Polar,Sphere=Sphere
;END
FUNCTION CONVERT_COORD,points
END
FUNCTION CONVERT_COORD,x, y [, z],T3d=T3d,Data=Data,Device=Device,Normal=Normal,To_Data=To_Data,To_Device=To_Device,To_Normal=To_Normal
END
FUNCTION CONVOL,array, kernel [, scale_factor]
END
FUNCTION COS,x
END
FUNCTION COSH,x
END
PRO CREATE_HOLIDAYS, dt_list
END
PRO CREATE_WEEKENDS,day_names
END
FUNCTION CROSSP,v1,v2
END
PRO CURSOR,x, y[, wait],Changes=Changes,Data=Data,Device=Device,Down=Down,Normal=Normal,Nowait=Nowait,Up=Up,Wait=Wait
END
FUNCTION CURVEFIT,x,y,wt,parms[,sigma]
END
FUNCTION CYLINDER,Color=Color,Decal=Decal,Kamb=Kamb,Kdiff=Kdiff,Ktran=Ktran,Transform=Transform
END
FUNCTION DAY_OF_WEEK,dt_var,
END
FUNCTION DAY_OF_YEAR,dt_var
END
FUNCTION DBLARR,dim1[,dim2...dimN],Nozero=Nozero
END
FUNCTION DC_ERROR_MSG,status
END
FUNCTION DC_OPTIONS,msg_level
END
FUNCTION DC_READ_8_BIT,filename, imgarr,XSize=XSize,YSize=YSize
END
FUNCTION DC_READ_24_BIT,filename, imgarr,Org=Org,XSize=XSize,YSize=YSize
END
FUNCTION DC_READ_CONTAINER,filename, var_name,End_record=End_record,Extend=Extend,Start_record=Start_record
END
FUNCTION DC_READ_DIB,filename, imgarr,Colormap=Colormap,ColorsUsed=ColorsUsed,Compression=Compression,ImageHeight=ImageHeight,ImageWidth=ImageWidth,ImportantColors=ImportantColors,XResolution=XResolution,YResolution=YResolution
END
FUNCTION DC_READ_FIXED,filename,var_list,Bytes_Per_Rec=Bytes_Per_Rec,Column=Column,Dt_Template=Dt_Template,Filters=Filters,Format=Format,Ignore=Ignore
END
FUNCTION DC_READ_FREE,filename, var_list,Column=Column,Delim=Delim,Dt_Template=Dt_Template,Filters=Filters,Get_Columns=Get_Columns,Ignore=Ignore
END
FUNCTION DC_READ_TIFF,filename, imgarr,BitsPerSample=BitsPerSample,Colormap=Colormap,Compression=Compression,Imagelength=Imagelength,Imagewidht=Imagewidht,ImgNum=ImgNum,Order=Order,PhotometricInterpretation=PhotometricInterpretation,PlanarConfig=PlanarConfig,ResolutionUnit=ResolutionUnit,SamplesPerPixel=SamplesPerPixel,XResolution=XResolution,YResolution=YResolution
END
FUNCTION DC_SCAN_CONTAINER,filename,num_variables,start_records,end_records
END
FUNCTION DC_WRITE_8_BIT,filename,imgarr
END
FUNCTION DC_WRITE_24_BIT,filename,imgarr,Org=Org
END
FUNCTION DC_WRITE_DIB,filename, imgarr,ColorClass=ColorClass,ColorsUsed=ColorsUsed,Compression=Compression,ImportantColors=ImportantColors,Palette=Palette,SystemPalette=SystemPalette
END
FUNCTION DC_WRITE_FIXED,filename,var_list,Column=Column,Dt_Template=Dt_Template,Format=Format,Miss_Str=Miss_Str,Miss_Vals=Miss_Vals,Row=Row
END
FUNCTION DC_WRITE_FREE,filename,var_list,Column=Column,Delim=Delim,Dt_Template=Dt_Template,Miss_Str=Miss_Str,Miss_Vals=Miss_Vals,Row=Row
END
FUNCTION DC_WRITE_TIFF,filename, imgarr,Class=Class,Compress=Compress,Negative=Negative,Order=Order,Palette=Palette,Threshold=Threshold
END
PRO DEFINE_KEY,key[,value],Back_Character=Back_Character,Back_Word=Back_Word,Delete_Character=Delete_Character,Delete_Forward_Char=Delete_Forward_Char,Delete_Line=Delete_Line,Delete_To_EOL=Delete_To_EOL,Delete_Word=Delete_Word,End_Of_Line=End_Of_Line,Enter_Line=Enter_Line,Escape=Escape,Forward_Character=Forward_Character,Forward_Word=Forward_Word,Insert_Overstrike_Toggle=Insert_Overstrike_Toggle,Match_Previous=Match_Previous,Next_Line=Next_Line,Noecho=Noecho,Previous_Line=Previous_Line,Redraw=Redraw,Start_Of_Line=Start_Of_Line,Terminate=Terminate
END
FUNCTION DEFROI,sizex,sizey[,xverts,yverts],Noregion,Xo=Xo,Yo=Yo,Zoom=Zoom
END
PRO DEFSYSV, name, value [, read_only]
END
PRO DEL_FILE,filename
END
PRO DELETE_SYMBOL,name,Type=Type
END
PRO DELFUNC,procedure1[,...procedureN],All=All
END
PRO DELPROC,procedure1[,...procedureN],All=All
END
PRO DELLOG,logname,Table=Table
END
PRO DELSTRUCT,{structure1}[,{structure2},...{structureN}]
END
PRO DELVAR,var1[,var2,...varN]
END
;FUNCTION DERIV,[x,]y 
;END
FUNCTION DETERM,array
END
PRO DEVICE
END
FUNCTION DIGITAL_FILTER,flow, fhigh, gibbs, nterm,
END
FUNCTION DILATE,image, structure [, x0, y0],Gray=Gray,Values=Values
END
FUNCTION DINDGEN,dim1[,dim2,...dimN]
END
FUNCTION DIST,n
END
FUNCTION DOC_LIBRARY,[name],Directory=Directory,File=File,Multi=Multi,Path=Path,Print=Print
END
FUNCTION DOUBLE,expr
END
FUNCTION DOUBLE,expr,offset[,dim1,...dimN]
END
PRO DROP_EXEC_ON_SELECT,lun
END
FUNCTION DT_ADD,dt_var
END
FUNCTION DT_COMPRESS,dt_array
END
FUNCTION DT_DURATION,dt_var_1, dt_var_2,Compress=Compress
END
PRO DT_PRINT,dt_var
END
FUNCTION DT_SUBTRACT,dt_var,Compress=Compress,Day=Day,Hour=Hour,Minute=Minute,Month=Month,Second=Second,Year=Year
END
FUNCTION DT_TO_SEC,dt_var,Base=Base,Date_Fmt=Date_Fmt
END
PRO DT_TO_STR,dt_var, [, dates] [, times],Date_Fmt=Date_Fmt,Time_Fmt=Time_Fmt
END
PRO DT_TO_VAR,dt_var,Year=Year,Month=Month,Day=Day,Hour=Hour,Minute=Minute,Second=Second
END
FUNCTION DTGEN,dt_start, dimension,Compress=Compress,Day=Day,Hour=Hour,Minute=Minute,Second=Second,Year=Year
END
PRO EMPTY
   
END
FUNCTION ENVIRONMENT
END
FUNCTION EOF,unit
END
PRO ERASE,[background_color],Channel=Channel,Color=Color
END
FUNCTION ERODE,image, structure [, x0, y0],Gray=Gray,Values=Value
END
FUNCTION ERRORF,image, structure [, x0, y0],Gray=Gray,Values=Value
END
FUNCTION ERRPLOT,[points],low,high,Width=Width
END
PRO EXEC_ON_SELECT,luns,commands,Widget=Widget,Just_reg=Just_reg
END
FUNCTION EXECUTE,string
END
PRO EXIT
END
FUNCTION EXP,x
END
FUNCTION FAST_GRID3,points, grid_x, grid_y,Iter=Iter,Nghbr=Nghbr,No_Avg=No_Avg,XMin=XMin,XMax=XMax,YMin=YMin,YMax=YMax
END
FUNCTION FAST_GRID4,points, grid_x, grid_y, grid_z,Iter=Iter,Nghbr=Nghbr,No_Avg=No_Avg,XMin=XMin,XMax=XMax,YMin=YMin,YMax=YMax,ZMin=ZMin,ZMax=ZMax
END
FUNCTION FFT,array, direction,Intleave=Intleave
END
FUNCTION FILEPATH,filename,Subdirectory=Subdirectory,Terminal=Terminal,Tmp=Tmp
END
FUNCTION FINDFILE,file_specification,Count=Count
END
FUNCTION FINDGEN,dim1[,dim1,...dimN]
END
FUNCTION FINITE,x
END
FUNCTION FIX,expr
END
FUNCTION FIX,expr, offset[,dim1, ...dimN]
END
FUNCTION FLOAT,expr
END
FUNCTION FLOAT,expr, offset[,dim1,...dimN]
END
FUNCTION FLTARR,dim1[,dim1,...dimN],Nozero=Nozero
END
PRO FLUSH,unit1[,unit2...unitN]
END
PRO FREE_LUN,unit1[,unit2...unitN]
END
FUNCTION FSTAT,unit
END
PRO FUNCT,x, parms, funcval [, pder]
END
FUNCTION GAUSSFIT,x, y [, coefficients]
END
FUNCTION GAUSSINT,x
END
FUNCTION GET_KBRD,wait
END
PRO GET_LUN,unit
END
FUNCTION GET_SYMBOL,name,Type=Type
END
FUNCTION GETENV,name
END
FUNCTION GETNCERR,[errstr],Help=Help,Usage=Usage
END
FUNCTION GETNCOPTS,Help=Help,Usage=Usage
END
FUNCTION GRID,xtmp, ytmp, ztmp,Nghbr=Nghbr,Nx=Nx,Ny=Ny
END
FUNCTION GRID_2D,points, grid_x,Order=Order,XMax=XMax,XMin=XMin
END
FUNCTION GRID_3D,points, grid_x, grid_y,Order=Order,XMax=XMax,XMin=XMin,YMax=YMax,YMin=YMin
END
FUNCTION GRID_4D,points, grid_x, grid_y, grid_z,Order=Order,XMax=XMax,XMin=XMin,YMax=YMax,YMin=YMin,ZMax=ZMax,Zmin=Zmin
END
FUNCTION GRID_SPHERE,points, grid_x, grid_y,Degrees=Degrees,Order,XMax=XMax,XMin=XMin,YMax=YMax,YMin=YMin
END
FUNCTION HANNING,col[,row]
END
PRO HDF_TEST,No_display=No_display
END
FUNCTION HDFGET24,filename,image,Help=Help,Interface=Interface,Usage=Usage
END
FUNCTION HDFGETANN,filename, tag, ref,Description=Description,Help=Help,Label=Label,Usage=Usage
END
FUNCTION HDFGETFILEANN,filename,Description=Description,Help=Help,Isfirst=Isfirst,Label=Label,Usage=Usage
END
FUNCTION HDFGETNT,type,Help=Help,Name=Name,Usage=Usage,Wavecast=Wavecast,Wavetype=Wavetype
END
FUNCTION HDFGETR8,filename,image,palette,Help=Help,Usage=Usage
END
FUNCTION HDFGETRANGE,maxvalue, minvalue,Help=Help,Usage=Usage
END
FUNCTION HDFGETSDS,filename,data,Help=Help,Maxrank=Maxrank,Usage=Usage
END
PRO HDFLCT,palette
END
FUNCTION HDFPUT24,filename, image,Append=Append,Help=Help,Interlace=Interlace,Usage=Usage
END
FUNCTION HDFGETANN,filename, tag, ref,Description=Description,Help=Help,Label=Label,Usage=Usage
END
FUNCTION HDFGETFILEANN,filename,Description=Description,Help=Help,Isfirst=Isfirst,Label=Label
END
FUNCTION HDFGETNT,type,Help=Help,Name=Name,Usage=Usage,Wavecast=Wavecast,Wavetype=Wavetype
END
FUNCTION HDFGETR8,filename, image, palette,Help=Help,Usage=Usage
END
FUNCTION HDFGETRANGE,maxvalue, minvalue,Help=Help,Usage=Usage
END
FUNCTION HDFGETSDS,filename, data,Help=Help,Maxrank=Maxrank,Usage=Usage
END
PRO HDFLCT,palette,Help=Help,Usage=Usage
END
FUNCTION HDFPUT24,filename, image,Append=Append,Help=Help,Interlace=Interlace,Usage=Usage
END
FUNCTION HDFPUTFILEANN,filename,Description=Description,Help=Help,Label=Label,Usage=Usage
END
FUNCTION HDFPUTR8,filename, image,Append=Append,Compression=Compression,Help=Help,Palette=Palette,Usage=Usage
END
FUNCTION HDFPUTSDS,filename, data,Append=Append,Help=Help,Usage=Usage
END
PRO HDFSCAN,filename,Help=Help,Usage=Usage
END
FUNCTION HDFSETNT,data,Help=Help,Name=Name,Type=Type,Usage=Usage
END
PRO HELP,[topic],Contents=Contents,Documentation=Documentation,Filename=Filename,Help=Help,Index=Index,Keyword=Keyword,PartialKey=PartialKey,Quit=Quit
END
FUNCTION HILBERT,x [, d]
END
FUNCTION HIST_EQUAL,image,Binsize=Binsize,Maxv=Maxv,Minv=Minv,Top=Top
END
PRO HIST_EQUAL_CT,[image]
END
FUNCTION HISTOGRAM,array,Armax=Armax,Armin=Armin,Binsize=Binsize,Intleave=Intleave,Max=Max,Min=Min,Omax=Omax,Omin=Omin
END
PRO HLS, ltlo, lthi, stlo, sthi, hue, lp [, rgb]
END
PRO HSV, vlo, vhi, stlo, sthi, hue, lp [, rgb]
END
PRO HSV_TO_RGB, h, s, v, red, green, blue
END
PRO HTML_BLOCK,text,BlockQuote=BlockQuote,Pre=Pre,Safe=Safe,Tag=Tag
END
PRO HTML_CLOSE,
END
PRO HTML_HEADING,text,Center=Center,Justify=Justify,Left=Left,Level=Level,Right=Right,Safe=Safe
END
FUNCTION HTML_HIGHLIGHT,str,tag,Safe=Safe
END
FUNCTION HTML_IMAGE,url,Alt=Alt,Bottom=Bottom,Left=Left,Middle=Middle,Right=Right,Top=Top
END
FUNCTION HTML_LINK,url,text,Safe=Safe
END
PRO HTML_LIST,list_item,Add=Add,AllClose=AllClose,CloseCurrent=CloseCurrent,Compact=Compact,Dir=Dir,DL=DL,Menu=Menu,NoClose=NoClose,OL=OL,Safe=Safe,UL=UL
END
PRO HTML_OPEN,[filename],ALinkColor=ALinkColor,BgColor=BgColor,BgImage=BgImage,CGI=CGI,LineColor=LineColor,Stdout=Stdout,Title=Title,TextColor=TextColor,VLinkColor=VLinkColor
END
PRO HTML_PARAGRAPH,text,Center=Center,Justify=Justify,Left=Left,Safe=Safe,Right=Right
END
PRO HTML_RULE
END
FUNCTION HTML_SAFE,str
END
PRO HTML_TABLE,table_text,Border=Border,Bottom=Bottom,Caption=Caption,CBottom=CBottom,CellPadding=CellPadding,CellSpacing=CellSpacing,Center=Center,ColLabels=ColLabels,EqualWidth=EqualWidth,Left=Left,Middle=Middle,NoWrap=NoWrap,Right=Right,RowLabels=RowLabels,Safe=Safe,TCenter=TCenter,TLeft=TLeft,Top=Top,TRight=TRight
END
FUNCTION IMAGE_COLOR_QUANT,image [, n_colors],Colormap=Colormap,Dither=Dither,Intleave=Intleave,Loadcmap=Loadcmap,Quiet=Quiet
END
PRO IMAGE_CONT,array,Aspect=Aspect,Interp=Interp,Window_Scale=Window_Scale
END
FUNCTION IMAGE_CREATE,pixel_array,Colormap=Colormap,Colormodel=Colormodel,Comments=Comments,Depth=Depth,File_Name=File_Name,File_Type=File_Type,Img_Count=Img_Count,Intleave=Intleave,Quiet=Quiet,Units=Units,X_resolution=X_resolution,Y_resolution=Y_resolution
END
PRO IMAGE_DISPLAY, image [, x, y],Animate=Animate,Delay=Delay,Quiet=Quiet,Sub_Img=Sub_Img,Window=Window,Data=Data,Device=Device,Normal=Normal,Wset=Wset,Bitmap=Bitmap,Colors=Colors,NoMeta=NoMeta,Pixmap=Pixmap,Retain=Retain,Title=Title,XPos=XPos,XSize=XSize,YPos=YPos,YSize=YSize
END
PRO IMAGE_DISPLAY, image [, position],Animate=Animate,Delay=Delay,Quiet=Quiet,Sub_Img=Sub_Img,Window=Window,Data=Data,Device=Device,Normal=Normal,Wset=Wset,Bitmap=Bitmap,Colors=Colors,NoMeta=NoMeta,Pixmap=Pixmap,Retain=Retain,Title=Title,XPos=XPos,XSize=XSize,YPos=YPos,YSize=YSize
END
FUNCTION IMAGE_QUERY_FILE,filename [, filetype],Default_Filetype=Default_Filetype,Quiet=Quiet,Readable=Readable
END
FUNCTION IMAGE_READ,filename,All_Subimages=All_Subimages,Cmap_Compress=Cmap_Compress,File_Type=File_Type,Intleave=Intleave,Img_Count=Img_Count,Order=Order,Quiet=Quiet,Sub_Img=Sub_Img,Unmap=Unmap,Verbose=Verbose
END
FUNCTION IMAGE_WRITE,filename, image,Compress=Compress,File_type=File_type,Order=Order,Overwrite=Overwrite,Quality=Quality,Quiet=Quiet,Verbose=Verbose
END
FUNCTION IMAGINARY,complex_expr
END
PRO IMG_TRUE8, red_img, grn_img, blu_img, rgb_img, red, grn, blu
END
FUNCTION INDGEN,dim1[,dim2,...dimN]
END
PRO INFO, expr1[,expr2,...exprN]
END
FUNCTION INTARR,dim1[,dim2,...dimN],Nozero=Nozero
END
FUNCTION INTERPOL,v, n
END
FUNCTION INTERPOL,v,x,u
END
FUNCTION INVERT,array [, status]
END
FUNCTION ISASKEY,asarr,key
END
FUNCTION ISHFT,p1,p2
END
PRO JOURNAL,[param]
END
FUNCTION JUL_TO_DT,julian_day
END
FUNCTION KEYWORD_SET,expr
END
FUNCTION LEEFILT,image [, n, sigma],Edge=Edge,Intleave=Intleave
END
PRO LEGEND, label [, col, lintyp, psym, data_x, data_y, delta_y]
END
FUNCTION LINDGEN,dim1[,dim2,...dimN]
END
FUNCTION LINKNLOAD,object, symbol [, param1, ... paramN],Default=Default,D_Value=D_Value,F_Value=F_Value,Nocall=Nocall,S_Value=S_Value,Unload=Unload,Value=Value,Verbose=Verbose,Vmscall=Vmscall,Vmsstrdesc=Vmsstrdesc
END
FUNCTION LIST,expr1[expr2,...exprN]
END
PRO LN03,filename
END
PRO LOAD_HOLIDAYS
END
PRO LOAD_OPTION, option_name ,Load_Now=Load_Now
END
PRO LOAD_WEEKENDS,
END
PRO LOADCT, [table_number],Ctfile=Ctfile,Silent=Silent
END
PRO LOADCT_CUSTOM,[table_number],Ctfile=Ctfile,Silent=Silent
END
PRO LOADRESOURCES, file,Appdir=Appdir,Subdir=Subdir
END
PRO LOADSTRINGS,file,Appdir=Appdir,Subdir=Subdir,
END
FUNCTION LONARR,dim1[,dim2,...dimN],Nozero=Nozero
END
FUNCTION LONG,expr
END
FUNCTION LONG,expr,offset[,dim1,...,dimN]
END
PRO LUBKSB, a, index, b
END
PRO LUDCMP, a, index, d
END
FUNCTION MAKE_ARRAY,[dim1,...dimn]
END
PRO MAP,Axes=Axes,Background=Background,Center=Center,Color=Color,Data=Data,File_Path=File_Path,Filled=Filled,GridColor=GridColor,GridLat=GridLat,GridLines=GridLines,GridLong=GridLong,GridStyle=GridStyle,Image=Image,Parameters=Parameters,Position=Position,Projection=Projection,Radius=Radius,Range=Range,Read_Path,Resolution=Resolution,Save=Save,Select=Select,Stetch=Stetch,User=User,Zoom=Zoom
END
PRO MAP_CONTOUR, z [, x, y],File_Path=File_Path,Filled=Filled,Pattern=Pattern,C_Colors=C_Colors,C_Linestyle=C_Linestyle,C_Thick=C_Thick,Follow=Follow,Levels=Levels,Max_Values=Max_Values,NLevels=NLevels,Path_Filename=Path_Filename,Pattern=Pattern,Spline=Spline
END
PRO MAP_PLOTS, x, y [, outx, outy],Cylinder=Cylinder,Distance=Distance,Km=Km,Miles=Miles,NoCircle=NoCircle,Color=Color,Linestyle=Linestyle,Nodata=Nodata,Psym=Psym,Symsize=Symsize,Thick=Thick
END
PRO MAP_POLYFILL, x, y,Color=Color,Fill_Pattern=Fill_Pattern,Linestyle=Linestyle,Line_Fill=Line_Fill,Orientation=Orientation,Pattern=Pattern,Image_Coordinates=Image_Coordinates,Image_Interpolate=Image_Interpolate,Mip=Mip,Threshold=Threshold
END
PRO MAP_REVERSE, x, y, lon, lat,Data=Data,Device=Device,Normal=Normal
END
PRO MAP_VELOVECT,MAP_VELOVECT, u, v [, x, y],Color=Color,Dots=Dots,Length=Length,Missing=Missing
END
PRO MAP_XYOUTS, x, y, string,Charsize=Charsize,Charthick=Charthick,Color=Color,Alignment=Alignment
END
FUNCTION MAX,array [, max_subscript],Min=Min
END
FUNCTION MEDIAN,array[,width],Average=Average,Edge=Edge,Same_Type=Same_Type
END
FUNCTION MESH,vertex_list, polygon_list,Color=Color,Kamb=Kamb,Kdiff=Kdiff,Ktran=Ktran,Materials=Materials,Transform=Transform
END
PRO MESSAGE,text,Continue=Continue,Informational=Informational,IOError=IOError,Noname=Noname,Noprefix=Noprefix,Noprint=Noprint,Traceback=Traceback
END
FUNCTION MIN,array[,min_subscript],Max=Max
END
PRO MODIFYCT, table, name, red, green, blue,Ctfile=Ctfile
END
FUNCTION MONTH_NAME,dt_var
END
PRO MOVIE, images [, rate],Order=Order
END


PRO MPROVE, a, alud, index, b, x
END
FUNCTION N_ELEMENTS,expr
END
FUNCTION N_PARAMS,
END
FUNCTION N_TAGS,expr
END
PRO ON_ERROR, n
END
PRO ON_ERROR_GOTO, label
END
PRO ON_IOERROR, label
END
PRO OPENR, unit, filename [, record_length]
END
PRO OPENU, unit, filename [, record_length]
END
PRO OPENW, unit, filename [, record_length]
END
PRO OPENR, unit, filename
END
PRO OPENU, unit, filename
END
PRO OPENW, unit, filename
END
PRO OPLOT, x [, y]
END
FUNCTION OPTION_IS_LOADED ,option_name
END
FUNCTION PARAM_PRESENT,parameter
END
PRO PLOT, x [, y]
END
PRO PLOT_IO, x [, y]
END
PRO PLOT_OI, x [, y]
END
PRO PLOT_OO, x [, y]
END
PRO PLOTS, x [, y [, z]]
END
PRO POINT_LUN, unit, position
END
FUNCTION POLY_2D,array, coeffx, coeffy [, interp [, dimx,...dimy]]
END
PRO POLYFILL, x [, y [, z]]
END
FUNCTION POLYFILLV,x, y, sx, sy [, run_length]
END
PRO polygon_list2, vert, poly, pg_num
END
PRO fill_colors, edge_colors, poly_opaque
END
FUNCTION POLYSHADE,vertices, polygons
END
FUNCTION POLYSHADE,x, y, z, polygons
END
PRO PRINT, expr1[,...exprn]
END
PRO PRINTF, unit, expr1[,...exprn]
END
FUNCTION RANDOMN,seed [, dim1, ...imn]
END
FUNCTION RANDOMU,seed [, dim1, ...dimn]
END
PRO READ, var1[, ...varn]
END
PRO READF, unit, var1[, ...varn]
END
PRO READU, unit, var1[, ...varn]
END
FUNCTION REBIN,array, dim1[, ...dimn]
END
FUNCTION REFORM,array, dim1[, ...dimn]
END
PRO RENAME, variable, new_name
END
FUNCTION RENDER,object1[, ...objectn]
END
FUNCTION REPLICATE,value, dim1[, ...dimn]
END
PRO RESTORE,[ filename]
END
PRO RETALL
END
PRO REWIND, unit
END
FUNCTION ROBERTS,image
END
FUNCTION ROTATE,array, direction
END
PRO SAVE,[ var1, ...varn]
END
FUNCTION SEC_TO_DT,num_of_seconds
END
PRO SELECT_READ_LUN, luns
END
PRO SETENV, environment_expr
END
PRO SETLOG, logname, value
END
PRO SET_PLOT, device
END
PRO SET_SHADING
END
PRO SET_SYMBOL, name, value
END
PRO winx, winy, xr, yr, zr
END
PRO SHADE_SURF, z [, x, y]
END
PRO SHADE_VOLUME, volume, value, vertex, poly
END
FUNCTION SHIFT,array, shift1[, ...shiftn]
END
PRO SHOW_OPTIONS
END
FUNCTION SIN,x
END
FUNCTION SINDGEN,dim1[, ...dimn]
END
FUNCTION SINH,x
END
FUNCTION SIZE,expr
END
PRO SKIPF, unit, files
END
PRO SKIPF, unit, records, r
END
FUNCTION SMOOTH,array, width
END
FUNCTION SOBEL,image
END
FUNCTION SORT,array
END
PRO SPAWN,[ command [, result]]
END
PRO SPAWN,[ command [, result]]
END
FUNCTION SQRT,x
END
PRO STOP,[ expr1, ...exprn]
END
FUNCTION STRARR,dim1[, ...dimn]
END
FUNCTION STRCOMPRESS,string
END
FUNCTION STRING,expr1[, ...exprn]
END
FUNCTION STRLEN,expr
END
FUNCTION STRLOOKUP,[name]
END
FUNCTION STRLOWCASE,string
END


FUNCTION STRMATCH,string,expr[,registers],Grep=Grep,Egrep=Egrep,Exact=Exact,Length=Length,Position=Position
END


FUNCTION STRMESSAGE,errno
END
FUNCTION STRMID,expr, first_character, length
END
FUNCTION STRPOS,object, search_string [, position]
END
PRO STRPUT, destination, source [, position]
END
FUNCTION STR_TO_DT,date_strings [, time_strings]
END
FUNCTION STRTRIM,string [, flag]
END
FUNCTION STRUCTREF,{structure}
END
FUNCTION STRUPCASE,string
END
PRO SURFACE, z [, x, y]
END
PRO SVBKSB, u, w, v, b, x
END
PRO SVD, a, W [, u [, v]]
END
FUNCTION SYSTIME,param
END
FUNCTION TAG_NAMES,expr
END
FUNCTION TAN,x
END
FUNCTION TANH,x
END
PRO TAPRD, array, unit [, byte_reverse]
END
PRO TAPWRT, array, unit [, byte_reverse]
END
FUNCTION TODAY,
END
FUNCTION TOTAL,array
END
PRO TQLI, d, e, z
END
FUNCTION TRANSPOSE,array
END
PRO TRED2, a [, d [, e]]
END
PRO TRIDAG, a, b, c, r, u
END
FUNCTION TRNLOG,logname, value
END
PRO TV, image [, x, y [, channel ]]
END
PRO TV, image [, position]
END
PRO TVCRS,[ on_off]
END
PRO TVCRS,[ x, y]
END
PRO TVLCT, v1, v2, v3 [, start]
END
FUNCTION TVRD,x0, y0, nx, ny [, channel ]
END
PRO TVSCL, image [, x, y [, channel ]]
END
PRO TVSCL, image [, position]
END
FUNCTION UNIQUE,vec
END
PRO UNLOAD_OPTION, option_name
END
PRO UPVAR, name, local
END
PRO USERSYM, x [, y]
END
FUNCTION VAR_TO_DT,yyyy, mm, dd, hh, mn, ss
END
PRO ydim, zdim
END
PRO WAIT, seconds
END
FUNCTION WCOPY, [window_index]
END
PRO WDELETE,[ window_index]
END
PRO WEOF, unit
END
FUNCTION WHERE,array_expr [, count ]
END
PRO WINDOW,[ window_index]
END
FUNCTION WMENU,strings
END
FUNCTION WPASTE, [window_index]
END
PRO WPRINT,[ window_index]
END
FUNCTION WREAD_DIB, [window_index]
END
FUNCTION WREAD_META, [window_index]
END
PRO WRITEU, unit, expr1[, ...exprn]
END
PRO WSET, window_index
END
PRO WSHOW,[ window_index [, show]]
END
FUNCTION WWRITE_DIB, [window_index]
END
FUNCTION WWRITE_META, [window_index]
END
PRO XYOUTS, x, y, string
END
PRO ZROOTS, a, roots [, polish]
END
PRO doneCallback)
END
PRO changedCallback)
END
PRO WwPreview, parent, confirmCallback, clearCallback
END
FUNCTION WtAddCallback,widget, reason, callback [, client_data]
END
FUNCTION WtAddHandler,widget, eventmask, handler [, client_data]
END
FUNCTION WtClose,widget
END
FUNCTION WtCreate,name, class, parent [, argv]
END
FUNCTION WtCursor,FunctionName, widget [, index]
END
FUNCTION WtGet,widget [, resource]
END
FUNCTION WtInit,app_name, appclass_name [, Xserverargs...]
END
FUNCTION WtInput,FunctionName [, parameters]
END
FUNCTION WtList,FunctionName, widget [, parameters]
END
FUNCTION WtLookupString,event
END
FUNCTION WtMainLoop,
END
FUNCTION WtPointer,FunctionName, widget [, parameters]
END
FUNCTION WtPreview,action, widget
END
FUNCTION WtProcessEvent,
END
FUNCTION WtResource,[resvar]
END
FUNCTION WtSet,widget, [argv]
END
FUNCTION WtTable,FunctionName, widget [, parameters]
END
FUNCTION WtTimer,FunctionName, params, [client_data]
END
FUNCTION WtWorkProc,FunctionName, parameters
END
PRO TmAddSelectedVars, tool_name, var_name
END
PRO TmAddVar, tool_name, var_name
END
PRO TmCopy, tool_name
END
PRO TmCut, tool_name
END
PRO TmDelVar, tool_name [, var_names]
END
PRO TmDelete, tool_name
END
PRO TmDeselectVars
END
PRO TmDynamicDisplay, indices
END
PRO TmDynamicShowVars
END
FUNCTION TmEnumerateAttributes,tool_name, item
END
FUNCTION TmEnumerateItems,tool_name
END
FUNCTION TmEnumerateMethods,tool_name
END
FUNCTION TmEnumerateSelectedVars,
END
FUNCTION TmEnumerateToolNames,
END
FUNCTION TmEnumerateVars,tool_name
END
PRO TmExecuteMethod, tool_name, method_name
END
PRO TmExport, variable_names, destination_tool_names
END
PRO TmExportSelection, destination_tool_names
END
FUNCTION TmGetAttribute,tool_name, item, attr_name
END
FUNCTION TmGetMessage, [message_file], message_code
END
FUNCTION TmGetMethod,tool_name, method_name
END
FUNCTION TmGetTop,tool_name
END
FUNCTION TmGetUniqueToolName,tool_name
END
FUNCTION TmGetVarMainName,tool_name, local_variable
END
PRO TmInit
END
PRO TmPaste, tool_name
END
PRO TmRegister, unique_name, topShell
END
FUNCTION TmRestoreTemplate,tool_name, filename
END
FUNCTION TmRestoreTools,filename
END
PRO TmSaveTools, filename [, tool_names]
END
FUNCTION TmSetAttribute,tool_name, item, attr_name, attr_value
END
PRO TmSetMethod, tool_name, method_name, method_call
END
PRO TmUnregister, tool_name
END
PRO TmAddGrael, tool_name, grael_name
END
PRO TmAddSelectedGrael, tool_name, grael_name
END
PRO TmBottomGrael, tool_name, grael_name
END
PRO TmDelGrael, tool_name, grael_name
END
PRO TmDelSelectedGraels, tool_name, grael_name
END
FUNCTION TmEnumerateGraelMethods,tool_name, grael_name
END
FUNCTION TmEnumerateGraels,tool_name
END
FUNCTION TmEnumerateSelectedGraels,tool_name
END
PRO TmExecuteGraelMethod, tool_name, grael_name, method_name
END
FUNCTION TmGetGraelMethod,tool_name, grael_name, method_name
END
FUNCTION TmGetGraelRectangle,tool_name, grael_name
END
FUNCTION TmGetUniqueGraelName,tool_name, grael_name
END
FUNCTION TmGroupGraels,tool_name, grael_names
END
PRO TmSetGraelMethod, tool_name, grael_name, method_name, method_value
END
PRO TmSetGraelRectangle, tool_name, grael_name, rectangle
END
PRO TmTopGrael, tool_name, grael_name
END
PRO TmUngroupGraels, tool_name, group_name
END
FUNCTION WoColorButtonSetValue,wid, color
END
