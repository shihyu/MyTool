////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47662 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "scc.sh"
#include "xml.sh"
#import "backtag.e"
#import "bgsearch.e"
#import "compile.e"
#import "guiopen.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "vc.e"
#import "xcode.e"
#import "wkspace.e"
#endregion

/**
 * If a project is associated, returns the absolute
 * path to the file, and the type int VendorProjectFilename
 * and VendProjectType.
 *
 * @param ProjectFilename
 *               Name of project to check for association
 *
 * @param VendorProjectFilename
 *               Absolute filename of associated project
 *
 * @param VendorProjectType
 *               Associated project type
 *
 * @return 0 if project is associated and got information succesfully
 */
int _GetAssociatedProjectInfo(_str ProjectFilename,_str &VendorProjectFilename,_str &VendorProjectType='')
{
   int handle=_ProjectHandle(ProjectFilename);
   VendorProjectFilename=_ProjectGet_AssociatedFile(handle);
   if (VendorProjectFilename=='') {
      return(1);//Doesn't have to be an association
   }
   VendorProjectFilename=absolute(VendorProjectFilename,_strip_filename(ProjectFilename,'N'));

   VendorProjectType=_ProjectGet_AssociatedFileType(handle);

   return(0);
}

static _str GetVariableValue(_str VarName,_str (&vartab):[])
{
   _str line='';
   if (!vartab._indexin(VarName)) {
      save_pos(auto p);
      p_line=0;
      int status=search('^'_escape_re_chars(VarName)' @=','rh@');
      if (status) {
         restore_pos(p);
      } else {
         get_line(line);
         int lp=lastpos('=',line);
         if (!lp) return('');
         _str filename=substr(line,lp+1);
         filename=strip(filename);
         line=filename;
         vartab:[VarName]=line;
         restore_pos(p);
         return(line);
      }
   } else {
      line=vartab:[VarName];
      return(line);
   }
   if (line=='') {
      line=get_env(VarName);
      if (line=='') return('');
      vartab:[VarName]=line;
      return(line);
   }
   return(line);
} 

void _projecttb_AddFile(int tree_wid,int index,_str filename,int &NofInserted,int (&StatusList)[],boolean iUsingScc)
{
   int iBitmapIndex=_pic_doc_w;
   if (iUsingScc) {
      iBitmapIndex=0;
      int iFileStatus=StatusList[NofInserted];
      if (!iFileStatus || (iFileStatus&VSSCC_STATUS_DELETED)) {
         iBitmapIndex=_pic_doc_w;
      }
      if (iFileStatus&VSSCC_STATUS_OUTOTHER) {
         if (iFileStatus&VSSCC_STATUS_OUTEXCLUSIVE) {
            iBitmapIndex=_pic_vc_co_other_x_w;
         } else {/* if (iFileStatus&VSSCC_STATUS_OUTMULTIPLE) */
            iBitmapIndex=_pic_vc_co_other_m_w;
         }
      }
      if (!iBitmapIndex && iFileStatus&VSSCC_STATUS_CONTROLLED &&
          !(iFileStatus&VSSCC_STATUS_LOCKED)) {
         iBitmapIndex=_pic_vc_available_w;
      }
      if (iFileStatus & VSSCC_STATUS_CHECKEDOUT) {
         iBitmapIndex=_pic_vc_co_user_w;
      }
      ++NofInserted;
   }
   tree_wid._TreeAddItem(index,_strip_filename(filename,'P'):+"\t":+filename,
                         TREE_ADD_AS_CHILD,
                         iBitmapIndex,
                         iBitmapIndex,-1,0);
}
//Ok, here I am just going to cheat and grab the list.
//We can add more stuff to the ini file later if we have to
static void AddVariableValueToList2(int tree_wid,
                                    _str VarName,int index,
                                   _str VariableStart,_str VariableEnd,
                                   _str ProjectDir,boolean (&hashtab):[],
                                   _str (&vartab):[],
                                    int &NofInserted,
                                    int (&StatusList)[],
                                    boolean iUsingScc
                                   )
{
   _str ContinuationChar='\';
   VarName=substr(VarName,length(VariableStart)+1);
   VarName=substr(VarName,1,length(VarName)-length(VariableEnd));
   //orig_dir=getcwd();chdir(ProjectDir,1);
   GetVariableValue(VarName,vartab);
   save_pos(auto p);
   //get_line(line);
   _str line=vartab:[VarName];
   int stripped;
   for (;;) {
      if (line._varformat()==VF_EMPTY) {
         break;
      }
      line=strip(line);
      stripped=0;
      if (last_char(line)==ContinuationChar) {
         line=substr(line,1,length(line)-1);
         stripped=1;
      }
      if (strip(line)!='') {
         _str filename=strip(line,'B','"');
         filename=absolute(filename);
         if (!hashtab._indexin(filename)) {
            hashtab:[filename]=1;
            //filename=maybe_quote_filename(filename);
            _projecttb_AddFile(tree_wid,index,filename,NofInserted,StatusList,iUsingScc);
         }
      }
      if (!stripped) break;
      down();
      get_line(line);
   }
   //chdir(orig_dir,1);
   restore_pos(p);
} 

static int GetFileListFromVisualStudioFile(_str MakefileName,int FileListViewId,_str (&FileArray)[]=null,
                                           int (&IndexTable):[]=null,
                                           int (&FilterIndexes)[]=null,
                                           int handle=-1,
                                           boolean ConvertToAbsolute=true,
                                           boolean ResolveLinks=false,
                                           boolean listboxFormat=false)
{
   _str MakefilePath=_strip_filename(MakefileName,'N');
   boolean opened_file=false;
   if (handle<0) {
      opened_file=true;
      int status;
      if (file_eq(_get_extension(MakefileName,true),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
         handle=_xmlcfg_open(MakefileName,status);
      } else {
         handle=_xmlcfg_open(MakefileName,status,0);
      }
      if (handle<0) {
         return(status);
      }
   }

   // Visual C++ Project (.vcproj), VS2008 and earlier
   if (file_eq(_get_extension(MakefileName,1),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      typeless FileIndexes[]=null,OtherFileIndexes[]=null;
      int status=_xmlcfg_find_simple_array(handle,"//File",FileIndexes);
      int total=0;
      int i;
      _str val;
      for (i=0;i<FileIndexes._length();++i) {
         val=_xmlcfg_get_attribute(handle,FileIndexes[i],"RelativePath");
         if (val!='') {
            if (ConvertToAbsolute) {
               val=absolute(val,MakefilePath);
            }else{
               val=ConvertFromVCPPRelFilename(val,MakefilePath);
            }
            if (!IndexTable._indexin(_file_case(val))) {
               AddFileToView(FileListViewId,val,'',listboxFormat);
               FileArray[FileArray._length()]=val;
               IndexTable:[_file_case(val)]=FileIndexes[i];
            }
         }
      }
      for (i=0;i<OtherFileIndexes._length();++i) {
         val=_xmlcfg_get_attribute(handle,OtherFileIndexes[i],"RelativePath");
         if (val!='') {
            if (ConvertToAbsolute) {
               val=absolute(val,MakefilePath);
            }else{
               val=ConvertFromVCPPRelFilename(val,MakefilePath);
            }
            if (!IndexTable._indexin(_file_case(val))) {
               AddFileToView(FileListViewId,val,'',listboxFormat);
               FileArray[FileArray._length()]=val;
               IndexTable:[_file_case(val)]=OtherFileIndexes[i];
            }
         }
      }
   }
   // Visual C++ (vcxproj), Visual Studio 2010 and up
   else if(file_eq(_get_extension(MakefileName,1),VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      typeless itemGroups[]=null;
      _xmlcfg_find_simple_array(handle, '/Project/ItemGroup', itemGroups);

      foreach (auto groupNode in itemGroups) {
         if (_xmlcfg_get_attribute(handle, groupNode, 'Label') != '') {
            continue;
         }
         index := _xmlcfg_get_first_child(handle, groupNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         while (index > 0) {
            name := _xmlcfg_get_name(handle, index);
            if (name == 'ProjectConfiguration' ||
                name == 'ProjectReference' ||
                name == 'Filter' || 
                name == 'Reference') {
               index = _xmlcfg_get_next_sibling(handle,index);
               continue;
            }
            val := _xmlcfg_get_attribute(handle, index, 'Include');
            if (ConvertToAbsolute) {
               val = absolute(val,MakefilePath);
            } else {
               val = ConvertFromVCPPRelFilename(val,MakefilePath);
            }
            if (!IndexTable._indexin(_file_case(val))) {
               AddFileToView(FileListViewId,val,'',listboxFormat);
               FileArray[FileArray._length()]=val;
               IndexTable:[_file_case(val)]=index;
            }
            index = _xmlcfg_get_next_sibling(handle,index);
         }
      }
   }
   else if (_xmlcfg_find_simple(handle,'/VisualStudioProject')>=0) {
      _str AppName=GetVSStandardAppName(_get_extension(MakefileName,true));

      if (AppName:!='') {
         typeless FileIndexes[]=null;
         _str path='/VisualStudioProject/'AppName'/Files/Include/File';
         int status=_xmlcfg_find_simple_array(handle,path,FileIndexes);
         int i;
         _str val;
         for (i=0;i<FileIndexes._length();++i) {
            val=_xmlcfg_get_attribute(handle,FileIndexes[i],"RelPath");
            if (val!='') {
               if( ResolveLinks ) {
                  // 9/1/2005 - RB
                  // Check for a Link="relative-link-path"
                  // You usually see this in C# projects, but we will allow
                  // in any VStudio project file.
                  _str link = _xmlcfg_get_attribute(handle,FileIndexes[i],"Link");
                  if( link!="" ) {
                     val=link;
                  }
               }
               if (ConvertToAbsolute) {
                  val=absolute(val,MakefilePath);
               } else {
                  val=ConvertFromVCPPRelFilename(val,MakefilePath);
               }
               if (!IndexTable._indexin(_file_case(val))) {
                  AddFileToView(FileListViewId,val,'',listboxFormat);
                  FileArray[FileArray._length()]=val;
                  IndexTable:[_file_case(val)]=FileIndexes[i];
               }
            }
         }
      }
   }else {
      // Visual Studio 2005 and higher

      // MSBuild is a pretty free-form project format, and there is not
      // 100% fixed way to define the XML for the project. However *most*
      // files children of <ItemGroup> nodes, represented as <Compile> nodes.
      // In addition to <Compile>, some other node types are as follows:
      // None, EmbeddedResource, Content, Page, ApplicationDefinition
      typeless itemGroupIndexes[]=null;
      _xmlcfg_find_simple_array(handle,'/Project/ItemGroup',itemGroupIndexes);

      int curItemGroup;
      for (curItemGroup=0;curItemGroup<itemGroupIndexes._length();++curItemGroup) {
         typeless compileIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'Compile',compileIndexes,itemGroupIndexes[curItemGroup]);

         typeless noneIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'None',noneIndexes,itemGroupIndexes[curItemGroup]);

         typeless resourceIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'EmbeddedResource',resourceIndexes,itemGroupIndexes[curItemGroup]);

         typeless contentIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'Content',contentIndexes,itemGroupIndexes[curItemGroup]);

         typeless pageIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'Page',pageIndexes,itemGroupIndexes[curItemGroup]);

         typeless appDefIndexes[]=null;
         _xmlcfg_find_simple_array(handle,'ApplicationDefinition',appDefIndexes,itemGroupIndexes[curItemGroup]);

         int append_index;
         for (append_index=0;append_index<noneIndexes._length();++append_index) {
            compileIndexes[compileIndexes._length()]=noneIndexes[append_index];
         }

         for (append_index=0;append_index<resourceIndexes._length();++append_index) {
            compileIndexes[compileIndexes._length()]=resourceIndexes[append_index];
         }

         for (append_index=0;append_index<contentIndexes._length();++append_index) {
            compileIndexes[compileIndexes._length()]=contentIndexes[append_index];
         }

         for (append_index=0;append_index<pageIndexes._length();++append_index) {
            compileIndexes[compileIndexes._length()]=pageIndexes[append_index];
         }

         for (append_index=0;append_index<appDefIndexes._length();++append_index) {
            compileIndexes[compileIndexes._length()]=appDefIndexes[append_index];
         }

         int curCompile;
         for (curCompile=0;curCompile<compileIndexes._length();++curCompile) {
            _str val=_xmlcfg_get_attribute(handle,compileIndexes[curCompile],'Include');

            if (val!='') {
               if (ConvertToAbsolute) {
                  val=absolute(val,MakefilePath);
               } else {
                  val=ConvertFromVCPPRelFilename(val,MakefilePath);
               }
               if (!IndexTable._indexin(_file_case(val))) {
                  AddFileToView(FileListViewId,val,'',listboxFormat);
                  FileArray[FileArray._length()]=val;
                  IndexTable:[_file_case(val)]=compileIndexes[curCompile];
               }
            }
         }
      }
   }
   if (opened_file) {
      _xmlcfg_close(handle);
   }

   return(0);
}

