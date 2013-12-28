////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46085 $
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
#include "codetemplate.sh"
#include "eclipse.sh"
#include "tagsdb.sh"
#include "xml.sh"
#import "cformat.e"
#import "compile.e"
#import "fileman.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "xmlcfg.e"
#endregion


/**
 * @return Absolute path to system templates directory.
 */
_str _ctGetSysTemplatesDir()
{
   return ( get_env("VSROOT"):+"sysconfig":+FILESEP:+CT_ROOT_DIR );
}

/**
 * @return Absolute path to system templates/ItemTemplates directory.
 */
_str _ctGetSysItemTemplatesDir()
{
   return ( _ctGetSysTemplatesDir():+FILESEP:+CT_SYS_ITEM_DIR );
}

/**
 * @return Absolute path to user templates/ItemTemplates directory.
 */
_str _ctGetUserItemTemplatesDir()
{
   return ( _ConfigPath():+CT_ROOT_DIR:+FILESEP:+CT_USER_ITEM_DIR );
}

/**
 * Open a template file. A template file is a file with a .setemplate 
 * extension.
 * 
 * @param filename Full path to template file.
 * 
 * @return >0 handle to open template file on success, <0 on error.
 * 
 * @see _ctTemplateClose
 */
int _ctTemplateOpen(_str filename)
{
   if( !_ctIsTemplateFile(filename) ) {
      return VSRC_INVALID_ARGUMENT;
   }
   int status = 0;
   int handle = _xmlcfg_open(filename,status,VSXMLCFG_OPEN_ADD_PCDATA|VSXMLCFG_OPEN_REFCOUNT);
   if( handle<0 || status<0 ) {
      return ( handle<0 ? handle : status );
   }
   return handle;
}

/**
 * Close handle to open template file. Use _ctTemplateOpen to open a template file.
 * 
 * @param handle Handle to open template file. Handles are reference counted.
 * 
 * @see _ctTemplateOpen
 */
void _ctTemplateClose(int handle)
{
   if( handle>=0 ) {
      _xmlcfg_close(handle);
   }
}

/**
 * Save open template to file.
 * 
 * @param handle   Handle to open template file. Handles are reference counted.
 * @param filename Name of file to save to.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateSave(int handle, _str filename)
{
   int status = _xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE,filename);
   return status;
}

#define CTTAG_ITEM_ROOT "SETemplate"

#define CTTAG_TEMPLATEDETAILS "TemplateDetails"
#define CTTAG_TEMPLATECONTENT "TemplateContent"
#define CTTAG_NAME "Name"
#define CTTAG_DESCRIPTION "Description"
#define CTTAG_ICON "Icon"
#define CTTAG_CATEGORY "Category"
#define CTTAG_SORTORDER "SortOrder"
#define CTTAG_DEFAULTNAME "DefaultName"
#define CTTAG_PARAMETERS "Parameters"
#define CTTAG_PARAMETER "Parameter"
#define CTTAG_FILES "Files"
#define CTTAG_FILE "File"

#define CTXPATH_ITEM_ROOT "/"CTTAG_ITEM_ROOT
#define CTXPATH_ITEM_TEMPLATEDETAILS CTXPATH_ITEM_ROOT"/"CTTAG_TEMPLATEDETAILS
#define CTXPATH_ITEM_NAME CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_NAME
#define CTXPATH_ITEM_DESCRIPTION CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_DESCRIPTION
#define CTXPATH_ITEM_ICON CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_ICON
#define CTXPATH_ITEM_CATEGORY CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_CATEGORY
#define CTXPATH_ITEM_SORTORDER CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_SORTORDER
#define CTXPATH_ITEM_DEFAULTNAME CTXPATH_ITEM_TEMPLATEDETAILS"/"CTTAG_DEFAULTNAME
#define CTXPATH_ITEM_TEMPLATECONTENT CTXPATH_ITEM_ROOT"/"CTTAG_TEMPLATECONTENT
#define CTXPATH_ITEM_FILES CTXPATH_ITEM_TEMPLATECONTENT"/"CTTAG_FILES
#define CTXPATH_ITEM_FILE CTXPATH_ITEM_FILES"/"CTTAG_FILE
#define CTXPATH_ITEM_PARAMETERS CTXPATH_ITEM_TEMPLATECONTENT"/"CTTAG_PARAMETERS
#define CTXPATH_ITEM_PARAMETER CTXPATH_ITEM_PARAMETERS"/"CTTAG_PARAMETER

#define CTTAG_OPTIONS_ROOT "Options"

#define CTXPATH_OPTIONS_ROOT "/"CTTAG_OPTIONS_ROOT
#define CTXPATH_OPTIONS_PARAMETERS CTXPATH_OPTIONS_ROOT"/"CTTAG_PARAMETERS
#define CTXPATH_OPTIONS_PARAMETER  CTXPATH_OPTIONS_PARAMETERS"/"CTTAG_PARAMETER

#define CTOPTIONS_DTD_PATH "http://www.slickedit.com/dtd/vse/setemplate/1.0/options.dtd"

/**
 * Retrieve template version.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return String value template version.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctTemplate_GetTemplateVersion(int handle)
{
   _str Version = "";
   int node = _xmlcfg_find_simple(handle,CTXPATH_ITEM_ROOT);
   if( node>=0 ) {
      Version=_xmlcfg_get_attribute(handle,node,"Version");
   }
   return strip(Version);
}

/**
 * Set template version.
 * 
 * @param handle
 * @param Version
 * 
 * @return 0 on success, <0 on error.
 */
int _ctTemplate_SetTemplateVersion(int handle, _str Version)
{
   int status = 0;
   int node = _xmlcfg_set_path(handle,CTXPATH_ITEM_ROOT);
   if( node>=0 ) {
      status=_xmlcfg_set_attribute(handle,node,"Version",strip(Version));
   } else {
      // Error
      status=node;
   }
   return status;
}

/**
 * Retrieve template type.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return String value template type.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctTemplate_GetTemplateType(int handle)
{
   _str Type = "";
   int node = _xmlcfg_find_simple(handle,CTXPATH_ITEM_ROOT);
   if( node>=0 ) {
      Type=_xmlcfg_get_attribute(handle,node,"Type");
   }
   return strip(Type);
}

/**
 * Set template type.
 * 
 * @param handle
 * @param Type
 * 
 * @return 0 on success, <0 on error.
 */
int _ctTemplate_SetTemplateType(int handle, _str Type)
{
   int status = 0;
   int node = _xmlcfg_set_path(handle,CTXPATH_ITEM_ROOT);
   if( node>=0 ) {
      status=_xmlcfg_set_attribute(handle,node,"Type",strip(Type));
   } else {
      // Error
      status=node;
   }
   return status;
}

/**
 * General purpose function that retrieves a PCDATA value stored at location
 * given by XPath.
 * 
 * @param handle
 * @param xpath
 * 
 * @return PCDATA value.
 */
static _str _ctTemplate_Get(int handle, _str xpath)
{
   _str text = "";
   int node = _xmlcfg_find_simple(handle,xpath);
   if( node>=0 ) {
      int pcdatanode = _xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
      if( pcdatanode>=0 ) {
         text=_xmlcfg_get_value(handle,pcdatanode);
      }
   }
   // Strip off whitespace and newlines
   text=strip(text);
   text=strip(text,'B',"\n");
   text=strip(text,'B',"\r");
   text=strip(text);
   return text;
}

/**
 * General purpose function that sets a PCDATA value stored at location
 * given by XPath.
 * 
 * @param handle
 * @param xpath
 * @param value
 * 
 * @return 0 on success, <0 on error.
 */
