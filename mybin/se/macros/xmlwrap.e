////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46245 $
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
#include "tagsdb.sh"
#require "xmlwrap.sh"
#include "xml.sh"
#include "eclipse.sh"
#import "alias.e"
#import "adaptiveformatting.e"
#import "autobracket.e"
#import "clipbd.e"
#import "codehelp.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "env.e"
#import "fileman.e"
#import "files.e"
#import "html.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "notifications.e"
#import "pmatch.e"
#import "recmacro.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "xml.e"
#import "xmlwrapgui.e"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#endregion

using se.lang.api.LanguageSettings;

/*
 * Symbol translation help functions and structures
 */
struct symbolTransType {
   int longest;
   _str symbols:[];
};
//holds info on the symbols to be translated automatically.  This is 
//cached here to speed up the lookup when typing.
typeless gSTtable:[];
//Cache the whether the sym trans option is on
boolean ST_symTransOnHash:[];


//Reflow to next line result flags
#define XW_REFLOWED                 0x0000
#define XW_NONEEDTOREFLOW           0x0001
#define XW_CANNOTREFLOW             0x0002

#define XW_CANNOT_FORMAT_MESSAGE    'Unable to wrap this content.'
#define XW_CANNOT_FORMAT_MESSAGE2   'Unable to wrap this content within specified width.'

#define XW_RECURSE_LEVEL 100
#define XW_PRE_TAG_NEST_LIMIT 2

#define XW_REGULAR_TAG  1
#define XW_COMMENT      2
#define XW_PROC_TAG     3
#define XW_CDATA        4

//XWdocStat filenameToXWdocStatHash:[];
_str      useWithSchemeHash:[];

static XW_ContentWrapSettings defaultContentWrapSettings = {
   DEFAULTCONTENTWRAPSETTINGS
};
#define CDATACONTENTWRAPSETTINGS XW_CWS_PRESERVE, XW_CWS_FIXEDRIGHT, XW_CWS_FIXEDWIDTHCOLDEFAULT, XW_CWS_FIXEDWIDTHMRCDEFAULT, XW_CWS_AUTOWIDTHMRCDEFAULT, XW_CWS_FIXEDRIGHTCOLDEFAULT, XW_CWS_USEFIXEDWIDTHMRCDEFAULT, XW_CWS_USEAUTOWIDTHMRCDEFAULT, XW_CWS_INCLUDETAGSDEFAULT, XW_CWS_PRESERVEWIDTHDEFAULT
static XW_ContentWrapSettings CDATAContentWrapSettings = {
   CDATACONTENTWRAPSETTINGS
};

static XW_TagLayoutSettings defaultTagLayoutSettings = {
   DEFAULTTAGLAYOUTSETTINGS
};
#define CDATATAGLAYOUTSETTINGS /*XW_TLS_STYLE1,*/ XW_TLS_MATCHEXT, XW_TLS_FROMOPENING, XW_TLS_INDENTSPACES, XW_TLS_BREAKSBEFORE, XW_TLS_BREAKSAFTER, true, true, false, false
static XW_TagLayoutSettings CDATATagLayoutSettings = {
   CDATATAGLAYOUTSETTINGS
};

static XW_GeneralSettings defaultGeneralSettings = {
   DEFAULTGENERALSETTINGS
};

static XW_TagSettings defaultTagSettings = {
   XW_DEFAULT_TAGNAME,
   //false, 
   XW_DEFAULT_MATCH_TAGNAME,
   {DEFAULTGENERALSETTINGS},
   {DEFAULTCONTENTWRAPSETTINGS},
   {DEFAULTTAGLAYOUTSETTINGS}
};
static XW_TagSettings defaultTagSettings2 = {
   XW_DEFAULT_TAGNAME,
   //false, 
   XW_DEFAULT_MATCH_TAGNAME,
   {DEFAULTGENERALSETTINGS},
   {XW_CWS_IGNORE, XW_CWS_FIXEDRIGHT, XW_CWS_FIXEDWIDTHCOLDEFAULT, XW_CWS_FIXEDWIDTHMRCDEFAULT, XW_CWS_AUTOWIDTHMRCDEFAULT, XW_CWS_FIXEDRIGHTCOLDEFAULT, XW_CWS_USEFIXEDWIDTHMRCDEFAULT, XW_CWS_USEAUTOWIDTHMRCDEFAULT, XW_CWS_INCLUDETAGSDEFAULT, XW_CWS_PRESERVEWIDTHDEFAULT},
   {DEFAULTTAGLAYOUTSETTINGS}
};

_str xw_surround_with()
{
   //XWsay("XW_surround_with()");
   return("");
}

struct XMLLine {
   // an invalid line is a no-save line
   boolean valid;
   // whether this line == ''
   boolean blank;
   // the text of the line
   _str line;
   _str bullet;
   // line with initial spaces removed
   _str content;
   int  bulletRCol, bulletDCol;

   // first non-blank column (physical)
   int contentRCol;
   // first non-blank column (imaginary)
   int contentDCol;

   // the last non-blank column (physical)
   int RMRCol;
   // the last non-blank column (imaginary)
   int RMDCol;
   boolean startsWithTag;
   int  startTagStartRCol, startTagStartDCol;
   int  startTagEndRCol, startTagEndDCol;
   boolean endsWithTag;
   int  endTagStartRCol, endTagStartDCol;
   int  endTagEndRCol, endTagEndDCol;
   int  tagKind;
};

XMLLine XW_alines:[];

/* 0 not in tag
 * 1 open start
 * 2 closed start
 * 3 open end
 * 4 closed end
 * 5 closed empty
 */ 
#define  XW_UNKNOWN        0x0000
#define  XW_IN_CONTENT     0x0001
#define  XW_IN_COMMENT     0x0002
#define  XW_IN_START_TAG   0x0004
#define  XW_IN_END_TAG     0x0008
#define  XW_IN_EMPTY_ELEM_TAG 0x0010

#define  XW_FOUND_NO_TAG        0x0000
#define  XW_FOUND_S_TAG     0x0001
#define  XW_FOUND_E_TAG     0x0002
#define  XW_FOUND_EMPTY_TAG     0x0003

#define XW_INSIDEPRETAG       0x0003
#define XW_OUTSIDEWRAPCONTEXT 0x0004

#define XW_ATTRIB_NAME_REGEX "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*"
//#define XW_NAME_REGEX "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*(:[\\p{IsXMLNameChar}]*)*"
#define XW_NAME_REGEX "[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*([:][\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*):0,1"
#define XW_NAME_REGEX_SUFFIX "[\\p{IsXMLNameChar}]*([:][\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*):0,1"
#define XW_WHITESPACE '[ \t\10\13]'
#define XW_CHARACTER_DATA "([^&<]|&lt;|&amp;|&gt;|&quot;|&apos;)"
#define XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE "[~\']"
#define XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE '[~\"]'
#define XW_ANYCHAR_REGEX "[?\n]"

#define XW_START_OF_START_TAG XW_TAG_OPEN_BRACKET
#define XW_START_OF_END_TAG XW_TAG_OPEN_BRACKET'/'
#define XW_END_OF_TAG XW_TAG_CLOSE_BRACKET
#define XW_END_OF_EMPTY_TAG '/'XW_TAG_CLOSE_BRACKET

#define XW_STARTOFSTARTTAGREGEX '<{#0['XW_NAME_REGEX'}(\n|:b|>)'
static _str startOfStartTagRegex = XW_STARTOFSTARTTAGREGEX;
static _str correlateStartEndTagRegex1 = '<{#0['XW_NAME_REGEX'}(\n|\t|([ ]#)|>|<)';
static _str nextWordRegex = '^{#0['XW_NAME_REGEX_SUFFIX'}(\n|[ \t]|>|<|$)';
static _str startOfStartTagRegexOM = '\om'XW_STARTOFSTARTTAGREGEX;
#define XW_STARTOFENDTAGREGEX '</{#1['XW_NAME_REGEX'}(\n|:b|>)'
static _str startOfEndTagRegex = XW_STARTOFENDTAGREGEX;
static _str startOfEndTagRegexOM = '\om'XW_STARTOFENDTAGREGEX;
#define XW_STARTOFSTARTORENDTAGREGEX '(<|</){#0['XW_NAME_REGEX'}(\n|:b|>)';
static _str startOfStartOrEndTagRegex = XW_STARTOFSTARTORENDTAGREGEX;
static _str startOfStartOrEndTagRegexOM = '\om'XW_STARTOFSTARTORENDTAGREGEX;
#define XW_STARTOFSTARTORENDOREMPTYTAGREGEX '(<|</){#0['XW_NAME_REGEX'}(\n|:b|>|/>)';
static _str startOfStartOrEndOrEmptyTagRegex = XW_STARTOFSTARTORENDOREMPTYTAGREGEX;
static _str startOfStartOrEndOrEmptyTagRegexOM = '\om'XW_STARTOFSTARTORENDOREMPTYTAGREGEX;
_str getStartOfStartTagRegex() {return startOfStartTagRegexOM;}
//static _str attributeRegex = XML_NAME_REGEX"(:b*=:b*)(\'"XML_CHARACTER_DATA"*\'|\""XML_CHARACTER_DATA"*\")";
//#define XW_ATTRIBUTE_REGEX XW_NAME_REGEX"("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'"XW_CHARACTER_DATA"*\'|\""XW_CHARACTER_DATA"*\")"
//#define ATTRIBUTE_REGEX = XW_NAME_REGEX"("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'"XW_CHARACTER_DATA"*\'|\""XW_CHARACTER_DATA"*\")"
#define XW_ATTRIBUTE_REGEX XW_ATTRIB_NAME_REGEX"("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'"XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE"*\'|\""XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE"*\")"

/**
 * Create a SlickEdit regex that will search for a specific xml attribute 
 * name/value pair. (e.g.  id = 'myElement')
 * 
 * @param attributeName  Name of attribute to search for
 * @param attributeValue Value of attribute to find.  If not given, find any 
 *                       name/value pair that matches just the name.
 * 
 * @return _str The regex to use in a search() call.
 */
_str XW_namedAttributeRegex(_str attributeName, _str attributeValue = '') {
   if (attributeValue :== '') {
      return attributeName :+ "("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'{#0"XW_ATTRIBUTE_CHAR_DATA_SINGLE_QUOTE"*}\'|\"{#0"XW_ATTRIBUTE_CHAR_DATA_DOUBLE_QUOTE"*}\")";
   } else return attributeName :+ "("XW_WHITESPACE"*="XW_WHITESPACE"*)(\'{#0" :+ _escape_re_chars(attributeValue) :+ "*}\'|\"{#0" :+ _escape_re_chars(attributeValue) :+ "*}\")";
}
#define FULL_END_TAG_REGEX "</"XW_NAME_REGEX""XW_WHITESPACE"*>"

static _str startOrEndTagRegex = "<{#0/:0,1}{#0[\\p{IsXMLNameStartChar}][\\p{IsXMLNameChar}]*}[\\P{IsXMLNameChar}][\\p{IsXMLNameChar}:b:=\'\"]*>";

/**
 * If cursor is on a character in reference string, move back one text position.
 * 
 * @param reference String holding characters that cause cursor to be moved back.
 */
static boolean maybeMoveBackCursor(_str reference= "") {
   if (verify(get_text(), reference))
      return true;
   if (p_col == 1) {
      if (up())
         return false;
      _end_line();
   } else
      left();
   return true;
}

/**
 * Gets the names of all the schemes that are saved as files
 * 
 * @param filenames
 */
void XW_schemeNamesF(_str (&filenames)[])
{
   filenames._makeempty();
   //filenames[0] = " ";
   _str configDir = getUserXWSchemesDir();
   _maybe_append_filesep(configDir);
   _str filename= file_match(maybe_quote_filename(configDir'*'XW_SCHEME_EXTENSION):+' -P',1);         // find first.
   for (;;) {
      if (filename == '=' || filename == '')  break;
      filename = _strip_filename(absolute(filename), 'PDE');
      filenames[filenames._length()] = filename;
      //Result filename is built with path of given file name.
      filename = file_match(filename,0);       // find next.
   }
   filenames._sort();
}

/**
 * Gets the names of all the schemes that are in memory.
 * In alphabetical order with (default) at top of list.
 * 
 * @param filenames
 */
void XW_schemeNamesM(_str (&schemeName)[])
{
   typeless i;
   // Traverse the scheme elements in hash table
   schemeName._makeempty();
   for (i._makeempty();;) {
       XW_schemes._nextel(i);
       if (i._isempty()) break;
       schemeName[schemeName._length()] = XW_schemes:[i].Name;
   }
   schemeName._sort();
}

/**
 * Initialize XML Wrap state when editor is started
 * 
 * @return typeless
 */ 
definit()
{
   if (true || arg(1) != 'L') {
      XW_schemes._makeempty();
      filenameToXWdocStatHash._makeempty();
      useWithSchemeHash._makeempty();

      XWclearState();
    
      _str filenames[];
      XW_CopyXhtmlScheme();
      XW_schemeNamesF(filenames);
      int i;
    
      //load all the found schemes
      for (i=0; i<filenames._length(); i++) {
         //XWsay('Reading in 'filenames[i]'.');
         XW_readXWScheme(filenames[i]);
         XW_removeCycles(filenames[i]);
      }
    
      defaultXML := _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml');
      //XWsay(defaultXML);
      if (defaultXML == XW_NODEFAULTSCHEME || defaultXML == "" || !XW_schemes._indexin(defaultXML)) {
         if (!XW_schemes._indexin('xml')) {
            XW_CopyXmlScheme();
         }
         XW_readXWScheme('xml');
         XW_removeCycles('xml');
        _SetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml', 'xml');
      }
      defaultHTML := _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html');
      if (defaultHTML == XW_NODEFAULTSCHEME || defaultHTML == "" || !XW_schemes._indexin(defaultHTML)) {
         if (!XW_schemes._indexin('html')) {
            XW_CopyHtmlScheme();
         }
         XW_readXWScheme('html');
         XW_removeCycles('html');
        _SetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html', 'html');
      }
   }
}

/**
 * Check is an xmlwrap scheme is correctly loaded and saved to disk.
 * 
 * @param schemeToCheck Name of xmlwrap formatting scheme to check whether 
 *                      correctly loaded in memory and saved to disk.
 * 
 * @return Return <b>true</b> if <i>schemeToCheck</i> is correctly loaded in 
 *         memory and on disk.
 */
static boolean XW_checkSchemeLoaded(_str schemeToCheck) {
   //Is the scheme in memory?
   if (XW_schemes._indexin(schemeToCheck)) {
      //is it valid?
      if (XW_schemes:[schemeToCheck] == null) {
         XW_schemes._deleteel(schemeToCheck);
         return false;
      }
      //Is the scheme saved to disc?
      if (!file_exists(XW_schemeNameToSchemeFileName(schemeToCheck))) {
         if (!XW_saveXWScheme(XW_schemes:[schemeToCheck])) {
            //If unable to save, delete from memory
            XW_schemes._deleteel(schemeToCheck);
            return false;
         }
      }
      return true;
   } else {
      //Is there a version on disc that could be loaded?
      if (file_exists(XW_schemeNameToSchemeFileName(schemeToCheck))) {
         if (!XW_readXWScheme(schemeToCheck)) {
            //If unable to read from disc
            return false;
         }
         XW_removeCycles(schemeToCheck);
         return true;
      }
   }
   return false;
}

static void XW_CopyXmlScheme() {
   XW_CopyScheme(XW_XML_SCHEMA_FILENAME);
   return;
}
static void XW_CopyXhtmlScheme() {
   XW_CopyScheme(XW_XHTML_SCHEMA_FILENAME);
   XW_CopyScheme(XW_DOCBOOK_SCHEMA_FILENAME);
   return;
}
void XW_CopyHtmlScheme() {
   XW_CopyScheme(XW_HTML_SCHEMA_FILENAME);
   return;
#if 0
   _str defaultfilename = get_env('VSROOT');
   _maybe_append_filesep(defaultfilename);
   defaultfilename = defaultfilename :+ 'sysconfig' :+ FILESEP :+ XW_FORMATSCHEMES_DIR :+ FILESEP :+ XW_XMLHTMLSCHEMES_SUBDIR :+ FILESEP;
   defaultfilename = defaultfilename :+ XW_HTML_SCHEMA_FILENAME :+ XW_SCHEME_EXTENSION;
   _str userHTMLfilename = getUserXWSchemesDir();
   _maybe_append_filesep(userHTMLfilename);
   //XWsay('|'defaultHTMLfilename'|'userHTMLfilename'|');
   userHTMLfilename = userHTMLfilename :+ XW_HTML_SCHEMA_FILENAME :+ XW_SCHEME_EXTENSION;

   _str filematchResult = file_match(maybe_quote_filename(userHTMLfilename)' -P +HRS', 1);
   if (filematchResult == '=' || filematchResult == '') {
      //XWsay('not found');
      int copyStat = copy_file(defaultfilename, userHTMLfilename);
      if(copyStat) {
         //XWsay(copyStat' making default');
         maybeMakeDefaultXWScheme(XW_HTML_SCHEMA_FILENAME);
      }
   }
#endif 
}

/**
 * Copy a shipped xmlformatting scheme from the installation sysconfig directory 
 * to the users sysconfig directory. 
 * 
 * @author dobrien
 * 
 * @param schemeFilename Name of scheme to fetch from installation sysconfig directory
 * @param newSchemeName If not an empty _str, rename the copy to this
 * 
 * @return Return <b>true</b> if successfully copied.
 */
static boolean XW_CopyScheme(_str schemeFilename, _str newSchemeName = "", boolean force = false) {
   if (newSchemeName == "") {
      newSchemeName = schemeFilename;
   }
   boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (cant_write_config_files) return false;
   
   //Find the scheme file to copy
   _str fullSchemeFilename = get_env('VSROOT');
   _maybe_append_filesep(fullSchemeFilename);
   fullSchemeFilename = fullSchemeFilename :+ 'sysconfig' :+ FILESEP :+ XW_FORMATSCHEMES_DIR :+ FILESEP :+ XW_XMLHTMLSCHEMES_SUBDIR :+ FILESEP;
   fullSchemeFilename = fullSchemeFilename :+ schemeFilename :+ XW_SCHEME_EXTENSION;
   if (!file_exists(fullSchemeFilename)) {
      return false;
   }

   _str newSchemeFilename = XW_schemeNameToSchemeFileName(newSchemeName);
   if (newSchemeFilename == "") {
      return false;
   }
   
   if (file_exists(newSchemeFilename) && !force) {
      return true;
   } else {
      if (copy_file(fullSchemeFilename, newSchemeFilename)) {
         return false;
      }
   }
   return true;
}

/**
 * Given a URI, strips off the path and returns just the DTD or XSD filename. 
 * Simply returns everything after the final '/' in input URI string. 
 *  
 * @param url  URI string from which to strip filename.
 * 
 * @return _str  DTD ot XSD filename.
 */
_str XW_stripDTD_XSDName(_str url) {
   return substr(url, lastpos('/', url) + 1);
}

/**
 * Reads the schema associated with the root element of an XML file.  Uses a 
 * simple algo. to open the file through the root node and itereates through the 
 * attributes of the root element looking for either a 
 * xsi:noNamespaceSchemaLocation or xsi:schemaLocation attribute.  Just returns 
 * the first one found. 
 *  
 * Strips the URI path from the schema name and just returns the XSD filename 
 * 
 * @return _str  Filename of the XSD schema file associated with the root 
 *         element of the current XML file.
 */
_str XW_getSchema() {
   if (!_LanguageInheritsFrom('xml', p_LangId)) return '';

   save_pos(auto p2);
   top();
   _str returnVal = '';
   typeless status=search('<[^!?]','@rhxcs');
   if (!status) {
      status = search('>','@rhxcs');
      if (!status) {
         right();
         typeless EndRealSeekPos=_QROffset();
         //Open just up through the root tag
         typeless handle=_xmlcfg_open_from_buffer(p_window_id,status,VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR,0,EndRealSeekPos);
         if (handle>=0) {
            //Move to the root element
            int RootIndex=_xmlcfg_get_last_child(handle,TREE_ROOT_INDEX);
            int AttrIndex;
            _str AttribName, AttribValue;
            //Cycle through the root element attributes
            for (AttrIndex = RootIndex; AttrIndex >= 0;) {
                AttrIndex=_xmlcfg_get_next_attribute(handle,AttrIndex);
                if (AttrIndex<0) break;
                AttribName = _xmlcfg_get_name(handle,AttrIndex);
                if (AttribName == 'xsi:schemaLocation') {
                   _str ns, xsd;
                   AttribValue = _xmlcfg_get_value(handle,AttrIndex);
                   AttribValue = translate(AttribValue, '  ', "\n\r");
                   parse AttribValue with ns xsd .;
                   //say('AttribValue = 'AttribValue'  xsd = 'xsd);
                   returnVal = XW_stripDTD_XSDName(xsd);
                   break;
                }
                if (AttribName == 'xsi:noNamespaceSchemaLocation') {
                   AttribValue = _xmlcfg_get_value(handle,AttrIndex);
                   returnVal = XW_stripDTD_XSDName(AttribValue);
                   break;
                }
            }
         }
      }
   }
   restore_pos(p2);
   return (returnVal);
}

/**
 * Reads the DTD for the current XML file and saves it in targets.  If no DTD 
 * found, then looks for a schema.
 *  
 * @param targets structure to load with this file's DTD/Schema.
 * 
 * @return _str filename of the associated DTD or schema file.  (Not currently 
 *         used.)
 */
_str XW_getDTDandSchema(XW_schemeMatchTargets& targets) {
   _str maptype, mapid; int markid; boolean istaglib;
   //Look for DTD references in the !DOCTYPE tag
   _mapxml_get_doctype_info(maptype, mapid, markid, istaglib);
   _str returnVal;
   if (mapid == '') {
   } else {
      targets.matchType = XWDTDMatch;
      returnVal = targets.DtdFilename = XW_stripDTD_XSDName(mapid);
   }
   //Try to find a schema
   returnVal = XW_getSchema();
   if (returnVal != '') {
      targets.matchType = XWSchemeMatch;
      targets.SchemeFilename = returnVal;
   }
   return returnVal;
;
}

