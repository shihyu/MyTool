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
#import "se/lang/api/LanguageSettings.e"
#import "applet.e"
#import "diff.e"
#import "fileman.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "treeview.e"
#import "wizard.e"
#endregion

using se.lang.api.LanguageSettings;

struct EJB_FINDER {
   bool ReturnsCollection;
   _str Name;
   _str Args;
};

struct EJB_PROP {
   _str Type;
   _str Name;
};

struct EJB_STATE_FIELD {
   _str Type;
   _str Name;
   int AddSetGet;
};

struct EJB_BUSINESS_METHOD {
   _str Type;
   _str Name;
   _str Args;
};

struct EJB_FILENAMES {
   _str RemoteFilename;
   _str HomeFilename;
   _str BeanFilename;
   _str BeanPKFilename;
   _str ClientFilename;
};

struct EJB_INFO {
   _str Name;
   _str PackageName;
   int Type;
   _str CreateArguments[];
   _str PrimaryKeyClass;
   EJB_FINDER FinderMethods[];
   EJB_BUSINESS_METHOD BusinessMethods[];
   EJB_PROP EnvProperties[];
   EJB_STATE_FIELD ConvStateFields[];
   EJB_FILENAMES Filenames;
   bool GenerateClient;
   bool AddToProject;
}gEJBInfo;

static _str gJDKPrimaryKeyTypes[] = {
   'java.lang.Boolean',
   'java.lang.Double',
   'java.lang.Float',
   'java.lang.Integer',
   'java.lang.Long',
   'java.lang.Object',
   'java.lang.Short',
   'java.lang.String',
};

static _str gValidPropertyTypes[] = {
   'java.lang.String',
   'java.lang.Boolean',
   'java.lang.Integer',
   'java.lang.Short',
   'java.lang.Long',
   'java.lang.Float',
   'java.lang.Double',
   'java.lang.Byte',
   'String',
   'Boolean',
   'Integer',
   'Short',
   'Long',
   'Float',
   'Double',
   'Byte',
};

static const EJB_SESSION_STATEFUL=  0;
static const EJB_SESSION_STATELESS= 1;
static const EJB_ENTITY_BMP=        2;
static const EJB_ENTITY_CMP=        3;

static const DEPLOYMENT_DESCRIPTOR_FILENAME= 'ejb-jar.xml';

static int ejb_slide1add();
static int ejb_slide3add(_str CapData="\t\t",bool checked=false);

static int ejb_slide0create()
{
   ctlsession_stateful.p_value=1;
   ctls0_name._set_focus();

   ctls1_add.p_user=ejb_slide1add;
   ctls3_add.p_user=ejb_slide3add;
   ctls6_add.p_user=ejb_slide3add;

   ///////////////////////////////////////
   // Slide 2 code
   wid := p_window_id;
   p_window_id=ctls2_pkcombo.p_window_id;
   int i;
   for (i=0;i<gJDKPrimaryKeyTypes._length();++i) {
      _lbadd_item(gJDKPrimaryKeyTypes[i]);
   }
   _lbtop();
   p_text=_lbget_text();
   p_window_id=wid;
   ctls2_pkexisting.p_value=1;
   ctls0_pkg_name._retrieve_list();
   return(0);
}

static int ejb_slide0next()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   if (ctlsession_stateless.p_value) {
      pWizardInfo->callbackTable:['ctlslide1.skip']=1;
   }else{
      pWizardInfo->callbackTable:['ctlslide1.skip']=null;
   }
   if (ctlsession_stateless.p_value ||
       ctlsession_stateful.p_value) {
      pWizardInfo->callbackTable:['ctlslide2.skip']=1;
      pWizardInfo->callbackTable:['ctlslide3.skip']=1;
   }else{
      pWizardInfo->callbackTable:['ctlslide2.skip']=null;
      pWizardInfo->callbackTable:['ctlslide3.skip']=null;
   }
   if (!ctlsession_stateful.p_value) {
      pWizardInfo->callbackTable:['ctlslide6.skip']=1;
   }else{
      pWizardInfo->callbackTable:['ctlslide6.skip']=null;
   }
   if (!isid_valid(ctls0_name.p_text)) {
      ctls0_name._text_box_error("This field must be a valid identifier");
      return(1);
   }
   if (!ispkg_valid(ctls0_pkg_name.p_text) && ctls0_pkg_name.p_text!='') {
      ctls0_pkg_name._text_box_error("This field must be a valid identifier");
      return(1);
   }
   if (ctls0_pkg_name.p_text!='') {
      ctls2_pktext.p_text=ctls0_pkg_name.p_text'.'ctls0_name.p_text'PK';
   }else{
      ctls2_pktext.p_text=ctls0_name.p_text'PK';
   }
   SetFilenames(ctls0_name.p_text);
   return(0);
}

static bool ispkg_valid(_str name)
{
   /* name must not be null */
   if (name=='') {
      return(false);
   }
   /*  name must consist of valid identifier characters. */
   if ( pos('[~A-Za-z0-9_.$]',name,1,'r') ) {
      return(false);
   }
   /*  First character must not be number or period*/
   ch := substr(name,1,1);
   if (isinteger(ch) || ch=='.' || _last_char(name)=='.') {
      return(false);
   }
   return(true);
}

static void SetFilenames(_str BeanName)
{
   ctls7_home.p_text=BeanName'Home.java';
   ctls7_remote.p_text=BeanName'.java';
   ctls7_bean.p_text=BeanName'Bean.java';
   ctls7_client.p_text=BeanName'Client.java';
}

static int ejb_slide1create()
{
   wid := p_window_id;
   _nocheck _control ctls1_tree;
   p_window_id=ctls1_tree;
   _TreeSetColButtonInfo(0,p_width intdiv 2,0,0,"Name");
   _TreeSetColButtonInfo(1,p_width intdiv 2,0,0,"Arguments");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);

   _TreeAddItem(TREE_ROOT_INDEX,"ejbCreate\t",TREE_ADD_AS_CHILD,0,0,-1);
   p_window_id=wid;

   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   return(0);
}

static int ejb_slide1add()
{
   int status=ejb_slide3add("ejbCreate\t",false);
   return(status);
}

static int ejb_slide3add(_str CapData="\t\t",bool checked=false)
{
   index := _TreeCurIndex();
   newindex := -1;
   if (index<=0) {
      // Really mean >0 , can't delete root node anyway.
      newindex=_TreeAddItem(TREE_ROOT_INDEX,CapData,TREE_ADD_AS_CHILD,-1,-1,-1);
   }else{
      _str cap=CapData;
      //int BlankIndex=BlankIndexExists(cap);
      //if (BlankIndex>-1) {
         //newindex=BlankIndex;
      //}else{
         newindex=_TreeAddItem(index,cap,0,-1,-1,-1);
      //}
   }
   if (newindex>-1) {
      _TreeSetCheckState(newindex, (checked? TCB_CHECKED : TCB_UNCHECKED));
      int status=_TreeEditNode(newindex,1);
   }
   return(0);
}

// This is the index of the tree item for the ejbFindByPrimaryKey item
static int EJB_FBPK_INDEX(...) {
   if (arg()) ctls3_tree.p_user=arg(1);
   return ctls3_tree.p_user;
}