static int _ctTemplate_Set(int handle, _str xpath, _str value)
{
   int status = 0;
   int node = _xmlcfg_set_path(handle,xpath);
   if( node>=0 ) {
      int pcdatanode = _xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
      if( pcdatanode>=0 ) {
         _xmlcfg_delete(handle,pcdatanode);
      }
      pcdatanode=_xmlcfg_add(handle,node,strip(value),VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
      if( pcdatanode<0 ) {
         // Error
         status=pcdatanode;
      }
   } else {
      // Error
      status=node;
   }
   return status;
}

/**
 * Retrieve name for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return Name for template.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctTemplateDetails_GetName(int handle)
{
   _str text = _ctTemplate_Get(handle,CTXPATH_ITEM_NAME);
   return text;
}

/**
 * Set name for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param Name   Name value.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateDetails_SetName(int handle, _str Name)
{
   if( Name==null ) {
      Name="";
   }
   int status = _ctTemplate_Set(handle,CTXPATH_ITEM_NAME,Name);
   return status;
}

/**
 * Retrieve description for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return Description for template.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctTemplateDetails_GetDescription(int handle)
{
   _str text = _ctTemplate_Get(handle,CTXPATH_ITEM_DESCRIPTION);
   return text;
}

/**
 * Set description for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param Name   Description value.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateDetails_SetDescription(int handle, _str Description)
{
   if( Description==null ) {
      Description="";
   }
   int status = _ctTemplate_Set(handle,CTXPATH_ITEM_DESCRIPTION,Description);
   return status;
}

/**
 * Retrieve sort order for template. Used to sort template items in a list.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return Sort order.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateDetails_GetSortOrder(int handle)
{
   int sort_order=0;
   _str text = _ctTemplate_Get(handle,CTXPATH_ITEM_SORTORDER);
   if( isinteger(text) && (int)text>=0 ) {
      sort_order=(int)text;
   }
   return sort_order;
}

/**
 * Set sort order for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param SortOrder Sort order value.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateDetails_SetSortOrder(int handle, int SortOrder)
{
   if( SortOrder<0 ) {
      SortOrder=0;
   }
   int status = _ctTemplate_Set(handle,CTXPATH_ITEM_SORTORDER,SortOrder);
   return status;
}

/**
 * Retrieve default name for template. This is the name used to create the template file(s).
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return Default name for template.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctTemplateDetails_GetDefaultName(int handle)
{
   _str text = _ctTemplate_Get(handle,CTXPATH_ITEM_DEFAULTNAME);
   return text;
}

/**
 * Set default name for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param DefaultName Default name value.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateDetails_SetDefaultName(int handle, _str DefaultName)
{
   if( DefaultName==null ) {
      DefaultName="";
   }
   int status = _ctTemplate_Set(handle,CTXPATH_ITEM_DEFAULTNAME,DefaultName);
   return status;
}

/**
 * Retrieve template details structure for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param templateDetails (output). ctTemplateDetails_t object in which to
 *                        store retrieved details.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplate_GetTemplateDetails(int handle, ctTemplateDetails_t& templateDetails)
{
   templateDetails._makeempty();

   _str Name = _ctTemplateDetails_GetName(handle);
   _str Description = _ctTemplateDetails_GetDescription(handle);
   int SortOrder = _ctTemplateDetails_GetSortOrder(handle);
   _str DefaultName = _ctTemplateDetails_GetDefaultName(handle);

   templateDetails.Name=Name;
   templateDetails.Description=Description;
   templateDetails.SortOrder=SortOrder;
   templateDetails.DefaultName=DefaultName;

   return 0;
}

/**
 * Set template details from ctTemplateDetails_t object.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param templateDetails ctTemplateDetails_t object from which details settings come.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplate_SetTemplateDetails(int handle, ctTemplateDetails_t& templateDetails)
{
   int status = 0;

   status=_ctTemplateDetails_SetName(handle,templateDetails.Name);
   if( 0==status ) {
      status=_ctTemplateDetails_SetDescription(handle,templateDetails.Description);
      if( 0==status ) {
         status=_ctTemplateDetails_SetSortOrder(handle,templateDetails.SortOrder);
         if( 0==status ) {
            status=_ctTemplateDetails_SetDefaultName(handle,templateDetails.DefaultName);
         }
      }
   }

   return status;
}

/**
 * Retrieve template content structure for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param templateContent (output). ctTemplateContent_t object in which to
 *                        store retrieved content.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplate_GetTemplateContent(int handle, ctTemplateContent_t& templateContent)
{
   templateContent._makeempty();

   _str Delimiter = _ctTemplateContent_GetDelimiter(handle);
   ctTemplateContent_ParameterValue_t Parameters:[]; Parameters._makeempty();
   _ctTemplateContent_GetParameters(handle,Parameters);
   ctTemplateContent_File_t Files[];
   _str filea[];
   _str attribs:[]:[];
   _ctTemplateContent_GetFiles(handle,filea,attribs);
   int i;
   for( i=0; i<filea._length(); ++i ) {
      _str Filename = filea[i];
      if( Filename=="" ) {
         continue;
      }
      boolean ReplaceParameters = true;
      _str TargetFilename = Filename;
      if( attribs._indexin(Filename) ) {
         if( attribs:[Filename]._indexin("ReplaceParameters") ) {
            ReplaceParameters = ( attribs:[Filename]:["ReplaceParameters"] != "0" );
         }
         if( attribs:[Filename]._indexin("TargetFilename") ) {
            if( attribs:[Filename]:["TargetFilename"] != "" ) {
               TargetFilename = attribs:[Filename]:["TargetFilename"];
            }
         }
      }

      Filename=strip(Filename);
      Filename=strip(Filename,'B','"');
      TargetFilename=strip(TargetFilename);
      TargetFilename=strip(TargetFilename,'B','"');

      int j = Files._length();
      Files[j].Filename = Filename;
      Files[j].ReplaceParameters = ReplaceParameters;
      Files[j].TargetFilename = TargetFilename;
   }

   if( Delimiter=="" ) {
      // Use default
      Delimiter=CTPARAMETER_DELIM;
   }
   templateContent.Delimiter=Delimiter;
   templateContent.Parameters=Parameters;
   templateContent.Files=Files;

   return 0;
}

/**
 * Set template content from ctTemplateContent_t object.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param templateContent ctTemplateDetails_t object from which content settings come.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplate_SetTemplateContent(int handle, ctTemplateContent_t& templateContent)
{
   int status = 0;
   status=_ctTemplateContent_SetDelimiter(handle,templateContent.Delimiter);
   if( 0==status ) {
      status=_ctTemplateContent_SetParameters(handle,templateContent.Parameters);
      if( 0==status ) {
         // Make a copy of template Files and change all paths to be relative to
         // template directory (if their root is in the template directory of course).
         _str templateDir = absolute(_xmlcfg_get_filename(handle));
         templateDir=_strip_filename(templateDir,'n');
         ctTemplateContent_File_t Files[];
         Files=templateContent.Files;
         int i;
         for( i=0; i<Files._length(); ++i ) {
            Files[i].Filename = relative(Files[i].Filename,templateDir,false);
         }
         status=_ctTemplateContent_SetFiles(handle,Files);
      }
   }
   return status;
}

/**
 * Convert relative path to absolute path relative to a template file's directory.
 * 
 * @param relPath Relative path to convert.
 * @param toTemplateFilePath Absolute path to template file.
 * 
 * @return Relative path converted to absolute.
 */
_str _ctAbsoluteToTemplateFile(_str relPath, _str toTemplateFilePath)
{
   _str toPath = toTemplateFilePath;
   if( last_char(toPath)!=FILESEP ) {
      toPath=_strip_filename(toPath,'n');
   }
   return ( absolute(relPath,toPath) );
}

/**
 * Retrieve delimiter for template content.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * 
 * @return String value template content delimiter.
 */
_str _ctTemplateContent_GetDelimiter(int handle)
{
   _str Delimiter = "";
   int node = _xmlcfg_find_simple(handle,CTXPATH_ITEM_TEMPLATECONTENT);
   if( node>=0 ) {
      Delimiter=_xmlcfg_get_attribute(handle,node,"Delimiter");
   }
   return Delimiter;
}

/**
 * Set delimiter for template content.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param Delimiter Delimiter value.
 * 
 * @return 0 on success, <0 on error.
 */
int _ctTemplateContent_SetDelimiter(int handle, _str Delimiter)
{
   int status = 0;
   int node = _xmlcfg_set_path(handle,CTXPATH_ITEM_TEMPLATECONTENT);
   if( node>=0 ) {
      if( _xmlcfg_get_attribute(handle,node,"Delimiter","NOT-FOUND") != "NOT-FOUND" ) {
         // Delete attribute before replacing it
         _xmlcfg_delete_attribute(handle,node,"Delimiter");
      }
      // Only set the attribute if it is different from the default
      if( Delimiter != CTPARAMETER_DELIM ) {
         status=_xmlcfg_set_attribute(handle,node,"Delimiter",strip(Delimiter));
      }
   } else {
      // Error
      status=node;
   }
   return status;
}

/**
 * Retrieve files for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param files   (output). Array of files for template. <br>
 *                Example: files[0] is the first file.
 * @param attribs (output). Hash table of attributes for each file in files[]
 *                output array. Hash table is indexed by filename. <br>
 *                Example: attribs:[files[0]] is the hash table of name/value
 *                pairs for the first file. <br>
 *                Example: attribs:[files[0]]:['TargetFilename'] returns the
 *                TargetFilename attribute value for the first file.
 * @param absPaths (optional) (output). Hash table of absolute paths for each
 *                 relative filename in files[] output array. Hash table is
 *                 indexed by filename. <br>
 *                 Example: Assuming files[0]="Foo.cpp", and the template file
 *                 path="c:\path\to\templates\", then <br>
 *                 absPaths:[files[0]]="c:\path\to\templates\Foo.cpp" <br>
 *                 Example: Assuming files[0]="rel-path/Foo.cpp", and the template file
 *                 path="c:\path\to\templates\", then <br>
 *                 absPaths:[files[0]]="c:\path\to\templates\rel-path\Foo.cpp"
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
void _ctTemplateContent_GetFiles(int handle, _str (&files)[], _str (&attribs):[]:[], _str (&absPaths):[]=null)
{
   files._makeempty();
   attribs._makeempty();
   if( absPaths!=null ) {
      absPaths._makeempty();
   }
   typeless nodea[]; nodea._makeempty();
   int status = _xmlcfg_find_simple_array(handle,CTXPATH_ITEM_FILE,nodea);
   if( status==0 ) {
      _str template_filename = _xmlcfg_get_filename(handle);
      int i;
      for( i=0; i<nodea._length(); ++i ) {
         int pcdatanode = _xmlcfg_get_first_child(handle,nodea[i],VSXMLCFG_NODE_PCDATA);
         if( pcdatanode>=0 ) {
            _str filename = _xmlcfg_get_value(handle,pcdatanode);
            if( filename!="" ) {
               files[files._length()]=filename;
               attribs:[filename]._makeempty();
               if( absPaths!=null ) {
                  absPaths:[filename]=_ctAbsoluteToTemplateFile(filename,template_filename);
               }
               status=_xmlcfg_get_attribute_ht(handle,(int)nodea[i],attribs:[filename]);
               if( status!=0 ) {
                  attribs._deleteel(filename);
               }
            }
         }
      }
   }
}

/**
 * Set files for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param Files  Array of ctTemplateContent_File_t objects.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateContent_SetFiles(int handle, ctTemplateContent_File_t (&Files)[])
{
   int status = 0;
   int parent = _xmlcfg_set_path(handle,CTXPATH_ITEM_FILES);
   if( parent>=0 ) {
      _xmlcfg_delete_children_with_name(handle,parent,CTTAG_FILE);
      int i;
      for( i=0; i<Files._length(); ++i ) {
         int node = _xmlcfg_add(handle,parent,CTTAG_FILE,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         if( node<0 ) {
            // Error
            status=node;
            break;
         }

         _str Filename = Files[i].Filename;
         Filename=strip(Filename);
         Filename=strip(Filename,'B','"');
         _str TargetFilename = "";
         if( Files[i].TargetFilename != null ) {
            TargetFilename=Files[i].TargetFilename;
            TargetFilename=strip(TargetFilename);
            TargetFilename=strip(TargetFilename,'B','"');
         }
         _str ReplaceParameters = (_str)Files[i].ReplaceParameters;

         int pcdatanode = _xmlcfg_add(handle,node,Filename,VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
         if( pcdatanode<0 ) {
            // Error
            status=pcdatanode;
            break;
         }
         if( TargetFilename != "" ) {
            _xmlcfg_add_attribute(handle,node,"TargetFilename",TargetFilename);
         }
         _xmlcfg_add_attribute(handle,node,"ReplaceParameters",ReplaceParameters);
      }
   } else {
      // Error
      status=parent;
   }
   return status;
}

/**
 * Retrieve parameters for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param params (output). Hash table of parameter values indexed by parameter name. <br>
 *               Example: params:['foo'].Value="bar" where 'foo' is the parameter name and "bar"
 *               is the parameter value.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
void _ctTemplateContent_GetParameters(int handle, ctTemplateContent_ParameterValue_t (&params):[])
{
   params._makeempty();
   typeless nodea[]; nodea._makeempty();
   int status = _xmlcfg_find_simple_array(handle,CTXPATH_ITEM_PARAMETER,nodea);
   if( status==0 ) {
      int i;
      for( i=0; i<nodea._length(); ++i ) {
         _str Name = _xmlcfg_get_attribute(handle,nodea[i],"Name");
         // Substitution parameters are case-insensitive
         Name=lowcase(Name);
         if( Name!="" ) {
            _str Value = _xmlcfg_get_attribute(handle,nodea[i],"Value");
            params:[Name].Value=Value;
            _str val = _xmlcfg_get_attribute(handle,nodea[i],"Prompt");
            boolean Prompt = ( val!="" && val!="0" );
            params:[Name].Prompt=Prompt;
            _str PromptString = _xmlcfg_get_attribute(handle,nodea[i],"PromptString");
            params:[Name].PromptString=PromptString;
         }
      }
   }
}

/**
 * Set parameters for template.
 * 
 * @param handle Handle to open template file. Use _ctTemplateOpen to open a template
 *               file.
 * @param Files  Hash table of ctTemplateContent_ParameterValue_t objects.
 *               Hash table is indexed by parameter name.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctTemplateContent_SetParameters(int handle, ctTemplateContent_ParameterValue_t (&Parameters):[])
{
   int status = 0;
   int parent = _xmlcfg_set_path(handle,CTXPATH_ITEM_PARAMETERS);
   if( parent>=0 ) {
      _xmlcfg_delete_children_with_name(handle,parent,CTTAG_PARAMETER);
      _str Name;
      for( Name._makeempty();; ) {
         Parameters._nextel(Name);
         if( Name._isempty() ) {
            // Done
            break;
         }
         int node = _xmlcfg_add(handle,parent,CTTAG_PARAMETER,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         if( node<0 ) {
            // Error
            status=node;
            break;
         }
         _xmlcfg_add_attribute(handle,node,"Name",Name);
         _xmlcfg_add_attribute(handle,node,"Value",strip(Parameters:[Name].Value));
         if( Parameters:[Name].Prompt || Parameters:[Name].PromptString != "" ) {
            _xmlcfg_add_attribute(handle,node,"Prompt",(_str)Parameters:[Name].Prompt);
            _xmlcfg_add_attribute(handle,node,"PromptString",strip(Parameters:[Name].PromptString));
         }
      }
   } else {
      // Error
      status=parent;
   }
   return status;
}

/**
 * Determine if filename is a template file (.setemplate).
 * 
 * @param filename Filename to test.
 * 
 * @return true if filename is a template file.
 */
boolean _ctIsTemplateFile(_str filename)
{
   return ( filename!="" && CT_EXT==_get_extension(filename,true) && file_exists(filename) );
}

/**
 * Determine if filename is an options file (options.xml).
 * 
 * @param filename Filename to test.
 * 
 * @return true if filename is an options file.
 */
boolean _ctIsOptionsFile(_str filename)
{
   filename=strip(filename,'B','"');
   _str filenamenopath = _strip_filename(filename,'p');
   return ( file_eq(filenamenopath,CTOPTIONS_FILENAME) && file_exists(filename) );
}

/**
 * Determine if path is a system template path.
 * 
 * @param path
 * 
 * @return true if path is a system template path.
 */
boolean _ctIsSysItemTemplatePath(_str path)
{
   _str root = _ctGetSysItemTemplatesDir();
   if( file_eq(root,substr(path,1,length(root))) ) {
      return true;
   }
   // Not a system template path
   return false;
}

/**
 * Determine if path is a user template path.
 * 
 * @param path
 * 
 * @return true if path is a user template path.
 */
boolean _ctIsUserItemTemplatePath(_str path)
{
   _str root = _ctGetUserItemTemplatesDir();
   if( file_eq(root,substr(path,1,length(root))) ) {
      return true;
   }
   // Not a user template path
   return false;
}

/**
 * Determine if path is a template directory (i.e. a directory
 * containing a .setemplate file).
 * 
 * @param dir Directory to test.
 * 
 * @return true if path is a template directory.
 */
boolean _ctIsTemplateDirectory(_str dir)
{
   _maybe_append_filesep(dir);
   // Note:
   // We are using insert_file_list() because we want to be able to call
   // this from inside a find first/next loop without stomping on the callers
   // find first/next handle.
   // It is unfortunate that file_exists() will accept a wildcard on Windows
   // but not on UNIX, otherwise we could use that.
   int temp_wid;
   int orig_wid = _create_temp_view(temp_wid);
   int status = insert_file_list("+hsa ":+maybe_quote_filename(dir:+'*':+CT_EXT));
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return ( status == 0 );
}

boolean _ctTemplateIsValidVersion(_str Version)
{
   _str testMajor, testMinor, testRev, testBuild;
   normalizeVSEVersion(Version,testMajor,testMinor,testRev,testBuild);
   _str major, minor, rev, build;
   normalizeVSEVersion(CT_VERSION,major,minor,rev,build);
   return ( testMajor==major && testMinor==minor && testRev==rev );
}

boolean _ctTemplateIsValidType(_str Type)
{
   return ( lowcase(Type) == "item" );
}

/**
 * Retrieve template details and template content from template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_GetTemplateDetails, _ctTemplate_GetTemplateContent,
 * _ctTemplateClose if you want to retrieve from a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * @param templateDetails (output). Pointer to template details structure.
 *                        0 (NULL) is valid.
 * @param templateContent (output). Pointer to template content structure.
 *                        0 (NULL) is valid.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateGetTemplateDetails
 * @see _ctTemplateGetTemplateContent
 */
int _ctTemplateGetTemplate(_str filename,
                           ctTemplateDetails_t* templateDetails,
                           ctTemplateContent_t* templateContent)
{
   if( !templateDetails && !templateContent ) {
      // Nothing to do
      return 0;
   }
   if( templateDetails ) {
      templateDetails->_makeempty();
   }
   if( templateContent ) {
      templateContent->_makeempty();
   }
   if( !_ctIsTemplateFile(filename) ) {
      return VSRC_INVALID_ARGUMENT;
   }
   int h = _ctTemplateOpen(filename);
   if( h<0 ) {
      return h;
   }

   int status = 0;
   do {

      _str Version = _ctTemplate_GetTemplateVersion(h);
      if( !_ctTemplateIsValidVersion(Version) ) {
         status=VSRC_INVALID_ARGUMENT;
         break;
      }
      _str Type = _ctTemplate_GetTemplateType(h);
      if( !_ctTemplateIsValidType(Type) ) {
         status=VSRC_INVALID_ARGUMENT;
         break;
      }
      if( templateDetails ) {
         status=_ctTemplate_GetTemplateDetails(h,*templateDetails);
         if( status!=0 ) {
            break;
         }
      }
      if( templateContent ) {
         status=_ctTemplate_GetTemplateContent(h,*templateContent);
         if( status!=0 ) {
            break;
         }
      }

   } while( false );

   _ctTemplateClose(h);

   return status;
}

/**
 * Save template details and template content to template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_SetTemplateDetails, _ctTemplate_SetTemplateContent,
 * _ctTemplateSave, _ctTemplateClose if you want to retrieve from a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * @param templateDetails Template details object.
 * @param templateContent Template content object.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplatePutTemplateDetails
 * @see _ctTemplatePutTemplateContent
 */
int _ctTemplatePutTemplate(_str filename,
                           ctTemplateDetails_t& templateDetails,
                           ctTemplateContent_t& templateContent)
{
   int h = _ctTemplateOpen(filename);
   if( h<0 ) {
      return h;
   }

   int status = 0;
   do {

      // Version sanity please
      _str Version = _ctTemplate_GetTemplateVersion(h);
      if( !_ctTemplateIsValidVersion(Version) ) {
         Version=CT_VERSION;
      }
      status=_ctTemplate_SetTemplateVersion(h,Version);
      if( status!=0 ) {
         break;
      }
      // Type sanity please
      _str Type = _ctTemplate_GetTemplateType(h);
      if( !_ctTemplateIsValidType(Type) ) {
         // The one-and-only
         Type="Item";
      }
      status=_ctTemplate_SetTemplateType(h,Type);
      if( status!=0 ) {
         break;
      }

      if( templateDetails!=null ) {
         status=_ctTemplate_SetTemplateDetails(h,templateDetails);
         if( status!=0 ) {
            break;
         }
      }
      if( templateContent!=null ) {
         status=_ctTemplate_SetTemplateContent(h,templateContent);
         if( status!=0 ) {
            break;
         }
      }

   } while( false );

   status=_ctTemplateSave(h,filename);
   _ctTemplateClose(h);

   return status;
}

/**
 * Retrieve template details from template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_GetTemplateDetails, _ctTemplateClose
 * if you want to retrieve from a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateGetTemplateContent
 */
int _ctTemplateGetTemplateDetails(_str filename, ctTemplateDetails_t& templateDetails)
{
   int status = _ctTemplateGetTemplate(filename,&templateDetails,null);
   return status;
}

/**
 * Save template details to template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_SetTemplateDetails, _ctTemplateSave, _ctTemplateClose
 * if you want to save to a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * @param templateDetails Template details object.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplatePutTemplateContent
 * @see _ctTemplateGetTemplateDetails
 */
int _ctTemplatePutTemplateDetails(_str filename, ctTemplateDetails_t& templateDetails)
{
   int status = _ctTemplatePutTemplate(filename,templateDetails,null);
   return status;
}

/**
 * Retrieve template content from template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_GetTemplateContent, _ctTemplateClose
 * if you want to retrieve from a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * @param templateContent (output). ctTemplateContent_t object to store 
 *                        content.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateGetTemplateDetails
 */
int _ctTemplateGetTemplateContent(_str filename, ctTemplateContent_t& templateContent)
{
   int status = _ctTemplateGetTemplate(filename,null,&templateContent);
   return status;
}

/**
 * Save template content to template file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctTemplate_SetTemplateContent, _ctTemplateSave, _ctTemplateClose
 * if you want to save to a template file by XMLCFG handle.
 * 
 * @param filename Template filename.
 * @param templateContent Template content object.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplatePutTemplateDetails
 * @see _ctTemplateGetTemplateContent
 */
int _ctTemplatePutTemplateContent(_str filename, ctTemplateContent_t& templateContent)
{
   int status = _ctTemplatePutTemplate(filename,null,templateContent);
   return status;
}


//
// Options
//

/**
 * @return Absolute path to user options file.
 */
_str _ctOptionsGetOptionsFilename()
{
   return ( _ConfigPath():+CT_ROOT_DIR:+FILESEP:+CTOPTIONS_FILENAME );
}

int _ctOptionsMaybeCreate(_str filename)
{
   boolean recreate = false;
   int status = 0;
   int handle = -1;
   filename=absolute(filename);
   _str dir = _strip_filename(filename,'n');
   _maybe_strip_filesep(dir);
   if( !isdirectory(dir) ) {
      // Typically, the user templates directory is created on startup if it
      // does not exist. If, however, the user templates directory is not 
      // created, we must create it now.
      make_path(dir);
   }
   if( !file_exists(filename) ) {
      handle = _xmlcfg_create(filename,VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);
   } else {
      handle = _xmlcfg_open(filename,status,VSXMLCFG_OPEN_ADD_PCDATA|VSXMLCFG_OPEN_REFCOUNT);
      if( handle<0 || status<0 ) {
         handle = handle<0 ? handle : status;
      }
   }
   if( handle<0 ) {
      return handle;
   }
   int node = _xmlcfg_find_simple(handle,CTXPATH_OPTIONS_ROOT);
   if( node<0 ) {
      // Clear and recreate
      _xmlcfg_delete(handle,TREE_ROOT_INDEX,true);
      node=_xmlcfg_add(handle,TREE_ROOT_INDEX,"DOCTYPE",VSXMLCFG_NODE_DOCTYPE,VSXMLCFG_ADD_AS_CHILD);
      if( node<0 ) {
         _xmlcfg_close(handle);
         return node;
      }
      _xmlcfg_set_attribute(handle,node,"root",CTTAG_OPTIONS_ROOT);
      _xmlcfg_set_attribute(handle,node,"SYSTEM",CTOPTIONS_DTD_PATH);
      _xmlcfg_set_path(handle,CTXPATH_OPTIONS_ROOT,"Version",CTOPTIONS_VERSION);
      recreate=true;
   }
   if( recreate ) {
      status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE,filename);
      if( status!=0 ) {
         _xmlcfg_close(handle);
         return status;
      }
      handle = _xmlcfg_open(filename,status,VSXMLCFG_OPEN_ADD_PCDATA|VSXMLCFG_OPEN_REFCOUNT);
      if( handle<0 || status<0 ) {
         return ( handle<0 ? handle : status );
      }
   }
   node=_xmlcfg_set_path(handle,CTXPATH_OPTIONS_ROOT,"Version",CTOPTIONS_VERSION);
   if( node<0 ) {
      _xmlcfg_close(handle);
      return node;
   }
   return handle;
}