XW_schemeMatchTargets XW_getMatchTargets(_str filename) {
   XW_schemeMatchTargets returnMatches;
   returnMatches.matchType = XWNoMatch;
   returnMatches.DtdFilename = returnMatches.SchemeFilename = 
                               returnMatches.filenameExt = 
                               returnMatches.langExt = '';

   if (XW_isSupportedLanguage_XML(p_LangId)) {
      XW_getDTDandSchema(returnMatches);
   }
   returnMatches.filenameExt = _get_extension(filename);
   returnMatches.langExt = p_LangId;

   return returnMatches;
}

_str XW_getSchemeNameByExt(_str filename) {
   _str returnVal = '';
   if (filename != '' && XW_isSupportedLanguage_XML(p_LangId)) {
      _str bufferExt = _get_extension(filename);
   
      //Try to match to file extention
      if (XW_schemes._indexin(bufferExt)) {
         returnVal = bufferExt;
      }
   }
   return returnVal;
}

_str XW_getSchemeNameForUnmatchedFile(_str filename) {
   _str returnVal = '';

   if (false && filename != '' && XW_isSupportedLanguage_XML(p_LangId)) {
      XW_schemeMatchTargets matchCandidates = XW_getMatchTargets(filename);
   
      _str matchKey;
      //Try to match to DTD
      if (matchCandidates.matchType == XWDTDMatch) {
         matchKey = XW_UW_EXT' 'matchCandidates.DtdFilename;
         if (useWithSchemeHash._indexin(matchKey)) {
            returnVal = useWithSchemeHash:[matchKey];
         }
      }
   
      //Try to match to schema
      if (matchCandidates.matchType == XWSchemeMatch) {
         matchKey = XW_UW_SCHEMA' 'matchCandidates.SchemeFilename;
         if (useWithSchemeHash._indexin(matchKey)) {
            returnVal = useWithSchemeHash:[matchKey];
         }
      }
      //Try to match to file extention
      if (matchCandidates.filenameExt != '') {
         matchKey = XW_UW_EXT' 'matchCandidates.filenameExt;
         if (useWithSchemeHash._indexin(matchKey)) {
            returnVal = useWithSchemeHash:[matchKey];
         }
      }
   
      //Try to match to a language mode
      if (matchCandidates.langExt != '') {
         matchKey = XW_UW_MODE' 'matchCandidates.langExt;
         if (useWithSchemeHash._indexin(matchKey)) {
            returnVal = useWithSchemeHash:[matchKey];
         }
      }
   }
   returnVal = XW_getSchemeNameByExt(filename);
   //Then match to supported language mode
   if (returnVal == '' || returnVal == null || !XW_schemes._indexin(returnVal)) {
      returnVal = XW_getDefaultSchemeName();
   }
   return returnVal;
}

_str XW_getDefaultSchemeName() {

   _str thisLang = xw_p_LangId();
   _str returnVal = _GetXMLWrapFlags(XW_DEFAULT_SCHEME, thisLang);
   boolean passedCheck = XW_checkSchemeLoaded(returnVal);
   if (!passedCheck && XW_checkSchemeLoaded(thisLang)) {
      returnVal = thisLang;
   }
   if (returnVal == null || returnVal == XW_NODEFAULTSCHEME || strip(returnVal) == "") {
      if (_LanguageInheritsFrom('html')) {
         if (!XW_schemes._indexin('html')) {
            XW_CopyHtmlScheme();
         }
         XW_readXWScheme('html');
         XW_removeCycles('html');
         _SetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html', 'html');
         returnVal = 'html';
      } else {
         if (!XW_schemes._indexin('xml')) {
            maybeMakeDefaultXWScheme('xml');
         }
         _SetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml', 'xml');
         XW_readXWScheme('xml');
         XW_removeCycles('xml');
         _SetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml', 'xml');
         returnVal = 'xml';
      }
   }
   return returnVal;
}

void _before_write_state_clear_global_hash_table() {
   //XW_schemes._makeempty();
   //filenameToXWdocStatHash._makeempty();
   //gSTtable._makeempty();
   ST_symTransOnHash._makeempty();
}

/**
 * Gets name of current buffer.  If no buffers, returns blank.  If buffer does 
 * not have a name, then returns buffer id. 
 * 
 * @return _str containing current buffer name or id.
 */
_str xw_buf_name() 
{
   _str returnVal = '';
   if (!_no_child_windows()) {
      returnVal = _mdi.p_child.p_buf_name;
      if (returnVal == '' || !file_exists(returnVal))
         returnVal = _mdi.p_child.p_buf_id;
   } else {
      //say('No Child Window!');
   }
   return returnVal;
}

/**
 * Gets language of current buffer, or returns default of 'xml' if no open 
 * buffers found 
 * 
 * @return Language of current buffer or default of 'xml'
 */
_str xw_p_LangId() 
{
   if (_no_child_windows()) {
      return 'xml';
   }
   return _mdi.p_child.p_LangId;
}

/**
 * Get the XML/HTML options that are in memory for the specified buffer.  Defaults 
 * to the current buffer. 
 * 
 * @param  bufName name of buffer for which to get the XML/HTML formatting options. 
 * @return XWdocStat struct holding the XML/HTML formatting settings for this buffer
 */
XWdocStat getDocStat(_str bufName = '') {
   if (bufName == '') {
      bufName = xw_buf_name();
   }
   //If already stored in the hash table, just return value
   XWdocStat returnVal;
   if (filenameToXWdocStatHash._indexin(bufName)) {
      returnVal = filenameToXWdocStatHash:[bufName];
      if (returnVal != null && XW_schemes._indexin(returnVal.scheme) && returnVal.featureOptions != null) {
         return returnVal;
      }
   }
   //Otherwise, return default scheme and formatting options for the current language extension
   returnVal.scheme = XW_getSchemeNameForUnmatchedFile(bufName);
   returnVal.featureOptions = (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, xw_p_LangId()) ? XWcontentWrapFlag : 0) | (_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, xw_p_LangId()) ? XWtagLayoutFlag : 0);
   //Store these defaults assigned to this buffer in the hash table.
   filenameToXWdocStatHash:[bufName] = returnVal;
   return returnVal;
}

/**
 * Read in the name of the XML formatting scheme saved for this file from the user config and 
 * load that scheme if it is not yet loaded into memory. 
 */
void _buffer_add_XMLFormatting()
{  
   //XW_getDTDorSchema();
   if (!XW_isSupportedLanguage2()) {
      return;
   }

   XW_CopyHtmlScheme();
   _str bufferName = '';
   if (_mdi.p_child.p_buf_name == null || _mdi.p_child.p_buf_name == '') {
      bufferName = _mdi.p_child.p_buf_name;
   } else bufferName = _mdi.p_child.p_buf_name;
   XWdocStat optionsForThisFile;
   optionsForThisFile.featureOptions = 0; optionsForThisFile.scheme = 'xml';
   optionsForThisFile = _load_documentXWoptions(bufferName);
   if (!XW_schemes._indexin(optionsForThisFile.scheme)) {
      if (!XW_readXWScheme(optionsForThisFile.scheme)) {
         // Read option for sceme for this file, but the scheme does not exist
         // so assign to the language type default.
         if(XWAutoDetect) {
            optionsForThisFile.scheme = XW_getSchemeNameForUnmatchedFile(bufferName);
         } else {
            _str matchByExt = XW_getSchemeNameByExt(bufferName);
            if (matchByExt != '') {
               optionsForThisFile.scheme = matchByExt;
            } else {
               optionsForThisFile.scheme = XW_getDefaultSchemeName();
            }
         }
      }
   }
   filenameToXWdocStatHash:[bufferName] = optionsForThisFile;
}

/**
 * Gets the file extension indent options for the given extension.  Used to calculate XML/HTML 
 * indents when following syntax indent rules. 
 *  
 * @param lang    Language ID (see {@link p_LangId} 
 *                For list of language types,
 *                see the Language Manager dialog
 *                ("Tools", "Options...", "Language Manager").
 *
 * @return XW_indent struct holding the options needed by XML/HTML formatting.
 */
XW_indent XW_IndentStyle(_str lang = p_LangId) {
   XW_indent returnVal;
   returnVal.None = returnVal.Auto = false;
   returnVal.Syntax = true;
   returnVal.Indent = 1;
   returnVal.LMargin = "";
   int IndentStyle, SyntaxIndent;
   if (_GetExtIndentOptions(lang, IndentStyle, SyntaxIndent)) {
      return returnVal;
   }
   //Always use the syntax indent value
   IndentStyle = INDENT_SMART;

   // Adaptive formating can change the syntax indent.
   if (_isEditorCtl(false)) {
      updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT|AFF_INDENT_WITH_TABS|AFF_TABS);
      SyntaxIndent=p_SyntaxIndent;
   }

   if (IndentStyle == INDENT_SMART || IndentStyle == INDENT_AUTO) {
      if (SyntaxIndent > 0) {
         returnVal.LMargin = substr("", 1, SyntaxIndent);
         returnVal.Indent = SyntaxIndent;
      }
   }
   return returnVal;
}

/**
 * Get the XML/HTML formatting options for this file that are stored in the filepos file.  The 
 * options returned are the name of the formattting scheme and options for enabling content 
 * wrapping and tag layout. 
 *  
 * @param filename Name of file for which to retrieve options
 * 
 * @return XWdocStat struct holding the above mentioned options
 */
XWdocStat _load_documentXWoptions(_str filename)
{
   _str returnXWscheme = XW_NODEFAULTSCHEME, XWoptions= "0";
   XWdocStat returnVal;
   returnVal.featureOptions = 0;
   returnVal.scheme = 'xml';

   PERFILEDATA_INFO info;
   if (!_filepos_get_info(filename, info)) {
      returnXWscheme = info.m_xmlWrapScheme;
      XWoptions = info.m_xmlWrapOptions;
   }

   if (returnXWscheme == "0" || returnXWscheme == XW_NODEFAULTSCHEME || returnXWscheme == "" || !XW_schemes._indexin(returnXWscheme)) {
      returnXWscheme = XW_getSchemeNameForUnmatchedFile(filename);
   }

   returnVal.scheme = returnXWscheme;
   if (XWoptions == "") {
      XWoptions = '0';
   }
   if (isinteger(XWoptions))
      returnVal.featureOptions = (int)XWoptions;
   else
      returnVal.featureOptions = 0;
   return returnVal;
}

static _str namedFullStartTagRegex(_str name) {
   return ('\om{#0<{#3'name'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*>}');
}
static _str namedFullEndTagRegex(_str name) {
   return ('\om{#1</{#3'name'}'XW_WHITESPACE'*>}');
}
static _str namedFullStartOrEndTagRegex(_str name) {
   return (namedFullStartTagRegex(name)'|'namedFullEndTagRegex(name));
}

#define FULLSTARTTAGREGEX '{#0<{#3'XW_NAME_REGEX'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*>}'
static _str fullStartTagRegex = FULLSTARTTAGREGEX;
static _str fullStartTagRegexOM = '\om'FULLSTARTTAGREGEX;
#define FULLENDTAGREGEX '{#1</{#3'XW_NAME_REGEX'}'XW_WHITESPACE'*>}'
static _str fullEndTagRegex = FULLENDTAGREGEX;
static _str fullEndTagRegexOM = '\om'FULLENDTAGREGEX;
#define FULLEMPTYTAGREGEX '{#2<{#3'XW_NAME_REGEX'}('XW_WHITESPACE'*'XW_ATTRIBUTE_REGEX')*'XW_WHITESPACE'*/>}'
static _str fullEmptyTagRegex = FULLEMPTYTAGREGEX;
static _str fullEmptyTagRegexOM = '\om'FULLEMPTYTAGREGEX;
/**
 * Use only when not inside a tag
 * 
 * @return int XW_FOUND_NO_TAG No tag, XW_FOUND_S_TAG, XW_FOUND_E_TAG, XW_FOUND_EMPTY_TAG
 */
int XW_FindTag(_str &name) {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   //long orig_offset = _QROffset();
   int returnVal = XW_FOUND_NO_TAG;
   int pc = p_col;int pl = p_line;
   
   int status = search(fullStartTagRegexOM'|'fullEndTagRegexOM'|'fullEmptyTagRegexOM,'@-RHXCS');
   
   if (status /*|| match_length('2') != 0*/) {
      //found neither or found end
      //XWsay("XW_FindTag() found no tag "pl" "pc);
      returnVal = XW_FOUND_NO_TAG;
      name = "";
   } else {
      if (match_length('2') != 0) {
         //found neither or found end
         //XWsay("found empty  ");
         returnVal = XW_FOUND_EMPTY_TAG;
      } 
   
      if (match_length('0') != 0) {
         returnVal = XW_FOUND_S_TAG;
         //XWsay("found start  ");
         //XWsay("found start "get_match_text('0')"|"get_match_text('1'));
      }
      if (match_length('1') != 0) {
         returnVal = XW_FOUND_E_TAG;
         //XWsay("found end");
         //XWsay("found 1 "get_match_text('1')"|"get_match_text('0'));
      }
      name = get_text(match_length('3'),match_length('S3'));
      //XWmessage(name);
   }

   restore_search(s1,s2,s3,s4,s5);
   //_GoToROffset(orig_offset);
   return returnVal;
}

int XW_FindNamedStartTag(_str name, int nestLevel = 1) {
   if (nestLevel < 1) {
      return XW_FOUND_NO_TAG;
   }
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   //long orig_offset = _QROffset();
   int returnVal = XW_FOUND_NO_TAG;

   maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
   int status = search(namedFullStartOrEndTagRegex(name),'@-RHXCCCS');
   //XWsay(match_length('0')"|"match_length('1')"|"match_length('2'));
   if (status) {
      returnVal = XW_FOUND_NO_TAG;
   } else {
      //found start version
      if (match_length('0') != 0) {
         if (nestLevel == 1) {
            returnVal = XW_FOUND_S_TAG;
         } else
            returnVal = XW_FindNamedStartTag(name, nestLevel - 1);
      } else {
         returnVal = XW_FindNamedStartTag(name, nestLevel + 1);
      }
   }

   restore_search(s1,s2,s3,s4,s5);
   //_GoToROffset(orig_offset);
   return returnVal;
}

//Assuming not in a tag body
//Return 0 on error
//Return 1 on found a start block tag
int XW_FindParentBlockTag(_str &name, int &level) {
   int status = 1;
   while (isInlineTag(name)) {
      _str name2 = name;
      status = XW_FindParentBlockTag2(name, level);
      //XWsay(name2' Will return <'name'> 'status' '/*isInlineTag(name)*/);
      if (status == XW_FOUND_NO_TAG) {
         //XWmessageNwait('Returning no tag found');
         //return 0;
         return XW_FOUND_NO_TAG;
      }
   }
   //XWmessageNwait('Returning 'status);
   return status;
}
int XW_FindParentBlockTag3(_str &name, int &level) {
   int status = XW_FindParentBlockTag2(name, level);
   if (status == XW_FOUND_NO_TAG) {
      return XW_FOUND_NO_TAG;
   }
   return XW_FindParentBlockTag(name, level);
}
//Assuming not in a tag body
int XW_FindParentBlockTag2(_str &name, int &level) {
   //XWsay('XW_FindParentBlockTag2()');
   maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
   if (level > XW_RECURSE_LEVEL) {
      //XWsay('Hit recursion limit');
      return XW_FOUND_NO_TAG;
   }
   int status1 = XW_FindTag(name);
   if (status1 == XW_FOUND_S_TAG || status1 == XW_FOUND_NO_TAG) {
      return status1;
   } 
   // tagging for these languages is not strictly XML outlining,
   // so we need to use old-style tag matching
   if (XW_isHTMLTagLanguage(p_LangId)) {
      if (status1 == XW_FOUND_E_TAG) {
         right();
         int status_fmp = _find_matching_paren(0x7fffffff, true);
         if (status_fmp != 0) {
            //messageNwait('No matching');
            return XW_FOUND_NO_TAG;
         }
         level++;
         return XW_FindParentBlockTag2(name, level);
      } else if (status1 == XW_FOUND_EMPTY_TAG) {
         //_GoToROffset(_QROffset()-1);
         level++;
         return XW_FindParentBlockTag2(name, level);
      }
      //Should not reach this point.
      return XW_FOUND_S_TAG;
   } else if (!XW_isXMLTagLanguage(p_LangId)) {
      return(XW_FOUND_NO_TAG);
   }
   if (p_buf_size>def_update_context_max_file_size) {
      return(XW_FOUND_NO_TAG);
   }
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   XWsay('_UpdateContext(true)  called');
   int context_id = tag_current_context();
   if (context_id <=0) {
      XWsay('No context.');
      return(XW_FOUND_NO_TAG);
   }
   int parent_context=0;
   tag_get_detail2(VS_TAGDETAIL_context_outer,context_id,parent_context);
   if (!parent_context) {
      return(XW_FOUND_NO_TAG);
   }
   int start_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,parent_context,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_name,parent_context,name);
   _GoToROffset(start_seekpos);
   return(XW_FOUND_S_TAG);
}

/**
 * 
 * 
 * @author David A. O'Brien (9/29/2009)
 * 
 * @return int 
 */
_command int XW_promote() {
   return XW_sectadjust(-1, _QROffset());
}
_command int XW_demote() {
   return XW_sectadjust(1, _QROffset());
}
_command int XW_sectadjust(int delta = 1, long startOffset = 0) {
   //Maybe handle special case of cursor starting on an '<'

   long orig_offset = _QROffset();
   save_pos(auto startPos);
   _GoToROffset(startOffset);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   int status = search('\om{#0<sect{#1[12345]}}','@-RHXCS');
   if (status) {
      //nothing found
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }
   //found start version
   _str sectnum = get_text(match_length('1'), match_length('S1'));
   //Check that we are in proper range
   int sectnumint = delta + (int)sectnum;
   if (!((1 <= sectnumint) && (sectnumint <= 5))) {
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   //get context of surrounding section tag
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id <=0) {
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   //Find end of close tag
   long start_seekpos = _QROffset();
   long end_seekpos   = 0;
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
   if (!end_seekpos) {
      //Do nothing if not in a closed section context
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return 1;
   }

   //If starting offset is greater than end of close tag, need to search for next enclosing tag
   if (orig_offset >= end_seekpos) { 
      //start another search from start_seekpos
      _GoToROffset(start_seekpos);
      maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
      long nextSearchStartOffest = _QROffset();
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(startPos);
      return XW_sectadjust(delta, nextSearchStartOffest);
   }

   //Found our surrounding sect tag
   if ((start_seekpos <= orig_offset) && (orig_offset < end_seekpos))  {
      _GoToROffset(start_seekpos);
      select_char();
      _GoToROffset(end_seekpos);
      lock_selection('q');
      _GoToROffset(start_seekpos);
      //Update start and end tag names to ('sect'sectnumint)
      while (!search('{(role[ \t\10\13]*=[ \t\10\13]*[\"\'']SectionHeading)|(<(/:0,1)sect)}{[1-5]}', '@>*MRHXCS')) {
         _str part1 = get_text(match_length('1'), match_length('S1'));
         sectnumint = delta + (int)part1;
         if (!((1 <= sectnumint) && (sectnumint <= 5))) {
            //Skip this tag.
            continue;
            //Or perhaps change it and give a warning
         }
         search_replace('#0'sectnumint);
      }
      deselect();
   }
   
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(startPos);
   return 0;
}

/**
 * Checks to see if in the body of an XML tag (between the '<' and the '>').
 * 
 * This uses a loose definition of a tag that just looks for matching pairs of
 * '<' and '>'.  It does not check for well-formed tags.  This is consistent
 * with the XML color coding engine that color codes illegally defined tags.
 * Doe
 * 
 * @return long  The offset of the '<' if within an XML tag body.  0 if not.
 */
long XW_inTag3(int& location, boolean restoreLocation = true) {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   long orig_offset = _QROffset();
   long returnVal = 0;

   if (get_text() == XW_END_OF_TAG) {
      _GoToROffset(orig_offset-1);
   }

   //int status = search(XW_START_OF_START_TAG_LOOSE"|"XW_START_OF_END_TAG_LOOSE"|{#2"XW_END_OF_TAG_LOOSE"}",'@-RH');
   int status = search(XW_START_OF_START_TAG"|{#2"XW_END_OF_TAG"}",'@-RHXCCC');
   if (status) {
      //Case of found neither
      returnVal = 0;
      //Could also be case of just before the root tag.  Add look up of this
      //case later.
      location = XW_UNKNOWN;
      return returnVal;
   } 
   if (match_length('2') != 0) {
      //Case of found end '>'
      returnVal = 0;
      location = XW_IN_CONTENT;
      return returnVal;
   } 

   //Found a '<'
   returnVal = _QROffset();
   //Check case of '<>' and '</>'
   _str buffer2 = get_text(2);
   _str buffer3 = get_text(3);
   if (buffer2 == '<>' /*&& returnVal + 1 == orig_offset*/) {
      location = XW_IN_START_TAG;
   } else if (buffer2 == '</') {
      if (buffer3 == '</>')
         location = XW_IN_EMPTY_ELEM_TAG;
      else 
         location = XW_IN_END_TAG;
   } else {
      status = search(XW_END_OF_TAG"|"XW_END_OF_EMPTY_TAG,'@-HXCCC');
      if (status) {
         //Case of found no end '>'
         location = XW_IN_START_TAG;
      } else {
         if (get_text() == '/') 
            location = XW_IN_EMPTY_ELEM_TAG;
         else 
            location = XW_IN_START_TAG;
      }
   }

   restore_search(s1,s2,s3,s4,s5);
   if (restoreLocation)
      _GoToROffset(orig_offset);
   return returnVal;
}

/*
 /**
  * 0 not in tag
  * 1 open start
  * 2 closed start
  * 3 open end
  * 4 closed end
  * 5 closed empty
  *
  * @return int
  */
 int XW_inTag() {
    int returnVal = 0;
    long status1 = XW_inTag1();
    if (!status1) {
       return 0;//not in tag
    }
    long orig_offset = _QROffset();
    _GoToROffset(status1);
    //Are we closed
    long status1end = XW_matchClosingBracket();
    boolean isClosed = (status1end != 0);
    _str restOfLine = CW_getLineFromColumn();
    int statusTagMatch = pos(startOfStartOrEndTagRegexOM, restOfLine, 1, 'R');
    if (statusTagMatch != 1) {
       //messageNwait('Invalid tag');
       //invalid tag
       return 0;
    }
    if (substr(restOfLine, 1, 2) == '</')
       returnVal = 3;
    else returnVal = 1;
    if (isClosed)
       returnVal++;
    if (returnVal == 2) {
       //could be a closed empty tag
       _GoToROffset(status1end);
       if (p_col > 1) {
          left();
          if (get_text() == '/')
             returnVal = 5;
       }
    }
    _GoToROffset(orig_offset);
    return returnVal;
 }