static int ejb_slide3create()
{
   wid := p_window_id;
   _nocheck _control ctls3_tree;
   p_window_id=ctls3_tree;
   _TreeSetColButtonInfo(0,p_width intdiv 3,0,0,"Returns Collection");
   _TreeSetColButtonInfo(1,p_width intdiv 3,0,0,"Name");
   _TreeSetColEditStyle(0,0);
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColButtonInfo(2,p_width intdiv 3,0,0,"Arguments");
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   pk := "";
   if (ctls2_pkcustom.p_value) {
      //pk=ctls2_pktext.p_text;
      parse ctls2_pktext.p_text with 'pkg.' pk ;
   }else{
      //pk=ctls2_pkcombo.p_text;
      parse ctls2_pkcombo.p_text with 'java.lang.' pk ;
   }
   EJB_FBPK_INDEX(_TreeAddItem(TREE_ROOT_INDEX,"\tejbFindByPrimaryKey\t"pk" key",TREE_ADD_AS_CHILD,-1,-1,-1));
   _TreeSetCheckable(EJB_FBPK_INDEX(),0,0);
   _TreeSetCheckState(EJB_FBPK_INDEX(),TCB_UNCHECKED);
   p_window_id=wid;
   return(0);
}

static int ejb_slide3shown()
{
   if (EJB_FBPK_INDEX()!='') {
      // Check to see if the primary key type in ejbFindByPrimaryKey matches
      // what is currently in the primary key slide
      int fbpk_index=EJB_FBPK_INDEX();
      wid := p_window_id;
      p_window_id=ctls3_tree;
      cap := _TreeGetCaption(fbpk_index);
      keyinfo := "";
      parse cap with . "\t" . "\t"  keyinfo;

      pk := "";
      if (ctls2_pkcustom.p_value) {
         parse ctls2_pktext.p_text with 'pkg.' pk ;
      }else{
         parse ctls2_pkcombo.p_text with 'java.lang.' pk ;
      }
      if (keyinfo!=pk' key') {
         // If not, change the caption to match
         _TreeSetCaption(fbpk_index,"\tejbFindByPrimaryKey\t"pk" key");
      }
      p_window_id=wid;
   }
   return(0);
}

static int ejb_slide4create()
{
   wid := p_window_id;
   _nocheck _control ctls4_tree;
   p_window_id=ctls4_tree;
   _TreeSetColButtonInfo(0,p_width intdiv 3,0,0,"Type");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColButtonInfo(1,p_width intdiv 3,0,0,"Name");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColButtonInfo(2,p_width intdiv 3,0,0,"Arguments");
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   p_window_id=wid;
   return(0);
}

static int ejb_slide5create()
{
   wid := p_window_id;
   _nocheck _control ctls5_tree;
   p_window_id=ctls5_tree;
   _TreeSetColButtonInfo(0,p_width intdiv 2,0,0,"Type");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColButtonInfo(1,p_width intdiv 2,0,0,"Name");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   p_window_id=wid;
   return(0);
}

static int ejb_slide6create()
{
   wid := p_window_id;
   _nocheck _control ctls6_tree;
   p_window_id=ctls6_tree;
   _TreeSetColButtonInfo(0,p_width intdiv 3,0,0,"Add Set/Get");
   _TreeSetColButtonInfo(1,p_width intdiv 3,0,0,"Type");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColButtonInfo(2,p_width intdiv 3,0,0,"Name");
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   p_window_id=wid;
   return(0);
}

static int ejb_slide4next()
{
   wid := p_window_id;
   _nocheck _control ctls4_tree;
   p_window_id=ctls4_tree;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   int DelList[]=null;
   for (;;) {
      if (index<0) break;
      cap := _TreeGetCaption(index);
      if (cap=='') {
         DelList[DelList._length()]=index;
      }else{
         type := "";
         name := "";
         args := "";
         parse cap with type "\t" name "\t" args;
         if (type=='' || name=='') {
            fieldname := "Type";
            if (type!='') {
               fieldname='Name';
            }
            _message_box(nls("%s cannot be blank",fieldname));
            _TreeSetCurIndex(index);
            p_window_id=wid;
            return(-1);
         }
      }
      index=_TreeGetNextIndex(index);
   }
   int i;
   for (i=0;i<DelList._length();++i) {
      _TreeDelete(DelList[i]);
   }
   p_window_id=wid;
   return(0);
}

static int ejb_slide7next()
{
   int status=ctls7_home.CheckJavaFilenameInTB();
   if (status) {
      return(status);
   }
   if (pos(' ',ctls7_remote.p_text)) {
      ctls7_remote._text_box_error("This field must be a valid java source filename");
      return(1);
   }
   if (pos(' ',ctls7_bean.p_text)) {
      ctls7_bean._text_box_error("This field must be a valid java source filename");
      return(1);
   }
   return(0);
}

static int CheckJavaFilenameInTB()
{
   if (pos(' ',p_text)) {
      _text_box_error("This field must be a valid java source filename");
      return(1);
   }
   if (!SuffixFileMatches(p_text,'.java')) {
      p_text=_strip_filename(p_text,'E')'.java';
   }
   return(0);
}

static void GetSlide0Info()
{
   gEJBInfo.Name=ctls0_name.p_text;
   gEJBInfo.PackageName=ctls0_pkg_name.p_text;

   if (ctlsession_stateful.p_value) {
      gEJBInfo.Type=EJB_SESSION_STATEFUL;
   }else if (ctlsession_stateless.p_value) {
      gEJBInfo.Type=EJB_SESSION_STATELESS;
   }else if (ctlentity_bmp.p_value) {
      gEJBInfo.Type=EJB_ENTITY_BMP;
   }else if (ctlentity_cmp.p_value) {
      gEJBInfo.Type=EJB_ENTITY_CMP;
   }
   ctls0_pkg_name._save_form_response();
}

static void GetSlide1Info()
{
   wid := p_window_id;
   _nocheck _control ctls1_tree;
   p_window_id=ctls1_tree;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      cur := _TreeGetCaption(index);
      if (cur!='') {
         args := "";
         parse cur with . "\t" args;
         args=strip(args,'B','(');
         args=strip(args,'B',')');

         _str cleanlist=GetCleanArgs(args);
         gEJBInfo.CreateArguments[gEJBInfo.CreateArguments._length()]=cleanlist;
      }
      index=_TreeGetNextIndex(index);
   }
   RemoveDups(gEJBInfo.CreateArguments);
   p_window_id=wid;
}

static _str GetCleanArgs(_str args)
{
   cleanlist := "";
   for (;;) {
      curarg := "";
      parse args with curarg','args;
      if (curarg=='') break;
      type := "";
      name := "";
      parse curarg with type name;
      type=strip(type);
      name=strip(name);
      cleanlist :+= ','type' 'name;
   }
   cleanlist=substr(cleanlist,2);
   return(cleanlist);
}

static void RemoveDups(_str (&List)[])
{
   _str table:[];
   typeless i;
   for (i=0;i<List._length();++i) {
      table:[List[i]]=List[i];
   }
   List=null;
   for (i._makeempty();;) {
      table._nextel(i);
      if (i._isempty()) break;
      List[List._length()]=i;
   }
}

static void GetSlide2Info()
{
   if (ctls2_pkexisting.p_value) {
      gEJBInfo.PrimaryKeyClass=ctls2_pkcombo.p_text;
   }else{
      gEJBInfo.PrimaryKeyClass=ctls2_pktext.p_text;
   }
}