void GetFileListFromVSTemplateFile(_str filename, int FileListViewId, boolean ConvertToAbsolute)
{
   // even though etp file are XML, xmlcfg can not be used here because it can not read CDATA
   _str file_array[];

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   top();
   up();
   status=search('<ProjectExplorer>','@');

   if (!status) {
      _str line;

      while (!down()) {
         get_line(line);
         line=strip(line);

         if (line:=='</ProjectExplorer>') {
            break;
         }

         parse line with '<File>'line'</File>';

         if (line:!='') {
            if (ConvertToAbsolute) {
               file_array[file_array._length()]=absolute(line,_strip_filename(filename,'N'));
            } else {
               file_array[file_array._length()]=line;
            }
         }
      }

      p_window_id=FileListViewId;
      bottom();
      int index;
      for (index=0;index<file_array._length();++index) {
         insert_line(file_array[index]);
      }
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
}

static void GetFileListFromVSDatabaseFile(_str filename, int FileListViewId, boolean ConvertToAbsolute)
{
   _str file_array[];
   _str line;

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   top();
   up();
   _str cur_folder='';

   _str begin_folder='Begin Folder';
   _str script='Script';
   _str end_folder='End';

   while (!down()) {

      get_line(line);
      line=strip(line);

      if (substr(line,1,length(begin_folder)):==begin_folder) {
         parse line with . '=' line;
         line=strip(line);
         line=strip(line,'B','"');
         strappend(cur_folder,line:+FILESEP);
      } else if (substr(line,1,length(script)):==script) {
         parse line with . '=' line;
         line=strip(line);
         line=strip(line,'B','"');
         line=cur_folder:+line;

         if (ConvertToAbsolute) {
            file_array[file_array._length()]=absolute(line,_strip_filename(filename,'N'));
         } else {
            file_array[file_array._length()]=line;
         }
      } else if (substr(line,1,length(end_folder)):==end_folder) {
         if (cur_folder:!='') {
            //remove the trailing FILESEP
            cur_folder=substr(cur_folder,1,length(cur_folder)-1);
            cur_folder=_strip_filename(cur_folder,'N');
         }
      }
   }

   p_window_id=FileListViewId;
   bottom();
   int index;
   for (index=0;index<file_array._length();++index) {
      insert_line(file_array[index]);
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
}

static void InsertFileListFromVSDatabaseFile(_str ProjectName,
                                             _str filename,
                                             int iMenuOpenIndex,
                                             int iMenuCloseIndex,
                                             int iCurrentVCSIsScc,
                                             int iMaxSccNum,
                                             int index)
{
   _str fileList[];
   int StatusList[];
   boolean iUsingScc=false;

   if (iCurrentVCSIsScc && _SccGetCurProjectInfo(1)!="") {
      _getProjectFiles(_workspace_filename, ProjectName, fileList, 1);

      int status=_SccQueryInfo2(fileList,StatusList,iMaxSccNum);
      iUsingScc=true;
   }
   int NofInserted=0;

   _str line;

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   top();
   up();
   _str cur_folder='';

   _str begin_folder='Begin Folder';
   _str script='Script';
   _str end_folder='End';

   while (!down()) {

      get_line(line);
      line=strip(line);

      if (substr(line,1,length(begin_folder)):==begin_folder) {
         parse line with . '=' line;
         line=strip(line);
         line=strip(line,'B','"');
         strappend(cur_folder,line:+FILESEP);
         index=orig_view_id._TreeAddItem(index,
                                         line,
                                         TREE_ADD_AS_CHILD,
                                         iMenuCloseIndex,
                                         iMenuOpenIndex,
                                         0,0);
      } else if (substr(line,1,length(script)):==script) {
         parse line with . '=' line;
         line=strip(line);
         line=strip(line,'B','"');
         line=cur_folder:+line;

         line=absolute(line,_strip_filename(filename,'N'));

         _projecttb_AddFile(orig_view_id,index,line,NofInserted,StatusList,iUsingScc);
      } else if (substr(line,1,length(end_folder)):==end_folder) {
         if (cur_folder:!='') {
            //remove the trailing FILESEP
            cur_folder=substr(cur_folder,1,length(cur_folder)-1);
            //remove the last directory
            cur_folder=_strip_filename(cur_folder,'N');
            // go up the tree
            index=orig_view_id._TreeGetParentIndex(index);
         }
      }
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
}

/**
 * Get the list of files for the config in the specified JBuilder project.
 * The files should be relative to the project file
 */
static int GetFileListFromJBuilderFile(_str jbFilename, int FileListViewId, _str (&FileArray)[]=null,
                                       int (&IndexTable):[]=null, int (&FilterIndexes)[]=null,
                                       int handle=-1, boolean ConvertToAbsolute=true,
                                       boolean listboxFormat=false)
{
   int status = 0;

   // get the path to the project for use in absolute()
   _str jbFilePath = _strip_filename(jbFilename, "N");

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(jbFilename, status);
      if(handle < 0) return status;
      openedFile = true;
   }

   typeless fileNodeList[] = null;
   status = _xmlcfg_find_simple_array(handle, "/project//file", fileNodeList);
   int i;
   for(i = 0; i < fileNodeList._length(); i++) {
      _str filename = _xmlcfg_get_attribute(handle, fileNodeList[i], "path");
      if(filename == "") continue;

      // make absolute if requested
      if(ConvertToAbsolute) {
         filename = absolute(filename, jbFilePath);
      }

      // add it if not already found in the file index
      if(!IndexTable._indexin(_file_case(filename))) {
         AddFileToView(FileListViewId, filename, "", listboxFormat);
         FileArray[FileArray._length()] = filename;
         IndexTable:[_file_case(filename)] = fileNodeList[i];
      }
   }

   // close the file
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}


static int AddFileToView(int ViewId,_str Filename,
                         _str MakefileIndicator='',
                         boolean listboxFormat=false)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   bottom();
   if (listboxFormat) {
      insert_line(' 'MakefileIndicator:+Filename);
   } else {
      insert_line(MakefileIndicator:+Filename);
   }
   p_window_id=orig_view_id;
   return(0);
}

_str _Wildcard2RE(_str filespec)
{
   int filespec_len=length(filespec);
#if !__UNIX__
   if (filespec_len>=(int)length(ALLFILES_RE) && substr(filespec,filespec_len-length(ALLFILES_RE)+1)==ALLFILES_RE) {
      filespec=substr(filespec,1,filespec_len-2);
      filespec_len=length(filespec);
   }
#endif
   int i;
   _str result='';
   for (i=1;i<=filespec_len;++i){
      _str ch;
      ch= (i<=1)?'':substr(filespec,i-1,1);
      _str chi=substr(filespec,i,1);
      if (chi == '*'
#if __UNIX__
          && ch != '\'
#endif
          ){
         strappend(result,'?');
      }
      if (
#if __UNIX__
          (chi=='+' || chi=='@' || chi=='#' || chi=='$' || chi=='{'||
          chi=='}' || chi=='^' || chi=='~' || chi==':') && ch!='\\'
#else
          chi=='+' || chi=='@' || chi=='#' || chi=='$' || chi=='{'||
          chi=='}' || chi=='^' || chi=='~' || chi==':' ||
          chi=='(' || chi==')' || chi=='^' || chi=='|' || chi=='\'
#endif
          ) {
         strappend(result,'\');
      }
      strappend(result,chi);
   }
   return('^'result'$');
}
boolean _ExcludeMatches(_str wildcard,_str filename)
{
   if (last_char(wildcard)==FILESEP) {
      _str DirNamePart=substr(wildcard,1,length(wildcard)-1);
      typeless p=pos(FILESEP:+DirNamePart:+FILESEP,filename,1,_fpos_case);
      return(p!=0);
   }
   return(_FilespecMatches(wildcard,_strip_filename(filename,'P')));
}
boolean _FilespecMatches(_str filespec,_str filename)
{
   if( filespec=='*'
#if !__UNIX__
       ||  filespec=='*.*'
#endif
        ) return(true);
   filespec=strip(filespec);
   _str filespec_re=_Wildcard2RE(filespec);
   typeless p=pos(filespec_re,filename,1,'r'_fpos_case);
   return( p!=0 );
}
int _GetEclipsePathList(_str MakefilePath,_str (&pathList)[],boolean getDeps=false)
{
   int status=0;
   _str filename=MakefilePath:+'.classpath';
   int handle=_xmlcfg_open(filename,status);
   if (status) return(status);
   int index=_xmlcfg_get_first_child(handle,TREE_ROOT_INDEX);
   if (index>-1) {
      _str cap=_xmlcfg_get_name(handle,index);
      index=_xmlcfg_get_first_child(handle,index);
      if (index>-1) {
         for (;;) {
            _str kind=_xmlcfg_get_attribute(handle,index,"kind",'');
            if (getDeps) {
               if (kind=='src') {
                  _str path=_xmlcfg_get_attribute(handle,index,"path",'');
                  if (substr(path,1,1)=='/') {
                     pathList[pathList._length()]=path;
                  }
               }
            }else{
               if (kind=='src') {
                  _str path=absolute(_xmlcfg_get_attribute(handle,index,"path",''),MakefilePath);
                  if (path!='') {
                     _maybe_append_filesep(path);
                     pathList[pathList._length()]=path;
                  }
               }
            }
            index=_xmlcfg_get_next_sibling(handle,index);
            if (index<0) break;
         }
      }
   }
   _xmlcfg_close(handle);
   return(status);
}

/*

   Warning:  When BuildTree is false, files are not normalized (FILESEP is used) and
   files are inserted absolute.
*/
void _ExpandFileView2(int handle,int FileNode,_str RelFileName,_str (&pathList)[],
                      boolean BuildTree=false, boolean doAbsolute=true,boolean listboxFormat=false,
                      int (&folderNodeHash):[]=null)
{
   _str treeOption='';
   if (_xmlcfg_get_attribute(handle,FileNode,'Recurse',0)) {
      treeOption=' +t ';
   }
   _str excludeWildcards=translate(_xmlcfg_get_attribute(handle,FileNode,'Excludes'),FILESEP,FILESEP2);
   int Node=FileNode;

   // store the parent of this file node as the default folder ("") and
   // absolute the wildcard and point it to the parent as well
   //int folderNodeHash:[] = null;
   int parentFolderNode = _xmlcfg_get_parent(handle, FileNode);
   folderNodeHash:[""] = parentFolderNode;
   folderNodeHash:[_strip_filename(absolute(RelFileName, pathList[0]), "N")] = parentFolderNode;
   int i,ff;
   _str cardlist,curwildcard;
   for (i=0;i<pathList._length();++i) {
      outerloop:
      for (ff=1;;ff=0) {
         _str cur=file_match(maybe_quote_filename(absolute(RelFileName,pathList[i])):+treeOption,ff);
         if (cur=='') break;
         _str justname=_GetLastDirName(cur);
         if (justname=='.' || justname=='..') {
            continue;
         }

         // ignore directories if not building tree
         boolean isFolder = (_strip_filename(cur,"P") == "");
         if(!BuildTree && isFolder) {
            continue;
         } else if(isFolder) {
            // trim the trailing FILESEP
            cur = strip(cur, "T", FILESEP);
         }

         cardlist=excludeWildcards;
         for (;;) {
            parse cardlist with curwildcard ';' cardlist;
            if (curwildcard=='') break;
            // IF this is an exclude directory
            if (_ExcludeMatches(curwildcard,cur)) {
               continue outerloop;
            }
         }

         // remember path
         _str path = _strip_filename(cur, "N");

         if(!doAbsolute) {
            cur = relative(cur, pathList[i]);
         }
         if (BuildTree) {
            // find the folder that is the parent to this file
            int folderNode;

            // check to see if the parent folder to this new item was found.  if not,
            // build the path all the way up to and including the parent.  then fall
            // thru to add the new folder or file item
            if(!folderNodeHash._indexin(path)) {
               // build the path to the folder, one folder at a time
               _str partialPath = relative(path, absolute(pathList[i]));
               _str rebuiltPath = substr(path, 1, length(path) - length(partialPath));
               folderNode = folderNodeHash:[""];
               for(;;) {
                  if(partialPath == "") break;

                  // get next part of path
                  _str nextFolder = "";
                  int filesepPos = pos(FILESEP, partialPath);
                  if(filesepPos > 0) {
                     nextFolder = substr(partialPath, 1, filesepPos - 1);
                     partialPath = substr(partialPath, filesepPos + 1);
                  } else {
                     nextFolder = partialPath;
                     partialPath = "";
                  }

                  rebuiltPath = rebuiltPath :+ nextFolder :+ FILESEP;

                  // see if this path exists yet
                  if(folderNodeHash._indexin(rebuiltPath) || nextFolder=='') {
                     folderNode = folderNodeHash:[rebuiltPath];
                     continue;
                  }

                  // add the folder
                  folderNode=_xmlcfg_add(handle,folderNode,VPJTAG_FOLDER,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
                  _xmlcfg_set_attribute(handle,folderNode,'Name',_NormalizeFile(_strip_filename(nextFolder, "P")));

                  // remember this folders node index
                  folderNodeHash:[rebuiltPath] = folderNode;
               }
            } else {
               folderNode = folderNodeHash:[path];
            }

            // at this point the tree up thru the new items parent is guaranteed to
            // exist so add the new folder or file item
            if(isFolder) {
               Node=_xmlcfg_add(handle,folderNode,VPJTAG_FOLDER,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_set_attribute(handle,Node,'Name',_NormalizeFile(_strip_filename(cur, "P")));

               // remember this folders node index
               folderNodeHash:[absolute(cur, pathList[i]) :+ FILESEP] = Node;
            } else {
               Node=_xmlcfg_add(handle,folderNode,VPJTAG_F,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_set_attribute(handle,Node,'N',_NormalizeFile(cur));
            }
         } else {
            if(listboxFormat) {
               insert_line(" " cur);
            } else {
               insert_line(cur);
            }
         }
      }
   }
   if (BuildTree) {
      // delete the wildcard file node that was replaced
      _xmlcfg_delete(handle,FileNode);

      // sort every known folder
      typeless f;
      for(f._makeempty();;) {
         int sortNode = folderNodeHash._nextel(f);
         if(f._isempty()) break;

         _xmlcfg_sort_on_attribute(handle, sortNode, "N", "2P", VPJTAG_FOLDER, "Name", "2P");

      }
   }
   //_showxml(handle, TREE_ROOT_INDEX, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
}

boolean _ExpandFileView(int handle,int FileListViewId,_str (&pathList)[],int append_after_ln=0,
                     boolean listboxFormat=false)
{
   hasWildCards := false;
   int orig_view_id=p_window_id;
   p_window_id=FileListViewId;
   p_line=append_after_ln;
   _str line,line2;
   while (!down()) {
      get_line(line);
      p_window_id=FileListViewId;
      // inline "iswildcard(line)" for performance
      if (iswildcard(line) && !file_exists(line)) {
         hasWildCards=true;
         if(!_delete_line()) up();
         get_line(line2);
         line=strip(line);
         int FileNode=_ProjectGet_FileNode(handle,line);
         if (FileNode<0) {
            _message_box('could not find 'line);
            continue;
         }
         _ExpandFileView2(handle,FileNode,line,pathList,false,true,listboxFormat);
      }
   }
   p_window_id=orig_view_id;
   return hasWildCards;
}

void _ExpandXMLFilesNode(int handle,int FilesNode)
{
   // get list of F tags
   typeless nodeList[] = null;
   _xmlcfg_find_simple_array(handle, "//" VPJTAG_F, nodeList, FilesNode);
   int i;
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      // get the filename
      _str name = _xmlcfg_get_attribute(handle, node, "N");
      if(!iswildcard(name)) continue;

      // get the path of the wildcard
      _str path = _strip_filename(name, "N");
      _str wildcard = _strip_filename(name, "P");
      _str pathList[] = null;
      pathList[0] = absolute(path, _strip_filename(_xmlcfg_get_filename(handle), "N"));
      // does it just look like a wildcard, but actually does exist on disk?
      if (file_exists(pathList[0])) continue;
      // expand the wildcard specification
      _ExpandFileView2(handle, node, wildcard, pathList, true);
   }
}

#define MSVC_HEADER_STRING '# Microsoft Developer Studio'
#define MAKEFILE_INI_FILE 'makefile.ini'

#define BEGIN_GROUP_PREFIX      '# Begin Group "'
#define END_GROUP_PREFIX        '# End Group'
#define EXT_LIST_PREFIX         '# PROP Default_Filter "'
#define BEGIN_FILE_PREFIX       '# Begin Source File'
#define END_FILE_PREFIX         '# End Source File'
#define END_TARGET_PREFIX       '# End Target'
#define SOURCE_FILE_PREFIX      'SOURCE='
#define EXCLUDE_FROM_BUILD_LINE '# PROP Exclude_From_Build 1'
#define NAME_PREFIX             '# Name'


/**
 * Strips the last directory or filename off, and then
 * removes the trailing FILESEP at the end so that
 * we are set up to do this again.
 *
 * @param Path   Path to strip
 *
 * @return returns Path w/o the the filename/last dir name,
 *         and w/o a trailing FILESEP.
 */
static _str StripLastDir(_str Path)
{
   _str NewPath=_strip_filename(Path,'N');
   NewPath=substr(NewPath,1,length(NewPath)-1);
   return(NewPath);
}

/**
 * Gets the file case on disk for filename,
 *
 * This is pretty expensive, it does a file_match
 * for every directory in the path
 *
 * @param filename name of file to get the cased name for.
 *                 This must be an absolute filename.
 *
 *                 It can be a directory name as long as it is absolute.
 *
 * @return Filename as it appears on disk
 */
static _str GetWin32FileCase(_str filename)
{
   //We build thie filename backwards, as we get each correctly cased piece.
   _str newfilename='';
   boolean filename_is_path=last_char(filename)==FILESEP;
   if (filename_is_path) {
      //If this is a path, we have to strip off the trailing FILESEP
      filename=substr(filename,1,length(filename)-1);
   }
   for (;;) {
      if (filename=='') break;
      //Get the cased version of the current file piece and save it
      _str curfilename=file_match(maybe_quote_filename(filename)' -p +d',1);
      //Strip the last part off of the filename
      if (newfilename=='') {
         if (filename_is_path) {
            //Since this is the first segment, if filename was a path, this
            //will have a FILESEP on the end of it that we have to get rid
            //of
            curfilename=substr(curfilename,1,length(curfilename)-1);
         }
         //Strip off the path
         _str nextpiece=_strip_filename(curfilename,'P');
         //Since this is the first part just store it in newfilename
         newfilename=nextpiece;
      }else{
         //After the first piece, we have to take off the FILESEP at the end,
         //then strip the path
         _str nextpiece=_strip_filename(substr(curfilename,1,length(curfilename)-1),'P');
         //Prepend this to newfilename with a separating FILESEP
         newfilename=nextpiece:+FILESEP:+newfilename;
      }
      //Strip off this directory
      filename=StripLastDir(filename);

      //Check to see what we have left
      if (length(filename)==2 && substr(filename,2,1)==':') {
         //If we have a drive letter, like "C:", upcase it and stop
         newfilename=upcase(filename):+FILESEP:+newfilename;
         break;
      }
   }
   if (filename_is_path) {
      //if filename is a path, we have to add the trailing FILESEP back on
      newfilename=newfilename:+FILESEP;
   }
   return(newfilename);
}

#define VERSION_MARKER_PREFIX '# Microsoft Developer Studio Generated Build File, Format Version'

/**
 * Checks to see that the project file in the current
 * view is a version that we recognize.
 *
 * @return true if we recognize it
 */
static boolean IsValidVisualStudioProjectFile(boolean &isWhidbey_csharp=null)
{
   boolean dummy=false;
   if (isWhidbey_csharp==null) {
      isWhidbey_csharp=dummy;
   }
   isWhidbey_csharp=false;

   top();
   get_line(auto line);
   if (pos('<VisualStudioProject',line)>0) {
      return(true);
   }
   if (pos('<Project',line)>0) {
      isWhidbey_csharp=true;
      return(true);
   }

   down();
   get_line(line);
   if (pos('<VisualStudioProject',line)>0) {
      return(true);
   }
   if (pos('<Project',line)>0) {
      isWhidbey_csharp=true;
      return(true);
   }

   return(false);
}
/**
 * Checks to see that the dsp file in the current
 * view is a version that we recognize.
 *
 * @return True if we recognize it
 */
static boolean IsValidDSPVersion()
{
   top();
   int status=search('^'_escape_re_chars(VERSION_MARKER_PREFIX)'?@$','@rh');
   if (status) {
      _message_box(nls("Cannot save files for this associated project file, cannot find version marker"));
      return(false);
   }
   get_line(auto line);
   parse line with (VERSION_MARKER_PREFIX) version;
   version=strip(version);
   if (version=='6.00' || version==60000) {
      return(true);
   }
   return(false);
}

/**
 * Checks to see if a project file is writable.
 *
 * This function can open one or two files.
 *
 * @param AnyProjectFilename
 *               Project filename.  If you know that you have a non-VSE
 *               project file, it is cheaper to call with the third party
 *               filename because then we do not have to get it out of the
 *               .vpj file.
 *
 * @return true if we can write files into this project.
 */
boolean _CanWriteFileSection(_str AnyProjectFilename=_project_name)
{
   if(!_IsWorkspaceAssociated(_workspace_filename)) {
      return(true);
   }
   _str makefiletype='';
   if (_IsVSEProjectFilename(AnyProjectFilename)) {
      //AnyProjectFilename Is VSE project, see if there is an association
      //int status=_ini_get_value(AnyProjectFilename,"ASSOCIATION","makefile",makefilename,'');
      _str makefilename;
      int status=_GetAssociatedProjectInfo(AnyProjectFilename,makefilename,makefiletype);
      if (status) {
         //If there is not an association, it is writable
         return(true);
      }
      if (file_eq(_get_extension(makefilename,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         makefilename = absolute(getICProjAssociatedProjectFile(makefilename),_strip_filename(AnyProjectFilename,'N'));
      }
      //Look at the associated file from her on
      AnyProjectFilename=makefilename;
   }

   if (makefiletype==XCODE_PROJECT_VENDOR_NAME) {
      return true;
   }

   // check for jbuilder project
   if(file_eq( _get_extension(AnyProjectFilename,true), JBUILDER_PROJECT_EXT)) {
      return true;
   }

   _str ext = _get_extension(AnyProjectFilename,true);
   // check for visual studio projects
   if ( !file_eq( ext,VCPP_PROJECT_FILE_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_VB_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_VCX_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT) &&
        !file_eq( ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)
         )  {
      //If it is associated, but not VC++, we cannot do anything
      return(false);
   }

   //Open the third party(.dsp) file
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(AnyProjectFilename,temp_view_id,orig_view_id);
   if (status) {
      // if we cannot open it, return false because we know it is associated,
      // but we cannot write the whole file by ourself
      return(false);
   }

   //check to see that this is a version that we recognize
   boolean isWhidbey_csharp;
   boolean writeable=IsValidVisualStudioProjectFile(isWhidbey_csharp);
   if (!writeable) {
      writeable=IsValidDSPVersion();
   }
//    else if (isWhidbey_csharp) {
//       writeable=false;
//    }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(writeable);
}


/**
 * Saves files in the "Project files" listbox to the associated VC++
 * makefile(probably be a .dsp file - until they change the ext again)
 *
 * This must be called with the file box on the
 * _project_form dialog as the active object.
 *
 * @return 0 if succesful
 */
int SaveAssociatedProjectFiles(int _srcfile_list_view_id,_str ProjectFilename=_project_name)
{
   //Find the associated makefile(.dsp file).
   //int status=_ini_get_value(ProjectFilename,"ASSOCIATION","makefile",makefilename,'');
   _str makefilename;
   _str indirect_makefile = "";
   int status=_GetAssociatedProjectInfo(ProjectFilename,makefilename);
   if (status) return(status);
   if (file_eq(_get_extension(makefilename,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      indirect_makefile = makefilename;
      makefilename = absolute(getICProjAssociatedProjectFile(makefilename),_strip_filename(ProjectFilename,'N'));
   }

   _str ext=_get_extension(makefilename,1);
   if ( file_eq(ext, VCPP_PROJECT_FILE_EXT) ) {
      //Open the makefile(.dsp file)
      int makefile_view_id,orig_view_id;
      status=_open_temp_view(makefilename,makefile_view_id,orig_view_id);
      if (status) return(status);

      if (!IsValidDSPVersion()) {
         _message_box(nls("Cannot save files for this associated project file, unknown version.\n\nPlease contact SlickEdit Technical support"));
         p_window_id=orig_view_id;
         _delete_temp_view(makefile_view_id);
         return(0);
      }
      top();
      //Make the original view active, but keep the makefile around
      p_window_id=orig_view_id;

      //Make a backup of the file
      copy_file(makefilename,_strip_filename(makefilename,'E'):+'.bak');

      //Get the groups of file extensions
      _str GroupsInMakefile[]=null;
      GetVCPPGroups(makefile_view_id,GroupsInMakefile);

      //True if we have any rc files
      boolean have_rc_file=false;

      //Get the all of the source files
      _str FilesInMakefile[]=null;
      status=GetVCPP6Files(makefile_view_id,FilesInMakefile,have_rc_file);

      //Save the current window id and activate the project list box
      p_window_id=_srcfile_list_view_id;
      sort_buffer('-f');

      _str ProjectPath=_strip_filename(makefilename,'N');

      top();
      //Loop throught the files that are in the makefile, and remove the ones
      //that are in the list box
      int i;
      for (i=0;i<FilesInMakefile._length();++i) {
         _str curfilename=FilesInMakefile[i];
         if (substr(curfilename,1,2)=='.'FILESEP) {
            curfilename=substr(curfilename,3);
         }

         //Should not have to go to the top every time, the files are sorted
         //top();
         //Look for the file in the list
         if (!search('^'_escape_re_chars(curfilename)'$','@rh>'_fpos_case)) {
            //If we have it in the list and in the array, delete it from both
            //and don't worry about these.  This way, we are left with items
            //to be deleted in the array, and items to be added in the list.
            FilesInMakefile._deleteel(i);
            _delete_line();
            up();
            --i;
         }
      }
      //All of the files that are left in the list are new files that the user
      //added.  We put them into an array
      _str RelNewFiles[]=null;
      _str AbsNewFiles[]=null;
      _str OtherFiles[]=null;
      _str MakefilePath=_strip_filename(makefilename,'N');
      //Start at the top
      top();up();
      _str line;
      while (!down()) {
         //Get the current file
         //Convert it to absolute
         get_line(line);
         _str temp=absolute(line,MakefilePath);
         if (file_eq(_get_extension(temp),'rc')) {
            have_rc_file=true;
         }
         //Store a copy of the absolute filename
         AbsNewFiles[AbsNewFiles._length()]=temp;
         //Get the filename as it appears on disk(have to have abs filename for this)
         temp=GetWin32FileCase(temp);
         //Convert the filename back to relative
         temp=relative(temp,MakefilePath);
         //Store the relativei filename
         RelNewFiles[RelNewFiles._length()]=temp;
      }
      //Switch to view id of the .dsp file
      p_window_id=makefile_view_id;

      p_modify=0;
      top();

      //Open the tag database here.  We will make multiple calls to
      //RemoveFileFromVCPP6ProjectFile which individually removes many file
      //from the database
      _str tag_filename=_GetWorkspaceTagsFilename();
      status=tag_open_db(tag_filename);
      if (status < 0) {
         _message_box(nls("Unable to open tag file %s",tag_filename));
         return(status);
      }

      //Any filenames left in FilesInMakefile were deleted from the project dialog.
      //Remove the from the .dsp file
      //This funciton will remove them from the tag file too
      for (i=0;i<FilesInMakefile._length();++i) {
         status=RemoveFileFromVCPP6ProjectFile(FilesInMakefile[i]);

         //Get the absolute filename
         _str abs_filename=absolute(FilesInMakefile[i],_strip_filename(ProjectFilename,'N'));
         //Use the absolute filename to remove the file from the tags database
         tag_remove_from_file(abs_filename);
         message('Removing 'abs_filename' from 'tag_filename);
      }

      //Add the new files to the .dsp file
      for (i=0;i<RelNewFiles._length();++i) {
         AddFileToVCPP6ProjectFile(GroupsInMakefile,RelNewFiles[i],MakefilePath);
      }
      //Add the new files to the tag file.  This is done a little differently
      //from the way we remove the files because there was a really convenient
      //funciton to do this already.
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      int len=AbsNewFiles._length();
      for (i=0;i<len;++i) {
         RetagFile(AbsNewFiles[i], useThread);
         message('Tagging 'i'/'len': 'AbsNewFiles[i]);
      }
      //Close the database
      tag_close_db(tag_filename,1);

      if (p_modify) {
         status=_save_file('+o');

         if ( status ) {
            _message_box(nls("Could not save project file '%s'.\n\n%s",p_buf_name,get_message(status)));
         }
         //Since we save the project(.dsp) file, we have to match up the date in the
         //workspace file or we will retag everything again.

         // Moved this down below
         /*_ini_set_value(
            VSEWorkspaceFilename(_workspace_filename),
            "ProjectDates",
            GetProjectDisplayName(relative(_project_name,strip_filename(_workspace_filename,'N'))),
            _file_date(makefilename,'B'));*/
      }
      //Switch to the original view and delete the one with the .dsp file
      p_window_id=orig_view_id;
      _delete_temp_view(makefile_view_id);
      if (status) return(status);

   }else if ( file_eq(ext, VISUAL_STUDIO_VCPP_PROJECT_EXT) ) {
      status=WriteVisualStudioVCPPProjectFile(_srcfile_list_view_id,makefilename);
      if (status) return(status);
      if (indirect_makefile != '') {
         _ProjectCache_Update(indirect_makefile);
      }
   }else if ( file_eq(ext, VISUAL_STUDIO_VCX_PROJECT_EXT) ) {
      status=WriteVisualStudioVCXProjectFile(_srcfile_list_view_id,makefilename);
      if (status) return(status);
   }else if(file_eq(ext, JBUILDER_PROJECT_EXT)) {
      status = _UpdateFilesInJBuilderProject(_srcfile_list_view_id, makefilename);
   }else if(file_eq(_get_extension(makefilename,1), PRJ_FILE_EXT)) {
      // since Xcode only has workspace files, the vpj association points back to itself
      status = _xcode_update_files(_srcfile_list_view_id,makefilename);
   }else {
      status=WriteVisualStudioStandardProjectFile(_srcfile_list_view_id,makefilename,ext);
      if (status) return(status);
   }
   _WorkspacePutProjectDate(makefilename);
   return(0);
}
static int AddFileToVisualStudioVCPPProject(_str FileList,_str VisualStudioProjectName,boolean FileExistsOnDisk=true)
{
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   _str list=FileList;
   _str cur;
   for (;;) {
      cur=parse_file(list);
      if (cur=='') break;
      insert_line(' 'relative(cur,_strip_filename(VisualStudioProjectName,'N')));
   }
   p_window_id=orig_view_id;
   int status=WriteVisualStudioVCPPProjectFile2(VisualStudioProjectName,temp_view_id,0,-1,FileExistsOnDisk);
   _delete_temp_view(temp_view_id);
   return(status);
}

static int WriteVisualStudioVCXProjectFile(int _srcfile_list_view_id, _str VisualStudioProjectName)
{
   int status;
   int handle = _xmlcfg_open(VisualStudioProjectName,status,VSXMLCFG_OPEN_ADD_PCDATA,VSENCODING_AUTOXML);
   if (handle<0) {
      return(handle);
   }
   int filter = _xmlcfg_open(VisualStudioProjectName:+'.filters',status,VSXMLCFG_OPEN_ADD_PCDATA,VSENCODING_AUTOXML);

   int FileListViewId=-1;
   int orig_view_id=_create_temp_view(FileListViewId);
   p_window_id=orig_view_id;

   int IndexTable:[]=null;
   _str FilesInXMLFile[]=null;
   GetFileListFromVisualStudioFile(VisualStudioProjectName,FileListViewId,FilesInXMLFile,IndexTable,null,handle,true,false,false);

   p_window_id=_srcfile_list_view_id;
   int i;
   for (i=0;i<FilesInXMLFile._length();++i) {
      _str curfilename=_RelativeToProject(FilesInXMLFile[i],VisualStudioProjectName);

      top();
      //Look for the file in the list
      if (!search('^'_escape_re_chars(curfilename)'$','@rh>'_fpos_case)) {
         //If we have it in the list and in the array, delete it from both
         //and don't worry about these.  This way, we are left with items
         //to be deleted in the array, and items to be added in the list.
         FilesInXMLFile._deleteel(i);
         _delete_line();
         up();
         --i;
      }
   }
   int RemoveFileListViewId=0;
   _create_temp_view(RemoveFileListViewId);
   p_window_id=RemoveFileListViewId;
   for (i=0;i<FilesInXMLFile._length();++i) {
      insert_line(FilesInXMLFile[i]);
   }
   p_window_id=orig_view_id;

   status=WriteVisualStudioVCXProjectFile2(VisualStudioProjectName,_srcfile_list_view_id,RemoveFileListViewId,handle,filter,true,true);
   _delete_temp_view(FileListViewId);
   _delete_temp_view(RemoveFileListViewId);
   return(status);
}

static void GetVCXBuildTaskExtensions(_str projectExt, _str (&ExtToTask):[])
{
   ExtToTask._makeempty();
   ExtToTask:['cpp']    = 'ClCompile';
   ExtToTask:['c']      = 'ClCompile';
   ExtToTask:['cc']     = 'ClCompile';
   ExtToTask:['cxx']    = 'ClCompile';
   ExtToTask:['h']      = 'ClInclude';
   ExtToTask:['hpp']    = 'ClInclude';
   ExtToTask:['hxx']    = 'ClInclude';
   ExtToTask:['inl']    = 'ClInclude';
   ExtToTask:['rc']     = 'ResourceCompile';
   ExtToTask:['idl']    = 'Midl';
   ExtToTask:['resx']   = 'EmbeddedResource';
   ExtToTask:['rdlc']   = 'EmbeddedResource';
}

static int WriteVisualStudioVCXProjectFile2(_str VisualStudioProjectFilename,
                                            int AddViewId,
                                            int RemoveViewId,
                                            int handle, int filter,
                                            boolean FileExistsOnDisk,
                                            boolean doTagging)
{
   int vs2010Indent = 2;
   int vs2010SaveFlags = VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_SPACE_AFTER_LAST_ATTRIBUTE|VSXMLCFG_SAVE_PCDATA_INLINE|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE;
 
   int status;
   _str TagFilename=project_tags_filename();
   int FileToNode:[];
   int FilterFileToNode:[];
   //////////////////
   // Removing files
   if (RemoveViewId) {
      int open_status=tag_open_db(TagFilename);
      //Save the current window id and activate the project list box
      int orig_view_id=p_window_id;
      p_window_id=RemoveViewId;
      top();up();
      _csproj2005Get_FileToNodeHashTab(handle,FileToNode);
      if (filter > 0) {
         _csproj2005Get_FileToNodeHashTab(filter,FilterFileToNode);
      }
      _str projectFileAbsPath = _xmlcfg_get_filename(handle);
      _str cur_filename,RelFilename;
      for (;;) {
         if (down()) break;
         get_line(cur_filename);
         cur_filename=strip(cur_filename);
         if (open_status >= 0 && doTagging) {
            message('Removing 'cur_filename' from 'TagFilename);
            tag_remove_from_file(cur_filename);
         }
         RelFilename=_RelativeToProject(cur_filename, projectFileAbsPath);
         int *pnode=FileToNode._indexin(_file_case(RelFilename));
         if (pnode) {
            _xmlcfg_delete(handle,*pnode);
         }
         if (filter > 0) {
            pnode=FilterFileToNode._indexin(_file_case(RelFilename));
            if (pnode) {
               _xmlcfg_delete(filter,*pnode);
            }
         }
      }

      // cleanup empty groups
      typeless itemGroups;
      _xmlcfg_find_simple_array(handle, '/Project/ItemGroup', itemGroups);
      foreach (auto groupNode in itemGroups) {
         node := _xmlcfg_get_first_child(handle, groupNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         if (node < 0) {
            _xmlcfg_delete(handle, groupNode);
         }
      }

      if (filter > 0) {
         _xmlcfg_find_simple_array(filter, '/Project/ItemGroup', itemGroups);
         foreach (groupNode in itemGroups) {
            node := _xmlcfg_get_first_child(filter, groupNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
            if (node < 0) {
               _xmlcfg_delete(filter, groupNode);
            }
         }
      }
      p_window_id=orig_view_id;
   }
   if (!AddViewId) {
      if (RemoveViewId) {
         vc_make_file_writable(VisualStudioProjectFilename);
         _clearWorkspaceFileListCache();
         status=_xmlcfg_save(handle,vs2010Indent,vs2010SaveFlags);
         _xmlcfg_close(handle);
         _ProjectCache_Update(VisualStudioProjectFilename);
         if (filter > 0) {
            _xmlcfg_save(filter,vs2010Indent,vs2010SaveFlags);
            _xmlcfg_close(filter);
         }
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         tag_close_db('',1);
         return(status);
      }
   }

   /////////////////////
   // Adding files
   int orig_view_id=p_window_id;
   p_window_id=AddViewId;

   _str TasksPerExtension:[];
   GetVCXBuildTaskExtensions(_get_extension(VisualStudioProjectFilename,true), TasksPerExtension);

   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_window_id=AddViewId;top();up();
   while (!down()) {
      _str RelFilename = '';
      get_line(RelFilename);
      RelFilename=strip(RelFilename);

      // Don't double-add files
      if (!FileToNode._indexin(_file_case(RelFilename))) {

         // Insert the absolute path into the tagging hint temp file
         activate_window(temp_view_id);
         insert_line(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(handle)));
         p_window_id=AddViewId;
        
         // Determine the default build task name for this file extension
         _str taskName = 'None';
         _str fileExt = _get_extension(RelFilename);
         if(TasksPerExtension._indexin(fileExt)) {
            taskName = TasksPerExtension:[fileExt];
         }

         parentNode := -1;
         node := _xmlcfg_find_simple(handle, '/Project/ItemGroup/'taskName);
         if (node > 0) {
            parentNode = _xmlcfg_get_parent(handle, node);
         } else {
            // add new item group
            node = _xmlcfg_find_simple(handle, '/Project');
            if (node > 0) {
               parentNode = _xmlcfg_add(handle, node, 'ItemGroup', VSXMLCFG_ELEMENT_END, VSXMLCFG_ADD_AS_CHILD);
            }
         }

         if (parentNode > 0) {
            node = _xmlcfg_add(handle, parentNode, taskName, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_add_attribute(handle, node, "Include", RelFilename, VSXMLCFG_ADD_ATTR_AT_END);
         }
      }
   }
   TasksPerExtension._makeempty();

   if (doTagging) {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      tag_add_viewlist(TagFilename,temp_view_id,null,false,FileExistsOnDisk,useThread);
   }

   activate_window(orig_view_id);

   // Save the file
   vc_make_file_writable(VisualStudioProjectFilename);
   _clearWorkspaceFileListCache();
   status=_xmlcfg_save(handle,vs2010Indent,vs2010SaveFlags);
   _xmlcfg_close(handle);
   _ProjectCache_Update(VisualStudioProjectFilename);
   if (!status && filter > 0) {
      _xmlcfg_save(filter,vs2010Indent,vs2010SaveFlags);
      _xmlcfg_close(filter);
   }
   if (status) {
      _message_box(nls("Could not save project file '%s'.\n\n%s",VisualStudioProjectFilename,get_message(status)));
   }
   if (!status) {
      _WorkspacePutProjectDate(VisualStudioProjectFilename);
   }
   return(status);
}

static int WriteVisualStudioVCPPProjectFile(int _srcfile_list_view_id, _str VisualStudioProjectName)
{
   int handle=_ProjectAssociatedHandle(VisualStudioProjectName);
   if (handle<0) {
      return(handle);
   }
   int FileListViewId=-1;
   int orig_view_id=_create_temp_view(FileListViewId);
   p_window_id=orig_view_id;

   int IndexTable:[]=null;
   _str FilesInXMLFile[]=null;
   // 9/1/2005 - RB
   // ResolveLinks=false because VStudio only understands the relative-path
   // of file when removing files from project.
   // TODO:
   // Cannot currently add link files in a VStudio project.
   // Expose a way in GUI to add links to VStudio .NET projects. A link node
   // in a .csproj file looks like this:
   //
   // <File
   //     RelPath = "foo.cs"
   //     Link = "..\relative\foo.cs"
   //     BuildAction = "Compile"
   // />
   GetFileListFromVisualStudioFile(VisualStudioProjectName,FileListViewId,FilesInXMLFile,IndexTable,null,handle,true,false,false);

   p_window_id=_srcfile_list_view_id;
   int i;
   for (i=0;i<FilesInXMLFile._length();++i) {
      _str curfilename=_RelativeToProject(FilesInXMLFile[i],VisualStudioProjectName);

      top();
      //Look for the file in the list
      if (!search('^'_escape_re_chars(curfilename)'$','@rh>'_fpos_case)) {
         //If we have it in the list and in the array, delete it from both
         //and don't worry about these.  This way, we are left with items
         //to be deleted in the array, and items to be added in the list.
         FilesInXMLFile._deleteel(i);
         _delete_line();
         up();
         --i;
      }
   }
   int RemoveFileListViewId=0;
   _create_temp_view(RemoveFileListViewId);
   p_window_id=RemoveFileListViewId;
   for (i=0;i<FilesInXMLFile._length();++i) {
      insert_line(FilesInXMLFile[i]);
   }
   p_window_id=orig_view_id;
   int status=WriteVisualStudioVCPPProjectFile2(VisualStudioProjectName,_srcfile_list_view_id,RemoveFileListViewId,handle,true,true);
   _delete_temp_view(FileListViewId);
   _delete_temp_view(RemoveFileListViewId);
   //_xmlcfg_close(handle);
   return(status);
}

static int WriteVisualStudioVCPPProjectFile2(_str VisualStudioProjectName,
                                             int AddViewId,
                                             int RemoveViewId,
                                             int handle=-1,
                                             boolean FileExistsOnDisk=true,
                                             boolean doTagging=false)
{
   int vsVCPPIndent = -1;  // use tabs
   int vsVCPPSaveFlags = VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE;

   if (handle<0) {
      handle=_ProjectAssociatedHandle(VisualStudioProjectName);
      if (handle<0) {
         return(handle);
      }
   }

   // Get the tree indexes of the filter lists
   // Try changing this to:
   // _xmlcfg_find_simple_array(handle,"Filter",FilterIndexes,1);
   //for (i=0;i<FilterIndexes._length();++i) {
   //   cap=_xmlcfg_get_attribute(handle,FilterIndexes[i],'Name');
   //}
   int FileToNode:[];
   _vcprojGet_FileToNodeHashTab(handle,FileToNode);

   _str TagFilename=project_tags_filename();
   _str ProjectPath=_file_path(_xmlcfg_get_filename(handle));
   if (RemoveViewId) {
      int open_status=tag_open_db(TagFilename);

      int orig_view_id=p_window_id;
      p_window_id=RemoveViewId;
      top();up();
      _str cur_filename,RelFilename;
      for (;;) {
         if (down()) break;
         get_line(cur_filename);
         cur_filename=strip(cur_filename);

         if (open_status >= 0 && doTagging) {
            message('Removing 'cur_filename' from 'TagFilename);
            tag_remove_from_file(cur_filename);
         }

         RelFilename=_RelativeToProject(cur_filename,_xmlcfg_get_filename(handle));
         RelFilename=ConvertToVCPPRelFilename(RelFilename,ProjectPath);
         int *pnode=FileToNode._indexin(_file_case(RelFilename));
         if (pnode) {
            _xmlcfg_delete(handle,*pnode);
         }

         //DeleteFromVisualStudioTree(cur_filename,handle,FilteredFileIndexes,OtherFileIndexes);
      }
      p_window_id=orig_view_id;
   }
   if (!AddViewId) {
      int status=0;
      if (RemoveViewId) {
         vc_make_file_writable(VisualStudioProjectName);
         _clearWorkspaceFileListCache();
         status=_xmlcfg_save(handle, vsVCPPIndent, vsVCPPSaveFlags);
         if (status) {
            _message_box(nls("Could not save project file '%s'.\n\n%s",VisualStudioProjectName,get_message(status)));
         }
         _xmlcfg_close(handle);
         _ProjectCache_Update(VisualStudioProjectName);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         tag_close_db('',1);
      }
      return(status);
   }
   int DollarTable:[];
   _str ConfigurationNames[];
   _ProjectGet_ObjectFileInfo(handle,DollarTable,ConfigurationNames);

   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(handle,ExtToNodeHashTab);
   //_vcprojGetFilterNodeInfo(handle,ExtToNodeHashTab);

   int orig_view_id=p_window_id;
   p_window_id=AddViewId;
   _str lastext=null;
   int LastNode= -1;
   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_window_id=AddViewId;top();up();
   _str cur_filename,RelFilename,ext;
   for (;;) {
      if (down()) {
         break;
      }
      get_line(cur_filename);
      cur_filename=strip(cur_filename);

      RelFilename=_RelativeToProject(cur_filename,_xmlcfg_get_filename(handle));
      RelFilename=ConvertToVCPPRelFilename(RelFilename,ProjectPath);
      int *pnode=FileToNode._indexin(_file_case(RelFilename));
      if (!pnode) {
         ext=_get_extension(RelFilename);
         // We need to add this file
         pnode=ExtToNodeHashTab._indexin(_file_case(ext));
         if (!pnode) {
            pnode=ExtToNodeHashTab._indexin('');
         }
         int i;
         int newindex;
         // Add the new item
         if (ext==lastext) {
            newindex=_xmlcfg_add(handle,LastNode,"File",VSXMLCFG_ELEMENT_START,0);
         } else {
            newindex=_xmlcfg_add(handle,*pnode,"File",VSXMLCFG_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         }
         // Add the RelativePath attribute to the item that we just added
         _xmlcfg_add_attribute(handle,newindex,"RelativePath",RelFilename,VSXMLCFG_ADD_ATTR_AT_END);

         activate_window(temp_view_id);
         insert_line(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(handle)));
         p_window_id=AddViewId;
         _ProjectSet_ObjectFileInfo(handle,DollarTable,ConfigurationNames,newindex,RelFilename);
         LastNode=newindex;
         lastext=ext;
      }
   }
   if (doTagging) {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      tag_add_viewlist(TagFilename,temp_view_id,null,false,FileExistsOnDisk,useThread);
   }

   _ProjectSortFolderNodesInHashTable(handle,ExtToNodeHashTab);

   p_window_id=orig_view_id;
   vc_make_file_writable(VisualStudioProjectName);
   _clearWorkspaceFileListCache();
   int status=_xmlcfg_save(handle, vsVCPPIndent, vsVCPPSaveFlags);
   if (status) {
      _message_box(nls("Could not save project file '%s'.\n\n%s", VisualStudioProjectName, get_message(status)));
   }
   _xmlcfg_close(handle);
   _ProjectCache_Update(VisualStudioProjectName);
   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   tag_close_db('',1);
   return(status);
}

static int WriteVisualStudioCSharpProjectFile(int _srcfile_list_view_id,_str VisualStudioProjectFilename)
{
   return(WriteVisualStudioStandardProjectFile(_srcfile_list_view_id,VisualStudioProjectFilename,/*"CSHARP",*/'cs'));
}

static int WriteVisualStudioVBProjectFile(int _srcfile_list_view_id,_str VisualStudioProjectFilename)
{
   return(WriteVisualStudioStandardProjectFile(_srcfile_list_view_id,VisualStudioProjectFilename,/*"VisualBasic",*/'vb'));
}

static int AddFileToVisualStudioStandardProject(_str FileList,_str VisualStudioProjectName,
                                                _str ext,boolean FileExistsOnDisk=true)
{
   _str AppName=GetVSStandardAppName(ext);
   _str CompileExtensionList=GetVSStandardExt(ext);
   if (AppName:=='' || CompileExtensionList:=='') {
      return(0);
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   _str list=FileList;
   _str cur;
   for (;;) {
      cur=parse_file(list);
      if (cur=='') break;
      insert_line(' 'relative(cur,_strip_filename(VisualStudioProjectName,'N')));
   }
   p_window_id=orig_view_id;
   int status=WriteVisualStudioStandardProjectFile2(VisualStudioProjectName,
                                                AppName,
                                                CompileExtensionList,
                                                0,
                                                temp_view_id,
                                                -1,FileExistsOnDisk);
   _delete_temp_view(temp_view_id);
   return(status);
}

static int WriteVisualStudioStandardProjectFile(int _srcfile_list_view_id,
                                                _str VisualStudioProjectFilename,
                                                _str ext)
{
   _str AppName=GetVSStandardAppName(ext);
   _str CompileExtensionList=GetVSStandardExt(ext);
   int status;
   int handle=_xmlcfg_open(VisualStudioProjectFilename,status);
   if (handle<0) {
      return(status);
   }
   int FileListViewId=-1;
   int orig_view_id=_create_temp_view(FileListViewId);
   p_window_id=orig_view_id;

   int IndexTable:[]=null;
   _str FilesInXMLFile[]=null;

   // 9/1/2005 - RB
   // ResolveLinks=false because VStudio only understands the relative-path
   // of file when removing files from project.
   // TODO:
   // Cannot currently add link files in a VStudio project.
   // Expose a way in GUI to add links to VStudio .NET projects. A link node
   // in a .csproj file looks like this:
   //
   // <File
   //     RelPath = "foo.cs"
   //     Link = "..\relative\foo.cs"
   //     BuildAction = "Compile"
   // />
   GetFileListFromVisualStudioFile(VisualStudioProjectFilename,FileListViewId,FilesInXMLFile,IndexTable,null,-1,true,false,false);
  
   p_window_id=_srcfile_list_view_id;
   int i;
   for (i=0;i<FilesInXMLFile._length();++i) {
      _str curfilename=_RelativeToProject(FilesInXMLFile[i]);

      top();
      //Look for the file in the list
      if (!search('^'_escape_re_chars(curfilename)'$','@rh>'_fpos_case)) {
         //If we have it in the list and in the array, delete it from both
         //and don't worry about these.  This way, we are left with items
         //to be deleted in the array, and items to be added in the list.
         FilesInXMLFile._deleteel(i);
         _delete_line();
         up();
         --i;
      }
   }

   int RemoveFileListViewId=0;
   orig_view_id=_create_temp_view(RemoveFileListViewId);
   p_window_id=RemoveFileListViewId;
   for (i=0;i<FilesInXMLFile._length();++i) {
      insert_line(FilesInXMLFile[i]);
   }
   p_window_id=orig_view_id;

   status=WriteVisualStudioStandardProjectFile2(VisualStudioProjectFilename,
                                                AppName,
                                                CompileExtensionList,
                                                RemoveFileListViewId,
                                                _srcfile_list_view_id,
                                                handle,true,true);

   _delete_temp_view(FileListViewId);
   _delete_temp_view(RemoveFileListViewId);
   _xmlcfg_close(handle);
   _ProjectCache_Update(VisualStudioProjectFilename);
   return(status);
}
/**
 * Writes a C# or VB project file.  VC++ project files
 * are completely different, so a different function
 * altogether is called for them. This handles VS2002 and VS2003
 * project files. For Visual Studio 2005 and above, 
 * WriteVisualStudioStandardProjectFile2005 is called instead
 *
 * Checks to see what files were added/deleted and writes
 * appropriately.
 *
 * @param VisualStudioProjectFilename
 *                Name of the Visual Studio project file.
 *
 * @param AppName Name of the application.
 *
 *                This is used in one of the tags.  Should be either
 *                "CSHARP" or "VisualBasic"
 *
 * @param CompileExtensionList
 *                Space delimited list of extensions that are compiled
 *                for this language type.
 *
 * @return 0 if successful
 */
static int WriteVisualStudioStandardProjectFile2(_str VisualStudioProjectFilename,
                                                 _str AppName,
                                                 _str CompileExtensionList,
                                                 int RemoveViewId,
                                                 int AddViewId,
                                                 int handle=-1,
                                                 boolean FileExistsOnDisk=true,
                                                 boolean doTagging=false)
{
   int status;
   if (handle<0) {
      handle=_xmlcfg_open(VisualStudioProjectFilename,status);
      if (handle<0) {
         return(status);
      }
   }

   // Determine if this is a VS2002/2003 project, or a VS2005 project
   // by examining the top-level node in the XML document
   int firstChild = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   if(firstChild >= 0) {
      _str rootName = _xmlcfg_get_name(handle, firstChild);
      if(rootName == 'VisualStudioProject') {
         // This is a VS2002/2003 project file
         return WriteVisualStudioStandardProjectFile2003(VisualStudioProjectFilename,AppName,CompileExtensionList,RemoveViewId,AddViewId,handle,FileExistsOnDisk,doTagging);
      } else if(rootName == 'Project') {
         // This is a VS2005 project file. We need to open it differently so that
         // all the PCData is loaded (and saved)
         _xmlcfg_close(handle);
         handle=_xmlcfg_open(VisualStudioProjectFilename,status,VSXMLCFG_OPEN_ADD_PCDATA,VSENCODING_AUTOXML);
         return WriteVisualStudioStandardProjectFile2005(VisualStudioProjectFilename,AppName,CompileExtensionList,RemoveViewId,AddViewId,handle,FileExistsOnDisk,doTagging);
      }
   }
   return -1;
}

static int WriteVisualStudioStandardProjectFile2003(_str VisualStudioProjectFilename,
                                                 _str AppName,
                                                 _str CompileExtensionList,
                                                 int RemoveViewId,
                                                 int AddViewId,
                                                 int handle,
                                                 boolean FileExistsOnDisk,
                                                 boolean doTagging)
{
   int status;
   _str TagFilename=project_tags_filename();
   //Save the current window id and activate the project list box
   if (RemoveViewId) {
      int open_status=tag_open_db(TagFilename);

      int orig_view_id=p_window_id;
      p_window_id=RemoveViewId;
      top();up();

      int FileToNode:[];
      _csprojGet_FileToNodeHashTab(handle,AppName,FileToNode);
      _str cur_filename,RelFilename;
      for (;;) {
         if (down()) break;
         get_line(cur_filename);
         cur_filename=strip(cur_filename);
         if (open_status >= 0 && doTagging) {
            message('Removing 'cur_filename' from 'TagFilename);
            tag_remove_from_file(cur_filename);
         }
         RelFilename=_RelativeToProject(cur_filename,_xmlcfg_get_filename(handle));
         int *pnode=FileToNode._indexin(_file_case(RelFilename));
         if (pnode) {
            _xmlcfg_delete(handle,*pnode);
         }
      }
      p_window_id=orig_view_id;
   }
   if (!AddViewId) {
      if (RemoveViewId) {
         status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE);
         _xmlcfg_close(handle);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         tag_close_db('',1);
         return(status);
      }
   }
   int orig_view_id=p_window_id;
   p_window_id=AddViewId;

   int IncludeIndex=_xmlcfg_set_path(handle,'/VisualStudioProject/'AppName'/Files/Include');
   int ExtToNode:[];
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/"AppName"/Files/Include/File",array);
   int i;
   _str RelFilename;
   for (i=0;i<array._length();++i) {
      RelFilename=_xmlcfg_get_attribute(handle,array[i],'RelPath');
      ExtToNode:[_file_case(RelFilename)]=array[i];
   }
   int Node=IncludeIndex;
   int flags=VSXMLCFG_ADD_AS_CHILD;
   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_window_id=AddViewId;top();up();
   while (!down()) {
      get_line(RelFilename);
      RelFilename=strip(RelFilename);

      /*
         NOTE:  There is no copy code here like Visual Studio does.  It's easy to copy the file
         here but I think its really a bad idea nobody should want duplicate copies
         of code which can't be kept in sync.
      */
      if (!ExtToNode._indexin(_file_case(RelFilename))) {
         activate_window(temp_view_id);
         insert_line(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(handle)));
         p_window_id=AddViewId;
         // Add the new item
         Node=_xmlcfg_add(handle,Node,"File",VSXMLCFG_ELEMENT_END,flags);
         flags=0;
         // Add the RelativePath attribute to the item that we just added
         _xmlcfg_add_attribute(handle,Node,"RelPath",RelFilename,VSXMLCFG_ADD_ATTR_AT_END);
         if (pos(' '_get_extension(RelFilename)' ',' 'CompileExtensionList' ',1,_fpos_case)) {
            _xmlcfg_add_attribute(handle,Node,"SubType","Code",VSXMLCFG_ADD_ATTR_AT_END);
            _xmlcfg_add_attribute(handle,Node,"BuildAction","Compile",VSXMLCFG_ADD_ATTR_AT_END);
         }else{
            _xmlcfg_add_attribute(handle,Node,"BuildAction","Content",VSXMLCFG_ADD_ATTR_AT_END);
         }
      }
   }
   if (doTagging) {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      tag_add_viewlist(TagFilename,temp_view_id,null,false,FileExistsOnDisk,useThread);
   }

   _xmlcfg_sort_on_attribute(handle,IncludeIndex,'RelPath','F');
   /*
      Don't need this code because VCPP does not care

   int cindex=_xmlcfg_get_first_child(handle,IncludeIndex);
   if (cindex<0) {
      // There are no files left in here
      int pindex=_xmlcfg_get_parent(handle,IncludeIndex);
      _xmlcfg_delete(handle,IncludeIndexes[i]);
      _xmlcfg_add(handle,pindex,"Include",VSXMLCFG_ELEMENT_END,VSXMLCFG_ADD_AS_CHILD);
   } */

   activate_window(orig_view_id);
   // Save the file
   status=_xmlcfg_save(handle,4,VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR|VSXMLCFG_SAVE_SPACE_AROUND_EQUAL|VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE);
   if (status) {
      _message_box(nls("Could not save project file '%s'.\n\n%s",VisualStudioProjectFilename,get_message(status)));
      _xmlcfg_close(handle);
      return(status);
   }
   _xmlcfg_close(handle);
   _WorkspacePutProjectDate(VisualStudioProjectFilename);

   return(status);
}

static int WriteVisualStudioStandardProjectFile2005(_str VisualStudioProjectFilename,
                                                 _str AppName,
                                                 _str CompileExtensionList,
                                                 int RemoveViewId,
                                                 int AddViewId,
                                                 int handle,
                                                 boolean FileExistsOnDisk,
                                                 boolean doTagging)
{
   int vs2005Indent = 2;
   int vs2005SaveFlags = VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_SPACE_AFTER_LAST_ATTRIBUTE|VSXMLCFG_SAVE_PCDATA_INLINE|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE;
 
   int status;
   _str TagFilename=project_tags_filename();
   int FileToNode:[];
   //////////////////
   // Removing files
   if (RemoveViewId) {
      int open_status=tag_open_db(TagFilename);
      //Save the current window id and activate the project list box
      int orig_view_id=p_window_id;
      p_window_id=RemoveViewId;
      top();up();
      _csproj2005Get_FileToNodeHashTab(handle,FileToNode);
      _str projectFileAbsPath = _xmlcfg_get_filename(handle);
      _str cur_filename,RelFilename;
      for (;;) {
         if (down()) break;
         get_line(cur_filename);
         cur_filename=strip(cur_filename);
         if (open_status >= 0 && doTagging) {
            message('Removing 'cur_filename' from 'TagFilename);
            tag_remove_from_file(cur_filename);
         }
         RelFilename=_RelativeToProject(cur_filename, projectFileAbsPath);
         int *pnode=FileToNode._indexin(_file_case(RelFilename));
         if (pnode) {
            // TODO: Prompt for removing other files that
            // are dependent upon this file. (Like form.cs and form.designer.cs)
            int nodeToDelete = *pnode;
            int dependentNodes[];
            _str dependentNodeFileNames[];
            if(GetVS2005DependentNodes(handle, nodeToDelete, RelFilename, dependentNodes, dependentNodeFileNames))
            {
               // Dependents were found for this file.
               // If they are already in the list, great. They'll be taken care of
               // in a subsequent delete.
               // If not we'll need to prompt the user to see if the dependent should be removed
               int numDeps = dependentNodes._length();
               int depIdx = 0;
               typeless oldPos;
               save_pos(oldPos);
               for(; depIdx < numDeps; ++depIdx)
               {
                  // Search the "delete view"  (RemoveViewId) to see if this file
                  // has already been scheduled to be removed.
                  _str depFileRelName = dependentNodeFileNames[depIdx];
                  _str depFileAbsPath = _AbsoluteToProject(depFileRelName, projectFileAbsPath);
                  top(); up();
                  if(search(depFileAbsPath, '@Ih') == STRING_NOT_FOUND_RC)
                  {
                     // Nope, this dependent file has not been chosen already for removal.
                     // Prompt the user if they want this file removed as well.
                     int currentId = p_window_id;
                     _str promptMsg = 'Project file 'depFileAbsPath" depends upon \r"RelFilename", which is being removed.\rDo you also want to remove "depFileRelName'?';
                     _str choice = _message_box(promptMsg, 'Remove dependent file', MB_YESNO | MB_ICONQUESTION);
                     if(choice == IDYES)
                     {
                        // Yep, they want this one to go too. 
                        // Remove it from the XML tree, and remove it from the tag database.
                        tag_remove_from_file(depFileAbsPath);
                        _xmlcfg_delete(handle, dependentNodes[depIdx]);
                     }
                     p_window_id = currentId;
                  }
               }
               restore_pos(oldPos);
            }
            _xmlcfg_delete(handle,*pnode);
         }
      }
      p_window_id=orig_view_id;
   }
   if (!AddViewId) {
      if (RemoveViewId) {
         status=_xmlcfg_save(handle,vs2005Indent,vs2005SaveFlags);
         _xmlcfg_close(handle);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         tag_close_db('',1);
         return(status);
      }
   }
   /////////////////////
   // Adding files
   int orig_view_id=p_window_id;
   p_window_id=AddViewId;

   // Fill the hash table with existing relative paths
   int itemGroupNode = _csproj2005Get_FileToNodeHashTab(handle,FileToNode);

   // If there is not already an ItemGroup node containing
   // compilable files or resources, then we'll need to create one here
   if(itemGroupNode < 0)
   {
      _xmlcfg_save(handle,vs2005Indent,vs2005SaveFlags);
      return -1;
   }

   // Based on the project extension, get a list of build tasks
   // for each kind of file extension
   // (See the comment for GetVS2005BuildTaskExtensions)
   _str resourceExtList, compileExtList, contentExtList;
   _str TasksPerExtension:[];
   GetVS2005BuildTaskExtensions(_get_extension(VisualStudioProjectFilename,true), TasksPerExtension);
   
   int flags=VSXMLCFG_ADD_AS_CHILD;
   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_window_id=AddViewId;top();up();
   while (!down()) {
      _str RelFilename = '';
      get_line(RelFilename);
      RelFilename=strip(RelFilename);

      // Don't double-add files
      if (!FileToNode._indexin(_file_case(RelFilename))) {

         // Insert the absolute path into the tagging hint temp file
         activate_window(temp_view_id);
         insert_line(_AbsoluteToProject(RelFilename,_xmlcfg_get_filename(handle)));
         p_window_id=AddViewId;
        
         // Determine the default build task name for this file extension
         _str fileTaskName = 'None';
         _str fileExt = _get_extension(RelFilename);
         
         if(TasksPerExtension._indexin(fileExt))
         {
            fileTaskName = TasksPerExtension:[fileExt];
         }

         // See if we can find a more specific item group node
         // for this file build task. Sometimes the project file
         // lumps all files into one ItemGroup. Other times, there are
         // distinct item groups for each build task. (Like <Content>)
         int parentGroupNode = itemGroupNode;
         int maybeBetterNode = GetVS2005ItemGroupForTask(handle, fileTaskName);
         if(maybeBetterNode > 0)
         {
            parentGroupNode = maybeBetterNode;
         }

         // TODO: We may want to get crafty and ask if this is a WinForm, so that
         // we can set the appropriate <SubType>. We could also potentially check
         // if a form.designer.cs file is being added, and look for form.cs in the tree.
         // This way we can set up the <DependentUpon> value.

         // Add the new item to the project's xml tree
         int fileTaskNode =_xmlcfg_add(handle,parentGroupNode,fileTaskName,VSXMLCFG_ELEMENT_END,flags);
         // Add the Include attribute to the item that we just added
         _xmlcfg_add_attribute(handle,fileTaskNode,"Include",RelFilename,VSXMLCFG_ADD_ATTR_AT_END);
      }
   }
   TasksPerExtension._makeempty();

   if (doTagging) {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      tag_add_viewlist(TagFilename,temp_view_id,null,false,FileExistsOnDisk,useThread);
   }

   _xmlcfg_sort_on_attribute(handle,itemGroupNode,'Include','F');
   
   activate_window(orig_view_id);
   // Save the file
   status=_xmlcfg_save(handle,vs2005Indent,vs2005SaveFlags);
   if (status) {
      _message_box(nls("Could not save project file '%s'.\n\n%s",VisualStudioProjectFilename,get_message(status)));
      _xmlcfg_close(handle);
      return(status);
   }
   _xmlcfg_close(handle);
   _WorkspacePutProjectDate(VisualStudioProjectFilename);

   return(status);
}

// For Visual Studio 2005 project files:
// Determine the most appropriate <ItemGroup> node for a specific
// build task. Some projects lump all files into one big <ItemGroup>, but
// others will segregate the <Compile> tasks, the <Content> tasks, and the
// junkyard <None> tasks. (These tasks determine what to do with the file
// when the project is built)
// This way, when we add new files to a VS2005 project, we can place
// them in a sensible section.
static int GetVS2005ItemGroupForTask(int handle, _str taskName)
{
   int foundTaskNode = _xmlcfg_find_simple(handle, '/Project/ItemGroup/'taskName);
   if(foundTaskNode > 0)
   {
      int itemGroupNode = _xmlcfg_get_parent(handle, foundTaskNode);
      return itemGroupNode;
   }
   return -1;
}

// Based on the project extension, determine  what is the default build task.
// VS2003 uses a "BuildAction" attribute, with defaults for each file extension.
// But VS2005 puts files into MSBuild-style task tags. (These tasks determine what to do with the file
// when the project is built)
// So a file that is to be compiled goes into a <Compile> tag, and a file that's just static
// content goes in a <Content> tag. Files that we don't know what to do with
// go in the junkyard <None> tag.
static void GetVS2005BuildTaskExtensions(_str projectExt, _str (&ExtToTask):[])
{
   ExtToTask._makeempty();
   if (file_eq(projectExt,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ||
       file_eq(projectExt,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
      ExtToTask:['cs'] = 'Compile';
   }
   if (file_eq(projectExt,VISUAL_STUDIO_VB_PROJECT_EXT) ||
       file_eq(projectExt,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT)) {
      ExtToTask:['vb'] = 'Compile';
   }
   if (file_eq(projectExt,VISUAL_STUDIO_FSHARP_PROJECT_EXT)) {
      ExtToTask:['fs'] = 'Compile';
   }
   if (file_eq(projectExt,VISUAL_STUDIO_JSHARP_PROJECT_EXT)) {
      ExtToTask:['jsl'] = 'Compile';
      ExtToTask:['java'] = 'Compile';
   }

   ExtToTask:['resx'] = 'EmbeddedResource';
   ExtToTask:['rdlc'] = 'EmbeddedResource';
   ExtToTask:['txt'] = 'EmbeddedResource';

   ExtToTask:['jpg'] = 'Content';
   ExtToTask:['jpeg'] = 'Content';
   ExtToTask:['gif'] = 'Content';
   ExtToTask:['bmp'] = 'Content';
   ExtToTask:['png'] = 'Content';
   ExtToTask:['htm'] = 'Content';
   ExtToTask:['html'] = 'Content';
   ExtToTask:['dll'] = 'Content';
   ExtToTask:['exe'] = 'Content';
   ExtToTask:['wav'] = 'Content';
   ExtToTask:['avi'] = 'Content';
   ExtToTask:['mdb'] = 'Content';
   ExtToTask:['mdf'] = 'Content';
   ExtToTask:['vbs'] = 'Content';
   ExtToTask:['wsf'] = 'Content';
   ExtToTask:['css'] = 'Content';
}

// Determines if any other project files are dependent upon a specific file.
// Right now this is being used to determine if we need to remove additional files
// when a file is removed from a project.
// We could also potentially use this to "nest" files, like Visual Studio does
// when nesting winforms files with their associate form.designer files, or the way
// asp.net files are grouped with the associated code-behind file
static boolean GetVS2005DependentNodes(int xmlHandle, int parentNode, _str parentNodeFilename, int (&depNodes)[], _str (&depNodeFiles)[])
{
   depNodes._makeempty();
   depNodeFiles._makeempty();
   // Find all the <DependentUpon> nodes underneath the same <ItemGroup> node
   // as the parentNode (the file that's being removed).
   // Essentially, we're looking for associated WinForms and WebForms files
   // For example, if we try to delete Form1.cs from the project, if there is a Form1.Designer.cs
   // file, it should be removed as well.
   boolean foundDependents = false;
   // Search within the <ItemGroup> that is the parent of the parentNode
   int rootSearch = _xmlcfg_get_parent(xmlHandle, parentNode);
   if(rootSearch > 0)
   {
      // Find all <DependentUpon> nodes underneath this <ItemGroup>
      // (They aren't direct children, but children of the child items in the ItemGroup)
      // ...But there's no neat XPATH syntax for "grandchild" :-)
      typeless dependencyNodes[];
      if(_xmlcfg_find_simple_array(xmlHandle, '//DependentUpon', dependencyNodes, rootSearch) == 0)
      {
         int dIdx = 0;
         int dMax = dependencyNodes._length();
         for(; dIdx < dMax; ++dIdx)
         {
            // Look in the PCDATA value for this <DependentUpon> node
            int dNode = dependencyNodes[dIdx];
            int dNodeData = _xmlcfg_get_first_child(xmlHandle, dNode, VSXMLCFG_NODE_PCDATA);
            _str dependsUpon = _xmlcfg_get_value(xmlHandle, dNodeData);

            // Does the dependency match the file we're looking to remove?
            if(file_eq(dependsUpon, parentNodeFilename))
            {
               // Yep, found a dependent node. Return both the index, and the name
               // of the dependent file (relative path)
               int fileNode = _xmlcfg_get_parent(xmlHandle, dNode);
               _str depFileName = _xmlcfg_get_attribute(xmlHandle, fileNode, 'Include');
               depNodes[depNodes._length()] = fileNode;
               depNodeFiles[depNodeFiles._length()] = depFileName;
               foundDependents = true;
            }
         }
      }
   }
   return foundDependents;
}

/**
 * Finds the rc file included in the build the way
 * that VC++ does, uses the last one in their funny
 * sorting algorithm.
 *
 * @param AbsoluteNewFiles
 *               List of absolute files
 *
 * @return Name of rc file to include in build if we found one.
 */
static _str GetIncludedRCFile(_str AbsoluteNewFiles[])
{
   //First, change the order of these around so that we can sort them...
   //Put the name and a FILESEP on the front, and leave the absolute path at the
   //end.  This way a simple case insensitive sort seems to get us the same
   //results that they have.
   int i;
   for (i=0;i<AbsoluteNewFiles._length();++i) {
      AbsoluteNewFiles[i]=_strip_filename(AbsoluteNewFiles[i],'P'):+FILESEP:+_strip_filename(AbsoluteNewFiles[i],'N');
   }
   //Sort the "names"
   AbsoluteNewFiles._sort(_fpos_case);

   //loop through from the bottom and find the last rc file
   _str name, path;
   for (i=AbsoluteNewFiles._length()-1;i>=0;--i) {
      parse AbsoluteNewFiles[i] with name (FILESEP) path;
      _str curext=_get_extension(name);
      if (file_eq(curext,'rc')) {
         //return this name
         return(path:+name);
      }
   }
   return('');
}

/**
 * Adds "filename" to a VC++ dsp file.
 *
 * This funciton must be called with the dsp file
 * in the current view
 *
 * @param GroupNames Array of groups of file extensions in the dsp file
 *
 * @param filename   filename to add to the dsp file
 *
 * @param MakefilePath
 *                   Path of the makefile
 *
 * @param IncludedRCFile
 *                   Name of the RC file to actually be included in the build
 *                   Others are excluded with:
 *                   # PROP Exclude_From_Build 1
 *
 * @return 0 if successful
 */
static int AddFileToVCPP6ProjectFile(_str GroupNames[],_str filename,_str MakefilePath)
{
   message('Adding 'filename' to '_project_name);
   //Get the extension of this file
   _str ext=_get_extension(filename);
   _str abs_filename=_AbsoluteToProject(filename);

   boolean is_rc_file=false;
   is_rc_file=file_eq(ext,'rc')!=0;

   int ext_index=-1;
   //Loop through the groups to see if this file fits into one of them
   int i;
   for (i=0;i<GroupNames._length();++i) {
      _str cur_group=stranslate(GroupNames[i],'','*.');
      if (pos(';'ext';',';'cur_group';',1,_fpos_case)) {
         //If it does, set ext_index and stop
         ext_index=i;break;
      }
   }
   _str just_filename=_file_case(_strip_filename(filename,'P'));
   int end_of_group_line=-1;
   if (ext_index>-1) {
      //If ext_index is greater than -1, the file belongs in one of the groups,
      //so put it there
      //
      //Start at the top of the file
      top();
      //Search for the start of this group
      _str ch=_file_case(substr(just_filename,1,1));
      int status=search('^'_escape_re_chars(EXT_LIST_PREFIX:+GroupNames[ext_index])'"$','@rh>');
      if (status) {
         //If we cannot find the group, return an error
         return(status);
      }
      //Save our position at the top of the group
      save_pos(auto p);
      //Find the end of the group
      status=search('^'_escape_re_chars(END_GROUP_PREFIX)'$','@rh');
      if (status) {
         return(status);
      }
      //Save the filename for the end of the group
      end_of_group_line=p_line;
      //restore the postion at the end of the group
      restore_pos(p);
   }else{
      //This is an extension that there is not a group for
      //Find the end of the last group
      //Start at the top
      top();
      boolean foundone=false;
      int status;
      for (;;) {
         //Just keep searching for the end group delimiter until we run out
         status=search('^'_escape_re_chars(END_GROUP_PREFIX)'?@$','@rh>');
         if (status) {
            break;
         }
         foundone=true;
      }
      if (!foundone) {
         for (;;) {
            //Just keep searching for the end group delimiter until we run out
            status=search('^'_escape_re_chars(NAME_PREFIX)'?@$','@rh>');
            if (status) {
               break;
            }
            foundone=true;
         }
      }
      if (!foundone) {
         _message_box(nls("Cannot find place to insert file.  There are no groups in this project file"));
         return(1);
      }
   }

   //call ConvertToVCPPRelFilename to change this filename to match VC++'s relative style,
   //and also to match the filename as it appears on disk
   filename=ConvertToVCPPRelFilename(filename,MakefilePath);

   _str LastFilename='',CurFilename='';

   boolean had_filename=false;
   int status;
   _str line;
   for (;;) {
      //Search for the next source file
      status=search('^'SOURCE_FILE_PREFIX'?@$','@rh>');
      //If we did not find one, OR
      //This file has a group AND We are past the end of this files group
      //    Then stop
      if (status ||
          (end_of_group_line>-1 && p_line>end_of_group_line)) break;

      //Get the current line
      get_line(line);

      //If this is the end group delimiter stop
      if (line==END_GROUP_PREFIX) break;

      //strip off the SOURCE= part
      parse line with SOURCE_FILE_PREFIX CurFilename;
      CurFilename=_file_case(CurFilename);

      _str absfilename_path=absolute(_file_case(filename),MakefilePath);
      absfilename_path=_file_case(_strip_filename(absfilename_path,'N'));

      _str just_last_filename=_strip_filename(LastFilename,'P');
      _str just_cur_filename=_strip_filename(CurFilename,'P');

      if (just_filename >= just_last_filename &&
          just_filename <= just_cur_filename) {
         if (!had_filename) {
            had_filename=file_eq(just_filename,just_last_filename)!=0;
         }
         _str abs_last_path=LastFilename==''?'':_file_case(_strip_filename( absolute(LastFilename,MakefilePath),'N' ));
         _str abs_cur_path=_file_case(_strip_filename( absolute(CurFilename,MakefilePath),'N' ));
         if (
             (absfilename_path >= abs_last_path &&
              absfilename_path <= abs_cur_path) ||
             (had_filename && !file_eq(just_filename,just_cur_filename))
             ) {
            //If the stripped, case insensitive filename is greater than or equal
            //the last one, and less than or equal the next one,
            //OR if we found and exact match for the filename and the next
            //filename is not a match
            //THEN stop and put the
            //file here
            //
            //Go up 3 lines, to get to the proper position
            up();up();up();
            //insert the delimiters and blank lines the same way that VC++ does
            //It would look nicer if the blank line were at the end, but we want
            //to output identical dsp files
            insert_line(BEGIN_FILE_PREFIX);
            insert_line('');
            insert_line(SOURCE_FILE_PREFIX:+vcpp_maybe_quote_filename(filename));
            if (is_rc_file) {
               //We mark all of the the rc files that we add as not in the build
               //I cannot figure out excactly how VC++ picks which one is active
               insert_line(EXCLUDE_FROM_BUILD_LINE);
            }
            insert_line(END_FILE_PREFIX);
            return(0);
         }else{
            if (just_filename < just_cur_filename ) {
               //Break, but first adjust cursor position and blast
               //end_of_group_line so that the insertion code below
               //works
               up();up();up();up();
               end_of_group_line=-1;
               break;
            }
         }
      }else{
         if (had_filename) {
            //Want to put it right at the bottom of this seciton
            break;
         }
      }
      //Set the LastFilename to CurFilename and loop again
      LastFilename=CurFilename;
   }

   //If we get here, we did not find a place to insert the file, so
   //we are adding it to the end of the group/nongroup
   if (end_of_group_line>-1) {
      //position us just before the end of the group
      p_line=end_of_group_line-1;
   }else{
      //If we were not in a group, move down a line
      down();
   }
   //insert the delimiters and blank lines the same way that VC++ does
   //It would look nicer if the blank line were at the end, but we want
   //to output identical dsp files
   insert_line(BEGIN_FILE_PREFIX);
   insert_line('');
   insert_line(SOURCE_FILE_PREFIX:+vcpp_maybe_quote_filename(filename));
   if (is_rc_file) {
      //We mark all of the the rc files that we add as not in the build
      //I cannot figure out excactly how VC++ picks which one is active
      insert_line(EXCLUDE_FROM_BUILD_LINE);
   }
   insert_line(END_FILE_PREFIX);
   if (ext_index==-1) {
      //This item is not in a group, so we may have to move the
      //# End Target line
      MaybeMoveEndTargetLine();
   }
   return(0);
}

/**
 * Same as maybe quote filename, except it will also
 * quote a file that has a '-' in it, because VC++
 * does.
 *
 * @param filename name of file to quote
 *
 * @return filename in double quotes if there is a space or -
 *         in it, otherwise just filename.
 */
static _str vcpp_maybe_quote_filename(_str filename)
{
   filename=stranslate(filename,'','"');
   if ( pos(' |\-',filename,1,'r') ) {
      filename='"'filename'"';
   }
   return(filename);
}

/**
 * Check to see if the "# End Target" line needs
 * to move to the bottom of the file because we
 * added somethign after the last group.
 */
static void MaybeMoveEndTargetLine()
{
   //save our current position
   save_pos(auto p);
   //look for the "# End Target" line
   int status=search('^'_escape_re_chars(END_TARGET_PREFIX)'$','@rh');
   if (!status) {
      //If the END_TARGET_PREFIX line was below us, it has been moved already
      //Just restore position and return
      restore_pos(p);
      return;
   }
   //We need to move the line, look backwards for it.
   status=search('^'_escape_re_chars(END_TARGET_PREFIX)'$','@rh-');
   if (status) {
      //Hmmm, not sure what to do here.
      //Just restore position and return
      restore_pos(p);
      return;
   }
   //Get the line
   get_line(auto line);
   //delete the line
   _delete_line();
   //go back to our original position
   restore_pos(p);
   //re-insert the line
   insert_line(line);
}

/**
 * Changes filename to the VC++ relative style.
 *
 * VC++ relative style differences:
 *
 * * a file in the current directory is stored as
 * ".\filename" instead of "filename"
 *
 * * a file the root directory is stored as
 * "..\..filename"(however many ..'s) instead of "\filename"
 *
 * @param filename filename to change
 *
 * @param MakefilePath
 *                 Path of the .dsp file
 *
 * @return modified filename
 */
_str ConvertToVCPPRelFilename(_str filename,_str MakefilePath)
{
   //Visual C++ stores files in the same directory as the project as
   // ".\filename" rather than just "filename" and ".\t1\filename" rather
   //than "t1\filename".
   _str first_ch=substr(filename,1,1);
   if (first_ch!='.' && substr(filename,2,1)!=':' &&
       first_ch!=FILESEP) {
      //Everything that doesnt start with a drive letter start with a dot
      filename='.'FILESEP:+filename;
      return(filename);
   }else if (substr(filename,1,1)==FILESEP) {
      //If filename is in the root directory
      //
      //create a new filename the that is ..FILESEP:+filename.
      //we already know that if we are here filename started with a
      //FILESEP
      _str newfilename='..'filename;

      //Get an absolute copy of filename
      _str absfilename=absolute(filename,MakefilePath);

      //compare an absolute version of newfilename to absfilename.
      //If they match, we are done
      while (!file_eq( absfilename,
                       absolute(newfilename,MakefilePath) )
             ) {
         //Keep adding another ..:+FILESEP
         newfilename='..'FILESEP:+newfilename;
      }
      //When the loop breaks, return newfilename
      return(newfilename);
   }
   //Did not hit either case above, return the original filename
   return(filename);
}

static _str ConvertFromVCPPRelFilename(_str filename,_str MakefilePath)
{
   filename=relative(absolute(filename,MakefilePath),MakefilePath);
   return(filename);
}
/**
 * Adds a list of files to a VC++ project file.  It
 * will figure out which version(after 6.0) it is and call the right
 * function.
 *
 * @param filelist Space demited list of files to remove
 *
 * @param VCPPProjectName
 *                 Name of the .dsp file.  If this is blank, uses
 *                 the "makefile" field in the current project
 *
 * @param Quiet    If on, no errors are reported
 *
 * @return 0 if succesful.
 */
int _AddFileToVCPPMakefile(_str filelist,_str VCPPProjectName='',
                           boolean Quiet=false)
{
   if (VCPPProjectName=='') {
      //Find the associated makefile(.dsp file).
      //int status=_ini_get_value(_project_name,"ASSOCIATION","makefile",VCPPProjectName,'');
      int status=_GetAssociatedProjectInfo(_project_name,VCPPProjectName);
      if (status) return(status);
      if (file_eq(_get_extension(VCPPProjectName,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         VCPPProjectName = absolute(getICProjAssociatedProjectFile(VCPPProjectName),_strip_filename(_project_name,'N'));
      }

   } else if (file_eq(_get_extension(VCPPProjectName,true),PRJ_FILE_EXT)) {
      //Find the associated makefile(.dsp file).
      //int status=_ini_get_value(_project_name,"ASSOCIATION","makefile",VCPPProjectName,'');
      int status=_GetAssociatedProjectInfo(VCPPProjectName,VCPPProjectName);
      if (status) return(status);
      if (file_eq(_get_extension(VCPPProjectName,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         VCPPProjectName = absolute(getICProjAssociatedProjectFile(VCPPProjectName),_strip_filename(_project_name,'N'));
      }
   }

   //Make a backup of the file
   copy_file(VCPPProjectName,_strip_filename(VCPPProjectName,'E'):+'.bak');

   _str ext=_get_extension(VCPPProjectName,true);
   if ( file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT) ||
        file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)
        ) {
      return(_AddFileToVisualStudioProject(filelist,VCPPProjectName,!Quiet));
   }

   //Open the makefile(.dsp file)
   int makefile_view_id,orig_view_id;
   int status=_open_temp_view(VCPPProjectName,makefile_view_id,orig_view_id);
   if (status) return(status);

   top();
   //Make the original view active, but keep the makefile around
   p_window_id=orig_view_id;

   //Get the groups of file extensions
   _str GroupsInMakefile[]=null;
   GetVCPPGroups(makefile_view_id,GroupsInMakefile);

   //True if we have any rc files
   boolean have_rc_file=false;

   //Get the all of the source files
   _str FilesInMakefile[]=null;
   status=GetVCPP6Files(makefile_view_id,FilesInMakefile,have_rc_file);

   //Open the tag database here.  We will make multiple calls to
   //RemoveFileFromVCPP6ProjectFile which individually removes many file
   //from the database
   _str tag_filename=_GetWorkspaceTagsFilename();
   open_status := tag_open_db(tag_filename);
   if (open_status < 0 && !Quiet) {
      _message_box(nls("Unable to open tag file %s",tag_filename));
   }

   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   p_window_id=makefile_view_id;
   for (;;) {
      _str cur=parse_file(filelist);
      if (cur=='') break;
      status=AddFileToVCPP6ProjectFile(GroupsInMakefile,_RelativeToProject(cur),_strip_filename(VCPPProjectName,'N'));
      if (open_status >= 0) {
         RetagFile(_AbsoluteToProject(cur),useThread);
      }
   }

   //Close the database
   if (open_status >= 0) {
      tag_close_db(tag_filename,1);
   }
   if (p_modify) {
      status=_save_file('+o');
      //Since we save the project(.dsp) file, we have to match up the date in the
      //workspace file or we will retag everything again.
      _WorkspacePutProjectDate(VCPPProjectName);
   }
   //Switch to the original view and delete the one with the .dsp file
   p_window_id=orig_view_id;
   _delete_temp_view(makefile_view_id);
   return(status);
}

/**
 * remove filename from the VC++ dsp file VCPPProjectName.
 *
 * Currently, this function is only called when a user
 * presses the del key in the files tab of the project toolbar.
 *
 * @param VCPPProjectName
 *                 name of the VC++ dsp file to remove filename from
 *
 * @param filename file to remove from VC++ project file
 *
 * @return 0 if succesful
 */
int _RemoveFileFromVCPPMakefile(_str filelist,_str VCPPProjectName='',
                                boolean Quiet=false)
{
   if (VCPPProjectName=='') {
      //Find the associated makefile(.dsp file).
      //int status=_ini_get_value(_project_name,"ASSOCIATION","makefile",VCPPProjectName,'');
      int status=_GetAssociatedProjectInfo(_project_name,VCPPProjectName);
      if (status) return(status);
      if (file_eq(_get_extension(VCPPProjectName,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         VCPPProjectName = absolute(getICProjAssociatedProjectFile(VCPPProjectName),_strip_filename(_project_name,'N'));
      }
   }

   //Open the dsp file
   int makefile_view_id,orig_view_id;
   int status=_open_temp_view(VCPPProjectName,makefile_view_id,orig_view_id);
   if (status) return(status);
   p_window_id=makefile_view_id;

   //Get the name of the tag file
   _str tag_filename=_GetWorkspaceTagsFilename();
   //Open the tags database. RemoveFileFromVCPP6ProjectFile will remove the
   //files from the database
   open_status := tag_open_db(tag_filename);
   if (open_status < 0) {
      _message_box(nls("Unable to open tag file %s",tag_filename));
   }
   _str vse_project_name=_strip_filename(VCPPProjectName,'E'):+PRJ_FILE_EXT;
   for (;;) {
      _str filename=parse_file(filelist);
      if (filename=='') break;
      //Get the filename relative to the project
      filename=relative(filename,_strip_filename(VCPPProjectName,'N'));
      //Call the RemoveFileFromVCPP6ProjectFile to do the work
      status=RemoveFileFromVCPP6ProjectFile(filename,vse_project_name);
      if (status && !Quiet) {
         _message_box(nls("Could not remove '%s1' from %s2\n\n%s3",filename,VCPPProjectName,get_message(status)));
         p_window_id=orig_view_id;
         return(status);
      }
   }
   //Close the tags database
   if (open_status >= 0) {
      tag_close_db(tag_filename,1);
   }

   //Save the dsp file
   status=_save_file('+o');
   if (status && !Quiet) {
      _message_box(nls("Could not save file '%s1'\n\n%s2",VCPPProjectName,get_message(status)));
   }else{
      //Since we save the project file, we have to match up the date in the
      //workspace file or we will retag everything again.
      /*_ini_set_value(
         VSEWorkspaceFilename(_workspace_filename),
         "ProjectDates",
         _RelativeToProject(VCPPProjectName),
         _file_date(VCPPProjectName,'B'));*/
      _WorkspacePutProjectDate(VCPPProjectName);
   }
   p_window_id=orig_view_id;
   //delete the view with the dsp file
   _delete_temp_view(makefile_view_id);

   return(status);
}

int _RemoveFileFromVisualStudioProject(_str FileList,_str ProjectFilename)
{
   _str ext=_get_extension(ProjectFilename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      ProjectFilename = absolute(getICProjAssociatedProjectFile(ProjectFilename),_strip_filename(ProjectFilename,'N'));
      ext=_get_extension(ProjectFilename,1);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      return(RemoveFileFromVisualStudioVCPPProject(FileList,ProjectFilename));
   }

   return(RemoveFileFromVisualStudioStandardProject(FileList,ProjectFilename,ext));
}

int _AddFileToVisualStudioProject(_str FileList,_str ProjectFilename,boolean FileExistsOnDisk=true)
{
   _str ext=_get_extension(ProjectFilename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      ProjectFilename = absolute(getICProjAssociatedProjectFile(ProjectFilename),_strip_filename(ProjectFilename,'N'));
      ext=_get_extension(ProjectFilename,1);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      return(AddFileToVisualStudioVCPPProject(FileList,ProjectFilename,FileExistsOnDisk));
   }

   return(AddFileToVisualStudioStandardProject(FileList,ProjectFilename,ext,FileExistsOnDisk));
}

/**
 * Removes a filelist from a Visual C++  7.x project
 * file.
 *
 * @param FileList List of files to remove
 *
 * @param ProjectFilename
 *                 Name of the VC++ project file to remove the files from
 *
 * @return 0 if succesful
 */
static int RemoveFileFromVisualStudioVCPPProject(_str FileList,_str ProjectFilename)
{
   int temp_view_id;
   _str cur;
   int orig_view_id=_create_temp_view(temp_view_id);
   _str list=FileList;
   for (;;) {
      cur=parse_file(list);
      if (cur=='') break;
      insert_line(cur);
   }
   p_window_id=orig_view_id;
   int status=WriteVisualStudioVCPPProjectFile2(ProjectFilename,0,temp_view_id);
   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Removes a filelist from a C#/VB  7.x project
 * file.
 *
 * @param FileList List of files to remove
 *
 * @param ProjectFilename
 *                 Name of the VisualStudio project file to remove the files from
 *
 * @return 0 if succesful
 */
static int RemoveFileFromVisualStudioStandardProject(_str FileList,
                                                     _str ProjectFilename,
                                                     _str ext)
{
   _str AppName=GetVSStandardAppName(ext);
   _str CompileExtensionList=GetVSStandardExt(ext);
   if (AppName:=='' || CompileExtensionList:=='') {
      return(0);
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   _str list=FileList;
   _str cur;
   for (;;) {
      cur=parse_file(list);
      if (cur=='') break;
      insert_line(cur);
   }
   p_window_id=orig_view_id;
   int status=WriteVisualStudioStandardProjectFile2(ProjectFilename,
                                                AppName,
                                                CompileExtensionList,
                                                temp_view_id,
                                                0);
   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Removes filename from a VC++ dsp file.  The dsp file
 * must be in the current view
 *
 * @param RelativeFilename
 *               filename to remove
 *
 * @param project_name
 *               Name of the project the files are being removed from
 *
 * @return 0 if successful
 */
static int RemoveFileFromVCPP6ProjectFile(_str RelativeFilename,_str project_name=_project_name)
{
   //Get the filename the way that it will be in the dsp file
   RelativeFilename=ConvertToVCPPRelFilename(RelativeFilename,_strip_filename(project_name,'N'));

   //Start at the top of the file
   top();
   //Look for the filename
   int status=search('^'_escape_re_chars(SOURCE_FILE_PREFIX):+vcpp_maybe_quote_filename(_escape_re_chars(RelativeFilename))'$','@rh');
   if (status) return(status);

   //Backup and look for the "# BEGIN..."
   status=search('^'_escape_re_chars(BEGIN_FILE_PREFIX)'$','@rh-');
   if (status) return(status);

   //Start selection
   int markid=_alloc_selection();
   _select_line(markid);

   //Search forward for the "#END..."
   status=search('^'_escape_re_chars(END_FILE_PREFIX)'$','@rh');
   if (status) {
      _free_selection(markid);
      return(status);
   }

   //Finish the selection
   _select_line(markid);
   //Delete the selection, deleting the whole file seciton
   _delete_selection(markid);

   _free_selection(markid);

   return(0);
}

/**
 * Get the lists of file extensions from the dsp file.
 * They are stored in many lines starting with
 * "# PROP Default_Filter" ... with the extension list
 * semi-colon delmited after the prefix.
 *
 * @param MakeFilenameViewId
 *               View id with the dsp file
 *
 * @param Groups Array to store the file extensions in.
 *               Each array element is a "group"(list of extensions)
 */
static void GetVCPPGroups(int MakeFilenameViewId,_str (&Groups)[])
{
   //Save original view id
   int orig_view_id=p_window_id;
   //switch to dsp file view
   p_window_id=MakeFilenameViewId;
   //start at the top
   top();
   int status;
   _str line;
   for (;;) {
      //Loop through and look for lines that start with "# PROP Default_Filter"
      status=search('^'_escape_re_chars(EXT_LIST_PREFIX)'?@','@rh>');
      if (status) break;
      //Get the line
      get_line(line);
      //Strip the quotes and the prefix
      _str cur_group=substr(line,length(EXT_LIST_PREFIX)+1);
      cur_group=substr(cur_group,1,length(cur_group)-1);
      //Save the extension list in the array
      Groups[Groups._length()]=cur_group;
   }
   //restore the original view id
   p_window_id=orig_view_id;
}

/**
 * Gets all of the source files out of a VC++
 * dsp file.
 *
 * @param MakeFilenameViewId
 *               View id with the dsp file
 *
 * @param Files  Array to store the filenames in
 *
 *               These filenames are stored relative, VSE style
 *
 * @return 0 if successful
 */
static int GetVCPP6Files(int MakeFilenameViewId,_str (&Files)[],
                        boolean &HaveRCFile)
{
   //Store the view id
   int orig_view_id=p_window_id;
   //Switch to the makefile view id
   p_window_id=MakeFilenameViewId;

   //Start at the top
   top();
   _str last='';
   int status;
   _str line;
   for (;;) {
      //Search for the "SOURCE=" prefix until we can't find it anymore
      //Groups do not matter in this case, we just need all of the files
      status=search('^'_escape_re_chars(SOURCE_FILE_PREFIX)'?@','@rh>');
      if (status) break;
      //Get the line
      get_line(line);
      //Strip off the prefix
      _str cur_filename=substr(line,length(SOURCE_FILE_PREFIX)+1);

      //Convert the file to absolute and back to relative. This gives us
      //a VSE style relative fileame
      _str abs_filename=absolute(cur_filename,_strip_filename(_project_name,'N'));
      cur_filename=relative(abs_filename,_strip_filename(_project_name,'N'));

      //Save the filename
      Files[Files._length()]=cur_filename;

      _str first_ch=substr(_strip_filename(cur_filename,'P'),1,1);
      _str ext=_get_extension(cur_filename);

      if (file_eq(_file_case(ext),'rc')) {
         HaveRCFile=true;
      }
   }
   //restore the view id
   p_window_id=orig_view_id;
   Files._sort('F'_fpos_case);
   return(0);
}

/**
 * Add the list of files to the specified JBuilder XML project
 *
 * @param fileList Space delimited list of files
 * @param projectName
 *                 JBuilder XML project
 *
 * @return 0 on success, <0 on failure
 */
int _AddFilesToJBuilderProject(_str fileList, _str projectName)
{
   // create temp view and insert the file list one file per line
   int tempViewID;
   int origViewID = _create_temp_view(tempViewID);
   for(;;) {
      _str filename = parse_file(fileList);
      if(filename == "") break;
      insert_line(" " _RelativeToProject(filename, projectName));
   }

   // switch back to the original view
   p_window_id = origViewID;

   // update the jbuilder project
   int status=_WriteJBuilderProject(projectName, 0, tempViewID);

   // cleanup
   _delete_temp_view(tempViewID);
   return status;
}

/**
 * Removes the list of files from the specified JBuilder XML Project file
 *
 * @param fileList Space delimited list of files
 * @param projectName
 *                 JBuilder XML project
 *
 * @return 0 on success, <0 on failure
 */
int _RemoveFilesFromJBuilderProject(_str fileList, _str projectName)
{
   // create temp view and insert the file list one file per line
   int tempViewID;
   int origViewID = _create_temp_view(tempViewID);
   for(;;) {
      _str filename = parse_file(fileList);
      if(filename == "") break;
      insert_line(" " _RelativeToProject(filename, projectName));
   }

   // switch back to the original view
   p_window_id = origViewID;

   // update the jbuilder project
   int status=_WriteJBuilderProject(projectName, tempViewID, 0);

   // cleanup
   _delete_temp_view(tempViewID);
   return status;
}

/**
 * Updates the list of files in a JBuilder XML project file to
 * match the provided list.  Files will be added or removed
 * as necessary.
 *
 * @param _srcfile_list_view_id
 *               View containing list of files in the project, one per line
 * @param projectName
 *               JBuilder XML project
 *
 * @return 0 on success, <0 on failure
 */
int _UpdateFilesInJBuilderProject(int _srcfile_list_view_id,_str projectName)
{
   int status = 0;

   int handle=_xmlcfg_open(projectName, status);
   if (handle<0) {
      return(status);
   }
   int FileListViewId=-1;
   int orig_view_id=_create_temp_view(FileListViewId);
   p_window_id=orig_view_id;

   int IndexTable:[]=null;
   _str FilesInXMLFile[]=null;
   GetFileListFromJBuilderFile(projectName,FileListViewId,FilesInXMLFile,IndexTable,null,handle,true,false);

   p_window_id=_srcfile_list_view_id;
   int i;
   for (i=0;i<FilesInXMLFile._length();++i) {
      _str curfilename=_RelativeToProject(FilesInXMLFile[i],projectName);

      top();
      //Look for the file in the list
      if (!search('^'_escape_re_chars(curfilename)'$','@rh>'_fpos_case)) {
         //If we have it in the list and in the array, delete it from both
         //and don't worry about these.  This way, we are left with items
         //to be deleted in the array, and items to be added in the list.
         FilesInXMLFile._deleteel(i);
         _delete_line();
         up();
         --i;
      }
   }

   // put all the remove files into a view
   int RemoveFileListViewId=0;
   orig_view_id=_create_temp_view(RemoveFileListViewId);
   p_window_id=RemoveFileListViewId;
   for (i=0;i<FilesInXMLFile._length();++i) {
      insert_line(FilesInXMLFile[i]);
   }
   p_window_id=orig_view_id;

   // write the project
   status = _WriteJBuilderProject(projectName, RemoveFileListViewId, _srcfile_list_view_id, handle, true, true);

   _delete_temp_view(FileListViewId);
   _delete_temp_view(RemoveFileListViewId);
   _xmlcfg_close(handle);
   return(status);
}

/**
 * Updates the specified JBuilder XML project with the list of files
 * that should be added or removed.
 */
int _WriteJBuilderProject(_str projectName, int removeViewId, int addViewId, int handle = -1,
                          boolean fileExistsOnDisk = true, boolean doTagging = false)
{
   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(projectName, status);
      if(handle < 0) return status;
      openedFile = true;
   }

   _str TagFilename = project_tags_filename();

   //Save the current window id and activate the project list box
   if(removeViewId) {
      int open_status=tag_open_db(TagFilename);

      int orig_view_id=p_window_id;
      p_window_id=removeViewId;
      top();up();

      while(!down()) {
         _str cur_filename = "";
         get_line(cur_filename);
         cur_filename=strip(cur_filename);
         if (open_status >= 0 && doTagging) {
            message('Removing 'cur_filename' from 'TagFilename);
            tag_remove_from_file(cur_filename);
         }

         // remove the file from the project
         int node = _xmlcfg_find_simple(handle, "/project//file" XPATH_FILEEQ("path", _NormalizeFile(_RelativeToProject(cur_filename, _xmlcfg_get_filename(handle)))));
         if(node >= 0) {
            _xmlcfg_delete(handle, node);
         }
      }
      p_window_id=orig_view_id;
   }
   if (!addViewId) {
      if (removeViewId) {
         status=_xmlcfg_save(handle,2,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
         if(openedFile) {
            _xmlcfg_close(handle);
         }
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         tag_close_db('',1);
         return(status);
      }
   }

   int orig_view_id=p_window_id;
   int temp_view_id;
   _create_temp_view(temp_view_id);
   p_window_id=addViewId;

   int projectNode = _xmlcfg_find_simple(handle, "/project");
   if(projectNode >= 0) {
      top(); up();
      while(!down()) {
         _str line = "";
         get_line(line);
         line = _RelativeToProject(line, _xmlcfg_get_filename(handle));

         int newnode = _xmlcfg_add(handle, projectNode, "file", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(handle, newnode, "path", _NormalizeFile(line), VSXMLCFG_ADD_ATTR_AT_END);

         // add it to the view to be tagged
         activate_window(temp_view_id);
         insert_line(_AbsoluteToProject(line, _xmlcfg_get_filename(handle)));
         p_window_id = addViewId;
      }
   }

   if (doTagging) {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      tag_add_viewlist(TagFilename,temp_view_id,null,false,fileExistsOnDisk,useThread);
   }

   activate_window(orig_view_id);

   // Save the file
   status=_xmlcfg_save(handle,2,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   if (status) {
      _message_box(nls("Could not save project file '%s'.\n\n%s",projectName,get_message(status)));
      if(openedFile) {
         _xmlcfg_close(handle);
      }
      return(status);
   }

   if(openedFile) {
      _xmlcfg_close(handle);
   }
   _WorkspacePutProjectDate(projectName);

   return(status);
}

/**
 * Gets the specified section from the current view
 * and copies it into temp_view_id.
 *
 * Leaves temp_view_id active.
 *
 * @param section_name
 *               Name of section to get
 *
 * @param temp_view_id
 *               View id to put section data into.
 *
 * @return returns 0 if successfule
 */
static int my_ini_get_section3(_str section_name,int &temp_view_id)
{
   int ini_view_id;
   get_window_id(ini_view_id);
   int status=_ini_find_section(section_name);
   if (status) {
      return(status);
   }
   down();
   get_line(auto line);
   if (substr(line,1,1)=='[') {
      return(0);// Nothing was in the section, but I guess we were still technically
   }            // succesful.
   int mark_id=_alloc_selection();
   _select_line(mark_id);
   if (_ini_find_section('')) {
      bottom();
   } else {
      up();
   }
   _select_line(mark_id);
   activate_window(temp_view_id);
   _copy_to_cursor(mark_id);
   p_line=1;
   _free_selection(mark_id);

   // Remove blank lines:
   top();
   up();
   while (!down()) {
      get_line(line);
      if (line=="") {
         _delete_line();
         up();
      }
   }
   p_line=1;

   return(0);
}

// Convert all the file names in this view to absolute paths
// Also will parse out and replace project escape sequences.
void _ConvertViewToAbsolute(int ViewId, _str WorkingDir, int iFirstLine=0,
                            boolean listboxFormat=false,
                            boolean parseProjectCommand=false,
                            boolean convertToAbsolute=true)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;

   p_line=iFirstLine;
   _str filename;
   int handle=0;
   _str config='';
   if (_project_name!='' && _workspace_filename!='') {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   }
   while (!down()) {
      get_line(filename);
      if (filename=='') continue;

      if (parseProjectCommand && pos('%',filename)) {
         filename = _parse_project_command(filename,"",_project_name,"",'','','',null,null,handle,config);
      }

      if (convertToAbsolute) {
         if (listboxFormat) {
            replace_line(' 'absolute(substr(filename,2),WorkingDir));
         } else {
            replace_line(absolute(filename,WorkingDir));
         }
      } else {
         replace_line(filename);
      }
   }

   p_window_id=orig_view_id;
}

//Appends sections from current view to OutputViewId if SectionNamePrefix matches
static void AppendSectionsToView(_str SectionNamePrefix,int OutputViewId,boolean listboxFormat=false)
{
   int orig_view_id=p_window_id;
   save_pos(auto p);
   top();up();
   int markid=_alloc_selection();
   int status;
   for (;;) {
      status=search('^\['_escape_re_chars(SectionNamePrefix)'?@\]','@rih');
      if (status) {
         break;
      }
      if (down()) break;
      if (get_text()!='[') {
         _deselect(markid);
         _select_line(markid);
         status=search('^\[?@\]$','@rh');
         if (status) {
            bottom();
         } else {
            up();
         }
         status=_select_line(markid);
         if (status) {
            clear_message();
         }
         if (status!=TEXT_NOT_SELECTED_RC) {
            p_window_id=OutputViewId;
            bottom();
            _copy_to_cursor(markid);
            if (listboxFormat) {
               _shift_selection_right(markid);
               //_showbuf(p_buf_id);
            }
            p_window_id=orig_view_id;
         }
      }
   }
   p_window_id=orig_view_id;
   restore_pos(p);
   _free_selection(markid);
}

static void RemoveWildcards(int FileListViewId)
{
   int orig_view_id=p_window_id;
   p_window_id=FileListViewId;
   top();up();
   int status;
   for (;;) {
#if __PCDOS__
      status=search('\*|\?','@rh>');
#elif __UNIX__
  /* :,+,@,#,$ sign not included because UNIX allows these chars. */
      status=search('\*|\?|\[|\]|\^|\\','@rh>');
#else
  what are the wild card characters
#endif
     if (!status) {
        _delete_line();up();
     }else{
        break;
     }
   }
   p_window_id=orig_view_id;
}

/**
 * Clear the project file list cache when they close the workspace.
 */
void _wkspace_close_project_cache()
{
   _clearWorkspaceFileListCache();
}
/**
 * Clear the project file list cache on exit the editor.
 */
void _exit_project_cache() 
{
   _clearWorkspaceFileListCache();
}

/**
 * Called when files are added to the workspace.
 */
void _workspace_file_add_project_cache(_str projName, _str fileName)
{
   _clearWorkspaceFileListCache();
}

/** 
 * Called when files are added to any project by any means 
 * (i.e. even if a project is inserted into a workspace) 
 */
void _prjupdate_project_cache() 
{
   _clearWorkspaceFileListCache();
}

/** 
 * Get the list of project files and put them into a list.
 * <p>
 * This function supports putting the files into an editor control
 * line by line or into a list box.  It also can create a temp view
 * (and will by default).  Remember to delete the temp view after you
 * are done with it, unless you are using the cached temp view, then
 * it is not necessary to delete the temp view.
 *  
 *  
 * @param CacheFileListViewId
 *             If true, attempt to find a cached copy of the file list.
 *             This option is not compatible with makefile types and
 *             it only works when "CreateFilesView" is true and
 *             "listBoxFormat" is false. If using the caching mechanism,
 *             do not delete or modify the contents of the temp view
 *             (since it is cached and re-used).
 *  
 *  
 * @param ProjectFilename
 *             Project file to get file list from     
 * @param FileListViewId
 *             Editor control or list box to insert into.
 *             If creating a temp view, this will be set to the window
 *             ID of the temp view.
 * @param MakefileIndicator
 *             Optional third argument is a character to put in front of
 *             files that come from an associated makefile(I recommend using
 *             '*', because it is invalid).  This is to identify the files as
 *             being members of an associated makefile.
 * @param Makefilename
 *             Name of makefile (or other non-slickedit project) to parse
 *             for the file list.
 * @param MakefileType
 *             Type of makefile
 * @param CreateFilesView
 *             If true, create a new temp view to put the file list into.
 * @param ConvertFilesToAbsolute
 *             If true, convert file names to absolute paths.  Note that this
 *             can be expensive, so use with care.
 * @param listboxFormat
 *             If true, insert files in a list box format.  Note, that this
 *             option is incompatible with the caching option (see below).
 * @param project_handle
 *             Project handle for the given project
 * @param ConfigName
 *             Name of configuration to get files from specifically.
 *             "" implies all configurations.
 * 
 * @return 0 on success, <0 on error.
 */
int GetProjectFiles(_str ProjectFilename,int &FileListViewId,
                    _str MakefileIndicator="",
                    _str Makefilename=null,// null means get makefile and type from project file.
                    // Anything else means already
                    // have Makefilename and MakeFileType
                    _str MakefileType="",
                    boolean CreateFilesView=true,
                    boolean ConvertFilesToAbsolute=true,
                    boolean listboxFormat=false,
                    int project_handle=-1,
                    _str ConfigName=""
                    )
{
   // create temp view if requested
   get_window_id(auto orig_view_id);
   if (CreateFilesView) {
      orig_view_id=_create_temp_view(FileListViewId);
      activate_window(orig_view_id);
   }

   // get the file list
   _str filelist[];
   _getProjectFiles(_workspace_filename, ProjectFilename, filelist, (int)ConvertFilesToAbsolute, project_handle);

   // Prepare to fill in the file list view id
   p_window_id=FileListViewId;
   bottom();
   int append_after_ln=p_line;

   // do we put a space before each file name?
   prefix := listboxFormat ? ' ' : '';

   for (i := 0; i < filelist._length(); i++) {
      insert_line(prefix :+ filelist[i]);
   }

   activate_window(orig_view_id);

   return(0);
}

void _InsertAssociatedProjectFileList(_str ProjectName,
                                      int (&BitmapIndexList)[],
                                      int iMaxSccNum,
                                      int iMenuCloseIndex,
                                      int iMenuOpenIndex,
                                      int iCurrentVCSIsScc,
                                      int iProjectIndex)
{
   // make sure the project can be opened
   if (_ProjectHandle(ProjectName)<0) return;

   _str AutoFolders=_ProjectGet_AutoFolders(_ProjectHandle(ProjectName));
   if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {

      _str path=_strip_filename(ProjectName,'N');
      int temp_handle=_ProjectCreate(path);
      int FilesNode=_ProjectGet_FilesNode(temp_handle,true);
      _xmlcfg_set_attribute(temp_handle,FilesNode,'AutoFolders',AutoFolders);
      int Node=FilesNode;
      int flags=VSXMLCFG_ADD_AS_CHILD;

      _str fileList[];
      int status = _getProjectFiles(_workspace_filename, ProjectName, fileList, 0);
      if (!status) {
         for (i := 0; i < fileList._length(); i++) {
            Node=_xmlcfg_add(temp_handle,Node,VPJTAG_F,VSXMLCFG_NODE_ELEMENT_START_END,flags);
            _xmlcfg_set_attribute(temp_handle,Node,'N',_NormalizeFile(fileList[i]));
            flags=0;
         }
      }

      _ProjectAutoFolders(temp_handle);
      typeless ExtToNodeHashTab;
      _InsertProjectFileListXML(temp_handle,
                                BitmapIndexList,
                                iMaxSccNum,
                                iMenuCloseIndex,
                                iMenuOpenIndex,
                                iCurrentVCSIsScc,
                                iProjectIndex,
                                ExtToNodeHashTab,
                                true   // Normalize folder names
                                );
      _xmlcfg_close(temp_handle);
      return;

   }
   _str AssociatedFile,AssociatedFileType;
   _GetAssociatedProjectInfo(ProjectName,AssociatedFile,AssociatedFileType);
   _str ext=_get_extension(AssociatedFile,true);

   if (file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT) ||
       file_eq(ext, JBUILDER_PROJECT_EXT) ||
       file_eq(ext, MACROMEDIA_FLASH_PROJECT_EXT)
       ) {
      int status;
      int cachedHandle = _ProjectAssociatedHandle(_AbsoluteToProject(AssociatedFile,ProjectName), status);
      if (cachedHandle>=0) {
         // make a copy of the cached xml file because it may be modified
         // before being passed to _InsertProjectFileListXML().  the filename
         // must have the same extension as the xml file that we are cloning
         // because of support for xml variations and other functions that check
         // the extension of the file.  this is ok since this copy will never
         // be saved
         int handle = _xmlcfg_create(_xmlcfg_get_filename(cachedHandle), VSENCODING_UTF8);
         int rootnode = _xmlcfg_copy(handle, TREE_ROOT_INDEX, cachedHandle, TREE_ROOT_INDEX, VSXMLCFG_COPY_CHILDREN);

         // check the associated project type
         if(file_eq(_get_extension(AssociatedFile,true),JBUILDER_PROJECT_EXT)) {
            // this is a jbuilder project which had its xml syntax modified by
            // _ProjectAssociatedHandle() when it was opened.  now expand any
            // wildcards before inserting the file list
            _ExpandXMLFilesNode(handle, _ProjectGet_FilesNode(handle));
         }
         typeless junk;
         status= _InsertProjectFileListXML(handle,
                                           BitmapIndexList,
                                           iMaxSccNum,
                                           iMenuCloseIndex,
                                           iMenuOpenIndex,
                                           iCurrentVCSIsScc,
                                           iProjectIndex,
                                           junk,
                                           false   // Don't normalize folder names
                                           );

         // get rid of the copy with the expanded wildcards
         _xmlcfg_close(handle);
      }
   } else if(file_eq(ext, VISUAL_STUDIO_VCX_PROJECT_EXT)){
      _InsertVCXProjectHierarchy(AssociatedFile, 0, p_window_id, iProjectIndex);

   } else if (file_eq(ext,VISUAL_STUDIO_DATABASE_PROJECT_EXT)) {
      InsertFileListFromVSDatabaseFile(ProjectName,AssociatedFile,iMenuOpenIndex,iMenuCloseIndex,iCurrentVCSIsScc,iMaxSccNum,iProjectIndex);
   } else if (file_eq(ext,VCPP_PROJECT_FILE_EXT) || file_eq(ext,VCPP_EMBEDDED_PROJECT_FILE_EXT)) {
      int tree_wid=p_window_id;
      int temp_view_id, orig_view_id;
      int status=_open_temp_view(AssociatedFile,temp_view_id,orig_view_id);
      if (status) {
         return;
      }
      _str VariableEnd=")";
      _str VariableStart="$(";
      activate_window(temp_view_id);top();
      int index=iProjectIndex;
      _str vartab:[];
      _str ProjectDir=_strip_filename(AssociatedFile,'N');
      boolean hashtab:[];
      boolean iUsingScc=false;
      int StatusList[];

      if (iCurrentVCSIsScc && _SccGetCurProjectInfo(1)!="") {
         _str fileList[];
         _getProjectFiles(_workspace_filename, ProjectName, fileList, 1);
         status=_SccQueryInfo2(fileList,StatusList,iMaxSccNum);
         iUsingScc=true;
      }
      int NofInserted=0;
      _str type,filename,varend;

      // Hash table of indexes of parent tree items.  We are actually collecting
      // them as the indexes of the hash table because we do not want to get
      // duplicates
      int parent_indexes:[];
      for (;;) {
         /* look for
            SOURCE=.\xxx.cpp
            SOURCE=".\xxx.cpp"
            # Begin Group "Source Files"
            # End Group
         */
         status=search('^(':+
                       '({#0S}OURCE={#1(:p)|("?@")})':+'|':+
                       '(\# {#0B}egin Group:b"{#1?@}")':+'|':+
                       '(\# {#0E}nd Group)':+
                       ')$','@rh>');
         if (status) {
            break;
         }
         type=get_match_text(0);
         filename=get_match_text(1);
         switch (type) {
         case 'S':
            varend=substr(filename,(length(filename)+1)-length(VariableEnd),length(VariableEnd));
            if ( (substr(filename,1,length(VariableStart))==VariableStart && VariableStart!='')||
                 (substr(filename,length(filename)-length(VariableEnd),length(VariableEnd))==VariableEnd) &&
                 VariableEnd!=''
               ) {
               AddVariableValueToList2(tree_wid,filename,index,VariableStart,VariableEnd,ProjectDir,hashtab,vartab,NofInserted,StatusList,iUsingScc);
            } else {
               filename= absolute(filename,ProjectDir);
               if (!hashtab._indexin(filename)) {
                  hashtab:[filename]=1;
                  //filename=maybe_quote_filename(filename);
                  _projecttb_AddFile(tree_wid,index,filename,NofInserted,StatusList,iUsingScc);
                  parent_indexes:[index]=1; // Save the parent index as an index into this hash table
               }
            }
            break;
         case 'B':
            index=tree_wid._TreeAddItem(index,
                                        filename,
                                        TREE_ADD_AS_CHILD,
                                        iMenuCloseIndex,
                                        iMenuOpenIndex,
                                        0,0);
            parent_indexes:[index]=1; // Save the parent index as an index into this hash table
            break;
         case 'E':
            index=tree_wid._TreeGetParentIndex(index);
            break;
         }
         /*if (length(FileList) > CurStringWarningLimit-100) {
            _default_option(VSOPTION_WARNING_STRING_LENGTH,CurStringWarningLimit*2);
            CurStringWarningLimit*=2;
         }*/
      }
      // Loop through the parent indexes and sort the items below those tree nodes
      typeless indexvar;
      for (indexvar._makeempty();;) {
         parent_indexes._nextel(indexvar);
         if (indexvar==null) break;
         tree_wid._TreeSortCaption(indexvar,'F');
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);

   } else if (AssociatedFileType == XCODE_PROJECT_VENDOR_NAME) {
      // This is associated to the .xcode or .xcodeproj bundle dir, but we need
      // to read the information from the .pbxproj in the bundle
      _str pbxprojPath = absolute("project.pbxproj", AssociatedFile);
      _InsertXcodeProjectHierarchy(pbxprojPath, p_window_id, iProjectIndex);
   } else {
      /*
          Filter the files on the fly.
          Get here for Tornado
      */
      _str fileList[];
      _getProjectFiles(_workspace_filename, ProjectName, fileList, 1);
      fileList._sort('2');  // Sort on name case insensitive, then name case sensitive
      int TempHandle=_ProjectHandle(ProjectName);
      int Node=_ProjectGet_FilesNode(TempHandle,true);
      int ExtToNodeHashTab:[];
      _CreateProjectFilterTree(p_window_id,iProjectIndex,TempHandle,Node,ExtToNodeHashTab);
      _InsertProjectFileList(fileList,
                             ExtToNodeHashTab,//assocTypeList,
                             //patternList,
                             BitmapIndexList,
                             MAXINT,   // Not used any more
                             iMaxSccNum,
                             iCurrentVCSIsScc);

   }

}

/**
 * This function can convert the copy of the jpx file in memory
 * to and from VSE format so that the files and folders can be
 * read like a VSE project.  This is only to be used for the
 * file list.  Other options are still read during
 * _WorkspaceAssociate().
 *
 * @param handle Handle to the JBuilder project (.jpx)
 * @param toVSEFormat
 *               T to convert to VSE format, F to convert back to JBuilder format
 */
void _convertJBuilderXML(int handle, boolean toVSEFormat)
{
   // find the project node for use later
   int projectNode = _xmlcfg_find_simple(handle, "/project");
   int status;
   if(toVSEFormat) {
      // convert all file nodes
      typeless fileNodeList[] = null;
      status = _xmlcfg_find_simple_array(handle, "/project//file", fileNodeList);
      int i;
      for(i = 0; i < fileNodeList._length(); i++) {
         int fileNode = fileNodeList[i];

         // change file to F
         _xmlcfg_set_name(handle, fileNode, VPJTAG_F);

         // change path to N
         int jpxFileNameAttr = _xmlcfg_find_child_with_name(handle, fileNode, "path", VSXMLCFG_NODE_ATTRIBUTE);
         if(jpxFileNameAttr >= 0) {
            _xmlcfg_set_name(handle, jpxFileNameAttr, "N");
         }
      }

      // convert all folders
      typeless folderNodeList[] = null;
      status = _xmlcfg_find_simple_array(handle, "/project//node", folderNodeList);
      for(i = 0; i < folderNodeList._length(); i++) {
         int folderNode = folderNodeList[i];

         // make sure this is a node that we are intersted in.  we only
         // want nodes that have type="Folder" or type="NavigationDirectory"
         _str nodeType = _xmlcfg_get_attribute(handle, folderNode, "type");
         if(strieq(nodeType, "Folder")) {
            // change node to Folder
            _xmlcfg_set_name(handle, folderNode, VPJTAG_FOLDER);

            // change name to Name
            int jpxFolderNameAttr = _xmlcfg_find_child_with_name(handle, folderNode, "name", VSXMLCFG_NODE_ATTRIBUTE);
            if(jpxFolderNameAttr >= 0) {
               _xmlcfg_set_name(handle, jpxFolderNameAttr, "Name");
            }

         } else if(strieq(nodeType, "NavigationDirectory")) {
            // change node to Folder
            _xmlcfg_set_name(handle, folderNode, VPJTAG_FOLDER);

            // get the path to the folder
            int node = _xmlcfg_find_simple(handle, "property" XPATH_STRIEQ("category", "directorynode") XPATH_STRIEQ("name", "url"), folderNode);
            if(node < 0) {
               // undefined path so ignore it
               continue;
            }
            _str folderPath = _xmlcfg_get_attribute(handle, node, "value");

            // convert the path to the native format and replace any special placeholders
            folderPath = stranslate(folderPath, ":", "%%|");
            folderPath = _AbsoluteToProject(folderPath);
            _maybe_append_filesep(folderPath);

            // change name to Name
            int folderNameAttr = _xmlcfg_find_child_with_name(handle, folderNode, "name", VSXMLCFG_NODE_ATTRIBUTE);
            if(folderNameAttr >= 0) {
               _xmlcfg_set_name(handle, folderNameAttr, "Name");
            }

            // change the value of the Name attribute to the path to the directory
            //_xmlcfg_set_attribute(handle, folderNode, "Name", folderPath);

            // check for recursive
            boolean recursive = false;
            node = _xmlcfg_find_simple(handle, "property" XPATH_STRIEQ("category", "directorynode") XPATH_STRIEQ("name", "showSubdirectories"), folderNode);
            if(node >= 0) {
               if(_xmlcfg_get_attribute(handle, node, "value") == "1") {
                  recursive = true;
               }
            }

            // check for filter
            boolean useFilter = false;
            node = _xmlcfg_find_simple(handle, "property" XPATH_STRIEQ("category", "directorynode") XPATH_STRIEQ("name", "usePatternFilter"), folderNode);
            if(node >= 0) {
               if(_xmlcfg_get_attribute(handle, node, "value") == "1") {
                  useFilter = true;
               }
            }

            // check for filter pattern
            _str filter = "";
            node = _xmlcfg_find_simple(handle, "property" XPATH_STRIEQ("category", "directorynode") XPATH_STRIEQ("name", "pattern"), folderNode);
            if(node >= 0) {
               filter = _xmlcfg_get_attribute(handle, node, "value");
            }

            // check filter type
            boolean filterIsWildcard = true;
            node = _xmlcfg_find_simple(handle, "property" XPATH_STRIEQ("category", "directorynode") XPATH_STRIEQ("name", "patternType"), folderNode);
            if(node >= 0) {
               // patternType is always removed from the project if it is a wildcard so its
               // presence implies that it is a regexp
               filterIsWildcard = false;
            }

            // add the wildcard file tag inside the folder (this should be removed during save)
            int wildcardNode = _xmlcfg_add(handle, folderNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
            if(filter == "") {
               if(__UNIX__) {
                  filter = "*";
               } else {
                  filter = "*.*";
               }
            }
            filter = folderPath :+ filter;
            _xmlcfg_set_attribute(handle, wildcardNode, "N", _NormalizeFile(filter));
            if(recursive) {
               _xmlcfg_set_attribute(handle, wildcardNode, "Recurse", "1");
            }

         } else {
            // ignored type
            continue;
         }
      }

      // check to see if the 'source and package discovery' feature is enabled
      int sourceDiscoveryNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("category", "sys") XPATH_STRIEQ("name", "enable.auto.packages"));
      if(sourceDiscoveryNode < 0 || _xmlcfg_get_attribute(handle, sourceDiscoveryNode, "value") != "false") {
         // source discovery enabled so retrieve the list of source dirs
         int sourceDirNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "SourcePath"));
         if(sourceDirNode >= 0) {
            // add a folder named '<Project Source>' to hold the discovered source
            // NOTE: need to force '<Project Source>' to the top of the list so it
            //       must be added before all other folders in the xml file.  to do this
            //       we have to find the first child node of the project and add the
            //       folder before it
            int sourceDiscoveryFolderNode = -1;

            // look for the first child of the project node
            int projectFirstChild = _xmlcfg_get_first_child(handle, projectNode);
            if(projectFirstChild >= 0) {
               sourceDiscoveryFolderNode = _xmlcfg_add(handle, projectFirstChild, VPJTAG_FOLDER, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_BEFORE);
            } else {
               sourceDiscoveryFolderNode = _xmlcfg_add(handle, projectNode, VPJTAG_FOLDER, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            }

            // set the name and type (this folder should be removed during save)
            _xmlcfg_set_attribute(handle, sourceDiscoveryFolderNode, "Name", "<Project Source>");
            _xmlcfg_set_attribute(handle, sourceDiscoveryFolderNode, "type", "SourceDiscovery");

            _str sourceDirList = _xmlcfg_get_attribute(handle, sourceDirNode, "value");
            for(;;) {
               // NOTE: this intentionally uses ';' instead of PATHSEP because the jbuilder
               //       projects always use semi-colon no matter the platform
               _str dir = "";
               parse sourceDirList with dir ";" sourceDirList;
               if(dir == "") break;

               // absolute it to the project
               dir = absolute(dir, _strip_filename(_xmlcfg_get_filename(handle), "N"));

               // add a wildcard file tag for this source dir
               int wildcardNode = _xmlcfg_add(handle, sourceDiscoveryFolderNode, VPJTAG_F, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
               _str filter = dir;
               _maybe_append_filesep(filter);
               if(__UNIX__) {
                  filter = filter "*";
               } else {
                  filter = filter "*.*";
               }

               _xmlcfg_set_attribute(handle, wildcardNode, "N", _NormalizeFile(filter));
               _xmlcfg_set_attribute(handle, wildcardNode, "Recurse", "1");
            }
         }
      }

   } else {
      // convert all file nodes
      typeless fileNodeList[] = null;
      status = _xmlcfg_find_simple_array(handle, "/project//" VPJTAG_F, fileNodeList);
      int i;
      for(i = 0; i < fileNodeList._length(); i++) {
         int fileNode = fileNodeList[i];

         // change F to file
         _xmlcfg_set_name(handle, fileNode, "file");

         // change N to path
         int jpxFileNameAttr = _xmlcfg_find_child_with_name(handle, fileNode, "N", VSXMLCFG_NODE_ATTRIBUTE);
         if(jpxFileNameAttr >= 0) {
            _xmlcfg_set_name(handle, jpxFileNameAttr, "path");
         }
      }
                                                                                    
      // convert all folders
      // NOTE: only basic folders are allowed to be added, so there is no need to handle
      //       the NavigationDirectory folders specially
      typeless folderNodeList[] = null;
      status = _xmlcfg_find_simple_array(handle, "/project//" VPJTAG_FOLDER, folderNodeList);
      for(i = 0; i < folderNodeList._length(); i++) {
         int folderNode = folderNodeList[i];

         // change Folder to node
         _xmlcfg_set_name(handle, folderNode, "node");

         // change name to Name
         int jpxFolderNameAttr = _xmlcfg_find_child_with_name(handle, folderNode, "Name", VSXMLCFG_NODE_ATTRIBUTE);
         if(jpxFolderNameAttr >= 0) {
            _xmlcfg_set_name(handle, jpxFolderNameAttr, "name");
         }

         // if type attribute not specified, set it to "Folder" since NavigationDirectories
         // are not allowed to be added in VSE
         int jpxFolderTypeAttr = _xmlcfg_find_child_with_name(handle, folderNode, "type", VSXMLCFG_NODE_ATTRIBUTE);
         if(jpxFolderTypeAttr < 0) {
            _xmlcfg_set_attribute(handle, folderNode, "type", "Folder");
         } else {
            _str nodeType = _xmlcfg_get_attribute(handle, folderNode, "type");
            if(strieq(nodeType, "NavigationDirectory")) {
               // remove wildcard (file node) that was added to NavigationDirectory Folder
               typeless wildcardFileNodeList[] = null;
               status = _xmlcfg_find_simple_array(handle, "file", wildcardFileNodeList, folderNode);
               int k;
               for(k = 0; k < wildcardFileNodeList._length(); k++) {
                  _xmlcfg_delete(handle, wildcardFileNodeList[k]);
               }
            } else if(strieq(nodeType, "SourceDiscovery")) {
               // remove '<Source Discovery>' node because it does not really exist
               _xmlcfg_delete(handle, folderNode);
            }
         }
      }
   }
   //_showxml(handle, TREE_ROOT_INDEX, VSXMLCFG_SAVE_ALL_ON_ONE_LINE, 3);
}

static void ConvertViewToLBFormat(int ViewId)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   if (!p_Noflines) {
      p_window_id=orig_view_id;
      return;
   }
   top();
   search('^{[~ ]}','rh@',' #0');
   p_window_id=orig_view_id;
}

//Make file import section
struct MI_makefileMacro_t {
   _str basePath;
   _str expansion;
   _str filename;
   long lineNumber;
};
struct MI_referencedMakefile{
   _str makefileName;
   _str startDir;
};
struct MI_makefileTarget_t{
   _str basePath;
   _str prereqs;
   _str filename;
   int  lineNumber;
   _str commands[];
   MI_referencedMakefile recursiveMakefiles[];
};
struct MI_projectTargets{
   //_str compile;
   _str build;
   _str rebuild;
   _str exe;
   _str clean;
};

//Make file import section
#define MAXMAKEFILEINCLUDEDEPTH 10

/**
 * Author: David A. O'Brien
 * Date:   1/3/2008
 * 
 * Given a string representing a line in a makefile, compress any 
 * trailing whitespace to a single space as defined by make rules.
 * 
 * @param content (_str&) String from which to compress trailing 
 *                whitespace.
 */
static void MI_compressTrailingWS(_str &content) {
   if (content._length() && (last_char(content) == ' ' || last_char(content) == "\t")) {
      content = strip(content, 'T') :+ ' ';
   }
}

/**
 * Author: David A. O'Brien
 * 
 * Given a string that may represent multiple lines continued by "\" at 
 * last character before new line sequence, combine these lines into a 
 * single line string divided by a space as defined by make rules. 
 * 
 * @param content (_str&) String to compress to single line form. 
 */
static void MI_compressContinuedLines(_str &content) {
   int position = pos("\\\n", content);
   while(position) {
      if (content._length() > position + 1) {
         content = strip(substr(content, 1, position -1)) :+ ' ' :+ strip(substr(content, position + 2), 'L');
      } else {
         content = strip(substr(content, 1, position -1));
      }
      position = pos("\\\n", content);
   }
}

_str removeSuffix(_str input) {
   return input;
}

_str dotOFile(_str input) {
   return input;
}

static _str specialMacroRefRegex = '\${#0\@|\$\@|\?|<|\*|\%}|\$\({#0\@|\?|<|\*|\%}\)|\$\{{#0\@|\?|<|\*|\%}\}';
static _str macroRefRegex = '\${#0:a|\@|\$}|\$\({#0[0-9a-zA-Z_ ]@|\@|\$}\)|\$\{{#0[0-9a-zA-Z_ ]@|\@|\$}\}';

#define RM_FAILURE -1
#define RM_NO_SUBSTITUTION 0
#define RM_SUBSTITUTION 1

int resolveMacros(MI_makefileMacro_t (&makefileMacros):[], _str& value, _str usedKeys:[], _str targetName = '', _str preReqNames = '') {
   _str origUsedKeys:[] = usedKeys;
   value = resolveSpecialMacros(value, targetName, preReqNames);
   int matchPos = 0, matchLen = 0;
   int returnVal = RM_NO_SUBSTITUTION;
   _str posResult = '', macroName = '', macroExpansion = '', newValue = '';
   int posStatus = macroPos(value, 1, macroName, matchPos, matchLen);
   int status, strSubStatus;
   while (posStatus) {
      //Expand any macros in the name of the macro (e.g. ${AA${BB}AA})
      status = resolveMacros(makefileMacros, macroName, usedKeys, targetName, preReqNames);

      //Check macro string substitution (e.g. ${SRCS:.c=.o}
      strSubStatus = lastpos('\:{#1[~=\:]#}={#2[~=\:]@}$', macroName, '', 'R');
      _str subStr1 = '', subStr2 = '';
      if (strSubStatus > 1) {
         subStr1   = substr(macroName, lastpos('S1'), lastpos('1'));
         subStr2   = substr(macroName, lastpos('S2'), lastpos('2'));
         macroName = substr(macroName, 1, strSubStatus - 1);
      }

      //Break out if we've hit a cycle 
      if (usedKeys._indexin(macroName)) {
         return RM_FAILURE;
      }

      if (!makefileMacros._indexin(macroName)) {
         macroExpansion =  '';
      } else {
         usedKeys:[macroName] = 'X';
         _str lookup = makefileMacros:[macroName].expansion;
         //Resolve any macros in the portion returned.
         int rmStatus = resolveMacros(makefileMacros, lookup, usedKeys, targetName, preReqNames);
         usedKeys._deleteel(macroName);
         if (rmStatus == RM_SUBSTITUTION) {
            makefileMacros:[macroName].expansion = lookup;
            macroExpansion = lookup;
         } 
         else if (rmStatus == RM_FAILURE) {
            macroExpansion =   '';
         } else
         macroExpansion = lookup;
      }


      if (strSubStatus > 1) {
         //do macro string substitution.
         macroStringSubsitution(macroExpansion, subStr1, subStr2);
      }

      returnVal = RM_SUBSTITUTION;
      if (matchPos > 1) {
         newValue = substr(value, 1, matchPos - 1);
      } else newValue = '';
      strappend(newValue, macroExpansion);
      if (value._length() >= (matchPos + matchLen)) {
         int nextSearchPos = newValue._length() + 1;
         strappend(newValue, substr(value, matchPos + matchLen));
         //posStatus = pos(macroRefRegex, newValue, nextSearchPos, 'R');
         posStatus = macroPos(newValue, nextSearchPos, macroName, matchPos, matchLen);
      } else {
         posStatus = 0;
      }
      value = newValue;
   }

   return returnVal;
}

_str resolveSpecialMacros(_str value, _str targetName = '', _str preReqNames = '') {
   int matchPos = 0, matchLen = 0;
   int matchPos0 = 0, matchLen0 = 0;
   _str posResult = '', posResult0 = '', newValue = '';
   int posStatus = pos(specialMacroRefRegex, value, 1, 'R');
   while (posStatus) {
      matchPos = pos('S');
      matchLen = pos('');
      matchPos0 = pos('S0');
      matchLen0 = pos('0');
      //posResult = substr(value, matchPos, matchLen);
      posResult0 = substr(value, matchPos0, matchLen0);
      switch (posResult0) {
         case '@':
         case '$@':
            posResult0 = targetName;
            break;
         case '$?':
            posResult0 = preReqNames;
            break;
         case '$*':
            posResult0 = preReqNames;
            break;
         case '$<':
            posResult0 = removeSuffix(preReqNames);
            break;
         case '$%':
            posResult0 = dotOFile(preReqNames);
            break;
         default:
            posResult0 = '';
            break;
      }

      if (matchPos > 1) {
         newValue = substr(value, 1, matchPos - 1);
      } else newValue = '';
      strappend(newValue, posResult0);
      if (value._length() >= (matchPos + matchLen)) {
         int nextSearchPos = newValue._length() + 1;
         strappend(newValue, substr(value, matchPos + matchLen));
         posStatus = pos(specialMacroRefRegex, newValue, nextSearchPos, 'R');
      } else {
         posStatus = 0;
      }
      value = newValue;
   }
   return value;
}

/** 
 * Searches a string for the start sequence of a makefile macro. 
 * Parameters work like the Slick-C pos() function. 
 *  
 * Makefile macros look something like the following
 * <pre>
 * SOURCE = main.c helper.c
 * HEADERS = ${SOURCE:.c=.h}
 * FILES = ${SOURCE} ${HEADERS}
 * </pre>
 * 
 * @param value
 * @param startPos
 * @param matchStr
 * @param matchPos
 * @param matchLen
 * 
 * @return int
 */
int macroPos(_str value, int startPos, _str& matchStr, int &matchPos, int &matchLen) {
   int status1 = pos('\${#0\$\@|[_:a\@\?\*\<\%\(\{]}', value, startPos, 'R');
   if (!status1) {
      return 0;
   }
   int posLen = pos('0');
   matchPos = pos('S');
   if (posLen == 2) { //Found $$@ macro
      matchLen = 3;
      matchStr = substr(value, matchPos + 1, 2);
      return status1;
   } 
   if (posLen == 1) {
      int status2, closerPos;
      _str firstChar = substr(value, matchPos + 1, 1);
      if (firstChar != '{' && firstChar != '(') {
         //Found macro with no braces/parens, so one character name macro.
         matchLen = 2;
         matchStr = firstChar;
         return status1;
      }
      if (firstChar == '{') {
         firstChar = '}';
      }
      else firstChar = ')';
      closerPos = matchPos + 2; 
      //Find closing brace/paren or start of embedded macro
      while (pos('\$|\'firstChar, value, closerPos, 'R')) {
         closerPos = pos('S');
         if (substr(value, closerPos, 1) == '$') {
            _str matchStr2;
            int matchPos2, matchLen2;
            if (!macroPos(value, closerPos, matchStr2, matchPos2, matchLen2)) {
               return 0;
            }
            closerPos = matchPos2 + matchLen2;
            continue;
         }
         else {
            matchLen = closerPos - matchPos + 1;
            matchStr = substr(value, matchPos + 2, matchLen - 3);
            return status1;
         }
      }
   } 
   return 0;
}

int resolveMacroLHS(MI_makefileMacro_t (&makefileMacros):[], _str& value) {
   _str usedKeys:[];
   usedKeys._makeempty();
   _str origValue = value;
   int status = resolveMacros(makefileMacros, value, usedKeys);
   if (status == RM_FAILURE) {
      value = origValue;
   }
   return status;
}
_str resolveMacroRHS(MI_makefileMacro_t (&makefileMacros):[], _str& value, _str targetName = '', _str preReqNames = '') {
   return resolveMacroLHS(makefileMacros, value);
}

_str resolveTargetLHS(MI_makefileMacro_t (&makefileMacros):[], _str& value, _str targetName = '', _str preReqNames = '') {
   return resolveMacroLHS(makefileMacros, value);
}

_str resolveTargetRHS(MI_makefileMacro_t (&makefileMacros):[], _str& value, _str targetName = '', _str preReqNames = '') {
   _str usedKeys:[];
   usedKeys._makeempty();
   _str origValue = value;
   int status = resolveMacros(makefileMacros, value, usedKeys, targetName, preReqNames);
   value = strip(value);
   if (status == RM_FAILURE) {
      value = origValue;
   }
   
   return status;
}

/** 
 * used to do the actual lookup into the macro hashtable.  Recursively 
 * calls resolve macro to resolve macros within macros and stores these 
 * results so that they will not need to be recalculated each time. 
 * 
 * @param makefileMacros The macros hash table.
 * @param key            The name or key of the macro to retreive from 
 *                       the macros hash table,
 *                       <code>makefileMacros</code>.
 * @param usedKeys       Hash of keys used so far to get to this level 
 *                       of macro nesting.
 * @param targetName     Target name for expanding special macros that
 *                       insert this.
 * @param preReqNames    Prerequisite names for expanding special macros
 *                       that insert this.
 * 
 * @return _str          The expanded value of the macro corresponding 
 *                       to <code>key</code>.
 */
_str lookUpMacro(MI_makefileMacro_t (&makefileMacros):[], _str key, _str usedKeys:[], _str targetName = '', _str preReqNames = '') {
   if (!makefileMacros._indexin(key)) {
      return '';
   }
   usedKeys:[key] = 'X';
   _str lookup = makefileMacros:[key].expansion;
   //Resolve any macros in the portion returned.
   int rmStatus = resolveMacros(makefileMacros, lookup, usedKeys, targetName, preReqNames);
   if (rmStatus == RM_SUBSTITUTION) {
      makefileMacros:[key].expansion = lookup;
   } 
   else if (rmStatus == RM_FAILURE) {
      return '';
   }
   return lookup;
}

/** 
 * Handles makefile macro string substitution.  That is 
 * <pre> 
 *    SRC = aaa.c bbb.c ccc.c
 *    OBJ = ${SRC:.c=.o}
 * </pre> 
 *  
 * Does the translation of .c to .o 
 * 
 * @param string   Source string
 * @param subStr1  String to look for and replace
 * @param subStr2  String to use in place of <code>subStr1</code>
 */
void macroStringSubsitution(_str& string='', _str subStr1='', _str subStr2='') {

   int fromPos = 1;
   _str newValue;
   int posS0 = 1, pos0 = 0;
   while (pos('{#0'subStr1'}[ \t]', string:+' ', fromPos, 'R')) {
      posS0 = pos('S0');
      pos0  = pos('0');
      newValue = substr(string, 1, posS0 - 1);
      strappend(newValue, subStr2);

      if (string._length() >= (posS0 + pos0)) {
         fromPos = newValue._length() + 1;
         strappend(newValue, substr(string, pos('S0') + pos('0')));
         string = newValue;
      } else {
         string = newValue;
         break;
      }
   }
}

/**
 * 
 * 
 * @author David A. O'Brien (1/16/2008)
 */
class MI_makefileIncludeReference_t {
   int m_lineNumber = 0;
   _str m_includedFileNames[];

   MI_makefileIncludeReference_t() {
      init();
   }

   void init() {
      m_lineNumber = 0;
      m_includedFileNames._makeempty();
   }
};

/**
 * Search from the current location for makefile @include statements.  Returns 
 * the line number of a found @inlcude statement and an array of the included 
 * filenames. 
 * 
 * @param startDirectory Directory of the including makefile.
 * 
 * @return a MI_makefileIncludeReference_t structure holding the line number and 
 *         filenames found in an @include statement.  A line number of zero
 *         means no @inlcude statement found.
 * 
 * @author David A. O'Brien (1/16/2008)
 */
static MI_makefileIncludeReference_t MI_findIncludeReference(_str startDirectory) {
   save_pos(auto p);
   _str includedFile, includeLine;
   MI_makefileIncludeReference_t includeReference;
   if (!search('^[ ]@include{#2([~\#\n]@(\\\n))@[~\#\n]@}', '@R>XC')) {
      includeLine  = strip(get_text(match_length('2'), match_length('S2')), 'L');
      MI_compressContinuedLines(includeLine);
      while (includeLine != '') {
         parse includeLine with includedFile includeLine;
         includedFile = absolute(includedFile, startDirectory);
         if (file_exists(includedFile)) {
            includeReference.m_lineNumber = p_line;
            includeReference.m_includedFileNames[includeReference.m_includedFileNames._length()] = includedFile;
         }
      }
   }
   restore_pos(p);
   return includeReference;
}

/** 
 * 
 * 
 * @param makefileName
 * @param makefileFiles
 * @param makefileMacros
 * @param includeDepth
 * 
 * @return int
 */
int readMakefileMacros(_str makefileName, _str makefileDir, _str (&makefileFiles):[], MI_makefileMacro_t (&makefileMacros):[], boolean checkIfMakefile, int includeDepth = 0)
{
   makefileName = absolute(makefileName);
   if (makefileDir :== '') {
      makefileDir = _strip_filename(makefileName, 'NE');
   }
   //Have we already read this makefile
   if (makefileFiles._indexin(makefileName)) {
      return 1;
   }

   int ini_view_id = 0, view_id = 0;
   if (_open_temp_view(makefileName, ini_view_id, view_id, '', auto buffer_already_exists, false, checkIfMakefile)){
      message('Can not open the file 'makefileName'.');
      return 1;
   }

   // make sure this is a makefile
   if(checkIfMakefile && p_LangId != 'mak') {
      _str result = _message_box("This does not appear to be a makefile.  Continue anyway?", '', MB_OKCANCEL|MB_ICONQUESTION);
      if (result == IDCANCEL) {
         _delete_temp_view(ini_view_id);
         activate_window(view_id);
         return 1;
      }
   }

   //mark this file as processed so that we will not read again
   makefileFiles:[makefileName] = 'X';

   //Break out if we've met our include file depth limit
   if (includeDepth >= MAXMAKEFILEINCLUDEDEPTH) {
      message("Reached limit for makefile includes.");
      return 1;
   }

   _str LHside, RHside;

   //Look for an included makefile.
   top();
   MI_makefileIncludeReference_t includeStatement = MI_findIncludeReference(makefileDir);

   //Search for a macro line using the regex for a macro
   while(!search('{#0^[ ]@{#1[~\t=\:\.\#\n ]([~=\:\#\n]|(\\\n))+}}={#2([~\#\n]@(\\\n))@[~\#\n]@}', '@R>XC')) { 

      //Did we pass an included makefile, if so process that now
      if (includeStatement.m_lineNumber < p_line && includeStatement.m_lineNumber > 0) {
         int i;
         for (i = 0; i < includeStatement.m_includedFileNames._length(); i++) {
            readMakefileMacros(includeStatement.m_includedFileNames[i], makefileDir, makefileFiles, makefileMacros, false, includeDepth + 1);
         }
         //store next include line
         includeStatement = MI_findIncludeReference(makefileDir);
      }

      LHside  = strip(get_text(match_length('1'), match_length('S1')));
      RHside  = strip(get_text(match_length('2'), match_length('S2')), 'L');
      MI_compressContinuedLines(LHside);
      MI_compressContinuedLines(RHside);
      MI_compressTrailingWS(RHside);
      if (resolveMacroLHS(makefileMacros, LHside) != RM_FAILURE) {
         makefileMacros:[LHside].expansion = RHside;
      }
   }
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return 0;
}

/** 
 * 
 * 
 * @param makefileName
 * @param makefileFiles
 * @param makefileMacros
 * @param includeDepth
 * 
 * @return int
 */
int readMakefileTargets(_str makefileName, _str startDirectory, _str (&makefileFiles):[], MI_makefileTarget_t (&makefileTargets):[], MI_makefileMacro_t (&makefileMacros):[], _str &firstTargetName, boolean parseCommands = false, int includeDepth = 0)
{
   makefileName = absolute(makefileName);
   if (startDirectory :== '') {
      startDirectory = _strip_filename(makefileName, 'NE');
   }

   //Have we already read this makefile
   if (makefileFiles._indexin(makefileName)) {
      //message('Skipping 'makefileName);
      return 1;
   }

   int ini_view_id = 0, view_id = 0;
   if (_open_temp_view(makefileName, ini_view_id, view_id)){
      message('Can not open the file 'makefileName'.');
      return 1;
   }

   makefileFiles:[makefileName] = ' ';

   //Break out if we've met our include file depth limit
   if (includeDepth >= MAXMAKEFILEINCLUDEDEPTH) {
      message("Reached limit for makefile includes.");
      return 1;
   }

   _str LHside, RHside;

   //Look for an included makefile.
   top();
   MI_makefileIncludeReference_t includeStatement = MI_findIncludeReference(startDirectory);

   //Target parsing, match the regex for a target
   while(!search('{#0^[ ]@{#1[~\t=\:\.\#\n ]([~=\:\#\n]|(\\\n))+}}\:{#2([~\#\n]@(\\\n))@[~\#\n]@}', '@R>XC')) {

      //Did we pass an included makefile, if so process that now
      if (includeStatement.m_lineNumber < p_line && includeStatement.m_lineNumber > 0) {
         int i;
         for (i = 0; i < includeStatement.m_includedFileNames._length(); i++) {
            readMakefileTargets(includeStatement.m_includedFileNames[i], startDirectory, makefileFiles, makefileTargets, makefileMacros, firstTargetName, parseCommands, includeDepth + 1);
         }
         //store next include line
         includeStatement = MI_findIncludeReference(startDirectory);
      }

      LHside  = strip(get_text(match_length('1'), match_length('S1')));
      RHside  = strip(get_text(match_length('2'), match_length('S2')), 'L');
      MI_compressContinuedLines(LHside);
      MI_compressContinuedLines(RHside);
      MI_compressTrailingWS(RHside);

      if (resolveTargetLHS(makefileMacros, LHside) != RM_FAILURE) {
         _str orig_RHside = RHside;
         //if (resolveTargetRHS(makefileMacros, RHside, LHside) != RM_FAILURE) {
         _str target;
         while (true) {
            parse LHside with target LHside;
            if (target == '') {
               break;
            }
            RHside = orig_RHside;
            if (resolveTargetRHS(makefileMacros, RHside, target) != RM_FAILURE) {
               //Check if this is first target found
               if (makefileTargets._length() == 0) firstTargetName = target;
               makefileTargets:[target].prereqs = RHside;
               makefileTargets:[target].filename = makefileName;
               makefileTargets:[target].basePath = startDirectory;
               makefileTargets:[target].lineNumber = p_line;
               if (parseCommands) {
                  MI_parseTargetCommands(target, makefileMacros, makefileTargets, startDirectory);
               }
               int i;
               for (i = 0; i < makefileTargets:[target].commands._length(); i++) {
                  //say('   'makefileTargets:[target].commands[i]);
               }
            }
         }
      }
   }
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return 0;
}
void MI_parseTargetCommands(_str target, MI_makefileMacro_t (&makefileMacros):[], MI_makefileTarget_t (&makefileTargets):[], _str startDirectory) {
   makefileTargets:[target].commands._makeempty();
   _str commands[];
   commands._makeempty();
   save_pos(auto p);
   begin_line();
   _str line;
   while(true) {
      if(down()) break;
      get_line_raw(line);
      _str stripLine = strip(line);
      if (stripLine == '') {
         continue;
      }
      if (substr(line, 1, 1) :== "\t") {
         //concat continued lines
         while (last_char(line) :== "\\") {
            if(down()) break;
            get_line_raw(auto line2);
            line = strip(substr(line, 1, line._length() - 1)) :+ ' ' :+ strip(line2, 'L');
         }
         if (resolveTargetRHS(makefileMacros, line, target) != RM_FAILURE) {
            _str temp = '';
            while (true) {
               temp = _parse_line(line, ';');
               if (temp == '') break;
               //makefileTargets:[target].commands[makefileTargets:[target].commands._length()] = strip(temp);
               commands[commands._length()] = strip(temp);
            }
         }
         continue;
      }
      break;
   }
   if (commands._length()) {
      makefileTargets:[target].commands = commands;
   }
   restore_pos(p);
   return;
}

void MI_parseRecursiveMakefileCalls(_str (&commands)[], _str startDirectory, boolean debug = false) {
   //look for commands that start with 'cd' or a make command
   int i;
   _str firstToken, remainder;
   for (i = 0; i < commands._length(); i++) {
      _str thisCommand = translate(commands[i], '', '()');
      if (debug) say('+'thisCommand);
      parse thisCommand with firstToken remainder;
      int status = pos("(cd|make|nmake)$", firstToken, 1, 'R');
      if (status) {
         if (substr(firstToken, pos('S'), pos('')) :== 'cd') {
            //found cd command 
            if (remainder :== '') {
               remainder = get_env('HOME');
            }
            if (remainder :!= '') {
               _str newStartDirectory = isdirectory(absolute(remainder, startDirectory));
               if (newStartDirectory) {
                  startDirectory = newStartDirectory;
               }
            }
            if (debug) say('CD ('p_line'): 'commands[i]);
         } else {
            //make command
            status = pos('\-f', remainder, 1, 'R');
            if (debug) say('@'status' 'remainder);
            if (status) {
               _str newMakefile = substr(remainder' ', pos('S') + 2);
               if (debug) say('1'newMakefile);
               parse newMakefile with newMakefile .;
               if (debug) say('2'newMakefile);
               if ((newMakefile != null) && (newMakefile :!= '')) {
                  newMakefile = absolute(newMakefile, startDirectory);
                  if (debug) say('3'newMakefile);
                  if (file_exists(newMakefile)) {
                     if (debug) say('%%'newMakefile'%%');
                  }
               }
            } else {
            }
            if (debug) say('MAKE ('p_line'): 'commands[i]);
         }
      }
   }
   return;
}

int MI_makefile_GetTargetList(_str filename, _str startDirectory, _str (&targetList)[], _str (&descriptionList)[], boolean checkIfMakefile = true)
{
   if (!file_exists(filename)) return 1;

   _str makefileFiles:[];
   MI_makefileTarget_t makefileTargets:[];
   MI_makefileMacro_t makefileMacros:[];
   MI_initHashTables(targetList, makefileFiles, makefileTargets, makefileMacros);

   int status = readMakefileMacros(filename, startDirectory, makefileFiles, makefileMacros, checkIfMakefile);
   if (status) {
      return status;
   }

   makefileFiles._makeempty();
   _str firstTargetName = '';
   status = readMakefileTargets(filename, startDirectory, makefileFiles, makefileTargets, makefileMacros, firstTargetName, false);

   typeless el;
   for (el._makeempty();;) {
       makefileTargets._nextel(el);
       if (el._isempty()) break;
       targetList[targetList._length()] = el;
       descriptionList[descriptionList._length()] = "";
   }

   return 0;
}

/**
 * 
 * Parses a makefile for the files that it references and returns them
 * in <code>filesList</code>
 * 
 * @param makefileName Name of makefile to parse
 * @param makefileDir
 * @param filesList This array is filled with the names of the files
 *                  referenced by <code>makefilename</code>
 * @param targetList
 * @param runTargetName
 * @param recursiveMakefilesList
 * @param filterList
 * @param checkIfMakefile
 * @param wildcards
 * @param file_exclude
 * @param checkRecursiveFiles
 * @param isQTMakefile
 * @author David A. O'Brien (12/13/2008)
 * @return 
 * 
 */
int MI_getFilesInMakefile(_str makefileName, _str makefileDir, 
                          _str (&filesList)[], MI_projectTargets& targetList,
                           _str& runTargetName, _str (&recursiveMakefilesList)[],
                          boolean filterList = false, boolean checkIfMakefile = true,
                          _str wildcards = '*', _str file_exclude = '',
                          boolean checkRecursiveFiles = false,
                          boolean isQTMakefile = false) {

   makefileName = absolute(makefileName);
   if (!file_exists(makefileName)) return 1;
   if (makefileDir :== '') {
      makefileDir = _strip_filename(makefileName, 'NE');
   }
   
   int status;
   _str makefileFiles:[];
   MI_makefileTarget_t makefileTargets:[];
   MI_makefileMacro_t makefileMacros:[];
   MI_initHashTables(filesList, makefileFiles, makefileTargets, makefileMacros);

   status = readMakefileMacros(makefileName, makefileDir, makefileFiles, makefileMacros, checkIfMakefile);
   if (status) {
      return status;
   }

   _str firstTargetName = '';
   makefileFiles._makeempty();
   status = readMakefileTargets(makefileName, makefileDir, makefileFiles, makefileTargets, makefileMacros, firstTargetName, checkRecursiveFiles);
   if (status) {
      return status;
   }
   //Copy the target names to return to calling function
   targetList.build = firstTargetName;
   targetList.clean = targetList.exe = targetList.rebuild = '';
   foreach (auto key => auto value in makefileTargets) {
      if (key :== 'clean') targetList.clean = key;
      if (key :== 'rebuild') targetList.rebuild = key;
      if (key :== 'execute') targetList.exe = key;
      if (key :== 'run') targetList.exe = key;
      if (key :== 'compile') targetList.build = key;
      if (key :== 'build') targetList.build = key;
      if (key :== 'all') targetList.build = key;
   }

   _str preReqFiles:[];
   preReqFiles._makeempty();
   typeless el;
   for (el._makeempty();;) {
       makefileTargets._nextel(el);
       if (el._isempty()) break;
       _str targetPrereqs = makefileTargets:[el].prereqs;
       _str basePath = makefileTargets:[el].basePath;
       _str prereq; 
       while (true) {
          parse targetPrereqs with prereq targetPrereqs;
          if (prereq == '') {
             break;
          }
          prereq = absolute(strip(prereq), makefileDir);
          if (file_exists(prereq) && !preReqFiles._indexin(prereq)) {
             preReqFiles:[prereq] = 'X';
             filesList[filesList._length()] = prereq;
          } else if (isQTMakefile && !preReqFiles._indexin(prereq)) {//OR case of QT moc_ file not built yet
             _str prereqFilename = _strip_filename(prereq, 'P');
             _str prereqDirname = _strip_filename(prereq, 'N');
             if ((prereqFilename._length() > 4) && (substr(prereqFilename, 1, 4) :== 'moc_')  && file_exists(prereqDirname :+ FILESEP :+ substr(prereqFilename, 5))) {
                preReqFiles:[prereq] = 'X';
                filesList[filesList._length()] = prereq;
             }
          }
       }
   }

   if (filterList) {
      //Search for *.pro files if QT makefile
      if (isQTMakefile) strappend(wildcards, ';*.pro');
      MI_filter_files(filesList, wildcards, file_exclude);
   }

   if (makefileMacros._indexin('TARGET')) {
      runTargetName = makefileMacros:['TARGET'].expansion;
   } else runTargetName = '';

   if (checkRecursiveFiles) {
      recursiveMakefilesList._makeempty();
      //Look for the SUBTARGETS macro to find recursive makefiles
      if (isQTMakefile && makefileMacros._indexin('SUBTARGETS')) {
          if (makefileMacros:['SUBTARGETS'].expansion != null && makefileMacros:['SUBTARGETS'].expansion != '') {
             _str subtarget = '', subtargets = makefileMacros:['SUBTARGETS'].expansion;
             _str makefiledir = makefileDir;
             _maybe_append_filesep(makefiledir);
             while (subtargets != '') {
                parse subtargets with subtarget subtargets;
                if (makefileTargets._indexin(subtarget) && 
                    makefileTargets:[subtarget] != null && 
                    makefileTargets:[subtarget].commands != null) {
                   _str command = '', submakefile = '';
                   int cindex  = 0;
                   int clength = makefileTargets:[subtarget].commands._length();
                   while (cindex < clength) {
                      command = makefileTargets:[subtarget].commands[cindex++];
                      if (substr(command, 1, 3) == 'cd ') {
                         parse command with 'cd ' auto subdir command;
                         _maybe_append_filesep(subdir);
                         int posResult = pos(' -f ', command, 4);
                         if (posResult > 0 && command._length() >= posResult + 4) {
                            parse substr(command, posResult + 4) with submakefile .;
                            if (submakefile != '') {
                               submakefile = makefiledir :+ subdir :+ submakefile;
                               if (file_exists(submakefile)) {
                                  recursiveMakefilesList[recursiveMakefilesList._length()] = submakefile;
                                  break;
                               }
                            }
                         }
                      }
                   }
                }
             }
          }
      } else {
      }
   }

   return 0;
}

//based on bgm_filter_project_files()
void MI_filter_files(_str (&filesList)[], _str wildcards, _str file_exclude = '')
{
   _str pos_options = 'R':+_fpos_case;
   _str wildcard_re = bgm_make_re(wildcards);
   _str path_re = '';
   _str exclude_re = bgm_make_exclude_re(file_exclude, path_re);
   _str fname, pname;

   _str returnFilesList[];
   returnFilesList._makeempty();

   int i;
   for (i = 0; i < filesList._length(); i++) {
      fname = filesList[i];
      pname = _strip_filename(fname, 'N');
      if (!pos(wildcard_re, fname, 1, pos_options)) {
         continue;
      } else if ((exclude_re != '') && pos(exclude_re, fname, 1, pos_options)) {
         continue;
      } 
      returnFilesList[returnFilesList._length()] = fname;
   }
   filesList = returnFilesList;
}

//int MI_temp_printCommands(_str makefilename, _str (&filesList)[], boolean promptForFilters = false) {
//
//   if (!file_exists(makefilename)) return 1;
//   int status;
//   _str makefileFiles:[];
//   MI_makefileTarget_t makefileTargets:[];
//   MI_makefileMacro_t makefileMacros:[];
//   MI_initHashTables(filesList, makefileFiles, makefileTargets, makefileMacros);
//
//   status = readMakefileMacros(makefilename, makefileFiles, makefileMacros);
//
//   makefileFiles._makeempty();
//   status = readMakefileTargets(makefilename, makefileFiles, makefileTargets, makefileMacros);
//
//   _str preReqFiles:[];
//   preReqFiles._makeempty();
//   typeless el;
//   for (el._makeempty();;) {
//       makefileTargets._nextel(el);
//       if (el._isempty()) break;
//       _str targetPrereqs = makefileTargets:[el].prereqs;
//       _str basePath = makefileTargets:[el].basePath;
//       _str prereq;
//       while (true) {
//
//       }
//   }
//   return 0;
//}

int MI_showNewMakefileProjectOptions() {
   return 0; 
}

/**
 * 
 * Utility function for initializing the hash tables used in 
 * makefile import. 
 * 
 * @param filesList 
 * @param makefileFiles 
 * @param makefileTargets 
 * @param makefileMacros 
 * @return 
 * 
 * @author David A. O'Brien (1/8/2008)
 */
static void MI_initHashTables(_str (&filesList)[], _str (&makefileFiles):[], MI_makefileTarget_t (&makefileTargets):[], MI_makefileMacro_t (&makefileMacros):[]) {
   
   filesList._makeempty();
   makefileFiles._makeempty();
   makefileMacros._makeempty();
   makefileTargets._makeempty();

   makefileMacros:['MAKE'].expansion = 'make';
   makefileMacros:['MAKE_COMMAND'].expansion = 'make';
   makefileMacros:['CC'].expansion = 'gcc';
}

_command int checkQTMakefileDate() name_info(',')
{
   return 0;
}
_command int checkedQTMakefileDate() name_info(',')
{
   return 0;
}

defeventtab _import_makefile_form;
void ctl_MI_scanRecursiveMakefiles_check.lbutton_up()
{
   ctl_MI_makeSeparateProjects_check.p_enabled = (ctl_MI_scanRecursiveMakefiles_check.p_value == 1);
}
void ctlok.lbutton_up()
{
   _save_form_response();
   _param1 = absolute(strip(ctlListFile.p_text));
   //_param2 = false;//(ctl_MI_scanRecursiveMakefiles_check.p_value == 1);
   //_param3 = false;//(ctl_MI_makeSeparateProjects_check.p_value == 1);
   _param2 = (ctl_MI_scanRecursiveMakefiles_check.p_value == 1);
   _param3 = (ctl_MI_makeSeparateProjects_check.p_value == 1);
   _param4 = strip(ctl_MI_includeFileTypes_combo.p_text);
   _param5 = strip(ctl_MI_excludeFileTypes_combo.p_text);
   p_active_form._delete_window(IDOK);
   return;
}
#define MAKEFILECAPTION "Open Makefile as Workspace"
#define QTMAKEFILECAPTION "Open QT Makefile as Workspace"
void ctlok.on_create(int isQT)
{
   _import_makefile_form_initial_alignment();

   _retrieve_prev_form();
   if (isQT) {
      p_active_form.p_caption = QTMAKEFILECAPTION;
   } else {
      p_active_form.p_caption = MAKEFILECAPTION;
   }
   ctl_MI_makeSeparateProjects_check.p_enabled = (ctl_MI_scanRecursiveMakefiles_check.p_value == 1);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _import_makefile_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctlListFile, ctlListFileBrowse.p_window_id);
}

void ctlListFileBrowse.lbutton_up()
{
   _str makefile = ctlListFile.p_text;
   _str makefileDirectory = get_env("HOME");
   if (!file_exists(makefile)) {
      makefile = '';
   }
   else {
      makefileDirectory = substr(makefile, 1, pathlen(makefile));
   }
   makefile = _OpenDialog('-new -mdi -modal',
                              "Open Makefile",
                              ALLFILES_RE,     // Initial wildcards
                              "Make Files("ALLFILES_RE"),All Files("ALLFILES_RE")",  // file types
                              OFN_FILEMUSTEXIST,
                              '',      // Default extensions
                              makefile,      // Initial filename
                              makefileDirectory,//,      // Initial directory
                              '',      // Reserved
                              "Standard Open dialog box"
                             );
   if (makefile == "") {
      return;
   }
   ctlListFile.p_text = makefile;
}

#define objectfileexcludes "Object Files (*.o;*.so;*.a)"
static void _init_includeFileTypes(boolean forceRefresh = false)
{
   if (forceRefresh) ctl_MI_includeFileTypes_combo.p_user = '';
   if (ctl_MI_includeFileTypes_combo.p_user == '') {
      _init_filters();
      ctl_MI_includeFileTypes_combo.p_user = 1; // Indicate that retrieve list has been done
   }
}

static void _init_excludeFileTypes(boolean forceRefresh = false)
{
   if (forceRefresh) ctl_MI_excludeFileTypes_combo.p_user = '';
   if (ctl_MI_excludeFileTypes_combo.p_user == '') {
      _str wildcards = def_file_types;
      def_file_types = objectfileexcludes;
      _init_filters();
      def_file_types = wildcards;
      ctl_MI_excludeFileTypes_combo.p_user = 1; // Indicate that retrieve list has been done
   }
}

ctl_MI_includeFileTypes_combo.on_create() {
   _init_includeFileTypes();
}

ctl_MI_excludeFileTypes_combo.on_create() {
   _init_excludeFileTypes();
}

