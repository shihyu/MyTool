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
#pragma option(metadata,"notifications.e")

typedef _str NotificationFeature;

// alert types
const ALERT_TYPE_NOTIFICATION= 0;
const ALERT_TYPE_IN_PROCESS= 1;

// definitions of alert groups
const ALERT_GRP_EDITING_ALERTS= "feature";
const ALERT_GRP_BACKGROUND_ALERTS= "background";
const ALERT_GRP_DEBUG_LISTENER_ALERTS= "debug_listener";
const ALERT_GRP_WARNING_ALERTS= "warning";
const ALERT_GRP_UPDATE_ALERTS= "update";
// definitions of editing group alerts
const ALERT_AUTO_CLOSE= "close file";
//#define ALERT_GO_TO_DEFINITION "go to definition"
const ALERT_ADAPTIVE_FORMATTING= "adaptive formatting";
//#define ALERT_DELETE_CODE_BLOCK "delete code block"
//#define ALERT_UNSURROUND_SEL "unsurround"
//#define ALERT_SOURCE_DIFF "source diff"
//#define ALERT_RELOAD_FILES "reload files"
const ALERT_DEBUGGER= "debugger";
//#define ALERT_MACRO_ERROR "macro errors"
const ALERT_ALIAS_EXPANSION= "alias expansion";
const ALERT_AUTO_SYMBOL_TRANSLATION= "symbol translation";
const ALERT_COMMENT_WRAP= "comment wrap";
const ALERT_DOC_COMMENT_EXPANSION= "doc comment expansion";
const ALERT_DYNAMIC_SURROUND= "dynamic surround";
const ALERT_HTML_XML_FORMATTING= "xml/html formatting";
const ALERT_INSERT_RIGHT_BRACKET= "insert right bracket";
const ALERT_INSERT_MATCHING_PARAMETERS= "insert matching parameters";
const ALERT_SMART_PASTE= "smartpaste";
const ALERT_SYNTAX_EXPANSION= "syntax expansion";
const ALERT_AUTO_CLOSE_COMPLETIONS= "close completion";
const ALERT_AUTO_CASE_KEYWORD= "case keywords";
const ALERT_AUTO_LIST_MEMBERS= "list members";
const ALERT_AUTO_DISPLAY_PARAM_INFO= "display parameter information";
const ALERT_AUTO_LIST_COMPATIBLE_PARAMS= "list compatible parameters";
const ALERT_AUTO_LIST_COMPATIBLE_VALUES= "list compatible values";
const ALERT_LARGE_FILE_SUPPORT= "large file editing";
const ALERT_AUTO_DOT_FOR_DASHGT= "auto correct dot to dashgt";
const ALERT_AUTO_XML_VALIDATION= "auto xml validation";
// definitions of background group alerts
const ALERT_TAGGING= "tagging";
const ALERT_SVN_CACHE_SYNC= "svn cache sync";
const ALERT_FTP_PUBLISH= "ftp publish";
const ALERT_PIP_SEND= "pip";
const ALERT_BACKGROUND_SEARCH= "background search";
const ALERT_TAGGING_MAX_WORKSPACES= 10;
const ALERT_TAGGING_WORKSPACE=  "tag workspace";
const ALERT_TAGGING_WORKSPACE0= "tag workspace0";
const ALERT_TAGGING_WORKSPACE1= "tag workspace1";
const ALERT_TAGGING_WORKSPACE2= "tag workspace2";
const ALERT_TAGGING_WORKSPACE3= "tag workspace3";
const ALERT_TAGGING_WORKSPACE4= "tag workspace4";
const ALERT_TAGGING_WORKSPACE5= "tag workspace5";
const ALERT_TAGGING_WORKSPACE6= "tag workspace6";
const ALERT_TAGGING_WORKSPACE7= "tag workspace7";
const ALERT_TAGGING_WORKSPACE8= "tag workspace8";
const ALERT_TAGGING_WORKSPACE9= "tag workspace9";
const ALERT_TAGGING_MAX_PROJECTS= 10 ;
const ALERT_TAGGING_PROJECT=   "tag project";
const ALERT_TAGGING_PROJECT0=  "tag project0";
const ALERT_TAGGING_PROJECT1=  "tag project1";
const ALERT_TAGGING_PROJECT2=  "tag project2";
const ALERT_TAGGING_PROJECT3=  "tag project3";
const ALERT_TAGGING_PROJECT4=  "tag project4";
const ALERT_TAGGING_PROJECT5=  "tag project5";
const ALERT_TAGGING_PROJECT6=  "tag project6";
const ALERT_TAGGING_PROJECT7=  "tag project7";
const ALERT_TAGGING_PROJECT8=  "tag project8";
const ALERT_TAGGING_PROJECT9=  "tag project9";
const ALERT_TAGGING_MAX_BUILDS= 20 ;
const ALERT_TAGGING_BUILD=   "tag build";
const ALERT_TAGGING_BUILD0=  "tag build0";
const ALERT_TAGGING_BUILD1=  "tag build1";
const ALERT_TAGGING_BUILD2=  "tag build2";
const ALERT_TAGGING_BUILD3=  "tag build3";
const ALERT_TAGGING_BUILD4=  "tag build4";
const ALERT_TAGGING_BUILD5=  "tag build5";
const ALERT_TAGGING_BUILD6=  "tag build6";
const ALERT_TAGGING_BUILD7=  "tag build7";
const ALERT_TAGGING_BUILD8=  "tag build8";
const ALERT_TAGGING_BUILD9=  "tag build9";
const ALERT_TAGGING_BUILD10= "tag build10";
const ALERT_TAGGING_BUILD11= "tag build11";
const ALERT_TAGGING_BUILD12= "tag build12";
const ALERT_TAGGING_BUILD13= "tag build13";
const ALERT_TAGGING_BUILD14= "tag build14";
const ALERT_TAGGING_BUILD15= "tag build15";
const ALERT_TAGGING_BUILD16= "tag build16";
const ALERT_TAGGING_BUILD17= "tag build17";
const ALERT_TAGGING_BUILD18= "tag build18";
const ALERT_TAGGING_BUILD19= "tag build19";
// definitions of debug listener alerts
const ALERT_STARTED= "started";
const ALERT_CONNECTED= "connected";
const ALERT_DISCONNECTED= "disconnected";
// definitions of warning alerts
const ALERT_HTTP_LOAD_ERROR= "http load error";
const ALERT_DTD_LOAD_ERROR= "dtd error";
const ALERT_DEBUGGER_ERROR= "debugger";
const ALERT_SCHEMA_LOAD_ERROR= "schema error";
const ALERT_SYMBOL_NOT_FOUND= "context tagging";
const ALERT_TAG_FILE_ERROR= "tag file error";
const ALERT_FILE_OPEN_ERROR= "file open error";
//Support doesn't like this warning: Removed for now.
//#define ALERT_FILE_NEW_ERROR "file new"
const ALERT_TAGGING_ERROR= "tagging error";
const ALERT_PROJECT_ERROR= "projects";
const ALERT_MEMORY_ERROR= "memory";
const ALERT_XML_ERROR= "xml error";
// definitions of update alerts
const ALERT_HOTFIX_AUTO_FOUND= "auto hot fix";
const ALERT_VERSION_UPDATES_FOUND= "update manager";