static void GetSlide3Info()
{
   wid := p_window_id;
   p_window_id=ctls3_tree;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   gEJBInfo.FinderMethods=null;
   _str TempMethods:[]=null;
   name := "";
   args := "";
   for (;;) {
      if (index<0) break;
      cur := _TreeGetCaption(index);
      checked := _TreeGetCheckState(index);
      if (cur!='') {
         parse cur with . "\t" name "\t" args;
         args=GetCleanArgs(args);
         _str returnCollection=checked!=false;
         line := returnCollection"\t"name"\t"args;
         // Eliminate Duplicates
         TempMethods:[line]=line;
      }
      index=_TreeGetNextIndex(index);
   }
   typeless i;
   for (i._makeempty();;) {
      TempMethods._nextel(i);
      if (i._isempty()) break;
      len := gEJBInfo.FinderMethods._length();
      typeless returnCollection='';
      parse TempMethods:[i] with returnCollection "\t" name "\t" args;
      gEJBInfo.FinderMethods[len].Name=name;
      gEJBInfo.FinderMethods[len].Args=args;
      gEJBInfo.FinderMethods[len].ReturnsCollection=returnCollection;
   }
   p_window_id=wid;
}

static void GetSlide4Info()
{
   wid := p_window_id;
   _nocheck _control ctls4_tree;
   gEJBInfo.BusinessMethods=null;
   p_window_id=ctls4_tree;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _str Temp:[]=null;
   type := "";
   name := "";
   args := "";
   for (;;) {
      if (index<0) break;
      cur := _TreeGetCaption(index);
      if (cur!='') {
         parse cur with type "\t" name "\t" args;
         args=GetCleanArgs(args);
         line := type"\t"name"\t"args;
         Temp:[line]=line;
      }
      index=_TreeGetNextIndex(index);
   }
   typeless i;
   for (i._makeempty();;) {
      Temp._nextel(i);
      if (i._isempty()) break;

      len := gEJBInfo.BusinessMethods._length();
      parse Temp:[i] with type "\t" name "\t" args;
      gEJBInfo.BusinessMethods[len].Type=type;
      gEJBInfo.BusinessMethods[len].Name=name;
      gEJBInfo.BusinessMethods[len].Args=args;
   }
   p_window_id=wid;
}

static void GetSlide5Info()
{
   wid := p_window_id;
   _nocheck _control ctls5_tree;
   p_window_id=ctls5_tree;
   gEJBInfo.EnvProperties=null;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      cur := _TreeGetCaption(index);
      if (cur!='') {
         type := "";
         name := "";
         parse cur with type "\t" name;
         if (type!='' && name!='') {
            if (substr(type,1,10)!='java.lang.') {
               type='java.lang.':+type;
            }
            len := gEJBInfo.EnvProperties._length();
            gEJBInfo.EnvProperties[len].Type=type;
            gEJBInfo.EnvProperties[len].Name=name;
         }
      }
      index=_TreeGetNextIndex(index);
   }
   p_window_id=wid;
}

static void GetSlide6Info()
{
   wid := p_window_id;
   _nocheck _control ctls6_tree;
   p_window_id=ctls6_tree;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   gEJBInfo.ConvStateFields=null;
   for (;;) {
      if (index<0) break;
      cur := _TreeGetCaption(index);
      checked := _TreeGetCheckState(index);
      if (cur!='') {
         type := "";
         name := "";
         parse cur with "\t" type "\t" name;
         len := gEJBInfo.ConvStateFields._length();
         gEJBInfo.ConvStateFields[len].Type=type;
         gEJBInfo.ConvStateFields[len].Name=name;
         gEJBInfo.ConvStateFields[len].AddSetGet=(int)(checked!=false);
      }
      index=_TreeGetNextIndex(index);
   }
   p_window_id=wid;
}

static void GetSlide7Info()
{
   gEJBInfo.Filenames.HomeFilename=ctls7_home.p_text;
   gEJBInfo.Filenames.RemoteFilename=ctls7_remote.p_text;
   gEJBInfo.Filenames.BeanFilename=ctls7_bean.p_text;
   gEJBInfo.GenerateClient=ctls7_genclient.p_value!=0;
   gEJBInfo.Filenames.ClientFilename='';
   if (gEJBInfo.GenerateClient) {
      gEJBInfo.Filenames.ClientFilename=ctls7_client.p_text;
   }
   if (!_inarray(gEJBInfo.PrimaryKeyClass,gJDKPrimaryKeyTypes)) {
      _str pkClassName=gEJBInfo.PrimaryKeyClass;
      /*if (substr(pkClassName,1,length(gEJBInfo.PackageName)+1) == gEJBInfo.PackageName'.') {
         pkClassName=substr(pkClassName,length(gEJBInfo.PackageName'.')+1);
      }*/
      pkClassName=_strip_filename(_project_name,'n'):+stranslate(pkClassName,FILESEP,'.');
      _str filename=pkClassName;
      if (!SuffixFileMatches(filename,'.java')) {
         filename :+= '.java';
      }
      gEJBInfo.Filenames.BeanPKFilename=filename;
   }
}

static int _ejb_wizard_finish()
{
   GetSlide0Info();
   GetSlide1Info();
   GetSlide2Info();
   GetSlide3Info();
   GetSlide4Info();
   GetSlide5Info();
   GetSlide6Info();
   GetSlide7Info();
   int status=ejb_show_new_project_info();
   if (status) {
      return(status);
   }
   status=GenerateEJB(&gEJBInfo);
   return(status);
}

static int GenerateEJB(EJB_INFO *pinfo)
{
   _str PackagePath=_file_path(_project_name):+stranslate(pinfo->PackageName,FILESEP,'.');
   _maybe_append_filesep(PackagePath);
   int status=make_path(PackagePath);
   if (status && !file_exists(PackagePath'.')) {
      return(status);
   }

   _str MetaInfPath=_file_path(_project_name):+'classes':+FILESEP:+'META-INF':+FILESEP;
   status=make_path(MetaInfPath);
   if (status && !file_exists(MetaInfPath'.')) {
      return(status);
   }

   filelist := "";

   status=CopyDescriptorFiles(pinfo,MetaInfPath,filelist);
   if (status) {
      return(status);
   }

   if (!_inarray(pinfo->PrimaryKeyClass,gJDKPrimaryKeyTypes)) {
      status=GeneratePKClassFile(pinfo,PackagePath,filelist);
      if (status) {
         return(status);
      }
   }
   status=GenerateHomeInterface(pinfo,PackagePath,filelist);
   if (status) {
      return(status);
   }

   status=GenerateRemoteInterface(pinfo,PackagePath,filelist);
   if (status) {
      return(status);
   }

   status=GenerateBeanImplementation(pinfo,PackagePath,filelist);
   if (status) {
      return(status);
   }

   if (pinfo->GenerateClient) {
      status=GenerateClient(pinfo,PackagePath,filelist);
      if (status) {
         return(status);
      }
   }

   if (pinfo->AddToProject) {
      _str tag_filename=_GetWorkspaceTagsFilename();
      tag_add_filelist(tag_filename,filelist);
   }
   return(0);
}

static bool NeedToImportCollection(EJB_INFO *pinfo)
{
   int i;
   for (i=0;i<pinfo->FinderMethods._length();++i) {
      if (pinfo->FinderMethods[i].ReturnsCollection) {
         return(true);
      }
   }
   return(false);
}