*/

/**
 * 0 not in tag
 * 1 open start
 * 2 closed start
 * 3 open end
 * 4 closed end
 * 5 closed empty
 * 
 * @return int
 */
struct tagStat {
   boolean inTag;
   long tagStartOffset, tagEndOffset;
   boolean isClosed, isInlineTag;
   int type, startLine, endLine;
   _str tagName;
};
static initTagStat(tagStat &ts) {
   ts.inTag = ts.isInlineTag = false;
   ts.tagStartOffset = ts.tagEndOffset = -1;
   ts.isClosed = true;
   ts.type = 0;
   ts.startLine = ts.endLine = 0;
   ts.tagName = '';
}

/**
 * Return in tag stats as a struct
 * 
 * @return tagStat
 */
static tagStat XW_inTagB() {
   typeless p; save_pos(p);
   tagStat returnVal;
   initTagStat(returnVal);
   returnVal.tagStartOffset = XW_inTag1();
   if (returnVal.tagStartOffset == -1) {
      restore_pos(p);
      return returnVal;//not in tag
   }
   returnVal.inTag = true;
   _GoToROffset(returnVal.tagStartOffset);
   returnVal.startLine = p_line;
   //We are in a tag, but is it closed?
   returnVal.tagEndOffset = XW_matchClosingBracket();
   boolean isClosed = (returnVal.tagEndOffset != 0);
   _str restOfLine = CW_getLineFromColumn();
   int statusTagMatch = pos(startOfStartOrEndOrEmptyTagRegexOM, restOfLine, 1, 'R');
   returnVal.tagName = substr(restOfLine, pos('S0'),pos('0'));
   returnVal.isInlineTag = isInlineTag(returnVal.tagName);
   if (statusTagMatch != 1) {
      initTagStat(returnVal);
      //XWsay('Invalid tag');
      //invalid tag
      restore_pos(p);
      return returnVal;
   }

   if (substr(restOfLine, 1, 2) == '</')
      returnVal.type = 3;
   else returnVal.type = 1;
   if (isClosed) 
      returnVal.type++;
   if (returnVal.type == 2) {
      //could be a closed empty tag
      _GoToROffset(returnVal.tagEndOffset);
      if (p_col > 1) {
         left();
         if (get_text() == '/')
            returnVal.type = 5;
      }
   }
   _GoToROffset(returnVal.tagEndOffset);
   returnVal.endLine = p_line;
   //_GoToROffset(orig_offset);
   restore_pos(p);
   return returnVal;
}

/**
 * Simple in tag test.  If searching backwards, a tag opening 
 * char ('&lt;') is found before a closing char ('&gt;'), than 
 * in a tag. 
 * 
 * This uses a loose definition of a tag that just looks for matching pairs of
 * '&lt;' and '&gt;'.  It does not check for well-formed tags.  This is 
 * consistent with the XML color coding engine that color codes illegally 
 * defined tags. Does not differentiate between start tags, end tags, or empty 
 * element tags. 
 * 
 * @return long -1 if not in tag, else offset of tag opening char.
 */
/*static*/ long XW_inTag1() {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   typeless p; save_pos(p);
   long returnVal = -1;

   if (!maybeMoveBackCursor(XW_TAG_BRACKETS)) {
      return returnVal;
   }

   int status = search('{#1'XW_TAG_OPEN_BRACKET'}|'XW_TAG_CLOSE_BRACKET,'@-RHXCS');
   if ((!status) && (match_length('1') != 0)) {
      //say('//Found open bracket');
      returnVal = _QROffset();
      restore_pos(p);
   } 

   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return returnVal;
}

/**
 * Assumes that the cursor is on a '<' of a tag.  Searches for the matching '>'.  It must come
 * before any new opening bracket.
 * 
 * @return long Zero if not found (thus this is an unclosed tag, else offset of tag closing
 *         char.
 */
/*static*/ long XW_matchClosingBracket() {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   long orig_offset = _QROffset();
   long returnVal = 0;

   if (get_text() != '<')
      return returnVal;
   //move over current '<'
   right();

   int status = search('{#1'XW_TAG_CLOSE_BRACKET'}|'XW_TAG_OPEN_BRACKET,'@RHXCCCS');
   if ((!status) && (match_length('1') != 0)) {
      //Found closing bracket
      returnVal = _QROffset();
   } 

   restore_search(s1,s2,s3,s4,s5);
   _GoToROffset(orig_offset);
   return returnVal;
}

struct XW_state {
   long sTagOffset, eTagOffset, thisSTagOffset, thisETagOffset, sTagCloseOffset;
   int sTagLine, sTagCloseLine, sTagCol;
   int eTagLine, eTagCol;
   //this prefix means tag we are actually in, e/s prefix is the tag defining the behavior
   int thisSTagLine, thisSTagCol;
   int thisETagLine, thisETagCol;
   long cursorOffset;
   int cursorLine, cursorCol;
   int LMargin, RMargin;
   _str tagName, thisTagName;
};
static XW_state XWstate;
void XWclearState(_str name = '') {
   XWstate.sTagOffset = XWstate.eTagOffset = XWstate.sTagCloseOffset = XWstate.sTagLine = XWstate.sTagCloseLine = XWstate.eTagLine = XWstate.sTagCol = XWstate.eTagCol = 0;
   XWstate.thisSTagOffset = XWstate.thisETagOffset = XWstate.thisSTagLine = XWstate.thisETagLine = XWstate.thisSTagCol = XWstate.thisETagCol = 0;
   XWstate.cursorOffset = XWstate.cursorLine = XWstate.cursorCol = XWstate.LMargin = XWstate.RMargin = 0;
   XWstate.tagName = XWstate.thisTagName = name;
}

/**
 * Check if we should try to wrap content in this XML tag.
 * 
 * @return int   0 if we should try to format
 *               1 if not in a situation we can
 *               handle
 *               2 if formatting not enabled
 *               3 if inside a pre tag, do not wrap
 */
//Need to make these return values #defines
// int XW_checkWrapStatus() {
//    XWdocStat thisDocStat = getDocStat();
//    if (XW_isSupportedLanguage() && (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP) || _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT)) && ((!(thisDocStat.featureOptions & XWflagsSetFlag)) || ((thisDocStat.featureOptions & XWflagsSetFlag) && (thisDocStat.featureOptions & (XWcontentWrapFlag | XWtagLayoutFlag))) )) {
//       return 0;
//    }
//    return 1;
// }
static boolean XW_CWthisExt() {
   //say(xw_p_LangId());
   if (XW_isSupportedLanguage2(xw_p_LangId()) /*&& _GetXMLWrapFlags(XW_ENABLE_FEATURE)*/ && _GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, xw_p_LangId()))
      return true;
   return false;
}
static boolean XW_TLthisExt() {
   if (XW_isSupportedLanguage2(xw_p_LangId()) /*&& _GetXMLWrapFlags(XW_ENABLE_FEATURE)*/ && _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, xw_p_LangId()))
      return true;
   return false;
}
static boolean XW_XWthisDoc() {
   if (XW_CWthisDoc() || XW_TLthisDoc())
      return true;
   return false;
}
static boolean XW_CWthisDoc() {
   if (_in_comment(false)) return false;
   XWdocStat thisDocStat = getDocStat();
   if (thisDocStat == null || thisDocStat.featureOptions == null) {
      return false;
   }
   //XWsay(thisDocStat.featureOptions);
   if (XW_CWthisExt() && ((!(thisDocStat.featureOptions & XWflagsSetFlag)) || ((thisDocStat.featureOptions & XWflagsSetFlag) && (thisDocStat.featureOptions & XWcontentWrapFlag)) ))
      return true;
   return false;
}
static boolean XW_TLthisDoc() {
   XWdocStat thisDocStat = getDocStat();
   if (thisDocStat == null || thisDocStat.featureOptions == null) {
      return false;
   }
   if (XW_TLthisExt() && ((!(thisDocStat.featureOptions & XWflagsSetFlag)) || ((thisDocStat.featureOptions & XWflagsSetFlag) && (thisDocStat.featureOptions & XWtagLayoutFlag)) ))
      return true;
   return false;
}

/*
struct XW_state {
   long sTagOffset, eTagOffset, thisSTagOffset, thisETagOffset, sTagCloseOffset;
   int sTagLine, sTagCloseLine, sTagCol;
   int eTagLine, eTagCol;
   int thisSTagLine, thisSTagCol;
   int thisETagLine, thisETagCol;
   int cursorOffset, cursorLine, cursorCol;
   int LMargin, RMargin;
   _str tagName, thisTagName;
};
*/
boolean matchPrevState(boolean fromDoEditKey) {
   int offset = 0;
   if (fromDoEditKey) { //XWsay("FronDoEditKey  XWstate.cursorOffset = "XWstate.cursorOffset);
      offset = 1;
   }

   if ( !( (XWstate.cursorOffset == (_QROffset() - offset)) && (XWstate.cursorCol == (p_col - offset)) && (XWstate.cursorLine == p_line) ) ) {
      return false;
   }
   //if (XWstate.thisTagName == '') {
   //   return false;
   //}
   return true;
}

storeCursorState() {
   XWstate.cursorOffset = _QROffset();
   XWstate.cursorCol = p_col;
   XWstate.cursorLine = p_line;
   //XWsay('saving '_QROffset()' 'p_col' 'p_line);
}

/**
 * Assumes that cursor is at the start tag and tries to find the line number of 
 * the corresponding end tag to a point.  If end tag is not on the current line 
 * or the next line, then it just returns the current line +2. 
 * 
 * @param tagName 
 * 
 * @return int line number of end tag approximation as above.
 */
static int XW_find_match_end_line_fast(_str tagName, long startOffset) {
   //return p_line+2;
   //messageNwait(tagName' XW_find_match_end_line_fast');
   _str line1 = '';
   _str line2 = '';
   save_pos(auto p);
   if (XW_isXMLTagLanguage(p_LangId) || XW_isHTMLTagLanguage(p_LangId)) {
      _GoToROffset(startOffset);
      right();
      int startCol = p_col;
      _find_matching_paren(0x7fffffff, true);
      int returnVal = p_line;
      int endCol    = p_col;
      restore_pos(p);
      //Check if no match found
      if (returnVal == p_line && endCol == startCol) {
         returnVal = p_line + 2;
      }
      return returnVal;
   }
   return p_line + 2;
   
   get_line(line1);
   p_col += tagName._length();
   _str endRegex = namedFullEndTagRegex(tagName);
   int start_col = text_col(line1, p_col, 'P');
   
   int endPos1 = pos(endRegex, line1, start_col, 'R');
   int endPos2;
   if (!endPos1) {
      if (!down()) {
         restore_pos(p);
         return p_line+2;
      }
      get_line(line2);
      endPos2 = pos(endRegex, line2, start_col, 'R');
      if (!endPos2) {
         restore_pos(p);
         return p_line+2;
      }
   }
   
   restore_pos(p);
   return p_line;
}

/**
 * 
 * @param fromDoEditKey
 * 
 * @return int   0 if we should try to format
 *               1 if not in a situation we can
 *               handle
 *               2 if formatting not enabled
 *               3 if inside a pre tag, do not wrap
 *               5 if no context
 */
int XW_check_state(boolean fromDoEditKey = false) 
{
   // is formatting even allowed right now?
   if (!(XW_isSupportedLanguage2() && XW_XWthisDoc())) {
      XWclearState();
      return 2;
   }

   //If typing where we just typed, skip the check and use the saved state
   if (matchPrevState(fromDoEditKey)) {
      XWsay ('Matched');
      if (XWstate.thisTagName == XW_NOCONTEXTNAME) {
         return 5;
      }
      return 0;
   }
   //XWsay ('Not Matched');
   //Recalculate state, start with fresh slate
   XWclearState();
   long orig_offset = _QROffset();
   typeless p; save_pos(p);

   //Are we inside a element tag
   long inTagStatus = XW_inTag1();
   int status;
   //try to move to front of start tag
   if (inTagStatus != -1) {
      status = XW_check_stateInTag(inTagStatus);
   } else { //handle case of outside tag body
      status = XW_check_stateOutTag();
   }
   //Return if we can not find any context
   if (status == XW_OUTSIDEWRAPCONTEXT) {
      XWclearState(XW_NOCONTEXTNAME);
      storeCursorState();
      restore_pos(p);
      return 5;
   }
   //State of current tag is now stored.  Cursor in front of start tag
   //XWmessageNwait('Moved to front of this start tag');
   if (status) {
      //XWsay('Bad status');
      XWclearState();
      restore_pos(p);
      return 1;
   }   

   //Find the defining block tag
   //Two cases: This tag is inline or block

   //move to first parent block tag
   int levels = 0;_str tagName = XWstate.thisTagName;
   status = XW_FindParentBlockTag(tagName, 0);
   XWsay(status'*'tagName'*');
   if (!status) {
      //No context.
      XWsay('Bad status2');
      XWclearState(XW_NOCONTEXTNAME);
      restore_pos(p);
      storeCursorState();
      return 5;
   }
   //Check for <pre> tag
   long outer_tag_offset = _QROffset();
   int preTagNestLevel = 1;
   _str tagName2 = tagName;
   XW_ContentWrapSettings wrapSetting = getWrapSettings(tagName);
   while (wrapSetting.wrapMode != XW_CWS_PRESERVE && preTagNestLevel < XW_PRE_TAG_NEST_LIMIT) {
      //maybeMoveBackCursor(XW_TAG_OPEN_BRACKET);
      status = XW_FindParentBlockTag2(tagName2, 0);
      //XWmessageNwait(tagName2);
      if (!status) {
         break;
      }
      wrapSetting = getWrapSettings(tagName2);
      preTagNestLevel++;
   }
   if (wrapSetting.wrapMode == XW_CWS_PRESERVE) {
      //XWsay('Clear due to pre tag');
      XWclearState();
      restore_pos(p);
      //_GoToROffset(orig_offset);
      return XW_INSIDEPRETAG;
   }
   //return after search for pre tags
   _GoToROffset(outer_tag_offset);

   //XWmessageNwait('Moved to front of this defining tag');
   XWstate.sTagOffset = _QROffset();
   XWstate.sTagLine = p_line;
   XWstate.sTagCol = p_col;
   XWstate.tagName = tagName;
   XWstate.sTagCloseOffset = XW_matchClosingBracket();
   _GoToROffset(XWstate.sTagCloseOffset);
   XWstate.sTagCloseLine = p_line;
   //_GoToROffset(orig_offset);
   XWstate.eTagLine = XW_find_match_end_line_fast(tagName, XWstate.sTagOffset);

   restore_pos(p);
   return 0;
}

/**
 * 
 * @return int Return 0 if successful.
 */
static int XW_check_stateOutTag() {
   _str name = "";
   int levels = 0;
   int status = XW_FindParentBlockTag2(name, levels);
   if (status == XW_FOUND_NO_TAG) {
      XWsay('No surrounding block tag');
      return XW_OUTSIDEWRAPCONTEXT;
   }
   //XWmessageNwait('Found parent block at offset = '_QROffset());
   //XWmessage('Found parent block 'name' at offset = '_QROffset());
   XWstate.thisSTagOffset = _QROffset();
   XWstate.thisSTagLine = p_line;
   XWstate.thisSTagCol = p_col;
   XWstate.thisTagName = name;

   return 0;
}
/**
 * 
 * @param tagOffset Offset of start of tag
 * 
 * @return int return 0 if successful.
 */
static int XW_check_stateInTag(long tagOffset) {
   //XWsay('XW_check_stateInTag');
   _GoToROffset(tagOffset);
   right();
   boolean isEndTag = false;
   if(get_text() == '/') {
      isEndTag =true;
      right();
   }
   _str line = CW_getLineFromColumn();
   _GoToROffset(tagOffset);
   int posResult = pos('{#0'XW_NAME_REGEX'}(:b|>|$)', line, 1, 'R');
   if (!posResult) {//say('Could not read name of tag REGEX');
      XWclearState();
      return 1;
   }
   _str tagNameInside = substr(line,pos('S0'),pos('0'));
   if (isInlineTag(tagNameInside)) {
      //TODO is this correct?
      //return XW_check_stateOutTag();
   }
   if (isEndTag) {
      XWstate.thisETagOffset = tagOffset;
      XWstate.thisETagLine = p_line;
      XWstate.thisETagCol = p_col;
      XWstate.thisTagName = tagNameInside;
      _GoToROffset(tagOffset);
      //int status = XW_FindNamedStartTag(tagNameInside);
      //if (status != XW_FOUND_S_TAG) {
         //when in unmatched end tag, assume that your are not in a tag and search for context

      //TODO check that this is correct 2/28/07
         //XW_check_stateOutTag();
         return XW_check_stateOutTag();
      //} 
   }
   //if this tag (tagNameInside) is a block tag, wrap any content at end of line (unlikely)
   //if it is an inline, move to parent
   
   XWstate.thisSTagOffset = tagOffset;
   XWstate.thisSTagLine = p_line;
   XWstate.thisSTagCol = p_col;
   XWstate.thisTagName = tagNameInside;
   return 0;
}

//static XW_TagSettings defaulatTagSettings(_str name = XW_DEFAULT_TAGNAME) {
//   XW_TagSettings returnVal;
//   returnVal.name = name;
//   returnVal.matchTagName = XW_DEFAULT_MATCH_TAGNAME;
//   returnVal.generalSettings = DEFAULTGENERALSETTINGS;
//   returnVal.contentWrapSettings = DEFAULTCONTENTWRAPSETTINGS;
//   returnVal.tagLayoutSettings = DEFAULTTAGLAYOUTSETTINGS;
//   return returnVal;
//}

_str lookupschemename() {
   _str thisScheme;
   _str bufferName = xw_buf_name();
   if (filenameToXWdocStatHash._indexin(bufferName)) {
      thisScheme = filenameToXWdocStatHash:[bufferName].scheme;
   } else {
      filenameToXWdocStatHash:[bufferName] = getDocStat();
      //thisScheme = XW_getDefaultSchemeName();
      thisScheme = filenameToXWdocStatHash:[bufferName].scheme;
   }
   return thisScheme;
}
//Given a tag name, returns the final tag name that the original name refers to
_str lookupTagname(_str tagname) {
   if (p_LangId == 'html') {
      tagname = lowcase(tagname);
   }
   _str thisScheme = lookupschemename();
   return lookupTagname2(tagname, thisScheme);
}
//Given a tag name, returns the final tag name that the original name refers to
_str lookupTagname2(_str tagname, _str thisScheme) {
   if (!XW_schemes:[thisScheme].tagSettings._indexin(tagname)){
      if (!XW_schemes:[thisScheme].tagSettings._indexin(XW_DEFAULT_TAGNAME)){
         XW_schemes:[thisScheme].tagSettings:[XW_DEFAULT_TAGNAME] = defaultTagSettings;
      }
      return XW_DEFAULT_TAGNAME;
   } else {
      //XWsay('We do have 'thisScheme' 'tagname' in XW_schemes');
   }
   _str nextMatchName = '';
   _str currentMatchName = tagname;
   //while (XW_schemes:[thisScheme].tagSettings:[currentMatchName].matchTag){
   //while (matchStyleNameValidGui(thisScheme)){
   while (XW_schemes:[thisScheme].tagSettings._indexin(currentMatchName)){
      nextMatchName = XW_schemes:[thisScheme].tagSettings:[currentMatchName].matchTagName;
      if (nextMatchName == XW_DEFAULT_MATCH_TAGNAME || !XW_schemes:[thisScheme].tagSettings._indexin(nextMatchName)) {
         break;
      }
      currentMatchName = nextMatchName;
   }
   return currentMatchName;
}


static void XW_removeCycles(_str schemeName) {
   XW_TagSettings S:[] = XW_schemes:[schemeName].tagSettings;
   typeless i;
   // Traverse the scheme elements in hash table
   _str tagName[];
   for (i._makeempty();;) {
       S._nextel(i);
       if (i._isempty()) break;

       if (tagnameMakesCycle(schemeName, S:[i].name)) {
          //XW_schemes:[schemeName].tagSettings:[S:[i].name].matchTag = false;
          XW_schemes:[schemeName].tagSettings:[S:[i].name].matchTagName = XW_DEFAULT_MATCH_TAGNAME;
          XW_saveXWScheme(XW_schemes:[schemeName]);
       }
   }
}

//Given a tag name, returns true if the refereneces from this tag, cause a cycle.
//Assumes that the tag name is in the scheme
boolean tagnameMakesCycle(_str thisScheme, _str tagname) {
   if (!XW_schemes:[thisScheme].tagSettings._indexin(tagname)){
      //Should only be called with tag names that exist
      return false;
   }
   int cycleChecker:[]; cycleChecker._makeempty();
   cycleChecker:[tagname] = 0;
   _str nextMatchName = '';
   _str currentMatchName = tagname;
   //while (XW_schemes:[thisScheme].tagSettings:[currentMatchName].matchTag){
   while (true){
      nextMatchName = XW_schemes:[thisScheme].tagSettings:[currentMatchName].matchTagName;
      if (nextMatchName == XW_DEFAULT_MATCH_TAGNAME || nextMatchName == '' || !XW_schemes:[thisScheme].tagSettings._indexin(nextMatchName)) {
         break;
      }
      if (cycleChecker._indexin(nextMatchName)) {
         return true;
      }
      cycleChecker:[nextMatchName] = 0;
      currentMatchName = nextMatchName;
   }
   return false;
}

static boolean XW_inPreserveFormatTag() {
   return false;
}

static boolean isInlineTag(_str tagname) {
   _str theScheme = lookupschemename();
   _str theTag = lookupTagname(tagname);
   //XWsay(tagname' 'theScheme' 'theTag);
   if (theScheme == null || theTag == null || !XW_schemes._indexin(theScheme) || XW_schemes:[theScheme] == null || !XW_schemes:[theScheme].tagSettings._indexin(theTag) || XW_schemes:[theScheme].tagSettings:[theTag] == null) {
      return defaultContentWrapSettings.wrapMode == XW_CWS_IGNORE;
   }
   if (XW_schemes:[theScheme].tagSettings:[theTag].contentWrapSettings.wrapMode == XW_CWS_IGNORE){
      return true;
   }
   return false;
}

