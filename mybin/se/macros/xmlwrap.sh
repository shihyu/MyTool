////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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

/*
 * This section contains global variables and defines for XML Wrapping
 */
#define XW_TAG_OPEN_BRACKET         '<'
#define XW_TAG_CLOSE_BRACKET        '>'
#define XW_TAG_BRACKETS             '<>'

#define XW_SCHEME_EXTENSION         '.xml'
#define XW_HTML_SCHEMA_FILENAME     'html'
#define XW_XML_SCHEMA_FILENAME      'xml'
#define XW_XHTML_SCHEMA_FILENAME    'xhtml'
#define XW_DOCBOOK_SCHEMA_FILENAME  'docbook'
#define XW_FORMATSCHEMES_DIR        'formatschemes'
#define XW_XMLHTMLSCHEMES_SUBDIR    'xwschemes'

#define XW_SCHEME_TAGNAME           'scheme'
#define XW_INDENTSTYLE_ATTRIB       'indentStyle'
#define XW_ONLYWRAP_ATTRIB          'onlyWrap'
#define XW_XMLDEFAULT_ATTRIB        'xmlDefault'
#define XW_HTMLDEFAULT_ATTRIB       'htmlDefault'
#define XW_CASESENSITIVE_ATTRIB     'caseSensitive'
#define XW_TAG_TAGNAME              'tag'
#define XW_GENSETTINGS_TAGNAME      'generalSettings'
#define XW_CWSETTINGS_TAGNAME       'contentWrapSettings'
#define XW_TLSETTINGS_TAGNAME       'tagLayoutSettings'

#define XW_USEWITH_TAGNAME          'usewith'
#define XW_USEWITH_TYPE_ATTRIB      'type'
#define XW_USEWITH_VALUE_ATTRIB     'value'

#define XW_HASENDTAG_ATTRIB         'hasEndTag'
#define XW_INSERTENDTAG_ATTRIB      'insertEndTag'
#define XW_REQUIREDENDTAG_ATTRIB    'requiredEndTag'
#define XW_MATCHTAG_ATTRIB          'matchTag'
#define XW_MATCHTAGNAME_ATTRIB      'matchTagName'

#define XW_WRAPMODE_ATTRIB          'wrapMode'                                                
#define XW_WRAPMETHOD_ATTRIB        'wrapMethod'                                             
#define XW_FIXEDWIDTHCOL_ATTRIB     'fixedWidthCol'
#define XW_FIXEDWIDTHMRC_ATTRIB     'fixedWidthMRC'
#define XW_AUTOWIDTHMRC_ATTRIB      'autoWidthMRC'
#define XW_FIXEDRIGHTCOL_ATTRIB     'fixedRightCol'
#define XW_USEFIXEDWIDTHMRC_ATTRIB  'useFixedWidthMRC'
#define XW_USEAUTOWIDTHMRC_ATTRIB   'useAutoWidthHMRC'
#define XW_INCLUDETAGS_ATTRIB       'includeTags'
#define XW_PRESERVEWIDTH_ATTRIB     'preserveWidth'

#define XW_LAYOUTSTYLE_ATTRIB       'layoutStyle'    
#define XW_INDENTMETHOD_ATTRIB      'indentMethod'   
#define XW_INDENTFROM_ATTRIB        'indentFrom'     
#define XW_INDENTSPACES_ATTRIB      'indentSpaces'   
#define XW_LINESBEFORE_ATTRIB       'linesBefore'    
#define XW_LINESAFTER_ATTRIB        'linesAfter'     
#define XW_SEPSTARTTAG_ATTRIB       'separateStartTag'    
#define XW_SEPENDTAG_ATTRIB         'separateEndTag'      
#define XW_PRESERVELAYOUT_ATTRIB    'preserveLayout' 
#define XW_APPLYLAYOUT_ATTRIB       'applyLayout'    