static int GenerateHomeInterface(EJB_INFO *pinfo,_str Path,_str &FileList)
{
   filename := Path:+pinfo->Filenames.HomeFilename;
   int status=WarnIfFileExists(filename);
   if (status) {
      return(status);
   }
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);


   _SetEditorLanguage('java');
   indentAmount := LanguageSettings.getSyntaxIndent(p_LangId);
   _str indentstr=indent_string(indentAmount);

   if (pinfo->PackageName!='') {
      insert_line('package 'pinfo->PackageName';');
      insert_line('');
   }
   insert_line('import javax.ejb.*;');
   if (NeedToImportCollection(pinfo)) {
      insert_line('import java.util.Collection;');
   }
   insert_line('import java.rmi.RemoteException;');
   insert_line('');
   insert_line('');
   _str HomeName=GetNameFromFilename(pinfo->Filenames.HomeFilename,'');
   _str BeanName=GetNameFromFilename(pinfo->Filenames.BeanFilename,'');

   i := 0;
   insert_line('public interface 'HomeName' extends EJBHome {');
   if (!pinfo->CreateArguments._length()) {
      insert_line(indentstr:+pinfo->Name' create() throws CreateException,RemoteException;');
   }else{
      for (i=0;i<pinfo->CreateArguments._length();++i) {
         insert_line(indentstr:+pinfo->Name' create('pinfo->CreateArguments[i]') throws CreateException,RemoteException;');
      }
   }
   if (pinfo->Type==EJB_ENTITY_BMP ||
       pinfo->Type==EJB_ENTITY_CMP) {
      for (i=0;i<pinfo->FinderMethods._length();++i) {
         returnType := "";
         if (pinfo->FinderMethods[i].ReturnsCollection) {
            returnType='Collection';
         }else{
            returnType=pinfo->Name;
         }
         args := strip(pinfo->FinderMethods[i].Args,'B','(');
         args=strip(args,'B',')');
         insert_line(indentstr:+'public 'returnType' f'substr(pinfo->FinderMethods[i].Name,5)'('args') throws FinderException,RemoteException;');
      }
   }
   insert_line('}');

   filename=_maybe_quote_filename(filename);
   _save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' 'filename;
   return(0);
}

static int GenerateRemoteInterface(EJB_INFO *pinfo,_str Path,_str &FileList)
{
   filename := Path:+pinfo->Filenames.RemoteFilename;
   int status=WarnIfFileExists(filename);
   if (status) {
      return(status);
   }
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);

   needToImportCollection := false;
   int i;
   for (i=0;i<pinfo->FinderMethods._length();++i) {
      if (pinfo->FinderMethods[i].ReturnsCollection) {
         needToImportCollection==true;break;
      }
   }

   _SetEditorLanguage('java');
   indentAmount := LanguageSettings.getSyntaxIndent(p_LangId);
   _str indentstr=indent_string(indentAmount);

   if (pinfo->PackageName!='') {
      insert_line('package 'pinfo->PackageName';');
      insert_line('');
   }
   insert_line('import javax.ejb.*;');
   insert_line('import java.rmi.RemoteException;');
   insert_line('');
   insert_line('');
   _str HomeName=GetNameFromFilename(pinfo->Filenames.HomeFilename,'');
   _str BeanName=GetNameFromFilename(pinfo->Filenames.BeanFilename,'');

   insert_line('public interface 'pinfo->Name' extends EJBObject {');
   for (i=0;i<pinfo->BusinessMethods._length();++i) {
      args := strip(pinfo->BusinessMethods[i].Args,'B','(');
      args=strip(args,'B',')');
      insert_line(indentstr:+'public 'pinfo->BusinessMethods[i].Type' 'pinfo->BusinessMethods[i].Name'('args') throws RemoteException;');
   }
   insert_line('}');

   filename=_maybe_quote_filename(filename);
   _save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' 'filename;
   return(0);
}

