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
#pragma option(metadata,"codetemplate.e")


const CT_ROOT_DIR= "templates";
const CT_SYS_ITEM_DIR= "ItemTemplates";
const CT_USER_ITEM_DIR= "ItemTemplates";

const CT_SYS_ITEM_CAT_CAPTION= "Installed Templates";
const CT_USER_ITEM_CAT_CAPTION= "User Templates";

const CT_ITEM_TEMPLATE_TEMPLATE= "ItemTemplate.setemplate";

const CT_EXT= ".setemplate";
// Current template metadata version supported
const CT_VERSION= "1.0";
// Default delimiter for a substitution parameter
const CTPARAMETER_DELIM= '$';
// Default word characters that make up a valid identifier
const CTPARAMETER_NAME_RE= '[a-zA-Z0-9_]@';
// Invalid DefaultName characters (can also be used to validate item name)
const CTDEFAULTNAME_INVALID_CHARS= '[\@\&\<\>\|\?\\/]';

const CTOPTIONS_VERSION= "1.0";
const CTOPTIONS_FILENAME= "options.xml";

typedef struct {
   _str Name;
   _str Description;
   int SortOrder;
   _str DefaultName;
} ctTemplateDetails_t;

typedef struct {
   _str Value;
   bool Prompt;
   _str PromptString;
} ctTemplateContent_ParameterValue_t;

typedef struct {
   _str Filename;
   _str TargetFilename;
   bool ReplaceParameters;
} ctTemplateContent_File_t;

typedef struct {
   _str Delimiter;
   ctTemplateContent_ParameterValue_t Parameters:[];
    ctTemplateContent_File_t Files[];
} ctTemplateContent_t;

typedef struct {
   ctTemplateContent_ParameterValue_t Parameters:[];
} ctOptions_t;

/**
 * Pointer to function called by _ctInstantiateTemplate for copying a source file to
 * a target file. Useful when you want to prompt to overwrite when file already exists.
 * 
 * @param src     Source filename to copy from.
 * @param target  Target filename to copy to.
 * 
 * @return 0 on success, <0 on error.
 */
typedef int (*ctCopyFile_t)(_str src, _str& target);

/**
 * Pointer to function called by _ctInstantiateTemplate for dealing with undefined substitution
 * parameters and parameters that the template specifically prompts for.
 * 
 * @param details ctTemplateDetails_t object for the template being instantiated.
 * @param content ctTemplateContent_t object for the template being instantiated.
 *                Complete source, target, and options information is stored here at
 *                the time this function is called.
 * 
 * @return Number of parameters prompted for. <0 on error or command cancelled.
 */
typedef int (*ctPromptForParameters_t)(ctTemplateDetails_t& details, ctTemplateContent_t& content);