/**
 * Retrieve options version.
 * 
 * @param handle Handle to open options file. Use _ctTemplateOpen to open an options
 *               file.
 * 
 * @return String value version.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
_str _ctOptions_GetVersion(int handle)
{
   _str Version = "";
   int node = _xmlcfg_find_simple(handle,CTXPATH_OPTIONS_ROOT);
   if( node>=0 ) {
      Version=_xmlcfg_get_attribute(handle,node,"Version");
   }
   return strip(Version);
}

/**
 * Set options version.
 * 
 * @param handle
 * @param Version
 * 
 * @return 0 on success, <0 on error.
 */
int _ctOptions_SetVersion(int handle, _str Version)
{
   int status = 0;
   int node = _xmlcfg_set_path(handle,CTXPATH_OPTIONS_ROOT);
   if( node>=0 ) {
      status=_xmlcfg_set_attribute(handle,node,"Version",strip(Version));
   } else {
      // Error
      status=node;
   }
   return status;
}

/**
 * Retrieve parameters for options.
 * 
 * @param handle Handle to open options file. Use _ctTemplateOpen to open an options file.
 * @param params (output). Hash table of parameter values indexed by parameter name. <br>
 *               Example: params:['foo'].Value="bar" where 'foo' is the parameter name and "bar"
 *               is the parameter value.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
void _ctOptions_GetParameters(int handle, ctTemplateContent_ParameterValue_t (&params):[])
{
   params._makeempty();
   typeless nodea[]; nodea._makeempty();
   int status = _xmlcfg_find_simple_array(handle,CTXPATH_OPTIONS_PARAMETER,nodea);
   if( status==0 ) {
      int i;
      for( i=0; i<nodea._length(); ++i ) {
         _str Name = _xmlcfg_get_attribute(handle,nodea[i],"Name");
         // Substitution parameters are case-insensitive
         Name=lowcase(Name);
         if( Name!="" ) {
            _str Value = _xmlcfg_get_attribute(handle,nodea[i],"Value");
            params:[Name].Value=Value;
            _str val = _xmlcfg_get_attribute(handle,nodea[i],"Prompt");
            boolean Prompt = ( val!="" && val!="0" );
            params:[Name].Prompt=Prompt;
            _str PromptString = _xmlcfg_get_attribute(handle,nodea[i],"PromptString");
            params:[Name].PromptString=PromptString;
         }
      }
   }
}

/**
 * Set parameters for options.
 * 
 * @param handle Handle to open options file. Use _ctTemplateOpen to open an options
 *               file.
 * @param Files  Hash table of ctTemplateContent_ParameterValue_t objects.
 *               Hash table is indexed by parameter name.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctOptions_SetParameters(int handle, ctTemplateContent_ParameterValue_t (&Parameters):[])
{
   int status = 0;
   int parent = _xmlcfg_set_path(handle,CTXPATH_OPTIONS_PARAMETERS);
   if( parent>=0 ) {
      _xmlcfg_delete_children_with_name(handle,parent,CTTAG_PARAMETER);
      _str Name;
      for( Name._makeempty();; ) {
         Parameters._nextel(Name);
         if( Name._isempty() ) {
            // Done
            break;
         }
         int node = _xmlcfg_add(handle,parent,CTTAG_PARAMETER,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         if( node<0 ) {
            // Error
            status=node;
            break;
         }
         _xmlcfg_add_attribute(handle,node,"Name",Name);
         _xmlcfg_add_attribute(handle,node,"Value",strip(Parameters:[Name].Value));
         if( Parameters:[Name].Prompt || Parameters:[Name].PromptString != "" ) {
            _xmlcfg_add_attribute(handle,node,"Prompt",(_str)Parameters:[Name].Prompt);
            _xmlcfg_add_attribute(handle,node,"PromptString",strip(Parameters:[Name].PromptString));
         }
      }
   } else {
      // Error
      status=parent;
   }
   return status;
}

/**
 * Retrieve options object.
 * 
 * @param handle Handle to open options file. Use _ctTemplateOpen to open 
 *               an options file.
 * @param options (output). ctOptions_t object in which to store options.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctOptions_GetOptions(int handle, ctOptions_t& options)
{
   options._makeempty();

   ctTemplateContent_ParameterValue_t Parameters:[]; Parameters._makeempty();
   _ctOptions_GetParameters(handle,Parameters);

   options.Parameters=Parameters;

   return 0;
}

/**
 * Set options from ctOptions_t object.
 * 
 * @param handle Handle to open options file. Use _ctTemplateOpen to open 
 *               an options file.
 * @param options ctOptions_t object from which options settings come.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctTemplateOpen
 * @see _ctTemplateClose
 */