static int GenerateBeanImplementation(EJB_INFO *pinfo,_str Path,_str &FileList)
{
   filename := Path:+pinfo->Filenames.BeanFilename;
   int status=WarnIfFileExists(filename);
   if (status) {
      return(status);
   }
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);

   int i;
   needToImportCollection := false;
   for (i=0;i<pinfo->FinderMethods._length();++i) {
      if (pinfo->FinderMethods[i].ReturnsCollection) {
         needToImportCollection==true;break;
      }
   }

   _SetEditorLanguage('java');
   indentAmount := LanguageSettings.getSyntaxIndent(p_LangId);
   _str indentstr=indent_string(indentAmount);

   if (pinfo->PackageName!='') {
      insert_line('package 'pinfo->PackageName';');
      insert_line('');
   }
   insert_line('import javax.ejb.*;');
   if (NeedToImportCollection(pinfo)) {
      insert_line('import java.util.Collection;');
   }
   insert_line('');
   insert_line('');
   _str HomeName=GetNameFromFilename(pinfo->Filenames.HomeFilename,'');
   _str BeanName=GetNameFromFilename(pinfo->Filenames.BeanFilename,'');

   beanType := "";

   switch (pinfo->Type) {
   case EJB_ENTITY_BMP:
      beanType='EntityBean';
      break;
   case EJB_ENTITY_CMP:
      beanType='EntityBean';
      break;
   case EJB_SESSION_STATEFUL:
      beanType='SessionBean';
      break;
   case EJB_SESSION_STATELESS:
      beanType='SessionBean';
      break;
   }

   insert_line('public class 'BeanName' implements 'beanType' {');

   insert_line('');
   if (pinfo->Type==EJB_SESSION_STATEFUL) {
      insert_line(indentstr:+'public SessionContext sessionContext;');
      insert_line('');
   }
   insert_line(indentstr'public 'BeanName'() {');
   insert_line(indentstr'}');

   addSetGet := false;
   if (pinfo->Type==EJB_SESSION_STATEFUL) {
      insert_line(indentstr'// Variables for conversational state');
      for (i=0;i<pinfo->ConvStateFields._length();++i) {
         insert_line(indentstr'public 'pinfo->ConvStateFields[i].Type' 'pinfo->ConvStateFields[i].Name';');
         if (pinfo->ConvStateFields[i].AddSetGet) {
            addSetGet=true;
         }
      }
   }
   insert_line('');
   if (addSetGet) {
      insert_line(indentstr'// Set/Get methods for conversational state variables ');
      for (i=0;i<pinfo->ConvStateFields._length();++i) {
         insert_line(indentstr'public 'pinfo->ConvStateFields[i].Type' set'pinfo->ConvStateFields[i].Name'('pinfo->ConvStateFields[i].Type' 'pinfo->ConvStateFields[i].Name') {');
         insert_line(indentstr:+indentstr'this.'pinfo->ConvStateFields[i].Name'='pinfo->ConvStateFields[i].Name';');
         insert_line(indentstr:+'}');
         insert_line('');
         insert_line(indentstr'public 'pinfo->ConvStateFields[i].Type' get'pinfo->ConvStateFields[i].Name'() {');
         insert_line(indentstr:+indentstr'return 'pinfo->ConvStateFields[i].Name';');
         insert_line(indentstr:+'}');
      }
   }
   if (pinfo->BusinessMethods._length()) {
      insert_line('');
      insert_line(indentstr'// Business methods');
      for (i=0;i<pinfo->BusinessMethods._length();++i) {
         args := strip(pinfo->BusinessMethods[i].Args,'B','(');
         args=strip(args,'B',')');
         insert_line(indentstr:+'public 'pinfo->BusinessMethods[i].Type' 'pinfo->BusinessMethods[i].Name'('args') {');
         if (pinfo->BusinessMethods[i].Type=='String') {
            insert_line(indentstr:+indentstr'return "'pinfo->BusinessMethods[i].Name'";');
         }else{
            insert_line(indentstr:+indentstr'return 0;');
         }
         insert_line(indentstr:+'}');
      }
   }
   insert_line('');
   insert_line(indentstr'// EJB required methods');

   if (pinfo->Type==EJB_SESSION_STATELESS) {
      insert_line(indentstr'public void ejbCreate() throws CreateException {');
      insert_line(indentstr'}');
   }else{
      type := "";
      if (pinfo->Type==EJB_SESSION_STATEFUL) {
         type='void';
      }else{
         type=pinfo->PrimaryKeyClass;
         while (pos('.',type)) {
            parse type with '.' type;
         }
      }
      if (!pinfo->CreateArguments._length()) {
         insert_line(indentstr'public 'type' ejbCreate() throws CreateException {');
         if (type!='void') {
            insert_line(indentstr:+indentstr'System.out.println("ejbCreate()");');
            if (!_inarray(pinfo->PrimaryKeyClass,gJDKPrimaryKeyTypes) ||
                type=='String') {
               insert_line(indentstr:+indentstr'return new 'type'("ejbCreate");');
            }else if (type=='Boolean') {
               insert_line(indentstr:+indentstr'return Boolean.FALSE;');
            }else if (type=='void') {
            }else{
               insert_line(indentstr:+indentstr'return 0;');
            }
         }
         insert_line(indentstr'}');
      }else{
         for (i=0;i<pinfo->CreateArguments._length();++i) {
            insert_line(indentstr'public 'type' ejbCreate('pinfo->CreateArguments[i]') throws CreateException {');
            insert_line(indentstr:+indentstr'System.out.println("ejbCreate('pinfo->CreateArguments[i]')");');
            if (!_inarray(pinfo->PrimaryKeyClass,gJDKPrimaryKeyTypes) ||
                type=='String') {
               insert_line(indentstr:+indentstr'return new 'type'("ejbCreate");');
            }else if (type=='Boolean') {
               insert_line(indentstr:+indentstr'return Boolean.FALSE;');
            }else if (type=='void') {
            }else{
               insert_line(indentstr:+indentstr'return 0;');
            }
            insert_line(indentstr'}');
         }
      }
   }
   insert_line('');
   if (pinfo->Type==EJB_SESSION_STATEFUL ||
       pinfo->Type==EJB_SESSION_STATELESS) {
      insert_line(indentstr'public void ejbActivate() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbPassivate() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbRemove() {');
      insert_line(indentstr:+indentstr'System.out.println("ejbRemove()");');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void setSessionContext(SessionContext ctx) {');
      if (pinfo->Type==EJB_SESSION_STATEFUL) {
         insert_line(indentstr:+indentstr'this.sessionContext=ctx;');
      }
      insert_line(indentstr'}');
      insert_line('');
   }else{
      insert_line(indentstr'public void ejbPostCreate() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbActivate() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbLoad() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbPassivate() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbRemove() {');
      insert_line(indentstr:+indentstr'System.out.println("ejbRemove()");');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void ejbStore() {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void setEntityContext(EntityContext ctx) {');
      insert_line(indentstr'}');
      insert_line('');
      insert_line(indentstr'public void unsetEntityContext() {');
      insert_line(indentstr'}');
      insert_line('');
      if (pinfo->Type==EJB_ENTITY_BMP) {
         _str pkClass=pinfo->PrimaryKeyClass;
         if (pos('.',pkClass)) {
            parse pinfo->PrimaryKeyClass with '.' pkClass;
         }
         //insert_line(indentstr'public 'pkClass' ejbFindByPrimaryKey('pkClass' pk) throws CreateException {');
         //insert_line(indentstr'}');
         type := "";
         name := "";
         for (i=0;i<pinfo->FinderMethods._length();++i) {
            type=pkClass;
            if (pinfo->FinderMethods[i].ReturnsCollection) {
               type='Collection';
            }
            args := strip(pinfo->FinderMethods[i].Args,'B','(');
            args=strip(args,'B',')');
            insert_line(indentstr'public 'type' 'pinfo->FinderMethods[i].Name'('args') throws FinderException {');
            if (pinfo->FinderMethods[i].Name=='ejbFindByPrimaryKey') {
               parse args with type name ',' .;
               insert_line(indentstr:+indentstr'return 'name';');
            }else{
               insert_line(indentstr:+indentstr'return null;');
            }
            insert_line(indentstr'}');
         }
      }
   }
   insert_line('}');
   /*
   ENTITY bmp methods
   public void ejbPostCreate()
   public package1.MyEntityEJBPK ejbFindByPrimaryKey(package1.MyEntityEJBPK primaryKey) throws FinderException
   public void ejbActivate()
   public void ejbLoad()
   public void ejbPassivate()
   public void ejbRemove()
   public void ejbStore()
   public void setEntityContext(EntityContext ctx)
   public void unsetEntityContext()
  */
   /*
   ENTITY cmp methods
   public MyEntityEJBBean()
   public void ejbPostCreate()
   public void ejbActivate()
   public void ejbLoad()
   public void ejbPassivate()
   public void ejbRemove()
   public void ejbStore()
   public void setEntityContext(EntityContext ctx)
   public void unsetEntityContext()
   */
   /*
   SESSION stateful methods
   public MySessionEJBBean()
   public void ejbCreate() throws CreateException
   public void ejbActivate()
   public void ejbPassivate()
   public void ejbRemove()
   public void setSessionContext(SessionContext ctx)
   */

   /*
   SESSION stateless methods
   public MySessionEJBBean()
   public void ejbCreate() throws CreateException
   public void ejbActivate()
   public void ejbPassivate()
   public void ejbRemove()
   public void setSessionContext(SessionContext ctx)
   */


   filename=_maybe_quote_filename(filename);
   _save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' 'filename;
   return(0);
}

static int GenerateClient(EJB_INFO *pinfo,_str Path,_str &FileList)
{
   filename := Path:+pinfo->Filenames.ClientFilename;
   int status=WarnIfFileExists(filename);
   if (status) {
      return(status);
   }
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);

   needToImportCollection := false;
   int i;
   for (i=0;i<pinfo->FinderMethods._length();++i) {
      if (pinfo->FinderMethods[i].ReturnsCollection) {
         needToImportCollection==true;break;
      }
   }

   _SetEditorLanguage('java');
   indentAmount := LanguageSettings.getSyntaxIndent(p_LangId);
   _str indentstr=indent_string(indentAmount);

   if (pinfo->PackageName!='') {
      insert_line('package 'pinfo->PackageName';');
      insert_line('');
   }
   insert_line('import javax.naming.Context;');
   insert_line('import javax.naming.InitialContext;');
   insert_line('import java.util.Properties;');
   insert_line('');

   _str HomeName=GetNameFromFilename(pinfo->Filenames.HomeFilename,'');
   _str ClientName=GetNameFromFilename(pinfo->Filenames.ClientFilename,'');
   //_str BeanName=GetNameFromFilename(pinfo->Filenames.BeanFilename,'');
   _str BeanName=pinfo->Name;


   insert_line('public class 'ClientName' {');
   insert_line(indentstr:+'public static void main(String[] args) throws Exception {');
   insert_line(indentstr:+indentstr'try {');
   insert_line(indentstr:+indentstr:+indentstr'Properties props = System.getProperties();');
   insert_line('');
   insert_line(indentstr:+indentstr:+indentstr'Context ctx = new InitialContext(props);');
   insert_line('');
   insert_line(indentstr:+indentstr:+indentstr'Object obj = ctx.lookup("'HomeName'");');
   insert_line('');
   insert_line(indentstr:+indentstr:+indentstr:+HomeName' home = ('HomeName')javax.rmi.PortableRemoteObject.narrow(obj,'HomeName'.class);');
   insert_line('');
   varname := lowcase(BeanName);
   if (varname==BeanName) {
      varname=lowcase(BeanName)'1';
   }
   insert_line(indentstr:+indentstr:+indentstr:+BeanName' 'varname' = home.create();');
   insert_line('');
   insert_line(indentstr:+indentstr:+indentstr:+varname'.remove();');
   insert_line(indentstr:+indentstr:+'} catch (Exception e) {');
   insert_line(indentstr:+indentstr:+indentstr'e.printStackTrace();');
   insert_line(indentstr:+indentstr:+'}');
   insert_line(indentstr:+'}');
   insert_line('}');

   filename=_maybe_quote_filename(filename);
   _save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' 'filename;
   return(0);
}

static bool SuffixFileMatches(_str String,_str Suffix)
{
   if ( _file_eq(Suffix,substr(String,length(String)-length(Suffix)) ) ) {
      return(true);
   }
   return(false);
}

static int GeneratePKClassFile(EJB_INFO *pinfo,_str Path,_str &FileList)
{
   _str pkClassName=pinfo->PrimaryKeyClass;
   if (substr(pkClassName,1,length(pinfo->PackageName)+1) == pinfo->PackageName'.') {
      pkClassName=substr(pkClassName,length(pinfo->PackageName'.')+1);
   }
   _str filename=pinfo->Filenames.BeanPKFilename;
   /*if ( !file_eq('.java',substr(filename,length(filename)-5) ) ) {
      filename :+= '.java';
   }*/
   int status=WarnIfFileExists(filename);
   if (status) {
      return(status);
   }

   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   varname := lowcase(pinfo->Name)'ID';
   _SetEditorLanguage('java');
   indentAmount := LanguageSettings.getSyntaxIndent(p_LangId);
   _str indentstr=indent_string(indentAmount);

   if (pinfo->PackageName!='') {
      insert_line('package 'pinfo->PackageName';');
      insert_line('');
   }
   insert_line('import java.io.Serializable;');
   insert_line('');
   insert_line('/*');
   insert_line(' * Primary Key class for 'pinfo->Name);
   insert_line(' */');
   insert_line('public class 'pkClassName' implements java.io.Serializable {');
   insert_line(indentstr'public String 'varname';');
   insert_line('');
   insert_line(indentstr'public 'pkClassName'(String id) {');
   insert_line(indentstr:+indentstr'this.'varname' = id;');
   insert_line(indentstr'}');
   insert_line('');
   insert_line(indentstr'public 'pkClassName'() {');
   insert_line(indentstr'}');
   insert_line('');
   insert_line(indentstr'public String toString() {');
   insert_line(indentstr:+indentstr'return 'varname';');
   insert_line(indentstr'}');
   insert_line('');
   insert_line(indentstr'public int hashCode() {');
   insert_line(indentstr:+indentstr'return 'varname'.hashCode();');
   insert_line(indentstr'}');
   insert_line('');
   insert_line(indentstr'public boolean equals(Object 'lowcase(pinfo->Name)') {');
   insert_line(indentstr:+indentstr'return (('pinfo->PrimaryKeyClass')'lowcase(pinfo->Name)').'varname'.equals('varname');');
   insert_line(indentstr'}');
   insert_line('}');

   filename=_maybe_quote_filename(filename);
   _save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' 'filename;
   return(0);
}

static int WarnIfFileExists(_str filename)
{
   if (file_exists(filename)) {
      int result=_message_box(nls("File '%s' already exists.\n\nOverwrite existing file?",filename),'',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
      // If the file exists in a different case, we need to delete it because this
      // could cause problems.  Ex: Old File is named mybean.java and new file is
      // MyBean.java.
      if (file_match(filename' -p',1):!=filename) {
         delete_file(filename);
      }
   }
   return(0);
}

static int CopyDescriptorFiles(EJB_INFO *pinfo,_str DestPath,_str &FileList)
{
   _str ejbPath=_getSlickEditInstallPath():+'wizards':+FILESEP:+'java':+FILESEP:+'ejb':+FILESEP;
   _str Files[]=null;
   int ff;
   for (ff=1;;ff=0) {
      cur_filename := file_match(_maybe_quote_filename(ejbPath:+'*.xml'),ff);
      if (cur_filename=='') break;
      Files[Files._length()]=cur_filename;

   }
   int i;
   for (i=0;i<Files._length();++i) {
      int status=CopyOneDescriptorFile(pinfo,Files[i],DestPath,FileList);
      if (status) {
         return(status);
      }
   }
   return(0);
}

static int CopyOneDescriptorFile(EJB_INFO *pinfo,_str SourceFilename,_str DestPath,_str &FileList)
{
   destFilename := DestPath:+_strip_filename(SourceFilename,'P');
   int status=WarnIfFileExists(destFilename);
   if (status) {
      return(status);
   }
   status=copy_file(SourceFilename,destFilename);
   if (status) {
      return(status);
   }
   temp_view_id := orig_view_id := 0;
   status=_open_temp_view(destFilename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   top();
   type := "";
   description := "";
   entityBean := false;
   switch (pinfo->Type) {
   case EJB_ENTITY_BMP:
      type='entity';
      description='Entity Bean - BMP';
      entityBean=true;
      break;
   case EJB_ENTITY_CMP:
      description='Entity Bean - CMP';
      type='entity';
      entityBean=true;
      break;
   case EJB_SESSION_STATEFUL:
      description='Stateful Session Bean';
      type='session';
      break;
   case EJB_SESSION_STATELESS:
      description='Statelessq Session Bean';
      type='session';
      break;
   }
   numchanges := 0;
   status=search('\1TYPE\1','@rh',type,numchanges);
   top();
   status=search('\1DESCRIPTION\1','@rh',description,numchanges);
   top();
   status=search('\1DISPLAYNAME\1','@rh',pinfo->Name,numchanges);
   top();
   status=search('\1EJBNAME\1','@rh',pinfo->Name,numchanges);

   _str pkgName;
   if (_file_eq(_strip_filename(SourceFilename,'P'),DEPLOYMENT_DESCRIPTOR_FILENAME)) {
      pkgName=pinfo->PackageName;
   }else{
      pkgName='';
   }
   _str HomeName=GetNameFromFilename(pinfo->Filenames.HomeFilename,pkgName);
   top();
   status=search('\1HOME\1','@rh',HomeName,numchanges);

   _str RemoteName=GetNameFromFilename(pinfo->Filenames.RemoteFilename,pinfo->PackageName);
   top();
   status=search('\1REMOTE\1','@rh',RemoteName,numchanges);

   _str BeanName=GetNameFromFilename(pinfo->Filenames.BeanFilename,pinfo->PackageName);
   top();
   status=search('\1CLASSNAME\1','@rh',BeanName,numchanges);

   top();
   status=search('\1TYPESPECIFICTAGINFO\1','@rh','',numchanges);
   if (!status) {
      // Only want to perform this part if TYPESPECIFICTAGINFO is found
      if (entityBean) {
         persistence := "";
         if (pinfo->Type==EJB_ENTITY_BMP) {
            persistence='Bean';
         }else if (pinfo->Type==EJB_ENTITY_CMP) {
            persistence='Container';
         }
         replace_line('         <persistence-type>'persistence'</persistence-type>');
         insert_line('         <prim-key-class>'pinfo->PrimaryKeyClass'</prim-key-class>');
         insert_line('         <reentrant>False</reentrant>');
      }else{
         persistence := "";
         if (pinfo->Type==EJB_SESSION_STATEFUL) {
            persistence='Stateful';
         }else if (pinfo->Type==EJB_SESSION_STATELESS) {
            persistence='Stateless';
         }
         replace_line('         <session-type>'persistence'</session-type>');
         insert_line('         <transaction-type>Container</transaction-type>');
      }
      int i;
      for (i=0;i<pinfo->EnvProperties._length();++i) {
         InsertProperty(pinfo->EnvProperties[i],'         ');
      }
   }

   status=_save_file('+o');

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   FileList :+= ' '_maybe_quote_filename(destFilename);
   return(status);
}

static void InsertProperty(EJB_PROP &Prop,_str Indent)
{
   insert_line(Indent:+'<env-entry>');
   insert_line(Indent:+Indent'<env-entry-name>'Prop.Name'</env-entry-name>');
   insert_line(Indent:+Indent'<env-entry-type>'Prop.Type'</env-entry-type>');
   _str initVal;
   if (Prop.Type=='java.lang.String') {
      initVal=Prop.Name;
   }else if (Prop.Type=='java.lang.Boolean') {
      initVal='false';
   }else{
      initVal=0;
   }
   insert_line(Indent:+Indent'<env-entry-value>'initVal'</env-entry-value>');
   insert_line(Indent:+'</env-entry>');
}

static _str GetNameFromFilename(_str filename,_str pkgFilename)
{
   _str HomeName=filename;
   HomeName=_strip_filename(HomeName,'e');
   if (pkgFilename!='') {
      if (substr(HomeName,1,length(pkgFilename))!=pkgFilename) {
         HomeName=pkgFilename'.'HomeName;
      }
   }
   return(HomeName);
}

_command int ejb_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   WIZARD_INFO info=null;
   typeless ejb_callback_table:[]=null;
   ejb_callback_table:['ctlslide0.create']=ejb_slide0create;
   ejb_callback_table:['ctlslide0.next']=ejb_slide0next;

   ejb_callback_table:['ctlslide1.create']=ejb_slide1create;

   ejb_callback_table:['ctlslide3.create']=ejb_slide3create;
   ejb_callback_table:['ctlslide3.shown']=ejb_slide3shown;

   ejb_callback_table:['ctlslide4.create']=ejb_slide4create;
   ejb_callback_table:['ctlslide4.next']=ejb_slide4next;

   ejb_callback_table:['ctlslide5.create']=ejb_slide5create;

   ejb_callback_table:['ctlslide6.create']=ejb_slide6create;

   ejb_callback_table:['ctlslide7.next']=ejb_slide7next;

   ejb_callback_table:['ctlslide1.finishon']=1;
   ejb_callback_table:['ctlslide2.finishon']=1;
   ejb_callback_table:['ctlslide3.finishon']=1;
   ejb_callback_table:['ctlslide4.finishon']=1;
   ejb_callback_table:['ctlslide5.finishon']=1;
   ejb_callback_table:['ctlslide6.finishon']=1;
   ejb_callback_table:['ctlslide7.finishon']=1;

   ejb_callback_table:['finish']=_ejb_wizard_finish;

   info.callbackTable=ejb_callback_table;
   info.parentFormName='_ejb_slide_form';
   info.dialogCaption='Create Enterprise JavaBean';
   gEJBInfo=null;
   gEJBInfo.AddToProject=true;
   int status=_Wizard(&info);
   if (status==COMMAND_CANCELLED_RC) {
      return(COMMAND_CANCELLED_RC);
   }else if (!status) {
      _str PackagePath=_file_path(_project_name):+stranslate(gEJBInfo.PackageName,FILESEP,'.');
      _maybe_append_filesep(PackagePath);
      status=edit(_maybe_quote_filename(PackagePath:+gEJBInfo.Filenames.BeanFilename));
   }
   return(status);
}

defeventtab _ejb_slide_form;

static void EnableDeleteButton()
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      p_next.p_next.p_enabled=false;
   }else{
      p_next.p_next.p_enabled=true;
   }
}