static boolean isSemiBlockEndTag(_str tagname) {
   _str theScheme = lookupschemename();
   _str theTag = lookupTagname(tagname);
   XWsay(tagname' 'theScheme' 'theTag);
   if (!XW_schemes._indexin(theScheme) || !XW_schemes:[theScheme].tagSettings._indexin(theTag)) {
      return defaultContentWrapSettings.wrapMode == XW_CWS_IGNORE;
   }
   return XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].tagLayoutSettings.separateEndTag;
}

static boolean isInsertEndTag(_str tagname) {
   //TODO Add different logic for XML and XHTML
   if (XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].generalSettings.insertEndTags){
      return true;
   }
   return false;
}
static boolean isHasEndTag(_str tagname) {
   //TODO Add different logic for XML and XHTML
   if (XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].generalSettings.hasEndTag){
      return true;
   }
   return false;
}

XW_TagLayoutSettings getLayoutSettings(_str tagname) {
   return XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].tagLayoutSettings;
}

XW_ContentWrapSettings getWrapSettings(_str tagname) {
   return XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].contentWrapSettings;
}

boolean separateStartLine(_str tagname) {
   return XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].tagLayoutSettings.separateStartTag;
}
boolean separateEndLine(_str tagname) {
   return XW_schemes:[lookupschemename()].tagSettings:[lookupTagname(tagname)].tagLayoutSettings.separateEndTag;
}

int getSchemeIndentStyle() {
   return XW_schemes:[lookupschemename()].tagIndentStyle;
}
boolean getSchemeOnlyWrap() {
   return false;
   //return XW_schemes:[lookupschemename()].onlyWrap;
}

boolean nestTagsWithContent() {
   return (getSchemeIndentStyle() == XW_SS_PARENTINDENT);
}

_str XW_schemeNameToSchemeFileName(_str schemeName) {

   if (schemeName == "") return "";
   _str XWSchemeFileName = '';
   XWSchemeFileName = getUserXWSchemesDir();
   if (XWSchemeFileName == "") {
      return "";
   }
   _maybe_append_filesep(XWSchemeFileName);
   strappend(XWSchemeFileName, schemeName);
   strappend(XWSchemeFileName, XW_SCHEME_EXTENSION);
   return XWSchemeFileName;
}

/**
 * 
 * @param filename
 * 
 * @return boolean True if able to read in the scheme from file, else False
 */
//boolean XW_readXWScheme(_str schemeName = XW_DEFAULT_SCHEME,_str XWSchemeFileName='')
boolean XW_readXWScheme(_str schemeName)
{  
   if (schemeName == "" || schemeName == null) return false;
   _str XWSchemeFileName = XW_schemeNameToSchemeFileName(schemeName);
   //XWsay(XWSchemeFileName);
   if (XWSchemeFileName == "") {
      return false;
   }

   if (!file_exists(XWSchemeFileName)) {
      //scheme file does not exist, so create a new one with default settings
      //XWsay('Unable to open scheme 'XWSchemeFileName'.  Using default scheme.');
      maybeMakeDefaultXWScheme(schemeName);
      return false;
   }

   return XW_readXWSchemeFromFile(schemeName, XWSchemeFileName);
}

boolean XW_readXWSchemeFromFile(_str schemeName, _str filename)
{
   XW_Scheme schemeBuffer;
   if (!XW_readXWScheme2(filename, schemeBuffer)) return false;

   //XWsay(schemeBuffer.Name);
   //Scheme read in successfully, so store in memory
   
   //Add this scheme to the list of schemes 
   schemeBuffer.Name = schemeName;
   XW_schemes:[schemeName] = schemeBuffer;

   //Add this schemes default use types to the hash table
   int i;
   for (i = 0; i < schemeBuffer.useWithDefault._length(); i++) {
      useWithSchemeHash:[schemeBuffer.useWithDefault[i].type' 'schemeBuffer.useWithDefault[i].value] = schemeName;
   }

   return true;
}

/**
 * 
 * @param filename  Full path of xml file holding options set
 * @param schemeBuffer  In param to store results of read
 * 
 * @return boolean True if able to read in the scheme from file, else False
 */
static boolean XW_readXWScheme2(_str filename, XW_Scheme& schemeBuffer)
{  
   if (!file_exists(filename)) {
      return false;
   }

   int status;
   int treeHandle = _xmlcfg_open(maybe_quote_filename(filename), status, VSXMLCFG_OPEN_REFCOUNT, VSENCODING_AUTOXML);
   if (treeHandle < 0 || status < 0) {
      //XWsay('Unable to open 'filename);
      XWmessage(get_message(treeHandle));
      return false;
   }
   int rootNode = _xmlcfg_find_child_with_name(treeHandle, TREE_ROOT_INDEX,
                                         XW_SCHEME_TAGNAME,
                                         VSXMLCFG_NODE_ELEMENT_START);
   if (rootNode < 0) {
      //XWmessage(get_message(rootNode));
      return false;
   }
   //XWmessageNwait("HERE 111");
   //Try to read scheme name
   _str schemeName = _xmlcfg_get_attribute(treeHandle, rootNode, 'name', "");
   if (schemeName == "")
      return false;
   schemeBuffer.Name        = schemeName;
   schemeBuffer.tagIndentStyle = (int)_xmlcfg_get_attribute(treeHandle, rootNode, XW_INDENTSTYLE_ATTRIB, XW_SS_TAGINDENTSTYLEDEFAULT);
   schemeBuffer.caseSensitive    = (((int)_xmlcfg_get_attribute(treeHandle, rootNode, XW_CASESENSITIVE_ATTRIB, '1')) == 1);
   XW_TagSettings tagBuffer;
   XW_SchemeUseWith useWithBuffer;
   int tagNode = _xmlcfg_get_first_child(treeHandle, rootNode, VSXMLCFG_NODE_ELEMENT_START);
   while (tagNode >= 0) {
      //say(_xmlcfg_get_name(treeHandle, tagNode));
      switch(_xmlcfg_get_name(treeHandle, tagNode)) {
         case XW_USEWITH_TAGNAME:
            if (XW_readUseTag(treeHandle, tagNode, useWithBuffer))
               schemeBuffer.useWithDefault[schemeBuffer.useWithDefault._length()] = useWithBuffer;
            break;
         case XW_TAG_TAGNAME:
            if (XW_readXWTag(treeHandle, tagNode, tagBuffer))
               schemeBuffer.tagSettings:[tagBuffer.name] = tagBuffer;
            break;
      }
      tagNode = _xmlcfg_get_next_sibling(treeHandle, tagNode, VSXMLCFG_NODE_ELEMENT_START);
   }
   if (_xmlcfg_close(treeHandle)) {
      message("Could not read in scheme file "filename);
      delete_file(maybe_quote_filename(filename));
      return false;
   }
   return true;
}

boolean XW_readXWTag(int treeHandle, int tagNode, XW_TagSettings &settings) {
   settings.name = _xmlcfg_get_attribute(treeHandle, tagNode, 'name', "");
   if (settings.name == "") {
      return false;
   }
   //settings.matchTag = (((int)_xmlcfg_get_attribute(treeHandle, tagNode, XW_MATCHTAG_ATTRIB, 0)) == 1);
   settings.matchTagName = _xmlcfg_get_attribute(treeHandle, tagNode, XW_MATCHTAGNAME_ATTRIB, XW_DEFAULT_MATCH_TAGNAME);

   int setNode = _xmlcfg_get_first_child(treeHandle, tagNode, VSXMLCFG_NODE_ELEMENT_START);
   boolean readGenSettings = false, readCWSettings = false, readTLSettings = false;
   while (setNode >= 0) {
      //XWsay('---'_xmlcfg_get_name(treeHandle, setNode));
      switch (_xmlcfg_get_name(treeHandle, setNode)) {
      case XW_GENSETTINGS_TAGNAME:
         settings.generalSettings.hasEndTag = (((int)_xmlcfg_get_attribute(treeHandle, setNode,      XW_HASENDTAG_ATTRIB, defaultTagSettings.generalSettings.hasEndTag)) == 1);
         settings.generalSettings.insertEndTags = (((int)_xmlcfg_get_attribute(treeHandle, setNode,  XW_INSERTENDTAG_ATTRIB, defaultTagSettings.generalSettings.insertEndTags)) == 1);
         //settings.generalSettings.endTagRequired = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_REQUIREDENDTAG_ATTRIB, defaultTagSettings.generalSettings.endTagRequired)) == 1);
         readGenSettings = true;
         break;
      case XW_CWSETTINGS_TAGNAME: 
         settings.contentWrapSettings.wrapMode           = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_WRAPMODE_ATTRIB, defaultTagSettings.contentWrapSettings.wrapMode);
         settings.contentWrapSettings.wrapMethod         = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_WRAPMETHOD_ATTRIB, defaultTagSettings.contentWrapSettings.wrapMethod);
         settings.contentWrapSettings.fixedWidthCol      = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_FIXEDWIDTHCOL_ATTRIB, defaultTagSettings.contentWrapSettings.fixedWidthCol);
         settings.contentWrapSettings.fixedWidthMRC      = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_FIXEDWIDTHMRC_ATTRIB, defaultTagSettings.contentWrapSettings.fixedWidthMRC);
         settings.contentWrapSettings.autoWidthMRC       = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_AUTOWIDTHMRC_ATTRIB, defaultTagSettings.contentWrapSettings.autoWidthMRC);
         settings.contentWrapSettings.fixedRightCol      = (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_FIXEDRIGHTCOL_ATTRIB, defaultTagSettings.contentWrapSettings.fixedRightCol);
         settings.contentWrapSettings.useFixedWidthMRC   = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_USEFIXEDWIDTHMRC_ATTRIB, defaultTagSettings.contentWrapSettings.useFixedWidthMRC)) == 1);
         settings.contentWrapSettings.useAutoWidthMRC    = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_USEAUTOWIDTHMRC_ATTRIB, defaultTagSettings.contentWrapSettings.useAutoWidthMRC)) == 1);
         settings.contentWrapSettings.includeTags        = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_INCLUDETAGS_ATTRIB, defaultTagSettings.contentWrapSettings.includeTags)) == 1);
         settings.contentWrapSettings.preserveWidth      = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_PRESERVEWIDTH_ATTRIB, defaultTagSettings.contentWrapSettings.preserveWidth)) == 1);
         readCWSettings = true;
         break;
      case XW_TLSETTINGS_TAGNAME: 
         //settings.tagLayoutSettings.layoutStyle      =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_LAYOUTSTYLE_ATTRIB, defaultTagSettings.tagLayoutSettings.layoutStyle);
         settings.tagLayoutSettings.indentMethod     =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_INDENTMETHOD_ATTRIB, defaultTagSettings.tagLayoutSettings.indentMethod);
         settings.tagLayoutSettings.indentFrom       =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_INDENTFROM_ATTRIB, defaultTagSettings.tagLayoutSettings.indentFrom);
         settings.tagLayoutSettings.indentSpaces     =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_INDENTSPACES_ATTRIB, defaultTagSettings.tagLayoutSettings.indentSpaces);
         settings.tagLayoutSettings.lineBreaksBefore =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_LINESBEFORE_ATTRIB, defaultTagSettings.tagLayoutSettings.lineBreaksBefore);
         settings.tagLayoutSettings.lineBreaksAfter  =   (int)_xmlcfg_get_attribute(treeHandle, setNode, XW_LINESAFTER_ATTRIB, defaultTagSettings.tagLayoutSettings.lineBreaksAfter);
         settings.tagLayoutSettings.separateStartTag = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_SEPSTARTTAG_ATTRIB, defaultTagSettings.tagLayoutSettings.separateStartTag)) == 1);
         settings.tagLayoutSettings.separateEndTag   = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_SEPENDTAG_ATTRIB, defaultTagSettings.tagLayoutSettings.separateEndTag)) == 1);
         settings.tagLayoutSettings.preserveLayout   = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_PRESERVELAYOUT_ATTRIB, defaultTagSettings.tagLayoutSettings.preserveLayout)) == 1);
         settings.tagLayoutSettings.applyLayout      = (((int)_xmlcfg_get_attribute(treeHandle, setNode, XW_APPLYLAYOUT_ATTRIB, defaultTagSettings.tagLayoutSettings.applyLayout)) == 1);
         readTLSettings = true;
         break;
      default:
         //XWsay("This shouldn't happen.");
         return false;
         break;
      }
      setNode = _xmlcfg_get_next_sibling(treeHandle, setNode, VSXMLCFG_NODE_ELEMENT_START);
   }
   //settings = defaultTagSettings;
   //Be sure that we read all the settings
   if (!(readGenSettings && readCWSettings && readTLSettings)) {
      return false;
   }
   return true;
}

boolean XW_readUseTag(int treeHandle, int useWithNode, XW_SchemeUseWith &useWithBuffer) {
   _str typeStr = _xmlcfg_get_attribute(treeHandle, useWithNode, XW_USEWITH_TYPE_ATTRIB, XW_UW_BADTYPE);

   int type;
   switch (typeStr) {
      case XW_UW_EXTTYPEATTRIB:
         type = XW_UW_EXT;
         break;
      case XW_UW_MODETYPEATTRIB:
         type = XW_UW_MODE;
         break;
      case XW_UW_DTDTYPEATTRIB:
         type = XW_UW_DTD;
         break;
      case XW_UW_SCHEMATYPEATTRIB:
         type = XW_UW_SCHEMA;
         break;
      default:
         return false;
   }
   _str value = strip(_xmlcfg_get_attribute(treeHandle, useWithNode, XW_USEWITH_VALUE_ATTRIB, ""));
   if (value == '') {
      return false;
   }
   useWithBuffer.type = type;
   useWithBuffer.value = value;
   return true;
}

_command _str getUserXWSchemesDir() {
   boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (cant_write_config_files) return("");
   if (_create_config_path()) {
      return "";
   }
   _str XWschemesDir = _ConfigPath();
   strappend(XWschemesDir, XW_FORMATSCHEMES_DIR);
   _maybe_append_filesep(XWschemesDir);
   strappend(XWschemesDir, XW_XMLHTMLSCHEMES_SUBDIR);

   int status = 0;
   if( !isdirectory(XWschemesDir) ) {
      status=make_path(XWschemesDir);
      if( status!=0 ) {
         _str msg = "Error creating directory:\n\n":+
                    XWschemesDir:+"\n\n":+
                    get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return "";
      }
   }
   return (XWschemesDir);
}

boolean maybeMakeDefaultXWScheme(_str schemeName)
{  
   //Check if already loaded or if we can load the named scheme
   if (XW_checkSchemeLoaded(schemeName)) {
      return true;
   }
   
   //if not, try to make a copy of default provided xml scheme for the named scheme
   if (XW_CopyScheme(XW_XML_SCHEMA_FILENAME, schemeName)) {
      return true;
   }
   
   //If can not copy, then make a new totally blank scheme for the named scheme
   _str tagNames[];
   tagNames._makeempty();
   return maybeMakeBlankXWScheme(schemeName, tagNames, defaultTagSettings, defaultTagSettings, true);
}
static boolean maybeMakeBlankXWScheme(_str schemeName, _str tagNames[], XW_TagSettings settings1, XW_TagSettings settings2, boolean force = false)
{//XWmessageNwait(filename'  Blank');
   if (schemeName == 'default') {
      return false;
   }
   int status;
   _str XWSchemeFileName = XW_schemeNameToSchemeFileName(schemeName);
   if (XWSchemeFileName == "") {
      return false;
   }

   if (file_exists(XWSchemeFileName) && !force) {
      return true;
   }

   int xmlSchemasHandle = _xmlcfg_create(XWSchemeFileName, VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if (xmlSchemasHandle < 0) {
      //XWsay('Unable to open 'XWSchemeFileName);
      return false;
   }

   int doctypeNode = _xmlcfg_add(xmlSchemasHandle, TREE_ROOT_INDEX, 'DOCTYPE', VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, doctypeNode, 'root', XW_SCHEME_TAGNAME);
   _xmlcfg_set_attribute(xmlSchemasHandle, doctypeNode, 'SYSTEM', XW_DTD);
   int rootNode = _xmlcfg_add(xmlSchemasHandle, doctypeNode, XW_SCHEME_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, 'name', schemeName);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, XW_INDENTSTYLE_ATTRIB, XW_SS_TAGINDENTSTYLEDEFAULT);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, XW_CASESENSITIVE_ATTRIB, XW_SS_CASESENSITIVEDEFAULT);
   //Add (default) tag
   int tagNode = _xmlcfg_add(xmlSchemasHandle, rootNode, XW_TAG_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, 'name', XW_DEFAULT_TAGNAME);
   _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, XW_MATCHTAG_ATTRIB, '0');
   addTagSettingsToTree2(xmlSchemasHandle,tagNode);
   addContentWrapSettingsToTree(xmlSchemasHandle, tagNode, defaultContentWrapSettings);
   addTagLayoutSettingsToTree(xmlSchemasHandle, tagNode, defaultTagLayoutSettings);
   //Add Proc tag, use same defaults as CDATA
//    tagNode = _xmlcfg_add(xmlSchemasHandle, rootNode, XW_TAG_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
//    _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, 'name', XW_PROC_TAGNAME);
//    _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, XW_MATCHTAG_ATTRIB, '0');
//    addTagSettingsToTree2(xmlSchemasHandle,tagNode);
//    addContentWrapSettingsToTree(xmlSchemasHandle, tagNode, CDATAContentWrapSettings);
//    addTagLayoutSettingsToTree(xmlSchemasHandle, tagNode, CDATATagLayoutSettings);

   int i;
   for (i = 0; i < tagNames._length(); i++) {
      _str tagName = tagNames[i]; tagName = strip(tagName); 
      int type = (int)substr(tagName, length(tagName), 1);
      tagName = strip(substr(tagName, 1, length(tagName)-1));
      tagNode = _xmlcfg_add(xmlSchemasHandle, rootNode, XW_TAG_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, 'name', tagName);
      _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, XW_MATCHTAG_ATTRIB, '0');
      if (type == 1) {
         addTagSettingsToTree(xmlSchemasHandle,tagNode, settings1.generalSettings);
         addContentWrapSettingsToTree(xmlSchemasHandle, tagNode, settings1.contentWrapSettings);
         addTagLayoutSettingsToTree(xmlSchemasHandle, tagNode, settings1.tagLayoutSettings);
      } else {
         addTagSettingsToTree(xmlSchemasHandle,tagNode, settings2.generalSettings);
         addContentWrapSettingsToTree(xmlSchemasHandle, tagNode, settings2.contentWrapSettings);
         addTagLayoutSettingsToTree(xmlSchemasHandle, tagNode, settings2.tagLayoutSettings);
      }
   }

   if (_xmlcfg_save(xmlSchemasHandle, 3, VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR, null, -1, TREE_ROOT_INDEX)) {
      //XWmessageNwait("OOPS! "filename);
      return false;
   }
   if (_xmlcfg_close(xmlSchemasHandle)) {
      return false;
   }
   return true;
}

boolean XW_saveXWScheme(XW_Scheme scheme)
{
   //return false;
   int status;
   _str XWSchemeFileName = XW_schemeNameToSchemeFileName(scheme.Name);
   if (XWSchemeFileName == "") {
      return false;
   }
   
   //XWsay('Saving 'XWSchemeFileName);//return true;
   int xmlSchemasHandle = _xmlcfg_create(XWSchemeFileName, VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if (xmlSchemasHandle < 0) {
      message('Unable to open 'XWSchemeFileName);
      return false;
   }

   int doctypeNode = _xmlcfg_add(xmlSchemasHandle, TREE_ROOT_INDEX, 'DOCTYPE', VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, doctypeNode, 'root', XW_SCHEME_TAGNAME);
   _xmlcfg_set_attribute(xmlSchemasHandle, doctypeNode, 'SYSTEM', XW_DTD);
   int rootNode = _xmlcfg_add(xmlSchemasHandle, doctypeNode, XW_SCHEME_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, 'name', scheme.Name);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, XW_INDENTSTYLE_ATTRIB, scheme.tagIndentStyle);
   _xmlcfg_set_attribute(xmlSchemasHandle, rootNode, XW_CASESENSITIVE_ATTRIB, scheme.caseSensitive);

   int tagNode, useWithNode;
   typeless i;

   for (i = 0; i < scheme.useWithDefault._length(); i++) {
       _str type;
       switch (scheme.useWithDefault[i].type) {
       case XW_UW_MODE:
          type = XW_UW_MODETYPEATTRIB;
          break;
       case XW_UW_EXT:
          type = XW_UW_EXTTYPEATTRIB;
          break;
       case XW_UW_DTD:
          type = XW_UW_DTDTYPEATTRIB;
          break;
       case XW_UW_SCHEMA:
          type = XW_UW_SCHEMATYPEATTRIB;
          break;
       case XW_UW_BADTYPE:
       default:
          continue;
       }
       useWithNode = _xmlcfg_add(xmlSchemasHandle, rootNode, XW_USEWITH_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
       _xmlcfg_set_attribute(xmlSchemasHandle, useWithNode, XW_USEWITH_TYPE_ATTRIB, type);
       _xmlcfg_set_attribute(xmlSchemasHandle, useWithNode, XW_USEWITH_VALUE_ATTRIB, scheme.useWithDefault[i].value);
   }

   XW_TagSettings S:[] = scheme.tagSettings;
   // Traverse the elements in hash table
   _str tagName[];

   for (i._makeempty();;) {
       S._nextel(i);
       if (i._isempty()) break;
       tagNode = _xmlcfg_add(xmlSchemasHandle, rootNode, XW_TAG_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
       _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, 'name', S:[i].name);
       //_xmlcfg_set_attribute(xmlSchemasHandle, tagNode, XW_MATCHTAG_ATTRIB, S:[i].matchTag);
       _xmlcfg_set_attribute(xmlSchemasHandle, tagNode, XW_MATCHTAGNAME_ATTRIB, S:[i].matchTagName);
       addTagSettingsToTree(xmlSchemasHandle,tagNode, S:[i].generalSettings);
       addContentWrapSettingsToTree(xmlSchemasHandle, tagNode, S:[i].contentWrapSettings);
       addTagLayoutSettingsToTree(xmlSchemasHandle, tagNode, S:[i].tagLayoutSettings);
   }

   if (_xmlcfg_save(xmlSchemasHandle, 3, VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR, null, -1, TREE_ROOT_INDEX)) {
      message("Unable to save "XWSchemeFileName);
      return false;
   }
   if (_xmlcfg_close(xmlSchemasHandle)) {
      message("Unable to close! "XWSchemeFileName);
      return false;
   }
   return true;
}

static addContentWrapSettingsToTree(int xmlSchemasHandle, int tagNode, XW_ContentWrapSettings settings) {
   int settingsNode = _xmlcfg_add(xmlSchemasHandle, tagNode, XW_CWSETTINGS_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_WRAPMODE_ATTRIB        , settings.wrapMode);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_WRAPMETHOD_ATTRIB      , settings.wrapMethod);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_FIXEDWIDTHCOL_ATTRIB   , settings.fixedWidthCol);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_FIXEDWIDTHMRC_ATTRIB   , settings.fixedWidthMRC);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_AUTOWIDTHMRC_ATTRIB    , settings.autoWidthMRC);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_FIXEDRIGHTCOL_ATTRIB   , settings.fixedRightCol);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_USEFIXEDWIDTHMRC_ATTRIB, settings.useFixedWidthMRC);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_USEAUTOWIDTHMRC_ATTRIB , settings.useAutoWidthMRC);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INCLUDETAGS_ATTRIB     , settings.includeTags);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_PRESERVEWIDTH_ATTRIB   , settings.preserveWidth);
}