int _ctOptions_SetOptions(int handle, ctOptions_t& options)
{
   int status = 0;
   status=_ctOptions_SetParameters(handle,options.Parameters);
   return status;
}

boolean _ctOptionsIsValidVersion(_str Version)
{
   _str testMajor, testMinor, testRev, testBuild;
   normalizeVSEVersion(Version,testMajor,testMinor,testRev,testBuild);
   _str major, minor, rev, build;
   normalizeVSEVersion(CTOPTIONS_VERSION,major,minor,rev,build);
   return ( testMajor==major && testMinor==minor && testRev==rev );
}

/**
 * Retrieve options from options file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctOptions_GetOptions, _ctTemplateClose
 * if you want to retrieve from an options file by XMLCFG handle.
 * 
 * @param filename Options filename.
 * @param options  ctOptions_t object to store options.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctOptionsSetOptions
 */
int _ctOptionsGetOptions(_str filename, ctOptions_t& options)
{
   int h = _ctOptionsMaybeCreate(filename);
   if( h<0 ) {
      return h;
   }

   int status = 0;
   do {

      _str Version = _ctOptions_GetVersion(h);
      if( !_ctOptionsIsValidVersion(Version) ) {
         status=VSRC_INVALID_ARGUMENT;
         break;
      }
      status=_ctOptions_GetOptions(h,options);
      if( status!=0 ) {
         break;
      }

   } while( false );

   _ctTemplateClose(h);

   return status;
}

/**
 * Save options to options file.
 * <p>
 * Note: <br>
 * Use _ctTemplateOpen, _ctOptions_SetOptions, _ctTemplateSave, _ctTemplateClose if you
 * want to save to an options file by XMLCFG handle.
 * 
 * @param filename Options filename.
 * @param templateContent ctOptions_t object.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see _ctOptionsGetOptions
 */
int _ctOptionsPutOptions(_str filename, ctOptions_t& options)
{
   int h = _ctOptionsMaybeCreate(filename);
   if( h<0 ) {
      return h;
   }

   int status = 0;
   do {

      // Version sanity please
      _str Version = _ctOptions_GetVersion(h);
      if( !_ctOptionsIsValidVersion(Version) ) {
         Version=CTOPTIONS_VERSION;
      }
      status=_ctOptions_SetVersion(h,Version);
      if( status!=0 ) {
         break;
      }

      if( options!=null ) {
         status=_ctOptions_SetOptions(h,options);
         if( status!=0 ) {
            break;
         }
      }

   } while( false );

   status=_ctTemplateSave(h,filename);
   _ctTemplateClose(h);

   return status;
}

/**
 * Imports the options (parameters) from one code template options file to 
 * the current code template options file.
 * 
 * @param newOptsFilename           new options file to import
 * 
 * @return                          0 if import was successful, error code 
 *                                  otherwise
 */
int _ctOptions_ImportOptions(_str newOptsFilename)
{
   // open up the current code template options file
   curOptsFilename := _ctOptionsGetOptionsFilename();

   ctOptions_t curOptions;
   status := _ctOptionsGetOptions(curOptsFilename, curOptions);
   if( status ) {
      // there was a problem opening up the file, so just copy the new one over
      return copy_file(newOptsFilename, curOptsFilename);
   }

   ctOptions_t newOptions;
   status = _ctOptionsGetOptions(newOptsFilename, newOptions);
   if( status ) {
      return status;
   }

   // now we add the new params to the existing ones
   ctTemplateContent_ParameterValue_t param;
   changed := false;
   foreach( auto name => param in newOptions.Parameters ) {
      curOptions.Parameters:[name] = param;
      changed = true;
   }

   if( changed ) {
      return _ctOptionsPutOptions(curOptsFilename, curOptions);
   }

   return 0;
}

// Default word chars to use when the caller does not provide them
#define CODEHELP_DEFAULT_WORD_CHARS "A-Za-z0-9_"

static _str makeSafeString(_str s, _str charSet=CODEHELP_DEFAULT_WORD_CHARS)
{
   if( s=="" ) {
      return "";
   }

   // Find a good all-around substitution character for unsafe characters in s (e.g. underscore _).
   // Favor underscore because it should work for most languages.
   _str repch = '';
   if( pos("["charSet"]",'_',1,'er') > 0 ) {
      repch='_';
   }
   if( repch=="" ) {
      // Cannot use underscore, so look for something else
      _str cs = charSet;

      // Eliminate ranges
      while( pos('-',cs) ) {
         _str before, after;
         parse cs with before'-'after;
         cs=substr(before,1,length(before)-1):+substr(after,2);
         // Not worried about escaped ranges for now
      }
      // Letters and numbers are just not acceptable
      if( pos("[~A-Za-z0-9]",cs,1,'er') ) {
         repch=substr(cs,pos('S'),1);
      }
   }
   // If we do not have a repch at this point, then we will just elide any offending characters

   _str result = s;
   result=stranslate(s,repch,"[~"charSet"]",'er');
   return result;
}

static _str getProjectType(_str projectName=_project_name)
{
   if( _IsVSEProjectFilename(projectName) ) {
      _str vendorProjectName, vendorProjectType;
      int status = _GetAssociatedProjectInfo(projectName,vendorProjectName,vendorProjectType);
      if( status==0 && vendorProjectType!="" ) {
         return vendorProjectType;
      }
   }

   // Try harder
   _str projectType = "";
   _str ext = _get_extension(projectName,true);
   if( file_eq(ext,VCPP_PROJECT_FILE_EXT) ) {
      projectType=VCPP_VENDOR_NAME;
   } else if( file_eq(ext,TORNADO_PROJECT_EXT) ) {
      projectType=TORNADO_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_VCPP_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_VCPP_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_CSHARP_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_VB_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_JSHARP_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_FSHARP_VENDOR_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_TEMPLATE_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_TEMPLATE_NAME;
   } else if( file_eq(ext,VISUAL_STUDIO_DATABASE_PROJECT_EXT) ) {
      projectType=VISUAL_STUDIO_DATABASE_NAME;
   } else if( file_eq(ext,JBUILDER_PROJECT_EXT) ) {
      projectType=JBUILDER_VENDOR_NAME;
   } else if( file_eq(ext,XCODE_PROJECT_LONG_BUNDLE_EXT) || file_eq(ext,XCODE_PROJECT_SHORT_BUNDLE_EXT) ) {
      projectType=XCODE_PROJECT_VENDOR_NAME;
   } else if( file_eq(ext,MACROMEDIA_FLASH_PROJECT_EXT) ) {
      projectType=MACROMEDIA_FLASH_VENDOR_NAME;
   }
   return projectType;
}