void ctls1_tree.ENTER()
{
   if (_TreeCurIndex()<0) {
      wid := p_active_form._find_control('ctlnext');
      if (wid) {
         wid.call_event(wid,LBUTTON_UP);
      }
   }
}

void ctls1_del.lbutton_up()
{
   wid := p_window_id;
   p_window_id=p_prev.p_prev;
   index := _TreeCurIndex();
   if (index>0) {
      if (p_name=='ctls3_tree' && index==EJB_FBPK_INDEX()) {
         return;
      }
      _TreeDelete(index);
   }
   EnableDeleteButton();
   p_window_id=wid;
}

void ctls1_add.lbutton_up()
{
   typeless pfnButtonAction=p_user;
   wid := p_window_id;
   p_window_id=p_prev;
   if (pfnButtonAction!='') {
      (*pfnButtonAction)();
      return;
   }

   // Be sure that the caption that we are plugging in
   // has the right number of tabs in it.
   cap := "";
   int NumButtons=_TreeGetNumColButtons();
   int i;
   for (i=0;i<NumButtons-1;++i) {
      cap :+= "\t";
   }
   newindex := -1;
   //int BlankIndex=BlankIndexExists(cap);
   //if (BlankIndex>=0) {
      //_TreeSetCurIndex(BlankIndex);
      //newindex=BlankIndex;
      //p_prev._set_focus();
   //}else{
      index := _TreeCurIndex();
      if (index<=0) {
         // Really mean >0 , can't delete root node anyway.
         newindex=_TreeAddItem(TREE_ROOT_INDEX,cap,TREE_ADD_AS_CHILD,0,0,-1);
      }else{
         newindex=_TreeAddItem(index,cap,0,0,0,-1);
      }
      if (newindex>-1) {
         _TreeSetCurIndex(newindex);
      }
   //}
   status := 0;
   if (newindex>-1) {
      status=_TreeEditNode(newindex,0);
   }
   p_window_id=wid;
   //p_prev._set_focus();
}