static addTagLayoutSettingsToTree(int xmlSchemasHandle, int tagNode, XW_TagLayoutSettings settings) {
   int settingsNode = _xmlcfg_add(xmlSchemasHandle, tagNode, XW_TLSETTINGS_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   //_xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_LAYOUTSTYLE_ATTRIB   , settings.layoutStyle);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INDENTMETHOD_ATTRIB  , settings.indentMethod);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INDENTFROM_ATTRIB    , settings.indentFrom);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INDENTSPACES_ATTRIB  , settings.indentSpaces);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_LINESBEFORE_ATTRIB   , settings.lineBreaksBefore);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_LINESAFTER_ATTRIB    , settings.lineBreaksAfter);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_SEPSTARTTAG_ATTRIB   , settings.separateStartTag);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_SEPENDTAG_ATTRIB     , settings.separateEndTag);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_PRESERVELAYOUT_ATTRIB, settings.preserveLayout);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_APPLYLAYOUT_ATTRIB   , settings.applyLayout);
}

static addTagSettingsToTree(int xmlSchemasHandle, int tagNode, XW_GeneralSettings settings) {
   int settingsNode = _xmlcfg_add(xmlSchemasHandle, tagNode, XW_GENSETTINGS_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_HASENDTAG_ATTRIB, settings.hasEndTag);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INSERTENDTAG_ATTRIB, settings.insertEndTags);
   //_xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_REQUIREDENDTAG_ATTRIB, settings.endTagRequired);
}

static addTagSettingsToTree2(int xmlSchemasHandle, int tagNode) {
   int settingsNode = _xmlcfg_add(xmlSchemasHandle, tagNode, XW_GENSETTINGS_TAGNAME, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_HASENDTAG_ATTRIB, '1');
   _xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_INSERTENDTAG_ATTRIB, '1');
   //_xmlcfg_set_attribute(xmlSchemasHandle, settingsNode, XW_REQUIREDENDTAG_ATTRIB, '1');
}

static void sayPara()
{
   boolean result = XW_isParaStart(0);
   if (result) XWsay('Para');
   else XWsay('Not Para');
}
/**
 * Is this the start of an XML/HTML paragraph.
 * 
 * @return boolean
 */
static boolean XW_isParaStart(/*int startLine,*/ boolean considerIndent = true){
   boolean returnVal = false;
   if (/*p_line == startLine ||*/ p_line == 1) {
      return true;
   }
   typeless origPos; save_pos(origPos);
   if (up()) {
      //On top line, so must be start
      restore_pos(origPos);
      return true;
   }
   if (XW_isBlankLine()) {
      restore_pos(origPos);
      return true;
   }
   first_non_blank(); int prevLineFirstCol = p_col;

   restore_pos(origPos);
   first_non_blank(); int thisLineFirstCol = p_col;
   restore_pos(origPos);
   if (considerIndent && (prevLineFirstCol != thisLineFirstCol)) {
      //XWsay('Indent - new para');
      return true;
   }
   //first_non_blank();
   //5 Cases:
   //1) starts w/ character data
   //2) starts w/ <![CDATA[
   //3) starts w/ some element tag
   //4) starts w/ <?
   //5) starts w/ <!--
   _str line;
   get_line_raw(line);
   line = strip(line);
   //Check case 5)
   if (substr(line, 1, 4) == '<!--') {
      //TODO - comment handling
      //XWsay('<!--');
      returnVal = true;
   }
   //Check case 4)
   else if (substr(line, 1, 2) == '<?') {
      //XWsay('<?');
      returnVal = !isInlineTag('?');
   }
   //Check case 2)
   else if (false && substr(line, 1, 9) == '<![CDATA[') {
      //XWsay('<![CDATA[');
      returnVal = !isInlineTag('![CDATA[');
   }
   //Check case 3)
   else {//Catch these two cases for now, whether the block tag is
         //at the start of the line or after some other content
      int posStatus = pos(startOfStartOrEndTagRegexOM, line, 1, 'R');
      if (posStatus == 1) {
         _str name = substr(line,pos('S0'),pos('0'));
         //XWsay('3A 'line' 'name);
         returnVal = !isInlineTag(name);
         if (isInlineTag(name)) {
            returnVal = false;
         } else {
            //Catch for semi-block end tag case.
            //First see if it is an end tag
            boolean isEndTag = (substr(line, 2, 1) == '/');
            if (isEndTag && isSemiBlockEndTag(name)) {
               returnVal = false;
            } else {
               returnVal = true;
            }
         }
      } else if (posStatus > 1) {
         _str name = substr(line,pos('S0'),pos('0'));
         //returnVal = !isInlineTag(name);
         returnVal = false;
      }
      else {
         returnVal = false;
         //XWsay(posStatus' 1 'line);
      }
   }
   //restore_pos(origPos);
   return returnVal;
}

/**
 * Is this the start of an XML/HTML paragraph.
 * 
 * Assumes that there is some content on this line
 * 
 * @return int
 */
static int XW_isParaStartPullUp(int startLine, boolean considerIndent = true){
   int returnVal = 0;
   if (p_line == startLine || p_line == 1) {
      return 1;
   }
   typeless origPos; save_pos(origPos);
   if (up()) {
      //On top line, so must be start
      restore_pos(origPos);
      return 1;
   }
   if (XW_isBlankLine()) {
      restore_pos(origPos);
      return 1;
   }
   restore_pos(origPos);
   //first_non_blank();
   //5 Cases:
   //1) starts w/ character data
   //2) starts w/ <![CDATA[
   //3) starts w/ some element tag
   //4) starts w/ <?
   //5) starts w/ <!--
   _str line;
   get_line_raw(line);
   line = strip(line);
   //Check case 5)
   if (substr(line, 1, 4) == '<!--') {
      //TODO - comment handling
      //XWsay('<!--');
      returnVal = 1;
   }
   //Check case 4)
   else if (substr(line, 1, 2) == '<?') {
      //XWsay('<?');
      returnVal = isInlineTag('?') ? 0 : 1;
   }
   //Check case 2)
   else if (false && substr(line, 1, 9) == '<![CDATA[') {
      //XWsay('<![CDATA[');
      returnVal = isInlineTag('![CDATA[') ? 0 : 1;
   }
   //Check case 3)
   else {//Catch these two cases for now, whether the block tag is
         //at the start of the line or after some other content
      int posStatus = pos(startOfStartOrEndTagRegexOM, line, 1, 'R');
      if (posStatus == 1) {
         _str name = substr(line,pos('S0'),pos('0'));
         //XWsay('3A 'name);
         returnVal = isInlineTag(name) ? 0 : 1;
      } if (posStatus > 1) {
         _str name = substr(line,pos('S0'),pos('0'));
         //XWsay('3B 'name);
         //returnVal = !isInlineTag(name);
         returnVal = 0;
      }
      else {
         returnVal = 0;
         //XWsay('1 'line);
      }
   }
   //restore_pos(origPos);
   return returnVal;
}

/**
 * Toggles XML formatting on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void xml_formatting_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   xw_formatting_toggle('xml');
}
_command void xw_formatting_toggle(_str lang = p_LangId) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   boolean currentState = _GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang) || _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, lang);
   _str param="";
   if (currentState) {
      param='n';
   } else {
      param='y';
   }
   _macro_call('xw_formatting', lang, param);
   xw_formatting(lang, param);
}
/**
 * Toggles HTML formatting on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void html_formatting_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   boolean currentState = _GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, 'html') || _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, 'html');
   _str param="";
   if (currentState) {
      param='n';
   } else {
      param='y';
   }
   _macro_call('html_formatting',param);
   html_formatting(param);
}
/**
 * If yes, the editor attempts to wrap and auto format xml.
 * 
 * @see xml_formatting_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command xml_formatting(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return xw_formatting('xml', yesno);
}
_command XW_formatting(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return xw_formatting(p_LangId, yesno);
}
/**
 * If yes, the editor attempts to wrap and auto format html.
 * 
 * @see html_formatting_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command int html_formatting(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return xw_formatting('html', yesno);
}
static int xmlOrhtml_formatting(_str lang, _str yesno="")
{
    return xw_formatting(lang, yesno);
}
static int xw_formatting(_str lang, _str yesno="")
{
   boolean currentState = _GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang) || _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, lang);
   typeless number=0;
   _str arg1=prompt(yesno,'',number2yesno(currentState ? 1 : 0));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return(1);
   }
    boolean newSetting = (number == 1 ? true : false);
    //_ext_xmlwrap_set_flags(XW_ENABLE_FEATURE, newSetting, ext);
    _SetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, newSetting, lang);
    _SetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, newSetting, lang);

    update_format_line();
    return(0);
}

/**
 * Toggles the content wrapping portion of the XML formatting feature on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void xml_contentwrap_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str param = XW_option_toggle_helper(XW_ENABLE_CONTENTWRAP, 'xml');
   _macro_call('xml_contentwrap',param);
   xml_contentwrap(param);
}
_command void XW_contentwrap_toggle(_str lang = p_LangId) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   xw_contentwrap_toggle(lang);
}
_command void xw_contentwrap_toggle(_str lang = p_LangId) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str yesno = XW_option_toggle_helper(XW_ENABLE_CONTENTWRAP, lang);
   _macro_call('XW_option', lang, yesno);
   XW_option(XW_ENABLE_CONTENTWRAP, lang, yesno);
}
/**
 * Toggles the content wrapping portion of the HTML formatting feature on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void html_contentwrap_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str param = XW_option_toggle_helper(XW_ENABLE_CONTENTWRAP, 'html');
   _macro_call('html_contentwrap',param);
   html_contentwrap(param);
}
/**
 * Toggles the tag layout portion of the XML formatting feature on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void xml_taglayout_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str param = XW_option_toggle_helper(XW_ENABLE_TAGLAYOUT, 'xml');
   _macro_call('xml_taglayout',param);
   xml_taglayout(param);
}
_command void XW_taglayout_toggle(_str lang = p_LangId) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   xw_taglayout_toggle(lang);
}
_command void xw_taglayout_toggle(_str lang = p_LangId) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str yesno = XW_option_toggle_helper(XW_ENABLE_TAGLAYOUT, lang);
   _macro_call('XW_option', lang, yesno);
   XW_option(XW_ENABLE_TAGLAYOUT, lang, yesno);
}
/**
 * Toggles the tag layout portion of the HTML formatting feature on/off.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void html_taglayout_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str param = XW_option_toggle_helper(XW_ENABLE_TAGLAYOUT, 'html');
   _macro_call('html_taglayout',param);
   html_taglayout(param);
}
static _str XW_option_toggle_helper(int flag, _str lang)
{
   _macro_delete_line();
   boolean currentState = _GetXMLWrapFlags(flag, lang);
   _str param="";
   if (currentState) {
      param='n';
   } else {
      param='y';
   }
   return param;
}
/**
 * If yes, the editor attempts to wrap the contents of xml elements 
 * automatically. 
 * 
 * @see xml_contentwrap_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command int xml_contentwrap(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return XW_option(XW_ENABLE_CONTENTWRAP, 'xml', yesno);
}
/**
 * If yes, the editor attempts to wrap the contents of html elements 
 * automatically.
 * 
 * @see html_contentwrap_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command int html_contentwrap(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
    return XW_option(XW_ENABLE_CONTENTWRAP, 'html', yesno);
}
/**
 * If yes, the editor attempts to do automatic tag layout in xml documents.
 * 
 * @see xml_taglayout_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command int xml_taglayout(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return XW_option(XW_ENABLE_TAGLAYOUT, 'xml', yesno);
}
/**
 * If yes, the editor attempts to do automatic tag layout in html documents.
 * 
 * @see html_taglayout_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command int html_taglayout(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
    return XW_option(XW_ENABLE_TAGLAYOUT, 'html', yesno);
}
static int XW_option(int flag, _str lang, _str yesno="")
{
   boolean currentState = _GetXMLWrapFlags(flag, lang);
   typeless number=0;
   _str arg1=prompt(yesno,'',number2yesno(currentState ? 1 : 0));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return(1);
   }
    _SetXMLWrapFlags(flag, (number == 1 ? true : false), lang);
    update_format_line();
    return(0);
}
int _OnUpdate_XW_gui_currentDocOptions(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (_no_child_windows()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   _str lang = p_LangId;
   if (!XW_isSupportedLanguage2(lang)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
int _OnUpdate_xml_html_document_options(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_XW_gui_currentDocOptions(cmdui, target_wid, 'xml');
}
int _OnUpdate_xml_formatting_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_XW_formatting_toggle(target_wid, 'xml');
}
int _OnUpdate_html_formatting_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_XW_formatting_toggle(target_wid, 'html');
}
int _OnUpdate_XW_formatting_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   language := target_wid._GetEmbeddedLangId();
   if (language == "") language = "fundamental";
   int enabled = XW_isSupportedLanguage2(language) ? MF_ENABLED : MF_GRAYED;
   modeName := _LangId2Modename(language);

   _menu_get_state(cmdui.menu_handle,command,auto flags,"m",auto caption);
   parse caption with "Enable" auto keys "Formatting";
   int status = _menu_set_state(cmdui.menu_handle,
                                cmdui.menu_pos,
                                MF_ENABLED,
                                "p",
                                "Enable "modeName" Formatting");

   //return status;
   return onupdate_XW_formatting_toggle(target_wid, language);
}
static int onupdate_XW_formatting_toggle(int target_wid, _str lang)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   int enabled = XW_isSupportedLanguage2(p_LangId) ? MF_ENABLED : MF_GRAYED;
   int checked = (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang) || _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, lang)) ? MF_CHECKED : MF_UNCHECKED;
   return(enabled|checked);
}
int _OnUpdate_xml_contentwrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_CONTENTWRAP, 'xml');
}
int _OnUpdate_html_contentwrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_CONTENTWRAP, 'html');
}
int _OnUpdate_XW_contentwrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_CONTENTWRAP);
}
int _OnUpdate_xml_taglayout_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_TAGLAYOUT, 'xml');
}
int _OnUpdate_html_taglayout_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_TAGLAYOUT, 'html');
}
int _OnUpdate_XW_taglayout_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   return onupdate_formatOption_toggle(target_wid, XW_ENABLE_TAGLAYOUT);
}
static int onupdate_formatOption_toggle(int target_wid, int flag, _str lang = '')
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (lang == '') {
      lang = target_wid._GetEmbeddedLangId();
   }
   int enabled = XW_isSupportedLanguage2(lang) ? MF_ENABLED : MF_GRAYED;
   int checked = _GetXMLWrapFlags(flag, lang) ? MF_CHECKED : MF_UNCHECKED;
   return (enabled|checked);
}

static void moveBackOrBumpBlockTag(int cols, tagStat tstat, boolean forceBump = false) {
   if (getSchemeOnlyWrap()) {
      return;
   }
   long orig_offset = _QROffset();
   int orig_col = p_col, origLine = p_line;
   _GoToROffset(tstat.tagStartOffset);
   boolean willNotHitCursor = (orig_col <= p_col - cols);
   //XWsay(orig_col' 'p_col' 'cols);
   p_col = p_col - cols;
   //TODO adjust for tabs
   if (!forceBump && (strip(get_text(cols)) == "") && willNotHitCursor) {
      _delete_text(cols, 'C');
      p_line = origLine;
      p_col = orig_col;
      return;
   }
   _GoToROffset(tstat.tagStartOffset);
   //Can't move back tag without collision, so bump to next line
   int indentCols = p_col - cols - 1;
   if (tstat.type == 4) {
      //handle end tag differently
      _GoToROffset(tstat.tagStartOffset);
      int tagBackStatus = _html_matchTagBackward(tstat.tagName);
      if (tagBackStatus == -1) {
         //TODO is this the correct thing to do
         //Since unmatched end tag, do nothing
         _GoToROffset(orig_offset);
         p_line = origLine;
         p_col = orig_col;
         return;
      }
      indentCols = p_col - 1;
   }
   //XWsay(indentCols);
   _GoToROffset(tstat.tagStartOffset);
   if (indentCols >= 0) {
      _insert_text_raw(p_newline);
      _insert_text_raw(indent_string(indentCols));
      p_line = origLine;
      end_line();
      p_col = orig_col;
   } else {
      p_line = origLine;
      p_col = orig_col;
   }
   return;
}

/**
 * Author: David A. O'Brien
 * Date:   12/3/2007
 * 
 * Initial entry point into xml wrap for all keystrokes other than Home, 
 * Backspace, Delete, and Enter. 
 *  
 * @return int   Return 0 or return 2 if xml/html formatting is not on.
 */
int XW_doeditkey() {
   //XWsay("XW_doeditkey");

   boolean wrapOn        = XW_CWthisDoc();
//say(wrapOn);
   boolean correlationOn = startEndCorrelationOn();
   if (!wrapOn && !correlationOn){
      XWclearState();
      return 2;
   }

   _str key=last_event();
   if (key == '>' || key == '<') {
      boolean wasInComment = false;
      if (!_in_comment(false) && key == '>') {
         //Check if this may be closing a comment
         left(); _delete_text(1, 'C');
         wasInComment = _in_comment(false);
         _insert_text('>');
      }
      XWclearState();
      if (wasInComment) return 2;
   }

   int status = XW_check_state(true);
   if (status == 5) {
      storeCursorState();
      return 0;
   }
   if (/*false &&*/ status) {
      XWsay("bad state "status);
      XWclearState();
      //storeCursorState();
      return 0;
   }

   tagStat tstat = XW_inTagB();
   //Try auto correlation
   if (correlationOn) {
      maybeCorrelateEndTagDoedit(tstat);
   }
   //If wrap off, return
   if (!wrapOn){
      XWclearState();
      return 2;
   }
   if (tstat.inTag) {
      XW_doeditkeyInTag(tstat);
   } else {
      XW_doeditkeyOutTag();
   }
   storeCursorState();
   return 0;
}

static boolean startEndCorrelationOn() {
   //temporarily turn off
   return false;

   if (!XW_isSupportedLanguage2()) {
      return false;
   }
   return LanguageSettings.getAutoCorrelateStartEndTags(p_LangId);
}

static int correlateEndTagDoedit(_str oldName, _str newName, boolean doStartTag = true) {
   //return 0;
   say(oldName' 'newName);
   save_pos(auto p);
   _find_matching_paren(0x7fffffff, true);
   p_col += 2;//select_char();p_col += oldName._length();select_char();//p_col -= oldName._length(); 
   _delete_text(oldName._length());
   //messageNwait('1111');
   //delete_selection(); 
   _insert_text_raw(newName);
   restore_pos(p);
   if (doStartTag) {
      _delete_text(oldName._length());
      //messageNwait('1111');
      //delete_selection(); 
      _insert_text_raw(newName);
   }

   return 0;
}

static _str XW_doedit_selected_text = '';
//Store the contents of the selection if doing XML auto correlation
void XW_getSelection() {

   XW_doedit_selected_text = '';
   if (!startEndCorrelationOn() || command_state() || !_isEditorCtl()
       || !select_active() || (_select_type() != 'CHAR'))
      return;
   save_pos(auto p);
   int old_mark = _duplicate_selection("");
   int mark = _duplicate_selection();
   //tagStat tstat = XW_inTagB();
   filter_init();
   if ( !filter_get_string(XW_doedit_selected_text) ) {
      //say('|'XW_doedit_selected_text'|');
   }
   restore_pos(p);
   _show_selection(old_mark);
   _free_selection(mark);
}

static class XW_autoCorrelateState {
   boolean m_wasSelection   = false;
   boolean m_lastKeySpace   = false;
   boolean m_lastKeyTab     = false;
   boolean m_startSelIn     = false;
   boolean m_endSelIn       = false;
   boolean m_state          = false;
   long    m_selStartOffset = 0;
   long    m_selEndOffset   = 0;
   _str    m_text           = '';
};

#define notInStartTagName   0
#define inStartTagName      1
#define inStartTagNameSpace 2
#define inStartTagNameSel   3
#define fromDoEdit    1
#define fromBackspace 2
#define fromDelete    3
#define fromCut       4
#define fromPaste     5
#define fromDelSel    6
static int cursorInStartTagName(tagStat tstat, XW_autoCorrelateState& autoCorrrelateState) {
   int returnVal = notInStartTagName;
   save_pos(auto origp);
   _GoToROffset(tstat.tagStartOffset);

   if ((tstat.type == 2) && (p_line == tstat.startLine)) {
      long startOffset = _QROffset();
      //messageNwait('HERE I AM');
      _GoToROffset(tstat.tagStartOffset);
      int stcol = p_col + 1;
      //messageNwait('HERE I AM 1');
      search(correlateStartEndTagRegex1, 'RH@>');
      //messageNwait('HERE I AM 2');
      long endStartTagOffset = _QROffset();
      if (select_active()) {
         if (_select_type() != 'CHAR') {
            return notInStartTagName;
         }
         begin_select();
         autoCorrrelateState.m_selStartOffset = _QROffset();
         //say(startOffset' '_QROffset()' 'endStartTagOffset);
         if (startOffset <= _QROffset() && _QROffset() <= endStartTagOffset) {
            returnVal = inStartTagNameSel;
            autoCorrrelateState.m_wasSelection = true;
            autoCorrrelateState.m_startSelIn = true;
         }
         end_select();
         autoCorrrelateState.m_selEndOffset = _QROffset();
         //say(startOffset' '_QROffset()' 'endStartTagOffset);
         if (startOffset <= _QROffset() && _QROffset() <= endStartTagOffset) {
            returnVal = inStartTagNameSel;
            autoCorrrelateState.m_wasSelection = true;
            autoCorrrelateState.m_endSelIn = true;
         }
         if (autoCorrrelateState.m_startSelIn && autoCorrrelateState.m_endSelIn) {
            //say('Sel in 'XW_doedit_selected_text);
            autoCorrrelateState.m_state = true;
            autoCorrrelateState.m_text = XW_doedit_selected_text;
         }
      } else {
         if (endStartTagOffset >= startOffset) {
            returnVal = inStartTagName;
            autoCorrrelateState.m_state = true;
            autoCorrrelateState.m_text = '';
         }
      }
   }
   restore_pos(origp);
   return returnVal;
}