static boolean isJavaProjectType(_str projectType)
{
   if( projectType=="" ) {
      return false;
   }
   switch( projectType ) {
   case VISUAL_STUDIO_JSHARP_VENDOR_NAME:
   case JBUILDER_VENDOR_NAME:
      return true;
   }
   // Not a Java project type
   return false;
}

static boolean isCSharpProjectType(_str projectType)
{
   if( projectType=="" ) {
      return false;
   }
   switch( projectType ) {
   case VISUAL_STUDIO_CSHARP_VENDOR_NAME:
   case VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME:
      return true;
   }
   // Not a CSharp project type
   return false;
}

static boolean isCppProjectType(_str projectType)
{
   if( projectType=="" ) {
      return false;
   }
   switch( projectType ) {
   case VCPP_VENDOR_NAME:
   case TORNADO_VENDOR_NAME:
   case VISUAL_STUDIO_VCPP_VENDOR_NAME:
      return true;
   }
   // Not a C++ project type
   return false;
}

static _str getProjectBuildCmdline(_str projectName=_project_name)
{
   _str cmdline = "";
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(projectName,handle,config);
   if( handle>=0 ) {
      int buildTargetNode = _ProjectGet_TargetNode(handle,'build',config);
      if( buildTargetNode>0 ) {
         cmdline=_ProjectGet_TargetCmdLine(handle,buildTargetNode,true);
      }
   }
   return cmdline;
}

static boolean isJavaBuildCmdline(_str cmdline)
{
   if( cmdline=="" ) {
      return false;
   }
   _str cmd = parse_file(cmdline);
   cmd=strip(cmd,'B','"');
   cmd=_strip_filename(cmd,'pe');
   if( cmd=="javac" ) {
      return true;
   }
   // Not a Java build command line
   return false;
}

static boolean isCSharpBuildCmdline(_str cmdline)
{
   if( cmdline=="" ) {
      return false;
   }
   _str cmd = parse_file(cmdline);
   cmd=strip(cmd,'B','"');
   cmd=_strip_filename(cmd,'pe');
   if( cmd=="csc" ) {
      return true;
   }
   // Not a C# build command line
   return false;
}

static boolean isCppBuildCmdline(_str cmdline)
{
   if( cmdline=="" ) {
      return false;
   }
   _str cmd = parse_file(cmdline);
   cmd=strip(cmd,'B','"');
   cmd=_strip_filename(cmd,'pe');
   if( cmd=="cl" || cmd=="gcc" || cmd=="g++" || 
       cmd=="gcc-3" || cmd=="gcc-4" || 
       cmd=="g++-3" || cmd=="g++-4" ) {
      return true;
   }
   // Not a C++ build command line
   return false;
}

static _str getProjectMainName(_str projectName=_project_name, _str projectType=null, _str projectBuildCmdline=null)
{
   _str type = projectType;
   _str cmdline = projectBuildCmdline;
   _str mainName = "";

   if( type!=null && type!="" ) {
      type=getProjectType(projectName);
   }
   if( type=="" ) {
      // Try looking at the build command line
      if( cmdline==null || cmdline=="" ) {
         cmdline=getProjectBuildCmdline(projectName);
      }
   }
   if( isJavaProjectType(type) || isJavaBuildCmdline(cmdline) ) {
      mainName="main";
   } else if( isCSharpProjectType(type) || isCSharpBuildCmdline(cmdline) )  {
      mainName="Main";
   } else if( isCppProjectType(type) || isCppBuildCmdline(cmdline) ) {
      mainName="main";
   }
   return mainName;
}

static _str findMainNamespace()
{
   _str projectType = "";
   _str projectBuildCmdline = "";
   _str mainName = "";
   _str ns_list[]; ns_list._makeempty();

   int status = tag_read_db(_strip_filename(_workspace_filename,'e'):+TAG_FILE_EXT);
   if( status>=0 ) {

      projectType=getProjectType();
      projectBuildCmdline=getProjectBuildCmdline();

      mainName=getProjectMainName(_project_name,projectType,projectBuildCmdline);
      if( mainName!="" ) {
         // We recognize the type of project we are in and can make a good guess
         // as to the type of "main" (or "Main") we are looking for.
         status=tag_find_equal(mainName,true);
      } else {
         // Desperation
         mainName="Main";
         status=tag_find_equal(mainName,true);
         if( status!=0 ) {
            mainName="main";
            status=tag_find_equal(mainName,true);
         }
      }
      while( status==0 ) {
         _str filename, signature, type_name, package;
         int tag_flags;
         _str tag_class;
         tag_get_detail(VS_TAGDETAIL_file_name,filename);
         tag_get_detail(VS_TAGDETAIL_arguments,signature);
         tag_get_detail(VS_TAGDETAIL_type,type_name);
         tag_get_detail(VS_TAGDETAIL_flags,tag_flags);
         tag_get_detail(VS_TAGDETAIL_class_name,tag_class);
         if( _FileExistsInCurrentProject(filename) ) {

            // Used to indicate a match on the main() function signature for
            // the source code extension.
            boolean sig_match = false;
            _str lang = _Filename2LangId(filename);
            if( _LanguageInheritsFrom("java",lang) &&
                (isJavaBuildCmdline(projectBuildCmdline) || projectType=="" || isJavaProjectType(projectType)) ) {

               if( 
                   ( 0!=(tag_flags & VS_TAGFLAG_static) && tag_tree_type_is_func(type_name) ) ||
                   0==tag_tree_compare_args(signature,VS_TAGSEPARATOR_args:+"String args[]",true)
                 ) {
                  sig_match=true;
               }
            } else if( _LanguageInheritsFrom("cs",lang) &&
                       (isCSharpBuildCmdline(projectBuildCmdline) || projectType=="" || isCSharpProjectType(projectType)) ) {

               // C# is very loose about the signature for main()
               if( 0!=(tag_flags & VS_TAGFLAG_static) && tag_tree_type_is_func(type_name) ) {
                  sig_match=true;
               }
            } else if( _LanguageInheritsFrom("c",lang) &&
                       (isCppBuildCmdline(projectBuildCmdline) || projectType=="" || isCppProjectType(projectType)) ) {

               // You can have main() inside a namespace if you extern "C" it. Go figure.

               // C++ is very loose about the signature for main()
               if( 0==(tag_flags & VS_TAGFLAG_static) && tag_tree_type_is_func(type_name) ) {
                  sig_match=true;
               }
            }

            if( sig_match ) {
               _str className;
               parse tag_class with package VS_TAGSEPARATOR_package className;
               if( className=="" ) {
                  className=package;
                  package="";
               }
               //say('findMainNamespace: tag_class='tag_class);
               //say('findMainNamespace: className='className);
               //say('findMainNamespace: package='package);
               if( package!="" ) {
                  ns_list[ns_list._length()]=package;
               }
            }
         }
         status=tag_next_equal(true);
      }
      tag_reset_find_tag();
   }

   // No matches or too many matches?
   if( ns_list._length() == 0 || ns_list._length() > 1 ) {

      if( isCSharpBuildCmdline(projectBuildCmdline) ) {
         // Look for a '/main:classname' switch in the build command to determine
         // the namespace we want.
         _str className = "";
         _str cmdline = _parse_project_command(projectBuildCmdline,"",_project_name,"");
         _str opt;
         while( cmdline!="" ) {
            opt=parse_file(cmdline,false);
            if( lowcase(substr(opt,1,length("/main:"))) == "/main:" ) {
               parse opt with "/main:",'i' className;
               break;
            }
         }
         if( className!="" ) {
            // Found a class or namespace
            ns_list._makeempty();
            ns_list[0]=className;
         }
      }
   }

   // 1/30/2006 - RB
   // For now just take the first namespace in the list. Might want
   // to prompt for which namespace to use in future.
   return ( ns_list._length()>0 ? ns_list[0] : "" );
}

/**
 * Pre-process string by replacing substitution parameters with instantiated value parts.
 * <p>
 * This can be used by OEMs and VARs to provide customized parameter substitution.
 * For example: $tipoftheday$ might evaluate to a different tip each time it
 * is instantiated (e.g. "Use the ??? library to ...").
 * <p>
 * Note: <br>
 * If the OEM or VAR needs to process content BEFORE normal processing (e.g. in
 * order to insert generated code that uses substitution parameters, etc.), then
 * they should use the _ctPreProcessContent_ callback mechanism {@link _ctPreProcessContent}.
 * <p>
 * Note: <br>
 * If the OEM or VAR needs to process content AFTER normal processing, then
 * they should use the _ctPostProcessContent_ callback mechanism {@link _ctPostProcessContent}.
 * 
 * @param s            String to process.
 * @param itemName     Template item name. Used for substitution parameters that
 *                     require parts of item name.
 * @param itemLocation Template item location. Used for substitution parameters
 *                     that require parts of item location.
 * @param params       (output). Cache of substitution parameters. As
 *                     parameter values are computed they are cached in this hash
 *                     table so they do not have to be recomputed later.
 *                     Hash table is indexed by parameter name.
 * @param delim        Delimiter to use when searching for substitution parameters.
 * @param wordChars    Word characters that make up a valid identifier. Used when computing
 *                     a "safe" substitution value (e.g. $safeitemname$).
 *                     This is in the format of the p_word_chars property.
 *
 * @return Processed string with all substitution parameters replaced with values.
 * 
 * @see _ctPreProcessContent
 * @see _ctPostProcessContent
 * 
 * @example
 * To have your custom function called to pre-process a string, define
 * a Slick-C&reg; function with the following signature:
 * 
 * <pre>
 * int _ctPreProcessContentString_[custom-name](_str s, _str itemName, _str itemLocation,
 *                                        ctTemplateContent_ParameterValue (&params):[],
 *                                        _str delim, _str wordChars)
 * {
 *    // TODO: your code here
 * }
 * </pre>
 * 
 * Fhe function parameters correspond exactly to those passed in to
 * this function.
 * <p>
 * Your callback returns the processed string. If no substitutions are
 * made, then return the string passed in with no changes.
 */
static _str preProcessContentString(_str s, _str itemName, _str itemLocation,
                                    ctTemplateContent_ParameterValue_t (&params):[],
                                    _str delim, _str wordChars)
{
   _str result = s;
   int list[]; list._makeempty();
   int index = name_match("_ctPreProcessContentString_",1,PROC_TYPE);
   while( index>0 && index_callable(index) ) {
      list[list._length()]=index;
      index = name_match("_ctPreProcessContentString_",0,PROC_TYPE);
   }
   int i;
   for( i=0; i<list._length(); ++i ) {
      result=call_index(result,itemName,itemLocation,params,delim,wordChars,list[i]);
   }
   return result;
}