static int ValidateArgList(_str text)
{
   cur := "";
   type := "";
   variable := "";
   for (;;) {
      parse text with cur ',' text;
      if (cur=='') break;
      parse cur with type variable;
      type=strip(type);
      variable=strip(variable);
      if (type=='' && variable=='') {
         return(0);
      }
      if (!isid_valid(type)) {
         _message_box(nls("Invalid type:'%s'",type));
         return(-1);
      }
      if (!isid_valid(variable)) {
         _message_box(nls("Invalid identifier:'%s'",variable));
         return(-1);
      }
   }
   return(0);
}

int ctls1_tree.on_change(int reason,int index,int col=-1,_str &text='')
{
   if (reason==CHANGE_EDIT_CLOSE) {
      if (col==1) {
         text=strip(text,'B','(');
         text=strip(text,'B',')');
         int status;
         if (text=='') {
            // No arguments is ok...
            status=0;
         }else{
            status=ValidateArgList(text);
         }
         if (status) {
            return(-1);
         }
         text='('text')';
         return(0);
      }
   }
   EnableDeleteButton();
   return(0);
}

void ctls2_pkexisting.lbutton_up()
{
   if (ctls2_pkexisting.p_value) {
      ctls2_pkcombo.p_enabled=true;
      ctls2_pktext.p_enabled=false;
   }else{
      ctls2_pkcombo.p_enabled=false;
      ctls2_pktext.p_enabled=true;
   }
}

static void MaybeClickNext()
{
   if (_TreeCurIndex()<0) {
      wid := p_active_form._find_control('ctlnext');
      if (wid) {
         wid.call_event(wid,LBUTTON_UP);
      }
   }
}

void ctls3_tree.ENTER()
{
   MaybeClickNext();
}

int ctls3_tree.on_change(int reason,int index,int col=-1,_str &text='')
{
   switch (reason) {
   case CHANGE_EDIT_QUERY:
      if (index==EJB_FBPK_INDEX()) {
         // Cannot edit this method
         return(-1);
      }
      break;
   case CHANGE_EDIT_CLOSE:
      switch (col) {
      case 1:
         {
            if (!isid_valid(text)) {
               _message_box(nls("Invalid identifier:'%s'",text));
               return(-1);
            }
            if (substr(text,1,7)!='ejbFind') {
               _message_box(nls("Finder methods must start with 'ejbFind'"));
               return(-1);
            }
            return(0);
         }
      case 2:
         {
            text=strip(text,'B','(');
            text=strip(text,'B',')');
            int status=ValidateArgList(text);
            if (status) {
               return(-1);
            }
            text='('text')';
            return(0);
         }
      case 0:
         return(0);
      }
      break;
   }
   EnableDeleteButton();
   return(0);
}