int maybeCorrelateEndTagDoBackspace(tagStat tstat, int fromEvent = fromDoEdit) {
   return 1;
   _str selected_text = XW_doedit_selected_text;
   XW_doedit_selected_text = '';
   //say('maybeCorrelateEndTagDoBackspace()');
   typeless origp; save_pos(origp);
   if (tstat.type == 2) {
      if (p_line == tstat.startLine) {
         long startOffset = _QROffset();
         //messageNwait('HERE I AM');
         _GoToROffset(tstat.tagStartOffset);
         int stcol = p_col + 1;
         //messageNwait('HERE I AM 1');
         search(correlateStartEndTagRegex1, 'RH@>');
         //messageNwait('HERE I AM 2');
         if (_QROffset() >= startOffset) {
            //say('In element name 'tstat.tagName);
            restore_pos(origp);
            //return 0;
            int scol = p_col;
            _str oldTagname = substr(tstat.tagName, 1, scol-stcol-1) :+ substr(tstat.tagName, scol-stcol+1);
            boolean hitSpace = CW_lastEventHitSpace(auto key);
            //say(scol' 'stcol' 'tagname);
            p_col--; //_str letter = get_text_raw(1);
            _delete_text(1, 'C');
            _str rest;
            if (hitSpace) {
               _str fromCursor = CW_getLineFromColumn();
               int status = pos(nextWordRegex, fromCursor, 1, 'R');
               rest = substr(fromCursor, pos('S0'), pos('0'));
               oldTagname = tstat.tagName :+ rest;
               correlateEndTagDoedit(oldTagname, tstat.tagName, false);
               restore_pos(origp);p_col -= 1;
               _insert_text_raw(key);
            } else {
               _GoToROffset(tstat.tagStartOffset);p_col += 1;
               //messageNwait('ksjdfhksdhf');
               correlateEndTagDoedit(oldTagname, tstat.tagName);
            }
            restore_pos(origp);
         } else {
            restore_pos(origp);
         }
      }
   }
   return 0;
}
int maybeCorrelateEndTagDoedit(tagStat tstat, int fromEvent = fromDoEdit) {
   //say('maybeCorrelateEndTagDoedit() 'XW_doedit_selected_text);
   XW_autoCorrelateState autoCorrrelateState;
   if (!cursorInStartTagName(tstat, autoCorrrelateState)) {
      return 1;
   }
   //say('maybeCorrelateEndTagDoedit() 'XW_doedit_selected_text);
   _str selected_text = XW_doedit_selected_text;
   //say('PP:'selected_text);
   XW_doedit_selected_text = '';
   typeless origp; save_pos(origp);
   if (tstat.type == 2) {
      if (p_line == tstat.startLine) {
         long startOffset = _QROffset();
         //messageNwait('HERE I AM');
         _GoToROffset(tstat.tagStartOffset);
         int stcol = p_col + 1;
         //messageNwait('HERE I AM 1');
         search(correlateStartEndTagRegex1, 'RH@>');
         //messageNwait('HERE I AM 2');
         if (_QROffset() >= startOffset) {
            //say('In element name 'tstat.tagName);
            restore_pos(origp);
            //return 0;
            int scol = p_col;
            _str oldTagname = substr(tstat.tagName, 1, scol-stcol-1) :+ selected_text :+ substr(tstat.tagName, scol-stcol+1);
            boolean hitSpace = CW_lastEventHitSpace(auto key);
            //say(scol' 'stcol' 'tagname);
            p_col--; //_str letter = get_text_raw(1);
            _delete_text(1, 'C');_insert_text_raw(selected_text);
            _str rest;
            if (hitSpace) {
               _str fromCursor = CW_getLineFromColumn();
               int status = pos(nextWordRegex, fromCursor, 1, 'R');
               rest = substr(fromCursor, pos('S0'), pos('0'));
               oldTagname = tstat.tagName :+ rest;
               correlateEndTagDoedit(oldTagname, tstat.tagName, false);
               restore_pos(origp);p_col -= 1;
               _insert_text_raw(key);
            } else {
               _GoToROffset(tstat.tagStartOffset);p_col += 1;
               //messageNwait('ksjdfhksdhf');
               correlateEndTagDoedit(oldTagname, tstat.tagName);
            }
            restore_pos(origp);
         } else {
            restore_pos(origp);
         }
      }
   }
   return 0;
}

static void XW_doeditkeyInTag(tagStat tstat) {
   XW_doeditkeyOutTag();
   return;
}

static void XW_doeditkeyOutTag() {
   //XWsay("XW_doeditkeyOutTag");
   typeless origp; save_pos(origp);

   ////Check case of typing in content on a line before a block tag on same line
   //tagStat blockTagStats = findBlockTagOnLine();
   //if (blockTagStats.inTag) {
   //   moveBackOrBumpBlockTag(1, blockTagStats);
   //}

   calculateMargins();//XWsay(XWstate.tagName' 'XWstate.RMargin);

   int line_counter = p_line;
   int line_counter_p2 = p_line+2;
   //get the key pressed
   boolean hitSpace = CW_lastEventHitSpace(auto key);
   if (hitSpace) {
      //TODO a small check for whether the previous line can take text
      if (XW_inLineFirstWord() && !XW_isParaStart()) {
         XW_maybeMergeUp(line_counter - 1, XWstate.sTagCloseLine, line_counter_p2, XWstate.RMargin);
      }
   }
   //XWmessage('wrapping');//return;
   line_counter = p_line;
   int end_line_counter = XWstate.eTagLine;
   for(;!XW_maybeReflowToNext(line_counter, XWstate.sTagLine, end_line_counter, XWstate.RMargin); line_counter++){}
   XWstate.eTagLine = end_line_counter;
}

/*static*/ tagStat findBlockTagOnLine(int fromCol = p_col) {
   tagStat tstat;
   initTagStat(tstat);
   int origCol = p_col;
   _str line; get_line_raw(line);
   line = expand_tabs(line);
   //quick check using verify
   int verifyStatus = verify(line, XW_TAG_OPEN_BRACKET, 'M', fromCol);
   if (!verifyStatus)
      return tstat;
   //search through the line for open brackets and see if a tag that shouldn't move.
   while (verifyStatus) {
      //XWsay('-'verifyStatus'-');
      p_col = verifyStatus + 1;
      tstat = XW_inTagB();
      if (!tstat.isInlineTag) {
         if (tstat.type == 2 || tstat.type == 5)
            break;
         if (tstat.type == 4) {
            XW_TagLayoutSettings tlset = getLayoutSettings(tstat.tagName);
            if (tlset.separateEndTag)
               break;
         }
      }
      initTagStat(tstat);
      verifyStatus = verify(line, XW_TAG_OPEN_BRACKET, 'M', verifyStatus + 1);
   }
   p_col = origCol;
   return tstat;
}

/**
 * starting with cursor infront of a start tag,
 * return the margins for this tag.
 * 
 * @return int
 */
void calculateMargins() {
   typeless p; save_pos(p);
   int returnVal = 0;
   int sytaxIndentValue = 0;

   _GoToROffset(XWstate.sTagOffset);
   //XWmessageNwait('Calculate');
   XW_ContentWrapSettings wrapSetting = getWrapSettings(XWstate.tagName);
   int contentIndent, tagIndent;
   calculateTagIndentLevels(XWstate.LMargin, tagIndent, XWstate.tagName);

   if (wrapSetting.wrapMode == XW_CWS_PRESERVE) {
      //Set RMargin to 0, for no <pre> tag wrap
      XWstate.RMargin = 0;
      restore_pos(p);
      return;
   }
   //We now should have a wrapping tag
   if (wrapSetting.wrapMode != XW_CWS_WRAP) {
      //This should not happen, punt.
      XWstate.RMargin = 0;
      restore_pos(p);
      return;
   }

   if (wrapSetting.wrapMethod == XW_CWS_AUTOWIDTH || wrapSetting.wrapMethod == XW_CWS_PARENT) {
      //Not supporting these methods yet.
      
      //TODO correctly set these
      wrapSetting.wrapMethod = XW_CWS_FIXEDWIDTH;
   }
   if (wrapSetting.wrapMethod == XW_CWS_FIXEDRIGHT) {
      XWstate.RMargin = wrapSetting.fixedRightCol;
      restore_pos(p);
      return;
   }

   if (wrapSetting.wrapMethod == XW_CWS_FIXEDWIDTH) {
      if (wrapSetting.includeTags) {
            XWstate.RMargin = XWstate.sTagCol + wrapSetting.fixedWidthCol - 1;
      }
      else {
            XWstate.RMargin = XWstate.LMargin + wrapSetting.fixedWidthCol - 1;
      }
      if (wrapSetting.useFixedWidthMRC && XWstate.RMargin > wrapSetting.fixedWidthMRC ) {
         XWstate.RMargin = wrapSetting.fixedWidthMRC;
      }
      //_GoToROffset(orig_offset);
      restore_pos(p);
      return;
   }
//   restore_search(s1,s2,s3,s4,s5);
//   _GoToROffset(orig_offset);
   return;
}


static int XW_extractLineText2(_str &returnStr, int startLine, int endLine, int &rightMostCol, int &bulletOffset, boolean skipGetLine = false) {
   bulletOffset = 1;
   int origCol = p_col;
   first_non_blank();
   int returnVal = p_col;
   get_line_raw(returnStr);
   returnStr = strip(returnStr, 'L');
   p_col = origCol;
   return returnVal;
}

/**
 * 
 * @param returnLine
 * 
 * @return boolean   True if there is content.  False if blank.
 */
static boolean XW_extractLineText(XMLLine &returnLine) {
   if (_lineflags() & NOSAVE_LF) {
      returnLine.valid = false;
      return returnLine.valid;
   }
   returnLine.valid = true;

   //Not looking for bullets yet.
   returnLine.bullet = '';
   returnLine.bulletDCol = returnLine.bulletRCol = 0;

   // get the line!
   get_line_raw(returnLine.line);

   // strip off the initial spaces
   returnLine.content = strip(returnLine.line, 'L');

   // initialize everything
   returnLine.contentDCol = returnLine.contentRCol = returnLine.RMDCol = returnLine.RMRCol = 
                            returnLine.startTagStartDCol = returnLine.startTagStartRCol = 
                            returnLine.startTagEndDCol = returnLine.startTagEndRCol = 
                            returnLine.endTagStartDCol = returnLine.endTagStartRCol = 
                            returnLine.endTagEndDCol = returnLine.endTagEndRCol = 0;
   returnLine.startsWithTag = returnLine.endsWithTag = returnLine.blank = false;
   returnLine.tagKind = 0;

   // check for a blank line
   if (returnLine.content == '') {
      returnLine.blank = true;
      return false;
   }

   // find the first non-blank column
   returnLine.contentRCol = verify(returnLine.line, " \t");

   // find the last non-blank column
   returnLine.RMRCol = length(strip(returnLine.line, 'T'));

   // get the imaginary first non-blank column
   returnLine.contentDCol = text_col(returnLine.line, returnLine.contentRCol, 'I');

   // now the imaginary last non-blank column
   returnLine.RMDCol = text_col(returnLine.line, returnLine.RMRCol, 'I');

   return true;
}

static boolean keepOnUpperLine = false;
/**
 *  Will reflow a comment line if too long for current settings.
 * 
 *  If current line is too long a portion of it will be cut and 
 *  moved to the next line.  If the next line is a paragraph 
 *  start or a blank line, a new line will be insertedfirst.
 * 
 * This will only reflow one line.  If the next line is also too 
 * long, function will need to be called again.  Perserves
 * cursor location.
 * 
 * @param lineNumber    Number of line to check
 * @param startLine     start line of content
 * @param endLine       end line of content
 * @param absoluteRight Right most edge of comment, including 
 *                      any border
 * 
 * @return int  XW_REFLOWED if any wrapping was performed.
 *              XW_NONEEDTOREFLOW if no need to reflow.
 *              XW_CANNOTREFLOW if unable to reflow.
 */
static int XW_maybeReflowToNext(int lineNumber, int startLine, int& endLine, int absoluteRight) {
   //XWsay(p_line' XW_MRTN 'lineNumber' 'startLine' 'endLine);
   if ((_lineflags() & NOSAVE_LF) || absoluteRight < 1) {
      return XW_CANNOTREFLOW;
   }
   //XWsay(lineNumber' XW_maybeReflowToNext');
   int nextLMC = 0;

   int origLine = p_line; int origRLine = p_RLine; int origCol = p_col;
   save_pos(auto origPos);
   p_line = lineNumber;

   //Examine current line
   XMLLine currentLine, nextLine;
   XW_extractLineText(currentLine);
   //Store current line without left or right border.
   _str CW_currentLine2 = currentLine.line;

   //Do we really need to wrap?
   int lastPossibleContentCol = absoluteRight;
   boolean spacedOffEnd = false;
   //if ((origLine == lineNumber) && (currentRMC <= lastPossibleContentCol) && (origCol > lastPossibleContentCol + 1)) {
   //   spacedOffEnd = true;
   //}
   if ((currentLine.RMDCol <= lastPossibleContentCol && !spacedOffEnd) || (XW_inPreserveFormatTag())) {
      restore_pos(origPos);
      return(XW_NONEEDTOREFLOW);
   }

   if (false /*!getSchemeOnlyWrap()*/) {
      //If line is too long, but there is a block tag in the line, break line at block tag and try again
      tagStat blockTagStats1 = findBlockTagOnLine((origLine == lineNumber) ? origCol : 1);
      if (blockTagStats1.inTag && !getSchemeOnlyWrap() && false) {
         moveBackOrBumpBlockTag(0, blockTagStats1, true);
         p_line = origLine; p_col = origCol;
         return XW_maybeReflowToNext(lineNumber, startLine, endLine, absoluteRight);
      }
   }

   // Search for place to break the current line.
   int physHardRight = text_col(CW_currentLine2, absoluteRight, 'P');
   //XWsay (absoluteRight'  'CW_currentLine2'  'physHardRight);
   int physBreakCol = lastpos('[^ \t][ \t]', CW_currentLine2, physHardRight, 'U');
   //By searching backwards for the end of a word, this should prevent finding case
   //of trying to push the entire line down.  If searching for start of word, could
   //try to push whole line if it consisted of just one long word.
   if (!physBreakCol) {
      //TODO for now just do no wrap
      restore_pos(origPos);
      return (XW_CANNOTREFLOW);
      //Couldn't find a good break point that would be within the right margin
      //so still try to break this line somewhere.
      int i, pBC = 0;
      for (i = physHardRight; i < length(CW_currentLine2); i++) {
         pBC = lastpos('[^ \t][ \t]', CW_currentLine2, i, 'U');
         if (pBC) {
            physBreakCol = pBC;
            message(XW_CANNOT_FORMAT_MESSAGE2);
            break;
         }
      }
      if (pBC == 0) {
         message(XW_CANNOT_FORMAT_MESSAGE);
         restore_pos(origPos);
         return (XW_CANNOTREFLOW);
      }
   } else {
      //Check if break col is in front of a double byte character
      _str tempLineFromPhysBreakCol = substr(CW_currentLine2,lastpos('S0'),lastpos('0'));
      if (_dbcsStartOfDBCS(tempLineFromPhysBreakCol, 1)) {
         physBreakCol += 2;
      } else {
         physBreakCol++;
      }
   }

   //Find start of the next word.  That is what should be pushed to next line
   int physBreakCol2 = verify(CW_currentLine2, " \t", "", physBreakCol);
   if (!physBreakCol2 && !spacedOffEnd) {
      //This should not happen because there must have been content to trigger the reflow
      message(XW_CANNOT_FORMAT_MESSAGE);
      restore_pos(origPos);
      return (XW_CANNOTREFLOW);
   }
   if (spacedOffEnd) {
      physBreakCol2 = text_col(CW_currentLine2, origCol, 'P') - 1;
   }
   int DBreakCol = text_col(CW_currentLine2, physBreakCol2, 'I');
   p_col = DBreakCol;
   tagStat breakLocStat = XW_inTagB();
   if (breakLocStat.inTag && !isInlineTag(breakLocStat.tagName)) {
      //For now, no wrapping if break point in a block tag
      //XWsay(XW_CANNOT_FORMAT_MESSAGE);
      message(XW_CANNOT_FORMAT_MESSAGE);
      restore_pos(origPos);
      return (XW_CANNOTREFLOW);

      long gtStart = XW_inTag1();
      typeless pos2; save_pos(pos2);
      int lineN2 = p_line;
      _GoToROffset(gtStart);
      if (p_line != lineN2) {
         message(XW_CANNOT_FORMAT_MESSAGE);
         p_line = origLine; p_col = origCol;
         return (XW_CANNOTREFLOW);
      }
      physBreakCol2 = text_col(CW_currentLine2, p_col, 'P');
   }
   if (breakLocStat.inTag && isInlineTag(breakLocStat.tagName)) {
      //Can break an inline tag but check that not in an attribute string
      if (_in_string()) {
         //XWmessageNwait("in string");
         int inStringLine = p_line; int inStringCol = p_col;
         int status = search('?','-@<HRXSC');
         //int physHardRight = text_col(CW_currentLine2, absoluteRight, 'P');
         //int physBreakCol = lastpos('[^ \t][ \t]', CW_currentLine2, physHardRight, 'U');
         if (status || p_line < inStringLine) {
            restore_pos(origPos);
            return (XW_CANNOTREFLOW);
         }
         right();
         physBreakCol = lastpos('[^ \t][ \t]', CW_currentLine2, text_col(CW_currentLine2, p_col, 'P'), 'U');
         if (!physBreakCol) {
            //TODO go back and try to split line after the string
            restore_pos(origPos);
            return (XW_CANNOTREFLOW);
         }
         physBreakCol++;
         physBreakCol2 = verify(CW_currentLine2, " \t", "", physBreakCol);
         if (!physBreakCol2) {
            message(XW_CANNOT_FORMAT_MESSAGE);
            restore_pos(origPos);
            return (XW_CANNOTREFLOW);
         }
         DBreakCol = text_col(CW_currentLine2, physBreakCol2, 'I');
         p_col = DBreakCol;
      }
   }

   _str wrapPortion = substr(CW_currentLine2, physBreakCol2);

   //Get imaginary position to cut the line string
   int cutColI = text_col(CW_currentLine2, physBreakCol2, 'I');

   //Delete text that will be wrapped
   p_col = cutColI;
   _delete_end_line();
   //Check if we need to insert a line.  This happens if at last line
   boolean isEndPara = (p_line == endLine);

   //TODO need to really know the end of context (endLine param) in case all on one line
   if (!isEndPara && CW_down()) {
      isEndPara = true;
   }

   if (!isEndPara) {
      //Examine next line
      XW_extractLineText(nextLine);

      //Check blank line
      isEndPara = isEndPara || (nextLine.blank);
      //Check found bullet
      isEndPara = isEndPara || (nextLine.bulletRCol > 0 /*afterBulletCol > 1*/);
       
      //Is next line start of a paragraph?
      boolean isParaStart = XW_isParaStart(false);
      isEndPara = isEndPara || isParaStart;

      //Check different indent
      boolean differentIndent = (currentLine.contentDCol != nextLine.contentDCol);
      if (differentIndent && !isEndPara) {
         //Only accept a different indent as start of new paragraph if does not
         //immediately follow the start of a paragraph.
         boolean previousLineIsStart = p_line == XWstate.sTagCloseLine + 1;
         if (previousLineIsStart) {
            differentIndent = false;
         } else {
            save_pos(auto p3); 
            up();
            if (XW_isParaStart()) {
                   differentIndent = false;
            }
            restore_pos(p3);
         }
      }
      isEndPara = isEndPara || (differentIndent);
      //Check for other paragraph starting tags.
      if (!isEndPara) {
         //skip checking indent, since we've taken care of that above
         isEndPara = isEndPara || XW_isParaStart(false);
      }
      CW_up();
   }
   if (isEndPara) {
      endLine++;
   }

   if (isEndPara) { 
      //Need to add a new line
      nextLMC = currentLine.contentDCol;
      //XWsay(lineNumber' 'XWstate.sTagCloseLine' 'XWstate.LMargin' 'nextLMC);
      if (lineNumber == XWstate.sTagCloseLine && XWstate.LMargin != nextLMC) {
         //XWmessageNwait('special case of next line indent');
         nextLMC = XWstate.LMargin;
      }
      if(!CW_down()) up();
      insert_line('');
      //p_col = nextLMC;
      _insert_text_raw(indent_string(nextLMC - 1) :+ wrapPortion);
   } else {//XWsay('isNotEndPara.');
      //Wrap to front of content on the next line
      CW_down();
      p_col = nextLMC = nextLine.contentDCol;
      //wrap portion may be nothing when we've spaced past the right border, so
      //strip the leading whitespace of (wrapPortion' ')
      if (length(strip(wrapPortion, 'T')) == length(wrapPortion)) {
         wrapPortion = wrapPortion' ';
      }
      wrapPortion = strip(wrapPortion, 'L');
      //Check case of typing in content on a line before a block tag on same line
      _insert_text_raw(wrapPortion);
      if (!getSchemeOnlyWrap()) {
         tagStat blockTagStats = findBlockTagOnLine();
         if (blockTagStats.inTag) {
            moveBackOrBumpBlockTag(length(wrapPortion), blockTagStats);
         }
      }
   }
   //Fix the location of the cursor to proper place
   if (spacedOffEnd) {
      p_col = nextLine.contentDCol;
   }
   else if ((origRLine == p_RLine - 1) && (cutColI <= origCol)) {
      //Case that cursor was in portion that was moved to next line
      //XWsay(nextLMC' 'cutColI' 'origCol);
      restore_pos(origPos);
      if (keepOnUpperLine && (cutColI == origCol)) {
      } else {
         p_line = origLine + 1;
         p_col = nextLMC - (cutColI - origCol);
      }
   }
   else if (origLine == p_line) {
      //Case that cursor was originally on line that received the text from previous line
      restore_pos(origPos);
      p_col = origCol + length(wrapPortion);
   }
   else {
      //Case that cursor started on line unaffected by wrap.
      restore_pos(origPos);
   }

   // make sure the user is impressed with our line wrapping action
   XW_xmlwrap_nag();

   return (XW_REFLOWED);
}