enum NotificationMethod {
   NL_DIALOG,
   NL_ALERT_WITH_TOAST,
   NL_ALERT_NO_TOAST,
   NL_MESSAGE,
   NL_NONE,
};


// used to activate an alert
struct ALERT_REQUEST {
   NotificationFeature AlertGroupID;
   _str AlertGroupName;
   int AlertID;
   _str AlertName;
   _str Header;
   _str Message;
   _str TimeStampB;
   _str TimeStampG;
   _str AlertIconFileName;
   _str ConfigPath;
   _str ConfigOption;
   _str HelpID;
   int IsHoverRequest;
   int ShowPopup;
   int DeactivateOnCompletion;
};

struct ALERT_INFO {
   NotificationFeature AlertID;
   _str Name;
   int Priority;
   _str Command;
   _str HelpID;
   _str ImageFileName;
   _str ConfigPath;
   _str ConfigOption;
   int Enabled;
   int ShowPopups;
   int MaxShows;
   NotificationMethod Method;
   bool Log;
   _str Description;
   bool AllowDialogMethod;
   bool DisplayOption;
   _str AlertGroupID;
};

struct ALERT_GROUP_INFO {
   NotificationFeature AlertGroupID;
   _str Name;
   int AlertType;
   _str Command;
   int Enabled;
   int ShowPopups;
   _str InactiveImage;
   _str ActiveImage;
};