boolean _ctIsPredefinedParameter(_str Name)
{
   switch( Name ) {
   case "itemname":
   case "inputfilename":
   case "fileinputname":
   case "safeitemrootname":
   case "safeitemname":
   case "lowcaseitemname":
   case "lowcasesafeitemname":
   case "lowcaseinputfilename":
   case "upcaseitemname":
   case "upcasesafeitemname":
   case "upcaseinputfilename":
   case "tempdir":
   case "systemplatedir":
   case "usertemplatedir":
   case "rootnamespace":
   case "rootpackage":
   case "ampmtime":
   case "localtime":
   case "time":
   case "date":
   case "localdate":
   case "year":
   case "safeprojectname":
   case "projectname":
   case "safeworkspacename":
   case "workspacename":
   case "projectworkingdir":
   case "projectbuilddir":
   case "projectconfigname":
   case "workspaceconfigname":
   case "projectdir":
   case "workspacedir":
   case "username":
      return true;
   }
   // Not a pre-defined parameter name
   return false;
}

/**
 * Process string by replacing substitution parameters with instantiated value parts.
 * 
 * @param s             String to process.
 * @param itemName      Template item name. Used for substitution parameters that
 *                      require parts of item name.
 * @param itemLocation  Template item location. Used for substitution parameters
 *                      that require parts of item location.
 * @param params        (output). Cache of substitution parameters. As
 *                      parameter values are computed they are cached in this hash
 *                      table so they do not have to be recomputed later.
 *                      Hash table is indexed by parameter name.
 * @param paramsVisited (optional) (output). Hash table of substitution parameters actually 
 *                      visited (used). As parameters are visited they are stored in this 
 *                      in this hash table. Useful for determining whether a prompt-able
 *                      parameter should actually be prompted for.
 *                      Hash table is indexed by parameter name.
 * @param delim         Delimiter to use when searching for substitution parameters.
 * @param wordChars     Word characters that make up a valid identifier. Used when computing
 *                      a "safe" substitution value (e.g. $safeitemname$).
 *                      This is in the format of the p_word_chars property.
 * @param lang          (optional). The language ID of the content we are processing.
 *                      Example: 'c', 'java'.
 *                      Defaults to "".
 *
 * @return Processed string with all substitution parameters replaced with values.
 */
_str _ctProcessContentString(_str s, _str itemName, _str itemLocation,
                             ctTemplateContent_ParameterValue_t (&params):[],
                             ctTemplateContent_ParameterValue_t (&paramsVisited):[]=null,
                             _str delim='$', _str wordChars=CODEHELP_DEFAULT_WORD_CHARS, _str lang="")
{
   if( wordChars=="" ) {
      wordChars=CODEHELP_DEFAULT_WORD_CHARS;
   }
   if( delim=='' ) {
      delim=CTPARAMETER_DELIM;
   }
   // '\$[a-zA-Z0-9_]#\$'
   _str re = _escape_re_chars(delim):+CTPARAMETER_NAME_RE:+_escape_re_chars(delim);
   _str result = s;
   int i = pos("{"re"}",result,1,'er');
   while( i>0 ) {
      _str rep = null;
      _str parm = substr(result,pos('S0'),pos('0'));
      _str orig_parm = parm;
      _str before = substr(result,1,pos('S0')-1);
      _str after = substr(result,pos('S0')+pos('0'));
      parm=lowcase( strip(parm,'B',delim) );
      if( parm=="" ) {
         // This means a double delimiter '$$' which evaluates to '$'
         rep=delim;
      } else if( params._indexin(parm) ) {
         if( params:[parm].Prompt || params:[parm].Value._isempty() ) {
            // User wants to be prompted for this parameter value OR
            // user was prompted and hit ESC on the dialog before filling
            // in a value.
            rep=orig_parm;
         } else {
            // Cached value
            rep=params:[parm].Value;
         }
         paramsVisited:[parm]=params:[parm];
      } else {
         switch( parm ) {
         case "itemname":
         // RB - 1/26/2006
         // I have a hard time keeping "inputfilename" and "fileinputname"
         // straight, so let's support both.
         case "inputfilename":
         case "fileinputname":
            {
               // Name part, no extension
               _str itemNameName = _strip_filename(itemName,'pe');
               rep=itemNameName;
            }
            break;
         case "lowcaseitemname":
         case "lowcaseinputfilename":
            {
               // Name part, no extension, lower-cased
               _str itemNameName = _strip_filename(itemName,'pe');
               rep=lowcase(itemNameName);
            }
            break;
         case "upcaseitemname":
         case "upcaseinputfilename":
            {
               // Name part, no extension, upper-cased
               _str itemNameName = _strip_filename(itemName,'pe');
               rep=upcase(itemNameName);
            }
            break;
         case "safeitemrootname":
         case "safeitemname":
         case "upcasesafeitemname":
         case "lowcasesafeitemname":
            {
               // Name part, no extension
               _str itemNameName = _strip_filename(itemName,'pe');
               rep=makeSafeString(itemNameName,wordChars);
               if( parm=="upcasesafeitemname" ) {
                  rep=upcase(rep);
               } else if( parm=="lowcasesafeitemname" ) {
                  rep=lowcase(rep);
               }
            }
            break;
         case "tempdir":
            rep=_temp_path();
            _maybe_strip_filesep(rep);
            break;
         case "systemplatedir":
            rep=_ctGetSysItemTemplatesDir();
            break;
         case "usertemplatedir":
            rep=_ctGetUserItemTemplatesDir();
            break;
         case "rootnamespace":
         case "rootpackage":
            rep=findMainNamespace();
            if( rep=="" ) {
               // Prompt for it
               rep=orig_parm;
               // Pick a nice default value
               _str Value = _parse_project_command("%rn","",_project_name,"");
               Value=makeSafeString(Value,wordChars);
               if( Value=="" ) {
                  Value=_strip_filename(itemName,'pe');
                  Value=makeSafeString(Value,wordChars);
               }
               params:[parm].Value=Value;
               params:[parm].Prompt=true;
               if( _LanguageInheritsFrom("java",lang) ) {
                  params:[parm].PromptString="Root package";
               } else {
                  params:[parm].PromptString="Root namespace";
               }
            }
            break;
         case "ampmtime":
            rep=_time('T');
            break;
         case "localtime":
#if __UNIX__
            rep=_time('M');
#else
            // Locale dependent
            rep=_time('L');
#endif
            break;
         case "time":
            rep=_time('M');
            break;
         case "date":
            rep=_date('U');
            break;
         case "localdate":
#if __UNIX__
            rep=_date('U');
#else
            // Locale dependent
            rep=_date('L');
#endif
            break;
         case "year":
            parse _date('U') with .'/'.'/'rep;
            break;
         case "safeprojectname":
         case "projectname":
            if (!isEclipsePlugin()) {
               rep=_parse_project_command("%rn","",_project_name,"");
            } else {
               _eclipse_get_active_project_name(rep);
            }
            if( parm=="safeprojectname" ) {
               rep=makeSafeString(rep,wordChars);
            }
            break;
         case "safeworkspacename":
         case "workspacename":
            if (!isEclipsePlugin()) {
               rep=_parse_project_command("%wn","",_project_name,"");
            } else {
               _eclipse_get_workspace_name(rep);
            }
            if( parm=="safeworkspacename" ) {
               rep=makeSafeString(rep,wordChars);
            }
            break;
         case "projectworkingdir":
            if (!isEclipsePlugin()) {
               rep=_parse_project_command("%rw","",_project_name,"");
            } else {
               _eclipse_get_project_dir(rep);
            }
            _maybe_strip_filesep(rep);
            break;
         case "projectbuilddir":
            rep=_parse_project_command("%bd","",_project_name,"");
            _maybe_strip_filesep(rep);
            break;
         case "projectconfigname":
            rep=_parse_project_command("%bn","",_project_name,"");
            break;
         case "workspaceconfigname":
            // Visual Studio solution configuration
            rep=_parse_project_command("%b","",_project_name,"");
            break;
         case "projectdir":
            if (!isEclipsePlugin()) {
               rep=_parse_project_command("%rp","",_project_name,"");
            } else {
               _eclipse_get_project_dir(rep);
            }
            _maybe_strip_filesep(rep);
            break;
         case "workspacedir":
            if (!isEclipsePlugin()) {
               rep=_parse_project_command("%wp","",_project_name,"");
            } else {
               _eclipse_get_workspace_name(rep);
            }
            _maybe_strip_filesep(rep);
            break;
         case "username":
#if __UNIX__
            rep=get_env("USER");
            if( rep=="" ) {
               rep=get_env("LOGNAME");
            }
#else
            rep=get_env("USERNAME");
#endif
            break;
         }
         if( rep==null ) {
            // Undefined parameter, so store it and set the Prompt indicator
            params:[parm].Value=null;
            params:[parm].Prompt=true;
            params:[parm].PromptString="";
            // Stick it back in exactly the way we found it
            rep=orig_parm;
         } else if( rep==orig_parm ) {
            // Replacing with original delimited parameter name, so force a
            // prompt on this parameter (probably 'rootnamespace').
            params:[parm].Prompt=true;
         } else if( rep!="" ) {
            // Store this for later so we do not have to recompute
            params:[parm].Value=rep;
            params:[parm].Prompt=false;
            params:[parm].PromptString="";
         }
         paramsVisited:[parm]=params:[parm];
      }
      result=before:+rep:+after;
      i = pos("{"re"}",result,length(before:+rep)+1,'er');
   }
   return result;
}

/**
 * Give an OEM or VAR the opportunity to customize content before we start
 * processing the file.
 * <p>
 * This would be ideal for an OEM that generates custom blocks of code but
 * still wants to take advantage of our subsitution parameters by using them.
 * in their generated code.
 * <p>
 * Note: <br>
 * If the OEM or VAR needs to process content AFTER normal processing, then
 * they should use the _ctPostProcessContent_ callback mechanism {@link _ctPostProcessContent}.
 * <p>
 * Note: <br>
 * If the OEM or VAR is only providing custom parameters for substitution,
 * then they should use the _ctPreProcessString_ callback mechanism {@link _ctPreProcessString}.
 * 
 * @param wid          Window id of content.
 * @param itemName     Template item name. Used for substitution parameters that
 *                     require parts of item name.
 * @param itemLocation Template item location. Used for substitution parameters
 *                     that require parts of item location.
 * @param params       (output). Cache of substitution parameter/value pairs. As
 *                     parameter values are computed they are cached in this hash
 *                     table so they do not have to be recomputed later.
 * @param delim        Delimiter to use when searching for substitution parameters.
 * 
 * @return 0 on  success, <0 on error.
 * 
 * @see _ctPostProcessContent
 * @see _ctPreProcessString
 * 
 * @example
 * To have your custom function called to pre-process file content, define
 * a Slick-C&reg; function with the following signature:
 * 
 * <pre>
 * int _ctPreProcessContent_[custom-name](int wid, _str itemName, _str itemLocation,
 *                                        ctTemplateContent_ParameterValue (&params):[],
 *                                        _str delim)
 * {
 *    int orig_wid;
 *    get_window_id(orig_wid);
 *    activate_window(wid);
 *
 *    // TODO: your code here
 *
 *    activate_window(orig_wid);
 * }
 * </pre>
 * 
 * Fhe function parameters correspond exactly to those passed in to
 * this function.
 * <p>
 * Your callback must return 0 on success, or non-zero on
 * error. If non-zero is returned by your function, then instantiation
 * of that file is aborted.
 * <p>
 * IMPORTANT: <br>
 * Your function MUST NOT delete the window passed in.
 */