/**
 * Will try to merge next line of content into current content line if 
 * first word of next line will fit on current line. 
 * 
 * @param upperLine  Line number that may receive characters from next line
 * @param startLine  Line number of start of content
 * @param endLine    Line number of end of content
 * @return boolean   True if some content was moved up from next line
 */
static boolean XW_maybeMergeUp(int upperLineNumber, int startLine, int &endLine, int absRightMargin) {
   //messageNwait(XWstate.sTagCloseLine' 'upperLineNumber' XW_maybeMergeUp()');
   //Save start location
   int origLine = p_line, origCol = p_col;

   //Check that upperLineNumber is not the line that contains the close 
   //of the start tag that defines the wrapping context.  If this line 
   //contains nothing after the closing '>' and this tag is set to 
   //'Start tag on separate line' then we should not try to merge any 
   //content up to upperLineNumber and just return. 
   if (XWstate.sTagCloseLine == upperLineNumber) {
      p_line = upperLineNumber;
      if (XWstate.sTagCloseLine == XWstate.sTagLine) {
         p_col = XWstate.sTagCol;
      } else if (XWstate.sTagCloseLine > XWstate.sTagLine) {
         first_non_blank();
      }
      _str closeLine = strip(CW_getLineFromColumn());
      //Return to start location
      p_line = origLine; p_col = origCol;
      int posStatus = pos('>', closeLine);
      if (posStatus && posStatus == closeLine._length()) {
         XW_TagLayoutSettings closeSetting = getLayoutSettings(XWstate.tagName);
         if (closeSetting.separateStartTag) {
            return false;
         }
      }
   }

   int origRLine = p_RLine;
   p_line = upperLineNumber;
   int fromRLine = p_RLine;
   p_line = origLine;

   //May need to fix cursor position in two cases
   //When cursor starts on line from which we pull text, or
   //when after that line and a line is deleted, the cursor moves up a line
   boolean needToFixCursor = (p_RLine == fromRLine + 1);
   boolean needToFixCursor2 = (p_RLine > fromRLine + 1);
   boolean watchCursor = (p_RLine == fromRLine);

   if (absRightMargin == 0) {
      //Do nothing.  Either can't determine right margin or content can not fit.
      p_line = origLine; p_col = origCol;return(false);
   }

   int rightMostContentCol = absRightMargin;  //without borders, these will be the same
   //Move to line that may be appended to from below
   p_line = upperLineNumber;
   //Check that this is not an imaginary line
   XMLLine upperLine, nextLine;
   XW_extractLineText(upperLine);

//   currentLMC = CW_extractBCLineText(currentLine, startLine, endLine, RMC1, CafterBulletCol);
   if (watchCursor && p_col - 2 > upperLine.RMDCol) {
      upperLine.RMDCol = p_col - 2;
   }
   int remainingOpenColumns = rightMostContentCol - upperLine.RMDCol;
   //must be two columns left, because we pull up something plus a space
   if (remainingOpenColumns < 2) {
      p_line = origLine; p_col = origCol;
      return(false);
   }

   if(CW_down()) {
      p_line = origLine; p_col = origCol;
      return(false);
   }
   if (XW_isBlankLine()) {
      //Do nothing if next is a blank line
      p_line = origLine; p_col = origCol;
      return(false);
   }
   //Check using sTagCloseLine may need to change for matching parent RC
   if (XW_isParaStart(p_line != XWstate.sTagCloseLine + 1)) {
      //Do nothing if next line is a paragraph start
      p_line = origLine; p_col = origCol;
      return(false);
   }
   first_non_blank();
   tagStat blockTagStats = XW_inTagB();
   if (blockTagStats.inTag && !blockTagStats.isInlineTag) {
      //start of the next line is in a block tag, do nothing
      p_line = origLine; p_col = origCol;
      return(false);
   }
   if (blockTagStats.inTag && blockTagStats.isInlineTag && _in_string()) {
      //start of the next line is in string in inline tag, do nothing
      p_line = origLine; p_col = origCol;
      return(false);
   }

   XW_extractLineText(nextLine);
   _str portionToTest = nextLine.content;

   if (getSchemeOnlyWrap()) {
      blockTagStats = findBlockTagOnLine(1);
      if (blockTagStats.inTag) {
         _GoToROffset(blockTagStats.tagStartOffset);
         portionToTest = strip(CW_getLineToColumn());
         //moveBackOrBumpBlockTag(length(wrapPortion), blockTagStats);
      }
   }

   p_line = upperLineNumber;
   _str pulledText = substr(' ', 1, upperLine.RMDCol + 1) :+ portionToTest;
   if (length(pulledText) <= rightMostContentCol) {
      pulledText = substr(pulledText, 1, rightMostContentCol + 1);
   }
   int searchStart = text_col(pulledText, rightMostContentCol, 'P');
   //Find end of word
   int status = lastpos("[^ \t][ \t]", pulledText, searchStart, 'U');
   //Check if break col is in front of a double byte character
   _str tempPulledText = substr(pulledText,lastpos('S0'),lastpos('0'));
   if (_dbcsStartOfDBCS(tempPulledText, 1)) {
      status++;
   }
   //XWsay(status' 'searchStart' 'upperLine.RMDCol);
   if (status <= upperLine.RMDCol + 1 || text_col(pulledText, status, 'P') > absRightMargin) {    //No word from next line will fit
      p_line = origLine; p_col = origCol;    
      return(false);
   }
   status -= upperLine.RMDCol + 1;
   pulledText = substr(nextLine.content, 1, status);
   //We can pull something up
   //Add pulled text to current line

   p_line = upperLineNumber;
   int insertLocation = upperLine.RMDCol + 2;
   p_col = insertLocation; _delete_end_line();
   _insert_text_raw(pulledText);

   CW_down();
   //Two cases, part of the next line or entire next line.
   boolean pulledUpWholeLine = (strip(pulledText) == strip(nextLine.line));
   if (pulledUpWholeLine) { //entire line pulled up.
      _delete_line(); endLine--;
      p_line = upperLineNumber;         
      if (needToFixCursor2) {
         decrementRealLineCounter(origLine);
      }
      if (needToFixCursor) {
         decrementRealLineCounter(origLine);
         p_line = origLine;
         _str tempLine;get_line_raw(tempLine);
         //int pcolP = text_col(nextLine.line, origCol, 'P');
         p_col = origCol = text_col(tempLine, text_col(tempLine, insertLocation, 'P') + text_col(nextLine.line, origCol, 'P') - nextLine.contentRCol /* nextLMCP1*/, 'I');
      }

   } else {   //Part of line pulled up
      int nextLMCP = 0, cursorP = 0, cursorPOffset = 0;;
      if (needToFixCursor) {
         //Cursor is on line from which we are pulling text, save physical location of key points
         nextLMCP = nextLine.contentRCol;
         cursorP = text_col(nextLine.line, origCol, 'P');
         cursorPOffset = cursorP - nextLMCP + 1;
      }
      int secondWordColP = verify(nextLine.content, " \t", '', length(pulledText) + 1);
      if (!secondWordColP) {
         //Should not happen.  Log an error
      }
      //nextLine = strip(substr(nextLine, length(pulledText) + 1), 'L');
      _str newNextLine = substr(nextLine.content, secondWordColP);
      //Have to be very careful of how to adjust the cursor location in case
      //user is exanding with tabs.
      _str tempLine = substr('', 1, nextLine.contentDCol - 1) :+ newNextLine;
      int yankCol = text_col(tempLine, nextLine.contentDCol + secondWordColP - 1, 'I');

      //Pull out what is moved to next line, leaving trailing border intact.
      p_col = nextLine.contentDCol; _delete_text(yankCol - nextLine.contentDCol, 'C');

      if (needToFixCursor) {
         _str newLine2; get_line_raw(newLine2);
         int newLMCP = text_col(newLine2, nextLine.contentDCol, 'P');
         //Two cases, cursor after pulled portion and cursor in pulled portion 
         if (cursorPOffset >= secondWordColP) {
            //cursor after pulled portion
            origCol = text_col(newLine2, newLMCP + (cursorPOffset - secondWordColP), 'I');
         } else if (cursorP >= nextLMCP) {
            decrementRealLineCounter(origLine);
            p_line = origLine;
            get_line_raw(newLine2);
            int insertCursorP = text_col(newLine2, insertLocation, 'P') + (cursorP - nextLMCP);
            origCol = text_col(newLine2, insertCursorP, 'I');
         }
      }
   }
   //OrigLine and OrigCol now have been adjusted to new cursor location.
   p_line = origLine; p_col = origCol;    

   // make sure the user is impressed with our line wrapping action
   XW_xmlwrap_nag();

   return(true);
}

static boolean XW_isBlankLine() {
   _str line;
   get_line_raw(line);
   return (strip(line) == "");
}

static int XW_getDefaultOptions() {
   return (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, xw_p_LangId()) ? XWcontentWrapFlag : 0) | (_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, xw_p_LangId()) ? XWtagLayoutFlag : 0);
}

_str XW_getCurrentOptions(_str filename) {
   int returnValInt = 0;
   if (!filenameToXWdocStatHash._indexin(filename) || filenameToXWdocStatHash:[filename] == null || filenameToXWdocStatHash:[filename].featureOptions == null || filenameToXWdocStatHash:[filename].scheme == null) {
      XWdocStat temp;
      temp.featureOptions = XW_getDefaultOptions();
      temp.scheme = XW_getDefaultSchemeName();
      filenameToXWdocStatHash:[filename] = temp;
      //XWsay('making feature options 'filenameToXWdocStatHash:[filename].featureOptions);
   } 
   returnValInt = filenameToXWdocStatHash:[filename].featureOptions;
   if (returnValInt == null || !isinteger(returnValInt) || returnValInt < 0 || returnValInt > (XWcontentWrapFlag|XWtagLayoutFlag|XWflagsSetFlag)) {
      returnValInt = 0;
      filenameToXWdocStatHash:[filename].featureOptions = 0;
   }
   _str returnValStr = '0';
   returnValStr = (_str)returnValInt;
   return returnValStr;
}

/**
 * Find the name of the XML wrapping scheme for the named file or buffer.  This 
 * function will set all appropriate defaults and create a default scheme for an 
 * as of yet unmatched file or buffer. 
 * 
 * @param filename Name of file for which to get the current wrapping scheme
 * 
 * @return _str Name of the current wrapping scheme for the given file
 */
_str XW_getCurrentScheme(_str filename) {
   //XWsay(filename);
   _str returnVal = 'xml';
   if (filenameToXWdocStatHash._indexin(filename)) {
   //XWsay('|'filenameToXWdocStatHash:[filename].scheme'|');
      returnVal = filenameToXWdocStatHash:[filename].scheme;
   } else {
      filenameToXWdocStatHash:[filename] = getDocStat(filename);
      returnVal = filenameToXWdocStatHash:[filename].scheme;
   }
   if (returnVal == XW_NODEFAULTSCHEME || returnVal == '' || returnVal == null) {
      returnVal = XW_getDefaultSchemeName();
      filenameToXWdocStatHash:[filename].scheme = returnVal;
   }

   return returnVal;
}

void XW_setCurrentFields(_str filename,_str scheme,int featureOptions) {
   filenameToXWdocStatHash:[filename].scheme = scheme;
   filenameToXWdocStatHash:[filename].featureOptions = featureOptions;
}

static boolean XW_inLineFirstWord(int testFromCol = 0) {

   XMLLine thisLine;
   XW_extractLineText(thisLine);
   if (thisLine.blank) {
      return (false);
   }
   boolean returnVal = false;
   if (!testFromCol) {
      testFromCol = thisLine.contentDCol;      
      // move to start of real content
   }
   int secondWordStart = verify(thisLine.line, " \t", "M", text_col(thisLine.line, testFromCol, 'P'));
   if (!secondWordStart) {
      //Content is all just one word
      secondWordStart = text_col(thisLine.line, length(thisLine.line), 'I');
   } else {
      secondWordStart = verify(thisLine.line, " \t", "", secondWordStart);
      if (!secondWordStart) {
         //No second word to move up to
         secondWordStart = text_col(thisLine.line, length(thisLine.line), 'I');
      } else {
         secondWordStart = text_col(thisLine.line, secondWordStart, 'I');
      }
   }
   
   returnVal = (secondWordStart >= p_col);
   return (returnVal);
}


/**
 * Will try to merge next line of comment into current comment line if first 
 * word of next line will fit on current line.   Then it will reflow the 
 * paragraph to insure that the merge did not make any lines too long.
 * 
 * @param startLine  Line number of start of comment
 * @param endLine    Line number of end of comemnt
 */
static void XW_maybeMergeAndReflow(int startLine, int &endLine, int fromLine = -1, boolean skipMergeWithPrevious = false, boolean skipMergeWithNext = false) 
{

   // save our starting position
   typeless p; save_pos(p);

   // grab the current line if no fromLine was specified
   if (fromLine == -1) {
      fromLine = p_line;
   }

   // Check that fromLine is not imaginary
   p_line = fromLine;
   if (_lineflags() & NOSAVE_LF) {
      restore_pos(p);
      return;
   }
   restore_pos(p);

   int absRightMargin = XWstate.RMargin;
   if (absRightMargin == 0) {
      //Do nothing.  Either can't determine right margin or content can not fit
      //or shouldn't wrap when in script tag.
      return;
   }

   int mergeLine = fromLine;
   int reflowLine = fromLine;
   if (!skipMergeWithPrevious && p_line == fromLine && XW_inLineFirstWord() && !XW_isParaStart()) {
      decrementRealLineCounter(mergeLine);
   }

   //Rework to pull up more than one line if needed.
   if (!skipMergeWithNext) {
      for (;XW_maybeMergeUp(mergeLine, startLine, endLine, absRightMargin); incrementRealLineCounter(mergeLine)) {
      }
   }

   int reflowLine2 = XWstate.eTagLine;
   if (reflowLine <= endLine) 
      for (;XW_REFLOWED == XW_maybeReflowToNext(reflowLine, XWstate.sTagLine, reflowLine2, absRightMargin); incrementRealLineCounter(reflowLine)) {}
   XWstate.eTagLine = reflowLine2;   
}

/**
 * Determine if the current Delete or backspace actions should 
 * skip trying to pull content up from the next line.  This 
 * would be the case when the next line starts with a tag that 
 * is not inline, or when the indent of the next line does not 
 * line up content of the current line.   
 * 
 * @param nextLineStartCol 
 * @param thisLine_contentDCol 
 * 
 * @return boolean 
 */
static boolean _skipMergeWithNext(int thisLine_contentDCol, boolean isParaStart) 
{
   // do we want to merge with the next line?
   boolean skipMergeWithNext = false;

   // save our position before we start
   save_pos(auto pp);

   //go to next line
   if (!down()) {
      // find the first non blank in this line
      first_non_blank();
      int nextLineStartCol = p_col;

      // Does next line start with a tag?
      if (get_text() == '<') {
         XW_FindTag(auto tag2);
         //Check if it's inline
         if (!isInlineTag(tag2) && tag2 != '') {
            // we don't want to try and merge with an inline tag
            skipMergeWithNext = true;
         }
      } else {
         // If didn't begin at start of para, test is simple
         if (!isParaStart && nextLineStartCol != thisLine_contentDCol) {
            skipMergeWithNext = true;
         } else if (isParaStart) {
            // Calculate the proper indent level for nest line
            int contentIndent = 0, tagIndent = 0;
            p_line = XWstate.sTagLine;
            p_col  = XWstate.sTagCol;
            calculateTagIndentLevels(contentIndent, tagIndent, XWstate.tagName);
            //restore_pos(pp);
            if (nextLineStartCol != contentIndent) {
               skipMergeWithNext = true;
            }
         }
      }

      // go back to where we started
      restore_pos(pp);
   } else {
      // there is no next line, so we should not try to merge with it
      skipMergeWithNext = true;
   }

   return skipMergeWithNext;
}

boolean XW_doDelete(boolean alreadyDeleted = false) {
   //XWmessageNwait('Do delete');
   if (!XW_CWthisDoc()){
      XWclearState();
      return false;
   }
   int status = XW_check_state();
   if (/*false &&*/ status) {
      //XWsay("bad state");
      if (status != 5) XWclearState();
      return false;
   }

   typeless origp; save_pos(origp);
   int origLine = p_line; int origCol = p_col;

   tagStat tstat = XW_inTagB();
   restore_pos(origp);

   //XWsay(XWstate.tagName' 'XWstate.RMargin);
   calculateMargins();//XWsay(XWstate.tagName' 'XWstate.RMargin);

   //XWmessage('wrapping');//return;
   int line_counter = p_line;

   XMLLine thisLine, nextLine;
   XW_extractLineText(thisLine);
   int origRCol = text_col(thisLine.line, origCol, 'P');
   boolean origLineBlank = XW_isBlankLine();
   //special case end of line
   //XWsay(thisLine.line'|');
   if (text_col(thisLine.line:+' ',length(thisLine.line) + 1, 'I') == p_col || past_end_of_line()) {
      //XWmessageNwait('Endline');
      if (down()) {
         return false;
      }
      //Is next line blank
      if (XW_isBlankLine()) {
         //XWmessageNwait('Endline Blank');
         _delete_line();
         up();
         p_col = origCol;
         storeCursorState();
         return (true);
      } else {
         //XWmessageNwait('Endline Not Blank');
         first_non_blank();
         int bufferLength = p_col - XWstate.LMargin;
         if (bufferLength < 0) bufferLength = 0;
         up();
         if (origLineBlank && origCol < XWstate.LMargin) {
            origCol = XWstate.LMargin;
         }
         p_col = origCol;
         _insert_text_raw(substr(' ', 1, bufferLength));
         join_line();
         p_col = origCol;
      }
   } else {
      if (!alreadyDeleted) maybe_delete_tab();//XWsay('delete');
   }
   int endLine = p_line + 2;
   boolean isParaStart = XW_isParaStart();
   boolean skipMergeUp = isParaStart || origLineBlank;
   //check that next line should not merge up
   boolean skipMergeWithNext = _skipMergeWithNext(thisLine.contentDCol, isParaStart);
   XW_maybeMergeAndReflow(p_line, endLine, p_line, skipMergeUp, skipMergeWithNext);
   storeCursorState();
   return (true);
}

boolean XW_Enter() {  
      boolean returnValBool = XW_doEnter();
      maybeOpenHiddenLines(p_line, p_col);
      return (returnValBool);
}

/**
 * Handles Enter key stroke for XML/HTML content wrapping.
 * 
 * @return boolean
 */
boolean XW_doEnter() {  

   boolean calledFromNosplitInsertLine = false;
   //say(name_on_key(ENTER));
   if (name_on_key(ENTER)=='nosplit-insert-line') {
     calledFromNosplitInsertLine = true;
   }

   boolean addLeadIn = true;
   boolean addBlankLine = true;
   //XWsay('Do Enter');
   if (!XW_CWthisDoc()){
      XWclearState();
      return false;
   }

   if (calledFromNosplitInsertLine) {
     end_line();
   }

   int status = XW_check_state();
   if (/*false &&*/ status) {
      //XWsay("bad state");
      if (status != 5) XWclearState();
      return false;
   }

   tagStat tstat = XW_inTagB();
   //if (tstat.inTag)
   //   XW_doeditkeyInTag(tstat);
   //else XW_doeditkeyOutTag();
   //return false;
   typeless origp; save_pos(origp);
   int origLine = p_line; int origCol = p_col;


   //XWsay(XWstate.tagName' 'XWstate.RMargin);
   calculateMargins();//XWsay(XWstate.tagName' 'XWstate.RMargin);

   //XWmessage('wrapping');//return;
   int line_counter = p_line;
  // for(;!XW_maybeReflowToNext(line_counter, XWstate.sTagLine, line_counter + 2, XWstate.RMargin); line_counter++){};

   XMLLine thisLine, nextLine;
   XW_extractLineText(thisLine);
   int origRCol = text_col(thisLine.line, origCol, 'P');


   if (!tstat.inTag || (tstat.inTag && isInlineTag(tstat.tagName))) {
      if (XW_isBlankLine()) {
         // just a blank line - enter the new line
         //XWsay ('blank');
         call_root_key(ENTER);
         if (!getSchemeOnlyWrap()) {
            p_col = XWstate.LMargin;
         }
         storeCursorState();
         return true;
      } else {
         if (origCol > thisLine.RMDCol) {
            //TODO separate behaviors when doing only wrapping
            call_root_key(ENTER);
            if (!getSchemeOnlyWrap()) {
               p_col = XWstate.LMargin;
            }
            storeCursorState();
            return true;
         }
         else if (origCol < thisLine.contentDCol) {
            //call_root_key(ENTER);
            //p_col = XWstate.LMargin;
            //TODO
            storeCursorState();
            return false;
         }else {
            int indentSize = XWstate.LMargin - 1;
            if (getSchemeOnlyWrap()) {
               int thisCol = p_col;
               first_non_blank();
               indentSize = p_col - 1;
               p_col = thisCol;
            }
            _insert_text_raw(p_newline);
            _insert_text_raw(indent_string(XWstate.LMargin - 1));
            int a = p_col; first_non_blank();
            int b = p_col;
            p_col = a; 
            if (b > a) _delete_text(b - a, 'C');
            int endLine = p_line + 2;
            //boolean skipMergeUp = XW_isParaStart();
            XW_maybeMergeAndReflow(p_line, endLine, p_line, true);
            storeCursorState();
            return (true);
         }
      }
   } else if (tstat.inTag && !isInlineTag(tstat.tagName)) {
      //hitting Enter inside a block tag
      _GoToROffset(tstat.tagStartOffset);
      //Calculate indent as one space after the name of tag
      int indentintag = p_col + 2 + length(tstat.tagName);
      
      restore_pos(origp);
      _insert_text_raw(p_newline);
      _insert_text_raw(indent_string(indentintag - 1));
      //Now remove any spaces between cursor and first chars on line
      int a = p_col; first_non_blank();
      int b = p_col;
      p_col = a; 
      if (b > a) _delete_text(b - a, 'C');

      int endLine = p_line + 2;
      //boolean skipMergeUp = XW_isParaStart();
      //Reflow rest of paragraph
      XW_maybeMergeAndReflow(p_line, endLine, p_line, true);
   }
   //save cursor state and exit.
   storeCursorState();
   return (true);
}