#define XW_DTD 'xmlhtmlformatscheme.dtd'
#define XW_DEFAULT_TAGNAME '(default)'
#define XW_DEFAULT_TAGNAME_DISPLAY '(default)'
#define XW_DEFAULT_MATCH_TAGNAME '(no match)'
//#define XW_DEFAULT_MATCH_TAGNAME_DISPLAY '(none)'
//#define XW_DEFAULT_MATCH_TAGNAME_DISPLAY ''
#define XW_DEFAULT_MATCH_TAGNAME_DISPLAY XW_DEFAULT_MATCH_TAGNAME
//#define XW_DEFAULT_SCHEME '(default)'
#define XW_DEFAULT_SCHEME_FILENAME '(default)'
#define XW_CDATA_TAGNAME  '![CDATA['
#define XW_CDATA_TAGNAME_DISPLAY  '![CDATA['

#define XW_DEFAULT_XML_SUFFIX '(default xml)'
#define XW_DEFAULT_HTML_SUFFIX '(default html)'

#define XW_PROC_TAGNAME_DISPLAY    '?'
#define XW_COMMENT_DISPLAY         '<!-- -->'
#define XW_DOCTYPE_DISPLAY         '!DOCTYPE'
#define XW_DECL_TAG_DISPLAY        '!'
#define XW_COMMENT_TAG             '<!-- -->'
#define XW_ProcTagsDefaultToNoWrap true
#define XW_CommentsDefaultToNoWrap true
#define XW_DeclTagsDefaultToNoWrap true

#define XW_CWS_WRAP       1
#define XW_CWS_IGNORE     2
#define XW_CWS_PRESERVE   3
#define XW_CWS_FIXEDWIDTH 1
#define XW_CWS_AUTOWIDTH  2
#define XW_CWS_FIXEDRIGHT 3
#define XW_CWS_PARENT     4
#define XW_CWS_FIXEDWIDTHCOLDEFAULT 65
#define XW_CWS_FIXEDWIDTHMRCDEFAULT 80
#define XW_CWS_AUTOWIDTHMRCDEFAULT  80
#define XW_CWS_FIXEDRIGHTCOLDEFAULT 80
#define XW_CWS_USEFIXEDWIDTHMRCDEFAULT false
#define XW_CWS_USEAUTOWIDTHMRCDEFAULT  false
#define XW_CWS_INCLUDETAGSDEFAULT       true
#define XW_CWS_PRESERVEWIDTHDEFAULT    false
struct XW_ContentWrapSettings {
   //1 = wrap
   //2 = ignore
   //3 = preserve
   int wrapMode;
   //1 = fixed width
   //2 = auto width
   //3 = fixed right
   //4 = parent
   int wrapMethod;
   int fixedWidthCol, fixedWidthMRC, autoWidthMRC, fixedRightCol;
   boolean useFixedWidthMRC, useAutoWidthMRC, includeTags, preserveWidth;
};
#define DEFAULTCONTENTWRAPSETTINGS XW_CWS_WRAP, XW_CWS_FIXEDRIGHT, XW_CWS_FIXEDWIDTHCOLDEFAULT, XW_CWS_FIXEDWIDTHMRCDEFAULT, XW_CWS_AUTOWIDTHMRCDEFAULT, XW_CWS_FIXEDRIGHTCOLDEFAULT, XW_CWS_USEFIXEDWIDTHMRCDEFAULT, XW_CWS_USEAUTOWIDTHMRCDEFAULT, XW_CWS_INCLUDETAGSDEFAULT, XW_CWS_PRESERVEWIDTHDEFAULT

#define XW_TLS_STYLE1 1
#define XW_TLS_STYLE2 2
#define XW_TLS_STYLE3 3
#define XW_TLS_OTHER  4
#define XW_TLS_MATCHEXT  1
#define XW_TLS_INDENT 2
#define XW_TLS_FROMOPENING  1
#define XW_TLS_AFTERCLOSING 2
#define XW_TLS_INDENTSPACES 3
#define XW_TLS_BREAKSBEFORE  0
#define XW_TLS_BREAKSAFTER 1
struct XW_TagLayoutSettings {
   //1 = match extension indent style
   //2 = indent
   int indentMethod;
   //1 = from opening
   //2 = after closing
   int indentFrom;
   int indentSpaces, lineBreaksBefore, lineBreaksAfter;
   boolean separateStartTag, separateEndTag, preserveLayout, applyLayout;
};
#define DEFAULTTAGLAYOUTSETTINGS /*XW_TLS_STYLE1,*/ XW_TLS_MATCHEXT, XW_TLS_FROMOPENING, XW_TLS_INDENTSPACES, XW_TLS_BREAKSBEFORE, XW_TLS_BREAKSAFTER, true, true, false, false