static int preProcessTemplateContent(int wid, _str itemName, _str itemLocation,
                                     ctTemplateContent_ParameterValue_t (&params):[],
                                     _str delim)
{
   int orig_wid;
   get_window_id(orig_wid);
   if( orig_wid != wid ) {
      activate_window(wid);
   }
   int list[]; list._makeempty();
   int status = 0;
   int index = name_match("_ctPreProcessContent_",1,PROC_TYPE);
   while( index>0 && index_callable(index) ) {
      list[list._length()]=index;
      index = name_match("_ctPreProcessContent_",0,PROC_TYPE);
   }
   int i;
   for( i=0; i<list._length(); ++i ) {
      status=call_index(wid,itemName,itemLocation,params,delim,list[i]);
      if( status!=0 ) {
         break;
      }
   }
   if( orig_wid!=wid ) {
      activate_window(orig_wid);
   }
   return status;
}

/**
 * Post-process content.
 * <p>
 * SlickEdit uses this callback to run language-specific formatters (beautifers)
 * in order to format the code according to user preferences.
 * <p>
 * Give an OEM or VAR the opportunity to post-process content.
 * <p>
 * Note: <br>
 * If the OEM or VAR needs to process content BEFORE normal processing (e.g. in
 * order to insert generated code that uses substitution parameters, etc.), then
 * they should use the _ctPreProcessContent_ callback mechanism {@link _ctPreProcessContent}.
 * <p>
 * Note: <br>
 * If the OEM or VAR is only providing custom parameters for substitution,
 * then they should use the _ctPreProcessString_ callback mechanism {@link _ctPreProcessString}.
 * 
 * @param wid          Window id of content.
 * @param itemName     Template item name. Used for substitution parameters that
 *                     require parts of item name.
 * @param itemLocation Template item location. Used for substitution parameters
 *                     that require parts of item location.
 * 
 * @return 0 on  success, <0 on error.
 * 
 * @see _ctPreProcessContent
 * @see _ctPreProcessString
 * 
 * @example
 * To have your custom function called to post-process file content, define
 * a Slick-C&reg; function with the following signature:
 * 
 * <pre>
 * int _ctPostProcessContent_[custom-name](int wid, _str itemName, _str itemLocation)
 * {
 *    int orig_wid;
 *    get_window_id(orig_wid);
 *    activate_window(wid);
 *
 *    // TODO: your code here
 *
 *    activate_window(orig_wid);
 * }
 * </pre>
 * 
 * Fhe function parameters correspond exactly to those passed in to
 * this function.
 * <p>
 * Your callback must return 0 on success, or non-zero on
 * error. If non-zero is returned by your function, then
 * processing of that file is aborted.
 * <p>
 * IMPORTANT: <br>
 * Your function MUST NOT delete the window passed in.
 */
static int postProcessContent(int wid, _str itemName, _str itemLocation)
{
   int orig_wid;
   get_window_id(orig_wid);
   if( orig_wid != wid ) {
      activate_window(wid);
   }
   int list[]; list._makeempty();
   int status = 0;
   int index = name_match("_ctPostProcessContent_",1,PROC_TYPE);
   while( index>0 && index_callable(index) ) {
      list[list._length()]=index;
      index = name_match("_ctPostProcessContent_",0,PROC_TYPE);
   }
   int i;
   for( i=0; i<list._length(); ++i ) {
      status=call_index(wid,itemName,itemLocation,list[i]);
      if( status!=0 ) {
         break;
      }
   }
   if( orig_wid!=wid ) {
      activate_window(orig_wid);
   }
   return status;
}

/**
 * Process file by replacing substitution parameters with instantiated value parts.
 * 
 * @param filename      File to process.
 * @param itemName      Template item name. Used for substitution parameters that
 *                      require parts of item name.
 * @param itemLocation  Template item location. Used for substitution parameters
 *                      that require parts of item location.
 * @param params        (output). Cache of substitution parameter. As
 *                      parameter values are computed they are cached in this hash
 *                      table so they do not have to be recomputed later.
 *                      Hash table is indexed by paramter name.
 * @param paramsVisited (optional) (output). Hash table of substitution parameters actually 
 *                      visited (used). As parameters are visited they are stored in this 
 *                      in this hash table. Useful for determining whether a prompt-able
 *                      parameter should actually be prompted for.
 *                      Hash table is indexed by parameter name.
 * @param delim         Delimiter to use when searching for substitution parameters.
 *
 * @return 0 on success, <0 on error.
 */
static int processTemplateContentFile(_str filename, _str itemName, _str itemLocation,
                                      ctTemplateContent_ParameterValue_t (&params):[],
                                      ctTemplateContent_ParameterValue_t (&paramsVisited):[]=null,
                                      _str delim='$')
{
   if( delim=='' ) {
      delim=CTPARAMETER_DELIM;
   }
   // '\$[a-zA-Z]#\$'
   _str re = _escape_re_chars(delim):+CTPARAMETER_NAME_RE:+_escape_re_chars(delim);
   int temp_wid, orig_wid;
   boolean buffer_already_exists;
   int status = _open_temp_view(filename,temp_wid,orig_wid,"+d",buffer_already_exists,false,true);
   if( status!=0 ) {
      return status;
   }
   activate_window(temp_wid);
   _str wordChars = temp_wid.p_word_chars;
   if( wordChars=="" ) {
      wordChars=CODEHELP_DEFAULT_WORD_CHARS;
   }
   _str langId = _Filename2LangId(filename);

   // Give an OEM or VAR a chance to pre-process content
   status=preProcessTemplateContent(temp_wid,itemName,itemLocation,params,delim);
   if( status!=0 ) {
      return status;
   }

   top();
   status=search("{"re"}",'erh@');
   while( status==0 ) {
      _str rep = get_text(match_length('0'),match_length('S0'));
      // Must save/restore search params since _ctProcessContentString() might do
      // some heavy-duty stuff (e.g. like searching for a root namespace, etc.).
      _str old_search_string, old_word_re,old_ReservedMore;
      int old_flags, old_flags2;
      save_search(old_search_string,old_flags,old_word_re,old_ReservedMore,old_flags2);
      rep=_ctProcessContentString(rep,itemName,itemLocation,params,paramsVisited,delim,wordChars,langId);
      restore_search(old_search_string,old_flags,old_word_re,old_ReservedMore,old_flags2);
      // Have to escape things like backslash in paths (e.g. c:\windows\temp)
      rep=_escape_re_chars(rep);
      // 7/27/2006 - RB
      // Calling search_replace with 'r' option works better for the case of:
      // $foo$$bar$
      // where $foo$ and $bar$ are unknown on the first pass and get replaced with
      // exactly the same thing. repeat_search will match on the '$$' in between
      // the two substitution parameters and you end up with:
      // $foo$bar$
      // after the first pass.
      status=search_replace(rep,'r');
      //status=repeat_search();
   }

   // Post-process content.
   // This is where the content is formatted by _ctPostProcessContent_format().
   status=postProcessContent(temp_wid,itemName,itemLocation);

   if( p_modify ) {
      status=_save_file("+o");
   }
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return status;
}

int _ctPostProcessContent_format(int wid, _str itemName, _str itemLocation)
{
   _str file_name = wid.p_buf_name;
   _str lang = _Filename2LangId(file_name);
   if( lang=="" ) {
      lang=wid.p_LangId;
   }
   if( file_eq('.'lang,CT_EXT) || _LanguageInheritsFrom("xml",lang) ) {
      // Special case:
      // 1. Using the item template-template to create a new template.
      // 2. Creating an XML file. XML could be data or XHTML or ...
      //    We have no way of knowing, so safest to leave it alone.
      return 0;
   }

   int orig_wid;
   get_window_id(orig_wid);
   if( orig_wid!=wid ) {
      activate_window(wid);
   }

   // Call the language-independent beautify() command on the content.
   // Let it fail quietly. The worst that can happen is the user gets
   // unformatted content.
   int status = beautify(true);

   if( orig_wid!=wid ) {
      activate_window(orig_wid);
   }
   // Always succeed
   return 0;
}

/**
 * Process source file list in template content and assemble
 * absolute source and destination filenames.  This is a first step for
 * instantiating a template by generating the absolute source and destination
 * filenames for copying when a template is instantiated. It can also be used
 * to put together a preview of the files that would be created from a template.
 * <p>
 * IMPORTANT: <br>
 * The caller is responsible for initializing resultFile[]. This allows for
 * appending files to the list if needed.
 * 
 * @param content       Template content to process.
 * @param itemName      Name of item. This is common to both source and destination filenames.
 * @param DefaultName   Default name of item from template. Used to create destination filename
 *                      from source filename when in doubt.
 * @param srcDir        All source files are relative to this directory.
 * @param dstDir        Destination directory for all destination filenames.
 * @param resultFiles   (output). Result ctTemplateContent_File_t array that holds absolute source and
 *                      destination filenames. Source filenames are stored in .Filename member;
 *                      destination filenames are stored in .TargetFilename member.
 * @param statusMessage (optional) (output). Useful message given when status!=0 returned.
 * 
 * @return 0 on success, <0 error code on error.
 */
int _ctCreateTemplateContentFileList(ctTemplateContent_t& content,
                                     _str itemName,
                                     _str DefaultName,
                                     _str srcDir,
                                     _str dstDir,
                                     ctTemplateContent_File_t (&resultFiles)[],
                                     _str& statusMessage=null)
{
   int status = 0;

   // Setup name and extension part mapping from DefaultName => itemName
   _str DefaultNameName = _strip_filename(DefaultName,'pe');
   _str DefaultNameExt = _get_extension(DefaultName,true);
   _str itemNameName = _strip_filename(itemName,'pe');
   _str itemNameExt = _get_extension(itemName,true);

   int i;
   for( i=0; i<content.Files._length(); ++i ) {
      boolean ReplaceParameters=content.Files[i].ReplaceParameters;
      _str Filename = absolute(content.Files[i].Filename,srcDir);
      _str FilenameName = _strip_filename(Filename,'pe');
      _str FilenameExt = _get_extension(Filename,true);
      _str TargetFilename = content.Files[i].TargetFilename;
      if( TargetFilename=="" ) {
         TargetFilename=content.Files[i].Filename;
      }
      _str TargetPath = _strip_filename(TargetFilename,'n');
      _str TargetName = _strip_filename(TargetFilename,'pe');
      _str TargetExt = _get_extension(TargetFilename,true);
      TargetPath=_ctProcessContentString(TargetPath,itemName,dstDir,content.Parameters,null,content.Delimiter);
      TargetName=_ctProcessContentString(TargetName,itemName,dstDir,content.Parameters,null,content.Delimiter);
      TargetExt=_ctProcessContentString(TargetExt,itemName,dstDir,content.Parameters,null,content.Delimiter);
      if( DefaultNameName=="" ) {
         // No DefaultName, so form the DefaultName out of the first File we encounter.
         // This guarantees that a single-file template with no explicit TargetFilename's
         // will get copied correctly (i.e. to the itemName entered by user).
         // IMPORTANT:
         // If this is a multi-file template, and there are no explicit TargetFilename's,
         // then it is VERY important that the first file encountered makes a good
         // DefaultName mapping case for parts of the itemName (i.e. name, ext).
         DefaultNameName=FilenameName;
         DefaultNameExt=FilenameExt;
      }
      // Now map itemName parts (name, ext) onto TargetFilename
      if( TargetName==DefaultNameName ) {
         TargetName=itemNameName;
      }
      if( TargetExt==DefaultNameExt && itemNameExt!="" ) {
         TargetExt=itemNameExt;
      }
      // Reform the target
      TargetFilename=TargetPath:+TargetName:+TargetExt;
      TargetFilename=absolute(TargetFilename,dstDir);

      // Result

      // Actual filename source
      int result_i = resultFiles._length();
      resultFiles[result_i].Filename=Filename;
      // Actual filename target
      resultFiles[result_i].TargetFilename=TargetFilename;
      resultFiles[result_i].ReplaceParameters=ReplaceParameters;
   }
   return status;
}