int ctls4_tree.on_change(int reason,int index,int col=-1,_str &text='')
{
   switch (reason) {
   case CHANGE_EDIT_CLOSE:
      switch (col) {
      case 0:
         {
            if (!isid_valid(text)) {
               _message_box(nls("Invalid type:'%s'",text));
               return(-1);
            }
            return(0);
         }
         return(0);
      case 1:
         {
            if (!isid_valid(text)) {
               _message_box(nls("Invalid identifier:'%s'",text));
               return(-1);
            }
            return(0);
         }
      case 2:
         {
            text=strip(text,'B','(');
            text=strip(text,'B',')');
            int status=ValidateArgList(text);
            if (status) {
               return(-1);
            }
            text='('text')';
            return(0);
         }
      }
      break;
   }
   EnableDeleteButton();
   return(0);
}

static int BlankIndexExists(_str cap='')
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      curcap := _TreeGetCaption(index);
      if (curcap==cap) {
         return(index);
      }
      index=_TreeGetNextIndex(index);
   }
   return(-1);
}

int ctls5_tree.on_change(int reason,int index,int col=-1,_str text='')
{
   if (reason==CHANGE_EDIT_CLOSE) {
      msg := "";
      switch (col) {
      case 0:
         // First strip off any packages..
         if (!_inarray(text,gValidPropertyTypes)) {
            _message_box(nls("Invalid type:'%s'",text));
            return(-1);
         }
         break;
      case 1:
         if (!isid_valid(text)) {
            _message_box(nls("Invalid identifier:'%s'",text));
            return(-1);
         }

         if (!SearchForOtherVariables(strip(text))) {
            _message_box(nls("A property named '%s' already exists",text));
            return(-1);
         }

         break;
      }
      return(0);
   }
   EnableDeleteButton();
   return(0);
}

static int SearchForOtherVariables(_str name,_str prefix="\t")
{
   curindex := _TreeCurIndex();
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      cap := _TreeGetCaption(index);
      while (pos("\t",cap)) {
         parse cap with "\t" cap;
      }
      if (cap==name && index!=curindex) {
         return(0);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   return(1);
}

int ctls6_tree.on_change(int reason,int index,int col=-1,_str text='')
{
   if (reason==CHANGE_EDIT_CLOSE) {
      msg := "";
      switch (col) {
      case 1:
         msg=nls("Invalid type:'%s'",text);
         break;
      case 2:
         msg=nls("Invalid identifier:'%s'",text);
         break;
      }
      if (!isid_valid(text)) {
         _message_box(msg);
         return(-1);
      }
      if (!SearchForOtherVariables(strip(text))) {
         _message_box(nls("A field named '%s' already exists",text));
         return(-1);
      }
      return(0);
   }
   if (_TreeCurIndex()<0) {
      p_next.p_next.p_enabled=false;
   }
   EnableDeleteButton();
   return(0);
}

void ctls5_tree.ENTER()
{
   MaybeClickNext();
}

void ctls6_tree.ENTER()
{
   MaybeClickNext();
}
#if 0 //10:26am 10/7/2011
void ctls6_tree.lbutton_up()
{
   CBTreeLbuttonUp();
}
#endif

static int ejb_show_new_project_info()
{
   line := "";
   _add_line_to_html_caption(line,"<B>Bean name:</B>");
   _add_line_to_html_caption(line,"\t"gEJBInfo.Name);
   if (gEJBInfo.PackageName!='') {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Package name:</B>");
      _add_line_to_html_caption(line,"\t"gEJBInfo.PackageName);
   }else{
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"No package specified");
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Bean type:</B>");
   switch (gEJBInfo.Type) {
   case EJB_SESSION_STATEFUL:
      _add_line_to_html_caption(line,"\tSession - Stateful");
      break;
   case EJB_SESSION_STATELESS:
      _add_line_to_html_caption(line,"\tSession - Stateless");
      break;
   case EJB_ENTITY_BMP:
      _add_line_to_html_caption(line,"\tEntity - Bean-managed persistence");
      break;
   case EJB_ENTITY_CMP:
      _add_line_to_html_caption(line,"\tEntity - Container-managed persistence");
      break;
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Create methods:</B>");
   int i;
   for (i=0;i<gEJBInfo.CreateArguments._length();++i) {
      _add_line_to_html_caption(line,"\tejbCreate("gEJBInfo.CreateArguments[i]")");
   }
   if (gEJBInfo.Type==EJB_ENTITY_BMP ||
       gEJBInfo.Type==EJB_ENTITY_CMP) {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Finder methods:</B>");
      for (i=0;i<gEJBInfo.FinderMethods._length();++i) {
         _str type;
         _str pkname;

         pkname=gEJBInfo.PrimaryKeyClass;
         for (;;) {
            if (pos('.',pkname)) {
               parse pkname with . "." pkname;
            }else break;
         }

         if (gEJBInfo.FinderMethods[i].ReturnsCollection) {
            type='Collection';
         }else{
            type=pkname;
         }
         _str args=gEJBInfo.FinderMethods[i].Args;
         if (substr(args,1,1)!='(') {
            args='('args;
         }
         if (_last_char(args)!=')') {
            args :+= ')';
         }
         _add_line_to_html_caption(line,"\t"type' 'gEJBInfo.FinderMethods[i].Name:+args);
      }
   }
   if (gEJBInfo.BusinessMethods._length()) {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Business methods:</B>");
      for (i=0;i<gEJBInfo.BusinessMethods._length();++i) {
         _add_line_to_html_caption(line,"\t"gEJBInfo.BusinessMethods[i].Type" "gEJBInfo.BusinessMethods[i].Name:+gEJBInfo.BusinessMethods[i].Args);
      }
   }
   if (gEJBInfo.ConvStateFields._length()) {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Conversational state fields:</B>");
      for (i=0;i<gEJBInfo.CreateArguments._length();++i) {
         _add_line_to_html_caption(line,"\t"gEJBInfo.ConvStateFields[i].Type" "gEJBInfo.ConvStateFields[i].Name);
      }
   }
   if (gEJBInfo.EnvProperties._length()) {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Environment properties:</B>");
      for (i=0;i<gEJBInfo.EnvProperties._length();++i) {
         _add_line_to_html_caption(line,"\t"gEJBInfo.EnvProperties[i].Type" "gEJBInfo.EnvProperties[i].Name);
      }
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Files generated:</B>");
   _add_line_to_html_caption(line,gEJBInfo.Filenames.BeanFilename);
   _add_line_to_html_caption(line,gEJBInfo.Filenames.HomeFilename);
   _add_line_to_html_caption(line,gEJBInfo.Filenames.RemoteFilename);
   if (gEJBInfo.Filenames.BeanPKFilename!=null) {
      _add_line_to_html_caption(line,gEJBInfo.Filenames.BeanPKFilename);
   }
   if (gEJBInfo.Filenames.ClientFilename!=null) {
      _add_line_to_html_caption(line,gEJBInfo.Filenames.ClientFilename);
   }

   typeless status=show('-modal _new_project_info_form',
               "EJBBean wizard will create a skeleton project for you with the following\nspecifications:",
               line);
   if (status=='') {
      return(COMMAND_CANCELLED_RC);
   }
   return(status);
}