struct XW_GeneralSettings {
   boolean hasEndTag, insertEndTags, endTagRequired, insertAttributes;
};
#define DEFAULTGENERALSETTINGS true, true, true, false

struct XW_TagSettings {
   _str name;
   //boolean matchTag;
   _str matchTagName;
   XW_GeneralSettings generalSettings;
   XW_ContentWrapSettings contentWrapSettings;
   XW_TagLayoutSettings   tagLayoutSettings;
};

#define XW_UW_BADTYPE 0
#define XW_UW_EXT     1
#define XW_UW_DTD     2
#define XW_UW_SCHEMA  3
#define XW_UW_MODE    4
#define XW_UW_MODETYPEATTRIB   'mode'
#define XW_UW_EXTTYPEATTRIB    'fileExtension'
#define XW_UW_DTDTYPEATTRIB    'dtd'
#define XW_UW_SCHEMATYPEATTRIB 'schema'
#define XW_UW_MODEDISPLAY      'Language: '
#define XW_UW_EXTDISAPLAY      'Extension: '
#define XW_UW_DTDDISPLAY       'DTD: '
#define XW_UW_SCHEMADISPLAY    'Schema: '
struct XW_SchemeUseWith {
   //One of the above association types
   int  type;
   //Value of the association
   _str value;
};

#define XW_SS_SYNTAXINDENT 1
#define XW_SS_PARENTINDENT 2
#define XW_SS_TAGINDENTSTYLEDEFAULT XW_SS_PARENTINDENT
#define XW_SS_CASESENSITIVEDEFAULT true
#define XW_SS_ONLYWRAPDEFAULT true
struct XW_Scheme {
   _str Name;
   XW_TagSettings tagSettings:[];
   //1 = Use extension syntax indent
   //2 = match parent content indet
   int tagIndentStyle;
   
   //Is this a case sensitive scheme
   boolean caseSensitive;

   //default file types this scheme is used for
   XW_SchemeUseWith useWithDefault[];
};

struct XW_indent {
   boolean None, Auto, Syntax;
   int Indent;
   _str LMargin;
};

XW_Scheme XW_schemes:[];

#define XWcontentWrapFlag 1
#define XWtagLayoutFlag 2
#define XWflagsSetFlag 4
struct XWdocStat {
   int featureOptions;
   _str scheme;
};

#define XWNoMatch      XW_UW_BADTYPE
#define XWDTDMatch     XW_UW_DTD
#define XWSchemeMatch  XW_UW_SCHEMA
#define XWExtMatch     XW_UW_EXT
#define XWLangMatch    XW_UW_MODE
struct /*class*/ XW_schemeMatchTargets {
   //Used to determine if matched a DTD or a schema
   int   matchType;
   _str  DtdFilename;
   _str  SchemeFilename;
   _str  filenameExt;
   _str  langExt;
//    XW_schemeMatchTargets(int mt = XWNoMatch, _str dsf = '', _str fne = '', _str le = '') {
//       matchType = mt;
//       DtdSchemeFilename = dsf;
//       filenameExt = fne;
//       langExt = le;
//    }
};

XWdocStat filenameToXWdocStatHash:[];
_str      useWithSchemeHash:[];

#define XW_NOCONTEXTNAME '$$$'

#define XW_SM_FormCaption1 "Use '"
#define XW_SM_FormCaption2 "' Scheme for New Files that ..."
#define XW_SM_HelpItem     "Use Scheme for New Files"
#define XWDebug  false
#define XWAutoDetect false