/**
 * Copy source files to target files from list in template content. Call
 * _ctCreateTemplateContentFileList before calling this function.
 * 
 * @param content         Template content containing source and target filenames.
 * @param copiedFilenames (output). Target filenames of files that were successfully
 *                        copied. Useful when an error occurs and you need to clean up.
 * @param pfnCopyFile     (optional). Pointer to callback function that is called
 *                        to copy a source file to a target file. Useful when you want
 *                        to prompt the user to overwrite when file already exists.
 *                        If set to 0, then the default copy_file function is used which
 *                        always overwrites the destination.
 *                        Defaults to 0.
 * @param statusMessage   (optional) (output). Useful message given when status!=0 returned.
 * 
 * @return 0 on success, <0 error code on error.
 */
static int copyTemplateContentFiles(ctTemplateContent_t& content,
                                    _str copiedFilenames[],
                                    ctCopyFile_t pfnCopyFile=null,
                                    _str& statusMessage=null)
{
   int status = 0;

   int i;
   for( i=0; i<content.Files._length(); ++i ) {

      _str Filename = content.Files[i].Filename;
      _str TargetFilename = content.Files[i].TargetFilename;

      // Make sure target directory exists
      _str TargetDir = _strip_filename(TargetFilename,'n');
      if( !isdirectory(TargetDir) ) {
         status=make_path(TargetDir);
         if( status!=0 ) {
            if( statusMessage!=null ) {
               statusMessage="Error creating directory:\n\n":+
                             TargetDir:+"\n\n":+
                             get_message(status);
            }
            break;
         }
      }
      //say('copyTemplateContentFiles: copying src='Filename' to dst='TargetFilename);
      status=0;
      if( pfnCopyFile ) {
         status=(*pfnCopyFile)(Filename,TargetFilename);
      } else {
         status=copy_file(Filename,TargetFilename);
      }
      if( status!=0 ) {
         if( statusMessage!=null ) {
            statusMessage="Error copying to file:\n\n":+
                          TargetFilename:+"\n\n":+
                          get_message(status);
         }
         break;
      }
      copiedFilenames[copiedFilenames._length()]=TargetFilename;
   }
   return status;
}

/**
 * Process target files from list in template content by replacing all substitution
 * parameters with values. Call copyTemplateContentFiles before calling this function.
 * 
 * @param content            Template content target filenames.
 * @param itemName           Name of template item. Used during substitution.
 * @param itemLocation       Location to save template item. Used during substitution.
 * @param processedFilenames (output). Target filenames of files that were successfully
 *                           processed. Useful when an error occurs and you need to clean up.
 * @param paramsVisited      (optional) (output). Hash table of substitution parameters actually 
 *                           visited (used). As parameters are visited they are stored in this 
 *                           in this hash table. Useful for determining whether a prompt-able
 *                           parameter should actually be prompted for.
 *                           Hash table is indexed by parameter name.
 * @param statusMessage      (optional) (output). Useful message given when status!=0
 *                           returned.
 * 
 * @return 0 on success, <0 error code on error.
 */
static int processTemplateContentFiles(ctTemplateContent_t& content,
                                       _str itemName, _str itemLocation,
                                       _str processedFilenames[],
                                       ctTemplateContent_ParameterValue_t (&paramsVisited):[]=null,
                                       _str& statusMessage=null)
{
   int status = 0;

   int i;
   for( i=0; i<content.Files._length(); ++i ) {

      _str TargetFilename = content.Files[i].TargetFilename;
      boolean ReplaceParameters = content.Files[i].ReplaceParameters;

      if( ReplaceParameters ) {
         status=processTemplateContentFile(TargetFilename,itemName,itemLocation,content.Parameters,paramsVisited,content.Delimiter);
         if( status!=0 ) {
            if( statusMessage!=null ) {
               statusMessage="Error processing template file:\n\n":+
                             TargetFilename:+"\n\n":+
                             get_message(status);
            }
            break;
         }
      }
      processedFilenames[processedFilenames._length()]=TargetFilename;
   }
   return status;
}

static void deleteFileList(_str files[])
{
   int i;
   for( i=0; i<files._length(); ++i ) {
      delete_file(files[i]);
   }
}

/**
 * Instantiate a template (a .setemplate file) with name and location.
 * 
 * @param templateFilename Filename of template file.
 * @param itemName         Name of template item.
 * @param itemLocation     Location to save template item.
 * @param resultContent    (output). Template content structure containing actual created
 *                         filenames.
 * @param parameters       (optional). Substitution parameters to use when instantiating the
 *                         template. Parameters of the same name in the template will override
 *                         these.
 *                         Defaults to null.
 * @param pfnCopyFile            (optional). Pointer to callback function that is called
 *                               to copy a source file to a target file. Useful when you want
 *                               to prompt the user to overwrite when file already exists.
 *                               If set to 0, then the default copy_file function is used which
 *                               always overwrites the destination.
 *                               Defaults to 0.
 * @param pfnPromptForParameters (optional). Pointer to callback function that is called
 *                               when there are substitution parameters that have no value.
 *                               This can happen when a template file uses an undefined parameter
 *                               or when a custom parameter in the template has the Prompt="1"
 *                               attribute.
 *                               Defaults to 0.
 * @param statusMessage (optional) (output). Useful message given when status!=0 returned.
 * 
 * @return 0 on success, <0 error code on error.
 */
int _ctInstantiateTemplate(_str templateFilename,
                           _str itemName, _str itemLocation,
                           ctTemplateContent_t& resultContent,
                           ctTemplateContent_ParameterValue_t (&parameters):[]=null,
                           ctCopyFile_t pfnCopyFile=null,
                           ctPromptForParameters_t pfnPromptForParameters=null,
                           _str& statusMessage=null)
{
   resultContent._makeempty();

   if( templateFilename==null || templateFilename=="" || !file_exists(templateFilename) ) {
      if( statusMessage!=null ) {
         statusMessage="Bad or missing template.";
      }
      return VSRC_INVALID_ARGUMENT;
   }
   if( itemName==null || itemName=="" ) {
      if( statusMessage!=null ) {
         statusMessage="Missing item name.";
      }
      return VSRC_INVALID_ARGUMENT;
   }
   if( itemLocation==null || itemLocation=="" ) {
      itemLocation=getcwd();
   }

   int status;
   ctTemplateDetails_t details; details._makeempty();
   ctTemplateContent_t content; content._makeempty();
   status=_ctTemplateGetTemplate(templateFilename,&details,&content);
   if( status!=0 ) {
      if( statusMessage!=null ) {
         statusMessage="Error retrieving template.";
      }
      return status;
   }

   // Need this when creating source/destination file list for copying template files to destination
   _str TemplateDir = _strip_filename(templateFilename,'n');

   // Generate source/destination file list for copying
   ctTemplateContent_File_t resultFiles[]; resultFiles._makeempty();
   status=_ctCreateTemplateContentFileList(content,itemName,details.DefaultName,TemplateDir,itemLocation,resultFiles,statusMessage);
   if( status!=0 ) {
      if( statusMessage!=null && statusMessage=="" ) {
         statusMessage="Error building template file list. ":+get_message(status);
      }
      return status;
   }
   resultContent.Delimiter=content.Delimiter;
   resultContent.Parameters=content.Parameters;
   resultContent.Files=resultFiles;

   // Copy template files
   _str copiedFilenames[]; copiedFilenames._makeempty();
   status=copyTemplateContentFiles(resultContent,copiedFilenames,pfnCopyFile,statusMessage);
   if( status!=0 ) {
      deleteFileList(copiedFilenames);
      if( statusMessage!=null && statusMessage=="" ) {
         statusMessage="Error copying template file list. ":+get_message(status);
      }
      return status;
   }

   // Process template files
   if( parameters!=null ) {
      // Merge parameters from template with parameters passed in
      _str Name;
      for( Name._makeempty();; ) {
         parameters._nextel(Name);
         if( Name._isempty() ) {
            break;
         }
         if( !resultContent.Parameters._indexin(Name) ) {
            resultContent.Parameters:[Name].Value=parameters:[Name].Value;
            resultContent.Parameters:[Name].Prompt=parameters:[Name].Prompt;
            resultContent.Parameters:[Name].PromptString=parameters:[Name].PromptString;
         }
      }
   }
   _str processedFilenames[]; processedFilenames._makeempty();
   ctTemplateContent_ParameterValue_t paramsVisited:[]; paramsVisited._makeempty();
   status=processTemplateContentFiles(resultContent,itemName,itemLocation,processedFilenames,paramsVisited,statusMessage);
   if( status!=0 ) {
      deleteFileList(processedFilenames);
      if( statusMessage!=null && statusMessage=="" ) {
         statusMessage="Error processing template file list. ":+get_message(status);
      }
      return status;
   }

   // Undefined or prompt-able parameters
   //
   // Weed out any parameters that were never used in the template files.
   // We do this so we are not prompted for parameters that were never used.
   _str Name;
   for( Name._makeempty();; ) {
      resultContent.Parameters._nextel(Name);
      if( Name._isempty() ) {
         break;
      }
      if( !paramsVisited._indexin(Name) ) {
         // This parameter was never used when instantiating the template
         resultContent.Parameters._deleteel(Name);
      }
   }
   // Prompt for any undefined or prompt-able parameters
   if( pfnPromptForParameters ) {
      status=(*pfnPromptForParameters)(details,resultContent);
      if( status<0 ) {
         deleteFileList(processedFilenames);
         if( status!=COMMAND_CANCELLED_RC && statusMessage!=null && statusMessage=="" ) {
            statusMessage="Error processing template file list. ":+get_message(status);
         }
         return status;
      } else if( status>0 ) {
         // We have some more substitution parameters to process
         status=processTemplateContentFiles(resultContent,itemName,itemLocation,processedFilenames,null,statusMessage);
         if( status!=0 ) {
            deleteFileList(processedFilenames);
            if( statusMessage!=null && statusMessage=="" ) {
               statusMessage="Error processing template file list for prompted parameters. ":+get_message(status);
            }
            return status;
         }
      }
   }

   return status;
}