boolean XW_doBackspace() {

   // are we supposed to do any content wrap right now?
   if (!XW_CWthisDoc()) {
      // nope, bail
      XWclearState();
      return false;
   }

   // is there any reason why we shouldn't do this?
   int status = XW_check_state();
   if (status) {
      if (status != 5) XWclearState();
      return false;
   }

// tagStat tstat = XW_inTagB();
   //if (tstat.inTag)
   //   XW_doeditkeyInTag(tstat);
   //else XW_doeditkeyOutTag();
   //return false;

   // save our original position
   typeless origp;
   save_pos(origp);
   int origLine = p_line;
   int origCol = p_col;

   //Check case of typing in content on a line before a block tag on same line
   if (getSchemeOnlyWrap()) {
      tagStat blockTagStats = findBlockTagOnLine();
      if (blockTagStats.inTag) {
         //moveBackOrBumpBlockTag(1, blockTagStats);
         _GoToROffset(blockTagStats.tagStartOffset);
         _insert_text_raw(' ');
         restore_pos(origp);
      }
   }

   // figures out the margins, puts them in the XWstate object
   calculateMargins();

   // get the line info
   XMLLine thisLine;
   XW_extractLineText(thisLine);

   // special handling for blank lines
   if (thisLine.blank) {
      if (p_col <= XWstate.LMargin && p_line > 1) {
         int lineNumberBeforeDelete = p_line;
         _delete_line();
         //Need to set cursor this way to cover case of deleting last line
         p_line = lineNumberBeforeDelete - 1;
         if (XW_isBlankLine()) {
            p_col = 1; _delete_end_line();
            _insert_text_raw(indent_string(XWstate.LMargin - 1));
         }
         end_line();
         storeCursorState();
         return true;
      } else {
         storeCursorState();
         return false;
      }
   }

   // is the cursor past the first non-blank column?
   // or maybe it's past the left margin?
   if (p_col > thisLine.contentDCol || p_col > XWstate.LMargin) {
      // here is the actual backspace
      _rubout();

      int endLine = p_line + 2;

      // is this the start of paragraph?
      boolean isParaStart = XW_isParaStart();
      boolean skipMergeUp = isParaStart;

      //check that next line should not merge up
      boolean skipMergeWithNext = _skipMergeWithNext(thisLine.contentDCol, isParaStart);

      // and now reflow!
      XW_maybeMergeAndReflow(p_line, endLine, p_line, skipMergeUp, skipMergeWithNext);
      // save where our cursor is
      storeCursorState();
      return (true);
   }
   if (p_line == 1) {
      storeCursorState();
      return false;
   }
   //Must be something on line and cursor at or before first char
   up();
   if (XW_isBlankLine()) {
      _delete_line();
      p_line = origLine - 1;
      p_col = origCol;
      storeCursorState();
      return true;
   }
   p_line = origLine;//XWsay('Join');
   p_col = 1;
   _delete_text(origCol - 1, 'C');
   first_non_blank();
   int padding = p_col - 1;
   up(); end_line();
   //Make sure there is a blank at end
   left();
   if (get_text() != ' ' && get_text() != '\t') {
      end_line();
      _insert_text_raw(' ');
   } else end_line();
   _insert_text_raw(substr(' ', 1, padding));
   join_line();
   p_col = p_col - padding;

   int endLine = p_line + 2;
   boolean skipMergeUp = XW_isParaStart();
   //XWmessageNwait('before merge wrap');
   keepOnUpperLine = true;
   XW_maybeMergeAndReflow(p_line, endLine, p_line, skipMergeUp);
   keepOnUpperLine = false;
   storeCursorState();
   return (true);
}
 
//used by XW_Paste() and XW_Cut() function to prevent cycle of XW_Paste() and 
//paste() (and XW_Cut() and cut()) calling each other.  This is not elegant but 
//was used to keep changes in paste() and cut() function to a minimum. 
static boolean inXW_CutOrPaste = false;
/**
 * Called by paste to try a paste and then xml/html wrap on remaining content. 
 * Will only wrap simple pastes that leave the cursor on the same line as the
 * start position. 
 * 
 * @return boolean   Return true if xml/html wrap handled the paste.
 */
boolean XW_Paste(_str name='',boolean isClipboard=true) {
   if (inXW_CutOrPaste) {
      return false;
   }
   boolean returnVal = XW_CWthisDoc();
   if (!XW_CWthisDoc()){
      XWclearState();
      return false;
   }
   if (returnVal) {
      typeless pt = point();
      //int pc = p_col;
      inXW_CutOrPaste = true;
      int pasteStat;
      pasteStat = paste(name, isClipboard);
      inXW_CutOrPaste = false;
      if (!pasteStat) {
         if (point() == pt /*&& p_col >= pc*/) {
            XW_doeditkey();
         }
         return (true);
      }
      XWclearState();
      return true;
   }
   return (false);
}

/**
 * Called by cut() to try a cut and then xml/html wrap. Will only wrap simple 
 * cuts. 
 * 
 * @return boolean   Return true if xml/html wrap handled the cut.
 */
boolean XW_Cut(boolean push=true,boolean doCopy=false,_str name='') {
   if (inXW_CutOrPaste) {
      return false;
   }
   if ( !select_active() ) {
      return false;
   }
   boolean returnVal = XW_CWthisDoc();
   if (!XW_CWthisDoc()){
      XWclearState();
      return false;
   }
   if (returnVal) {
      int pl = p_line;
      int pc = p_col;
      inXW_CutOrPaste = true;
      int cutStat;
      cutStat = cut(push, doCopy, name);
      inXW_CutOrPaste = false;
      if (!cutStat) {
         if (p_line == pl) {
            XW_doDelete(true);
         }
         return (true);
      }
      XWclearState();
      return true;
   }
   return (false);
}

long XW_parentTagOffset() {
   //Three starting possibilities (excluding odd cases due to incomplete or 
   //ill-formed XML):
   // - in content of a tag
   // - in a start tag
   // - in an end tag
   // - in an empty element tag
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   long orig_offset = _QROffset();

   int location = XW_UNKNOWN;
   long inTagOffset = XW_inTag3(location);

   switch (location) {
   case XW_IN_CONTENT:
      break;
   case XW_IN_COMMENT:
      break;
   case XW_IN_START_TAG:
      break;
   case XW_IN_END_TAG:
      break;
   case XW_IN_EMPTY_ELEM_TAG:
      break;
   }

   if (inTagOffset == 0) {
   } else {
      _GoToROffset(inTagOffset - 1);
   }
   return 0;
}

/**
 * starting with cursor infront of a start tag,
 * return the Column of where the content should go.
 * 
 * @return int
 */
int calculateTagIndentLevels(int &contentIndent, int &tagIndent, _str tagName = '') {
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   long orig_offset = _QROffset();
   int returnVal = 0;
   int startCol = p_col;
   int sytaxIndentValue = 0;

   int status = 0;
   if (tagName == '') {
      status = search(fullStartTagRegexOM, '@>RHXCCC');
      tagName = get_text(match_length('3'),match_length('S3'));
   }
   XW_TagLayoutSettings setting = getLayoutSettings(tagName);
   //if (status || setting.indentMethod == XW_TLS_MATCHEXT) {
   XW_indent extIndentStyle = XW_IndentStyle();
   if (true) {
      //XWsay("MATCHEXT "status);
      
      if (extIndentStyle.None) {
         sytaxIndentValue = 1;
      } else if (extIndentStyle.Auto) {
         sytaxIndentValue = startCol;
      } else {
         sytaxIndentValue = startCol + extIndentStyle.Indent;
      }
      tagIndent = sytaxIndentValue;
   } 
   if (status || setting.indentMethod == XW_TLS_MATCHEXT) {
      contentIndent = sytaxIndentValue;
   } else {
      if (setting.indentFrom == XW_TLS_FROMOPENING) {
         contentIndent = startCol + setting.indentSpaces;
      } else {
         contentIndent = p_col + setting.indentSpaces;
      }
      //XWsay("Settings from indent "setting.indentSpaces);
   }

   if (nestTagsWithContent()) {
      tagIndent = contentIndent;
   }
   
   restore_search(s1,s2,s3,s4,s5);
   _GoToROffset(orig_offset);
   return returnVal;
}

/**
 * Counts number of consecutive blanks starting from startLine line
 * going up.
 * 
 * @return int Number of blank lines including current line.
 */
static int countBlankLinesUp(int startLine) {
   if (startLine < 1) {
      return 0;
   }
   int returnVal = 0;
   _str p;
   save_pos(p);
   p_line = startLine;
   while (XW_isBlankLine()) {
      returnVal++;
      if (up()) break;
   }
   restore_pos(p);
   return returnVal;
}
/**
 * Counts number of consecutive blanks starting from current line
 * going down.
 * 
 * @return int Number of blank lines including current line.
 */
static int countBlankLinesDown(int startLine) {
   int returnVal = 0;
   _str p;
   save_pos(p);
   while (XW_isBlankLine()) {
      returnVal++;
      if (down()) break;
   }
   restore_pos(p);
   return returnVal;
}

void XW_xmlwrap_nag()
{
   notifyUserOfFeatureUse(NF_HTML_XML_FORMATTING, p_buf_name, p_line);
}

/**
 * Handle '>' for xml/html formatting.
 * 
 * @return (int) Positive if handled by xml/html formatting.
 */
int XW_gt() {
   if (!_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, xw_p_LangId())) {
      return 0;
   }
   XWdocStat thisDocFlags = getDocStat();
   if ((thisDocFlags.featureOptions & XWflagsSetFlag) && !(thisDocFlags.featureOptions & XWtagLayoutFlag)) {
      return 0;
   }
   
   //clearState();  Shouldn't need this call to clear state.
    
   //Turn off the auto completion box
   XW_TerminateCodeHelp();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   int p1Line, p1Col, p2Line, p2Col;
   p1Line = p_line; p1Col = p_col;
   save_pos(auto orig_pos);

   _str restOfLine = strip(CW_getLineFromColumn(), 'L');

   //TODO instead search for full start tag and check that end is the current
   //cursor position
   int status = search(fullStartTagRegexOM, '@-RHXCS>');
   if (status || (p_line != p1Line) || (p_col != p1Col)) {
      //XWmessage("Unable to match > symbol");
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(orig_pos);
      return 0;
   }
   if (get_text_raw(1) == '>') {
      _delete_text(1, 'C');
   }
   goto_point(match_length('S'));

   int parentContentIndent, placeholder, thisTagIndent = p_col;
   int originalTagIndent = thisTagIndent;
   //Save position of start of the tag
   p2Line = p_line; p2Col = p_col;
   _str tagName = strip(get_match_text('3'), 'B');
   restore_search(s1,s2,s3,s4,s5);

   //Set parent content indent to be first char on line as a first default value
   first_non_blank();
   parentContentIndent = p_col;

   p_line = p1Line; p_col = p1Col;
   boolean inEmptyTag = false;
   //Is this an empty tag?
   if (p_col > 2) {
      p_col = p_col - 2;
      if (get_text(2) == '/>') {
         //Format the empty tag
         inEmptyTag = true;
         //return;
      }
      p_line = p1Line; p_col = p1Col;
   }

   if (inEmptyTag) {
      //Then just indent and check for lines above and below
      restore_pos(orig_pos);
      return 1;
   }

   XW_TagLayoutSettings setting = getLayoutSettings(tagName);

   if (!inEmptyTag && !isHasEndTag(tagName) && _LanguageInheritsFrom('xml')) {
      //Place holder for code to turn this tag into an empty tag.
   }

   _str endtag = "";
   if (isInsertEndTag(tagName) && isHasEndTag(tagName)) {
      endtag = "</"tagName">";
   }

   //No auto layout on inline tags
   if (isInlineTag(tagName)) {
      p_line = p1Line; p_col = p1Col;
      //insert the end tag if requested
      _insert_text_raw(endtag);
      restore_pos(orig_pos);
      return 1;
   }

   p_line = p2Line; p_col = p2Col;
   //Dealing with a block tag, cursor at start of just closed tag
   _str leadinText = strip(CW_getLineToColumn(), 'L');
   //How tags nest indent, scheme level attribute

   //Move to parent to calculate indent
   if (true || setting.lineBreaksBefore > 0 || leadinText != "") {
      _str parentTagName = "";
      int level = 0;
      //XWmessageNwait(parentTagName" Here0");
      int parentFindStatus = XW_FindParentBlockTag3(parentTagName, level);
      //XWsay('|'parentTagName"| Here");
      if (parentFindStatus == XW_FOUND_S_TAG) {
         calculateTagIndentLevels(parentContentIndent, thisTagIndent);
      }//else{XWsay('NO PARENT');}
   }

   //start doing things
   p_line = p1Line; p_col = p1Col;
   //insert enough line breaks
   int neededExtraLineBreaks = setting.lineBreaksAfter - (countBlankLinesDown(p_line + 1) + 1);
   if (restOfLine != "") neededExtraLineBreaks++;
   if (neededExtraLineBreaks > 0) {
      //TODO make this smarter
      int i = 0;
      for (; i < neededExtraLineBreaks; i++) {
         _insert_text_raw(p_newline);
      }
      _insert_text_raw(indent_string(parentContentIndent - 1));
   }

   p_line = p2Line; p_col = p2Col;
   //insert enough line breaks
   neededExtraLineBreaks = setting.lineBreaksBefore - (countBlankLinesUp(p_line - 1) + 1);
   if (leadinText != "") neededExtraLineBreaks++;
   if (neededExtraLineBreaks > 0) {
      int i = 0;
      for (; i < neededExtraLineBreaks; i++) {
         _insert_text_raw(p_newline);
      }
      _insert_text_raw(indent_string(thisTagIndent - 1));
      p2Line += neededExtraLineBreaks;
      p1Line += neededExtraLineBreaks;
      if (p1Line == p2Line) p1Col += (thisTagIndent - p2Col);
      p2Col = thisTagIndent;
   } else if (leadinText == "") {
      p_col = 1;
      _delete_text(p2Col - 1, "C");
      _insert_text_raw(indent_string(thisTagIndent - 1));
      if (p1Line == p2Line) p1Col += (thisTagIndent - p2Col);
      p2Col = thisTagIndent;
   }

   p_line = p2Line; p_col = p2Col;
   int contentIndent;
   calculateTagIndentLevels(contentIndent, placeholder);
   //restore position frist to preserve buffer state as much as possible.
   restore_pos(orig_pos);
   p_line = p1Line; p_col = p1Col;

   //XWmessageNwait('here 4');
   if (setting.separateStartTag) {
      _insert_text_raw(p_newline);
      _insert_text_raw(indent_string(contentIndent-1));
   } else {
   }
   int finalPLine = p_line;
   int finalPCol = p_col;
   if (setting.separateEndTag) {
      _insert_text_raw(p_newline);
      _insert_text_raw(indent_string(thisTagIndent-1));
   }
   _insert_text_raw(endtag);
   int lastLine = p1Line;
   p_line = finalPLine; p_col = finalPCol;
   int i;
   int shift = thisTagIndent - originalTagIndent;
   if (true || setting.lineBreaksBefore > 0) {
      int newIndent, firstChar;
      _str line;
      //If start tag covers more than one line, adjust indent of those middle lines
      //and final cursor column is needed.
      for (i = p2Line + 1; i <= lastLine; i++) {
         p_line = i;
         firstChar = _first_non_blank_col();
         get_line(line);
         line = strip(line, "L");
         if (line != 0) {
            newIndent = firstChar + shift - 1;
            if (newIndent < 0) newIndent = 0;
            replace_line(indent_string(newIndent) :+ line);
         }
         if (i == finalPLine) {
            finalPCol += shift;
            if (finalPCol < 1) finalPCol = 1;
         }
      }
   }
   p_line = finalPLine; p_col = finalPCol;

   // make sure the user is impressed with our formatting action
   XW_xmlwrap_nag();

   if (separateEndLine(tagName) && separateStartLine(tagName) && isInsertEndTag(tagName) && isHasEndTag(tagName)) {
      set_surround_mode_start_line(p_line - 1);
      set_surround_mode_end_line(p_line+1/*, 1, true*/);
      do_surround_mode_keys(true);
   }
   return 1;
}

/**
 * Scans the named files and returns an array holding the names of all 
 * the unique tags found.
 * 
 * @param bufName  Name of buffer to scan for tags
 * @param tagNames (out) Array holding the names of all the tags found 
 *                 in the buffer.
 */
void findAllTagsInFile(_str bufName, _str (&tagNames)[]) 
{
   find_buffer(bufName);
   tagNames._makeempty();
   boolean tagNameHash:[];
   sticky_message("Scanning buffer for tags");
   _str tag_name = '';
   int i;
   tagNameHash._makeempty();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int tagNum = tag_get_num_of_context();
   for (i = 0; i < tagNum; i++) {
      tag_get_detail2(VS_TAGDETAIL_context_type,i,tag_name);
      if (tag_name == 'taguse') {
         tag_get_detail2(VS_TAGDETAIL_context_name,i,tag_name);
         if (tag_name != '' && !tagNameHash._indexin(tag_name)) {
            tagNameHash:[tag_name] = true;
            tagNames[tagNames._length()] = tag_name;
         }
         tag_name = '';
      }
   }
   clear_message();
}

void XWsay(_str the_message) {
   if (XWDebug) {
      say(the_message);
   }
}
void XWmessage(_str the_message) {
   if (XWDebug) {
      message(the_message);
   }
}
void XWmessageNwait(_str the_message) {
   if (XWDebug) {
      messageNwait(the_message);
   }
}

/**********************************************************************
* This section includes the routines for automatic symbol translation *  
* for XML based languages.                                            * 
***********************************************************************/
static boolean ST_symTransOn(_str lang) {
   if (!XW_isSupportedLanguage2(lang)) {
      return false;
   }
// if (ST_symTransOnHash._indexin(lang) && ST_symTransOnHash:[lang] != null) {
//    return ST_symTransOnHash:[lang];
// }
   
   return LanguageSettings.getAutoSymbolTranslation(lang);
}


boolean ST_needToLoadSymbols(_str lang = p_LangId) {
   if (lang == '' || lang == null || lang._varformat() != VF_LSTR) {
      //Don't true to load a bad language
      return false;
   }
   //return true;
   //if (!XW_isSupportedLanguage3(lang)) {
   if (!XW_isSupportedLanguage2(lang)) {
      return false;
   }
   if (!gSTtable._indexin(lang)) {
      return true;
   }
   if (gSTtable:[lang] == null) {
      gSTtable._deleteel(lang);
      return true;
   }
   return false;
}

int ST_storeSymbols(_str lang, _str (&symbols)[]) {
   //say('|'lang'|ST_storeSymbols()');
   if (lang == '' || lang == null || lang._varformat() != VF_LSTR) {
      return 1;
   }
   int i;
   typeless dummy:[];
   _str symbolAbbr = '';
   for (i = 0; i < symbols._length(); i++) {
      if (symbols[i] == null) {
         symbols[i] = '';
      }
      if (symbols[i]._length() == 1) {
         symbolAbbr = symbols[i];
      } else if (symbols[i]._length() >= 2) {
         symbolAbbr = substr(symbols[i], symbols[i]._length() - 1, 2);
      }
      //say('\'symbolAbbr'\');
      if (dummy._indexin(symbolAbbr)) {
         int j = dummy:[symbolAbbr]._length();
         dummy:[symbolAbbr][j] = symbols[i];
         for (j--; j >= 0 && (symbols[i]._length() > dummy:[symbolAbbr][j]._length()); j--) {
            dummy:[symbolAbbr][j+1] = dummy:[symbolAbbr][j];
            dummy:[symbolAbbr][j] = symbols[i];
         }
      } else {
         _str dummy2[];
         dummy2._makeempty();
         dummy2[0] = symbols[i];
         dummy:[symbolAbbr] = dummy2;
      }
   }
   gSTtable:[lang] = dummy;
   //say(lang' 'dummy._length());
   return 0;
}

/**
 * Expand any automatic symbol translations
 * 
 * @param _str lang 
 * 
 * @return int 1 if there was an expansion, otherwise 0.
 */
int ST_doSymbolTranslation(_str lang = p_LangId) {
   if(!ST_symTransOn(lang)) {
      return 0;
   }
   if (p_col > 2) {
      p_col -= 2;
      _str lastTwoKeys = get_text(2);
      p_col += 2;
      //say('* 'lastTwoKeys' | 'p_LangId);
      if (gSTtable._indexin(p_LangId) && gSTtable:[p_LangId]._indexin(lastTwoKeys)) {
         //say('Expand');
         int i;
         _str lineToCursor = CW_getLineToColumn();
         int lineToCursorLength = lineToCursor._length();
         for (i = 0; i < gSTtable:[p_LangId]:[lastTwoKeys]._length(); i++) {
            _str possibleAlias = gSTtable:[p_LangId]:[lastTwoKeys][i];
            int possibleAliasLength = possibleAlias._length();
            if ((lineToCursorLength >= possibleAliasLength) && (substr(lineToCursor, lineToCursorLength + 1 - possibleAliasLength) == possibleAlias)) {
               p_col -= possibleAliasLength;
               _delete_text(possibleAliasLength);
               AutoBracketCancel(); AutoBracketDeleteText();
               if (expand_alias(possibleAlias, '', getSymbolTransaliasFile(p_LangId))) {
                  return 0;
               }
               return 1;
            }
         }
      }
   }
   return 0;
}

boolean def_nag_symbolTranslation = true;
void ST_nag() {
   notifyUserOfFeatureUse(NF_AUTO_SYMBOL_TRANSLATION, p_buf_name, p_line);
}

