////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49157 $
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
#include "xmlwrap.sh"
#include "tagsdb.sh"
#include "color.sh"
#include "listbox.sh"
#import "guiopen.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "sellist.e"
#import "setupext.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "util.e"
#import "xml.e"
#import "xmlwrap.e"
#import "se/alias/AliasFile.e"
#endregion

#define  XW_DEFAULTSYMBOLTRANSALIASFILE 'symboltrans.als.xml'
#define  XW_SYMBOLTRANSALIASFILESUFFIX  '_'XW_DEFAULTSYMBOLTRANSALIASFILE

static XW_TagSettings defaultTagSettings = {
   XW_DEFAULT_TAGNAME,
   //false, 
   XW_DEFAULT_MATCH_TAGNAME,
   {DEFAULTGENERALSETTINGS},
   {DEFAULTCONTENTWRAPSETTINGS},
   {DEFAULTTAGLAYOUTSETTINGS}
};

defeventtab _XML_Wrapping_form;
//Holds the schemes so we can revert on Cancel.
static XW_Scheme XW_schemes_temp:[];

//Load the preview sample into the dialog edit window
void loadXMLWrapSample(_str content[]) 
{
   //Somehow clear the textbox;
   XMLWrapSample.top();
   XMLWrapSample._delete_text(-2);
   int i;
   for (i = 0; i < content._length(); i++) {
      XMLWrapSample._insert_text(content[i]);
   }
   XMLWrapSample.top();
   XMLWrapSample.xml_mode();
}

static _str XW_tagName = "para";
static _str XW_linebreakS = "\n";
static _str XW_linebreakE = "\n";
static _str xmlSampleLine[];

//for ignore mode preview
#define PARENTCONTENT0A  "Parent element content. "
#define PARENTCONTENT0B  " More parent element content."
#define TAGCONTENT0A  "Current element content."
#define TAGCONTENT0B  "More current element content."

#define PARENTCONTENTINDENT 7
#define PARENTCONTENTMARGIN substr('',1, PARENTCONTENTINDENT )
#define PARENTCONTENT1  PARENTCONTENTMARGIN"Parent content ("PARENTCONTENTINDENT" space indent). Not affected by settings."
#define PARENTCONTENT2  PARENTCONTENTMARGIN"More parent content. Not affected by settings."

void XWmakePreviewTags(_str tagName, boolean hasEndTag, _str &startTag, _str &endTag) 
{
   if (hasEndTag) {
      startTag = '<'tagName'>';
      endTag = '</'tagName'>';
   } else {
      startTag = '<'tagName'/>';
      endTag = "";
   }
}

//Create preview sample
void XWSampleInit() 
{
   lang := _GetDialogInfoHt('lang');
   if (lang == null) return;
      
   XW_indent XW_IndentSettings = XW_IndentStyle(lang);

   int i = 0;
   xmlSampleLine._makeempty();
   _str thisScheme = currentScheme();
   _str thisTag = currentTag();
   if (thisScheme == "" || !XW_schemes._indexin(thisScheme)) {
      return;
   }
   if (thisTag == "" || !XW_schemes:[thisScheme].tagSettings._indexin(thisTag)) {
      return;
   }
   _str startTag, endTag;

   XW_TagSettings T = XW_schemes:[thisScheme].tagSettings:[lookupTagname2(thisTag, thisScheme)];
   XWmakePreviewTags(thisTag, T.generalSettings.hasEndTag, startTag, endTag);
   _str tagIndent = (XW_schemes:[thisScheme].tagIndentStyle == 1) ? XW_IndentSettings.LMargin : PARENTCONTENTMARGIN;
   T.name = thisTag = translate(strip(translate(thisTag,'','*','',0)), '_', ' ', '');
   if (T.tagLayoutSettings.lineBreaksBefore == 0) T.tagLayoutSettings.lineBreaksBefore = 1;
   if (T.tagLayoutSettings.lineBreaksAfter == 0) T.tagLayoutSettings.lineBreaksAfter = 1;
   if (T.contentWrapSettings.wrapMode == XW_CWS_IGNORE) {
      XWSampleInit2(T);
      return;
   }

   XW_linebreakS = (T.tagLayoutSettings.separateStartTag ? "\n" : "");
   XW_linebreakE = (T.tagLayoutSettings.separateEndTag == 1 ? "\n" : "");

   XW_tagName = T.name;
   int indentLength = XW_IndentSettings.Indent;
   if (T.tagLayoutSettings.indentMethod == 2) {
      indentLength = T.tagLayoutSettings.indentSpaces;
      if (T.tagLayoutSettings.indentFrom == 2) {
         indentLength+=length(XW_tagName) + 2;
      }
   }
   _str XW_indent2 = substr("", 1, indentLength);

   xmlSampleLine[i++] = "<Parent>\n";
   xmlSampleLine[i++] = PARENTCONTENT1 :+ substr("\n", 1, T.tagLayoutSettings.lineBreaksBefore, "\n");
   xmlSampleLine[i++] = tagIndent :+ "<" :+ XW_tagName :+ ">" :+ XW_linebreakS;
   xmlSampleLine[i++] = ((XW_linebreakS == "") ? "" : (tagIndent:+XW_indent2)) :+ "Current element content. Affected by settings.";
   xmlSampleLine[i++] = XW_linebreakE :+ ((XW_linebreakE == "") ? "" : tagIndent) :+ "</" :+ XW_tagName :+ ">";
   xmlSampleLine[i++] = substr("\n", 1, T.tagLayoutSettings.lineBreaksAfter, "\n") :+ PARENTCONTENT2;
   //xmlSampleLine[i++] = "</Parent>\n";

   loadXMLWrapSample(xmlSampleLine);
}

void XWSampleInit2(XW_TagSettings T) 
{

   int i = 0;
   xmlSampleLine._makeempty();
   _str startTag, endTag;
   XWmakePreviewTags(T.name, T.generalSettings.hasEndTag, startTag, endTag);

   xmlSampleLine[i++] = "<Parent>\n";
   //xmlSampleLine[i++] = "<Parent>\nContent of Parent" :+ parentlinebreak;
   xmlSampleLine[i++] = PARENTCONTENTMARGIN :+ PARENTCONTENT0A :+ startTag :+ TAGCONTENT0A :+ " " :+ TAGCONTENT0A :+ "\n";
   xmlSampleLine[i++] = PARENTCONTENTMARGIN :+ TAGCONTENT0A :+ endTag :+ PARENTCONTENT0A :+ "\n";
   xmlSampleLine[i++] = PARENTCONTENTMARGIN :+ PARENTCONTENT0A :+ " " :+ PARENTCONTENT0A :+ "\n";

   loadXMLWrapSample(xmlSampleLine);
   //setLink();
}

static _str addDefaultSuffix(_str schemeName) 
{
   /*if (schemeName == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml')) {
      return (schemeName' 'XW_DEFAULT_XML_SUFFIX);
   } else if (schemeName == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html')) {
      return (schemeName' 'XW_DEFAULT_HTML_SUFFIX);
   } else*/ return schemeName;
}

static void loadSchemeList(_str current, boolean doListOnChange = true)
{
//    if (!maybeMakeDefaultXWScheme()) {
//       message("No default XML/HTML formatting scheme.  Disabling XML/HTML formatting.");
//       //TODO disable formatting.
//    }
   //Get scheme names from memory
   _str schemeName[];
   XW_schemeNamesM(schemeName);
   ctl_XW_schemes_list._lbclear();

   int i;
   for (i = 0; i < schemeName._length(); i++) {
      //XW_schemes:[schemeName[i]].modified = false;
      ctl_XW_schemes_list._lbadd_item(addDefaultSuffix(schemeName[i]));
   }
   if (ctl_XW_schemes_list._lbi_search('', addDefaultSuffix(current), 'E')){
      ctl_XW_schemes_list._lbtop();
   }
   ctl_XW_schemes_list._lbselect_line();
   if (doListOnChange) ctl_XW_schemes_list_on_change();
}

static void validateTagSettings(XW_TagSettings (&S):[]) 
{
   if (!S._indexin(XW_DEFAULT_TAGNAME)) {
      S:[XW_DEFAULT_TAGNAME] = defaultTagSettings;
   }
   return;
}

static void getTagNamesInScheme(_str schemeName, _str (&tagNames)[]) 
{
//void getTagNamesInScheme(_str schemeName, _str (&tagNames)[]) {
   XW_TagSettings S:[] = XW_schemes:[schemeName].tagSettings;
   validateTagSettings(S);
   typeless i;
   // Traverse the scheme elements in hash table
   for (i._makeempty();;) {
       S._nextel(i);
       if (i._isempty()) break;
       if (S:[i].name != XW_DEFAULT_TAGNAME) {
          tagNames[tagNames._length()] = S:[i].name;
       }
   }
   tagNames._sort();
}

void ctl_XW_schemes_list.on_change() 
{
   ctl_XW_schemes_list_on_change();
}
void ctl_XW_schemes_list_on_change(_str selectTagName = "") 
{
   _str scheme = currentScheme();
   // Traverse the scheme elements in hash table
   _str tagName[];
   getTagNamesInScheme(scheme, tagName);
   //Save the modified state here so that just updating the controls when setting them
   //does not cause the scheme modified flag to be set.set.
   //boolean tempModified = XW_schemes:[currentScheme()].modified;
   //updateSchemeModifiedFlag = false;

   ctl_XW_tag_list._lbclear();
   ctl_XW_tag_list._lbadd_item(XW_DEFAULT_TAGNAME);
   int i;
   for (i = 0; i < tagName._length(); i++) {
      //say(tagName[i]);
      ctl_XW_tag_list._lbadd_item(tagName[i]);
   }
   if (selectTagName != ""){
      ctl_XW_tag_list._lbi_search('', selectTagName, 'E');
   } else ctl_XW_tag_list._lbtop();
   ctl_XW_tag_list._lbselect_line();
   ctl_XW_tag_list_on_change();

   //say('scheme = 'scheme);
   if (XW_schemes._indexin(scheme) && scheme != "") {
      ctl_XW_caseSensitive.p_value = XW_schemes:[scheme].caseSensitive ? 1 : 0;
   }

//DOB 
   if (XWAutoDetect) {
      ctl_XW_scheme_defaults._lbclear();
      //say('clearing ctl_XW_scheme_defaults.');
      for (i = 0; i < XW_schemes:[scheme].useWithDefault._length(); i++) {
         ctl_XW_scheme_defaults._lbadd_item(XW_schemes:[scheme].useWithDefault[i].type' 'XW_schemes:[scheme].useWithDefault[i].value);
      }
   }
}

static _str schemeItem[];
void getSchemesList() 
{
   schemeItem._makeempty();
   ctl_XW_schemes_list._lbtop();
   schemeItem[schemeItem._length()] = ctl_XW_schemes_list._lbget_text();
   while(ctl_XW_schemes_list._lbdown()) {
      schemeItem[schemeItem._length()] = ctl_XW_schemes_list._lbget_text();
   }
}

void ctl_XW_tag_list.on_change() 
{
   if (_lbnum_selected() == 1) {
      // Only one tag selected
      ctl_XW_tag_list_on_change();
   } //else say('multiple select');
}
void ctl_XW_tag_list_on_change() 
{
   _str thisTag = currentTag();

   //Check that the scheme we are requesting to load into the controls is really in memory
   if (!XW_schemes._indexin(currentScheme())) {
      XW_Scheme schemeBuffer;
      schemeBuffer.Name = currentScheme();
      schemeBuffer.tagIndentStyle = XW_SS_TAGINDENTSTYLEDEFAULT;
      schemeBuffer.tagSettings:[XW_DEFAULT_TAGNAME] = defaultTagSettings;
      XW_schemes:[currentScheme()] = schemeBuffer;
   }
   //Check that the tag data we are requesting to load into the controls is really in memory
   if (!XW_schemes:[currentScheme()].tagSettings._indexin(thisTag)) {
      XW_schemes:[currentScheme()].tagSettings:[thisTag] = defaultTagSettings;
   }
   XW_set_controls(XW_schemes:[currentScheme()].tagSettings:[thisTag]);
   layoutupdate();
}

defeventtab _XML_Wrapping_form;
static boolean ENABLEAUTOWRAP = true; //for debugging
static void contentWrapEnable(boolean enabled) 
{
   ctl_XW_wrapTagContent_radio.p_enabled = enabled;
   ctl_XW_noWrap_radio.p_enabled = enabled;
   ctl_XW_preserveContent_check_radio.p_enabled = enabled;
   ctl_XW_fixedWidth_radio.p_enabled = enabled;
   ctl_XW_autoWidth_radio.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_fixedRightMargin_radio.p_enabled = enabled;
   ctl_XW_parentRightMargin_radio.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_fixedWidthMax_check.p_enabled = enabled;
   ctl_XW_autoWidthMax_check.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_includeTags_check.p_enabled = enabled;
   ctl_XW_preserveContent_check.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_fixedWidthCol_spin.p_enabled = enabled;
   ctl_XW_fixedWidthMRC_spin.p_enabled = enabled;
   ctl_XW_fixedRightCol_spin.p_enabled = enabled;
   ctl_XW_autoWidthMRC_spin.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_fixedWidthCol_text.p_enabled = enabled;
   ctl_XW_fixedWidthMRC_text.p_enabled = enabled;
   ctl_XW_autoWidthMRC_text.p_enabled = ENABLEAUTOWRAP && enabled;
   ctl_XW_fixedRightCol_text.p_enabled = enabled;
   ctllabel20.p_enabled = enabled;
}
static void tagLayoutEnable(boolean enabled) 
{
   ctl_XW_startTagSeparate_check.p_enabled = enabled;
   ctl_XW_endTagSeparate_check.p_enabled = enabled;
   ctl_XW_TLSmatchExt_radio.p_enabled = enabled;
   ctl_XW_TLSindent_radio.p_enabled = enabled;
   ctl_XW_indentSpaces_text.p_enabled = enabled;
   ctl_XW_lineBreaksBefore_text.p_enabled = enabled;
   ctl_XW_lineBreaksAfter_text.p_enabled = enabled;
   ctllabel21.p_enabled = enabled;
   ctllabel22.p_enabled = enabled;
   ctl_XW_lineBreaksBefore_spin.p_enabled = enabled;
   ctl_XW_lineBreaksAfter_spin.p_enabled = enabled;
   ctl_XW_indentSpaces_spin.p_enabled = enabled;
}
static void tagLayoutEnableNoEndTag() 
{
   ctl_XW_endTagSeparate_check.p_enabled = false;
}
static void generalEnable(boolean enabled) 
{
   ctl_XW_insertEndTag_check.p_enabled = enabled;
   ctl_XW_endTag_check.p_enabled = enabled;
   ctl_XW_matchTagName_combo.p_enabled = true;
}
static void layoutupdate(boolean enabled = true) 
{

   _str currentSelected = currentScheme();
   if (currentSelected == "")
      return;
   if (!XW_schemes._indexin(currentSelected)) {
      return;
   }
   
   if ((!XW_schemes_temp._indexin(currentSelected)) || XW_schemes:[currentSelected] != XW_schemes_temp:[currentSelected]) {
         //say('-|'currentSelected'|-');
         ctl_XW_schemes_list._lbset_item('*'addDefaultSuffix(currentSelected)'*');
         ctl_XW_schemes_list._lbselect_line();
   }

   if (matchStyleNameValidGui()) {
      contentWrapEnable(false);
      tagLayoutEnable(false);
      generalEnable(false);
      XWSampleInit();
      return;
   } else {
      contentWrapEnable(true);
      tagLayoutEnable(true);
      generalEnable(true);
   }

   ctl_XW_insertEndTag_check.p_enabled = ctl_XW_endTag_check.p_value == 1;
   ctl_XW_endTag_check.p_enabled = enabled;
   ctl_XW_wrapTagContent_radio.p_enabled = enabled;
   ctlframe37.p_enabled = enabled;
   ctl_XW_noWrap_radio.p_enabled = enabled;
   ctl_XW_preserveContent_check_radio.p_enabled = enabled;

   if (ctl_XW_wrapTagContent_radio.p_value == 0) {
      contentWrapEnable(false);
      ctl_XW_wrapTagContent_radio.p_enabled = true;
      ctl_XW_noWrap_radio.p_enabled = true;
      ctl_XW_preserveContent_check_radio.p_enabled = true;
   }
   tagLayoutEnable((ctl_XW_noWrap_radio.p_value == 0) );

   ctl_XW_check_IndentFromClose.p_enabled = (ctl_XW_TLSindent_radio.p_value == 1);

   if (ctl_XW_endTag_check.p_value != 1) {
      //contentWrapEnable(false);
      tagLayoutEnableNoEndTag();
   }

   XWSampleInit();
}

static _str cleanXWSchemeName(_str name) 
{
   //say(name'--'strip(translate(name,'','*','',0)));
   return strip(translate(name,'','*','',0));
}
static _str cleanXWtagName(_str name) 
{
   return cleanXWSchemeName(name);
}

static _str currentScheme() 
{
//   say(cleanXWSchemeName(ctl_XW_schemes_list._lbget_seltext()));
   _str cleaned = cleanXWSchemeName(ctl_XW_schemes_list._lbget_seltext());
   //XW_DEFAULT_XML_SUFFIX
   if (length(cleaned) > length(XW_DEFAULT_XML_SUFFIX) && substr(cleaned, length(cleaned) - length(XW_DEFAULT_XML_SUFFIX) + 1) == XW_DEFAULT_XML_SUFFIX) {
      cleaned = strip(substr(cleaned, 1, length(cleaned) - length(XW_DEFAULT_XML_SUFFIX)));
   }
   if (length(cleaned) > length(XW_DEFAULT_HTML_SUFFIX) && substr(cleaned, length(cleaned) - length(XW_DEFAULT_HTML_SUFFIX) + 1) == XW_DEFAULT_HTML_SUFFIX) {
      cleaned = strip(substr(cleaned, 1, length(cleaned) - length(XW_DEFAULT_HTML_SUFFIX)));
   }
   if (!XW_schemes._indexin(cleaned)) {
      cleaned = "";
   }
   return cleaned;
}
static _str currentTag() 
{
   _str tagName = cleanXWtagName(ctl_XW_tag_list._lbget_seltext());
   //say('|'currentScheme()'|'tagName'|');
   return tagName;
}
static _str currentTagDisplay() 
{
   _str tagName = ctl_XW_tag_list._lbget_seltext();
   return cleanXWSchemeName(tagName);
}

void ctl_XW_useSyntaxIndent_radio.lbutton_up()
{
   XW_schemes:[currentScheme()].tagIndentStyle = XW_SS_SYNTAXINDENT;
   layoutupdate();
}
void ctl_XW_matchParentIndent_radio.lbutton_up()
{
   XW_schemes:[currentScheme()].tagIndentStyle = XW_SS_PARENTINDENT;
   layoutupdate();
}

boolean matchStyleNameValidGui(_str scheme = "") 
{
   if (scheme == "") {
      scheme = currentScheme();
   }
   return XW_schemes:[scheme].tagSettings._indexin(ctl_XW_matchTagName_combo.p_text);
}

void ctl_XW_endTag_check.lbutton_up()
{
   setOptionForSelectedItems(XW_HASENDTAG_ATTRIB, (ctl_XW_endTag_check.p_value == 1));
}

void ctl_XW_insertEndTag_check.lbutton_up()
{
   setOptionForSelectedItems(XW_INSERTENDTAG_ATTRIB, (ctl_XW_insertEndTag_check.p_value == 1));
}

void ctl_XW_caseSensitive.lbutton_up()
{
   boolean caseSensitive = (ctl_XW_caseSensitive.p_value == 1);
   _str currentSchemeName = currentScheme();
   XW_schemes:[currentSchemeName].caseSensitive = caseSensitive;
   layoutupdate();
   //loadSchemeList(currentSchemeName);
   if (!caseSensitive) {
      _str currentTagName = lowcase(currentTag());
      // Traverse the scheme elements in hash table
      _str tagName[];
      getTagNamesInScheme(currentSchemeName, tagName);
      int i;
      for (i = 0; i < tagName._length(); i++) {
         XW_TagSettings tagSettingsTemp = XW_schemes:[currentSchemeName].tagSettings:[tagName[i]];
         XW_schemes:[currentSchemeName].tagSettings._deleteel(tagName[i]);
         tagSettingsTemp.name = lowcase(tagSettingsTemp.name);
         tagSettingsTemp.matchTagName = lowcase(tagSettingsTemp.matchTagName);
         XW_schemes:[currentSchemeName].tagSettings:[tagSettingsTemp.name] = tagSettingsTemp;
      }
      ctl_XW_schemes_list_on_change(lowcase(currentTagName));
      ctl_XW_tag_list_on_change();
   }
}

static void setOptionForSelectedItems(_str setting, typeless value)
{
   // grab the selected items
   _str selectedItems[];
   ctl_XW_tag_list._lbget_selected_array(selectedItems);

   // get the current scheme
   curScheme := currentScheme();

   for (i := 0; i < selectedItems._length(); i++) {
      switch (setting) {
      case XW_HASENDTAG_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].generalSettings.hasEndTag = value;
         break;
      case XW_INSERTENDTAG_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].generalSettings.insertEndTags = value;
         break;
      case XW_WRAPMODE_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.wrapMode = value;
         break;
      case XW_WRAPMETHOD_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.wrapMethod = value;
         break;
      case XW_USEFIXEDWIDTHMRC_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.useFixedWidthMRC = value;
         break;
      case XW_USEAUTOWIDTHMRC_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.useAutoWidthMRC = value;
         break;
      case XW_INCLUDETAGS_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.includeTags = value;
         break;
      case XW_PRESERVEWIDTH_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.preserveWidth = value;
         break;
      case XW_FIXEDWIDTHCOL_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.fixedWidthCol = value;
         break;
      case XW_FIXEDWIDTHMRC_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.fixedWidthMRC = value;
         break;
      case XW_AUTOWIDTHMRC_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.autoWidthMRC = value;
         break;
      case XW_FIXEDRIGHTCOL_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].contentWrapSettings.fixedRightCol = value;
         break;
      case XW_SEPSTARTTAG_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.separateStartTag = value;
         break;
      case XW_SEPENDTAG_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.separateEndTag = value;
         break;
      case XW_INDENTMETHOD_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.indentMethod = value;
         break;
      case XW_INDENTFROM_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.indentFrom = value;
         break;
      case XW_INDENTSPACES_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.indentSpaces = value;
         break;
      case XW_LINESBEFORE_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.lineBreaksBefore = value;
         break;
      case XW_LINESAFTER_ATTRIB:
         XW_schemes:[curScheme].tagSettings:[selectedItems[i]].tagLayoutSettings.lineBreaksAfter = value;
         break;
      }
   }

   layoutupdate();
}

void ctl_XW_wrapTagContent_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMODE_ATTRIB, XW_CWS_WRAP);
}
void ctl_XW_noWrap_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMODE_ATTRIB, XW_CWS_IGNORE);
}
void ctl_XW_preserveContent_check_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMODE_ATTRIB, XW_CWS_PRESERVE);
}

void ctl_XW_fixedWidth_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMETHOD_ATTRIB, XW_CWS_FIXEDWIDTH);
}
void ctl_XW_autoWidth_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMETHOD_ATTRIB, XW_CWS_AUTOWIDTH);
}
void ctl_XW_fixedRightMargin_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMETHOD_ATTRIB, XW_CWS_FIXEDRIGHT);
}
void ctl_XW_parentRightMargin_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_WRAPMETHOD_ATTRIB, XW_CWS_PARENT);
}

void ctl_XW_fixedWidthMax_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_USEFIXEDWIDTHMRC_ATTRIB, (ctl_XW_fixedWidthMax_check.p_value == 1));
}
void ctl_XW_autoWidthMax_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_USEAUTOWIDTHMRC_ATTRIB, (ctl_XW_autoWidthMax_check.p_value == 1));
}
void ctl_XW_includeTags_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_INCLUDETAGS_ATTRIB, (ctl_XW_includeTags_check.p_value == 1));
}
void ctl_XW_preserveContent_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_PRESERVEWIDTH_ATTRIB, (ctl_XW_preserveContent_check.p_value == 1));
}

static int getTextBoxNumericValue(int minimum)
{
   int value = 1;
   if (isnumber(p_text)) {
      value = (int)p_text;
   }

   if (value < minimum) {
      p_text = value = minimum;
   }

   return value;
}

void ctl_XW_fixedWidthCol_text.on_change() 
{
   setOptionForSelectedItems(XW_FIXEDWIDTHCOL_ATTRIB, getTextBoxNumericValue(1));
}
void ctl_XW_fixedWidthMRC_text.on_change() 
{
   setOptionForSelectedItems(XW_FIXEDWIDTHMRC_ATTRIB, getTextBoxNumericValue(1));
}
void ctl_XW_autoWidthMRC_text.on_change() 
{
   setOptionForSelectedItems(XW_AUTOWIDTHMRC_ATTRIB, getTextBoxNumericValue(1));
}
void ctl_XW_fixedRightCol_text.on_change() 
{
   setOptionForSelectedItems(XW_FIXEDRIGHTCOL_ATTRIB, getTextBoxNumericValue(1));
}

void ctl_XW_startTagSeparate_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_SEPSTARTTAG_ATTRIB, (ctl_XW_startTagSeparate_check.p_value == 1));
}
void ctl_XW_endTagSeparate_check.lbutton_up() 
{
   setOptionForSelectedItems(XW_SEPENDTAG_ATTRIB, (ctl_XW_endTagSeparate_check.p_value == 1));
}
void ctl_XW_TLSmatchExt_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_INDENTMETHOD_ATTRIB, XW_TLS_MATCHEXT);
}
void ctl_XW_TLSindent_radio.lbutton_up() 
{
   setOptionForSelectedItems(XW_INDENTMETHOD_ATTRIB, XW_TLS_INDENT);
}
void ctl_XW_check_IndentFromClose.lbutton_up() 
{
   setOptionForSelectedItems(XW_INDENTFROM_ATTRIB, (p_value == 1) ? XW_TLS_AFTERCLOSING : XW_TLS_FROMOPENING);
}
void ctl_XW_indentSpaces_text.on_change() 
{
   setOptionForSelectedItems(XW_INDENTSPACES_ATTRIB, getTextBoxNumericValue(0));
}
void ctl_XW_lineBreaksBefore_text.on_change() 
{
   setOptionForSelectedItems(XW_LINESBEFORE_ATTRIB, getTextBoxNumericValue(0));
}
void ctl_XW_lineBreaksAfter_text.on_change() 
{
   setOptionForSelectedItems(XW_LINESAFTER_ATTRIB, getTextBoxNumericValue(0));
}

static _str removeNamespacePrefix(_str tagName) 
{
   return tagName;
}

void ctl_XW_matchTagName_combo.on_change(int reason) 
{
   //say("match name "ctl_XW_matchTagName_combo.p_cb_text_box.p_text);
   _str matchName = ctl_XW_matchTagName_combo.p_text;
   _str schemeName = currentScheme();
   if (XW_schemes:[schemeName].tagSettings._indexin(matchName) || matchName == XW_DEFAULT_MATCH_TAGNAME_DISPLAY) {
      XW_schemes:[schemeName].tagSettings:[currentTag()].matchTagName = matchName;
      if (tagnameMakesCycle(schemeName, currentTag())) {
         XW_schemes:[schemeName].tagSettings:[currentTag()].matchTagName = XW_DEFAULT_MATCH_TAGNAME;
         ctl_XW_matchTagName_combo._lbtop();
         ctl_XW_matchTagName_combo._lbselect_line();
         ctl_XW_matchTagName_combo.p_text = XW_DEFAULT_MATCH_TAGNAME_DISPLAY;
      }
   }
   layoutupdate();
}
void ctl_XW_namespace.on_change() 
{
   //say("match name "ctl_XW_matchTagName_combo.p_cb_text_box.p_text);
   _str matchName = ctl_XW_matchTagName_combo.p_text;
   _str schemeName = currentScheme();
   if (XW_schemes:[schemeName].tagSettings._indexin(matchName) || matchName == XW_DEFAULT_MATCH_TAGNAME_DISPLAY) {
      XW_schemes:[schemeName].tagSettings:[currentTag()].matchTagName = matchName;
      if (tagnameMakesCycle(schemeName, currentTag())) {
         XW_schemes:[schemeName].tagSettings:[currentTag()].matchTagName = XW_DEFAULT_MATCH_TAGNAME;
         ctl_XW_matchTagName_combo._lbtop();
         ctl_XW_matchTagName_combo._lbselect_line();
         ctl_XW_matchTagName_combo.p_text = XW_DEFAULT_MATCH_TAGNAME_DISPLAY;
      }
   }
   layoutupdate();
}
static void updateTagMatchList(_str matchName) 
{
   _str tagNames[];
   getTagNamesInScheme(currentScheme(), tagNames);
   ctl_XW_matchTagName_combo._lbclear();
   ctl_XW_matchTagName_combo._lbadd_item(XW_DEFAULT_MATCH_TAGNAME_DISPLAY);
   int i;
   for (i = 0; i < tagNames._length(); i++) {
      if (tagNames[i] != currentTag()) {
         //say(tagNames[i]);
         ctl_XW_matchTagName_combo._lbadd_item(tagNames[i]);
      }
   }
   if (matchName == XW_DEFAULT_MATCH_TAGNAME || matchName == "") {
      ctl_XW_matchTagName_combo._lbtop();
      ctl_XW_matchTagName_combo._lbselect_line();
      ctl_XW_matchTagName_combo.p_text = XW_DEFAULT_MATCH_TAGNAME_DISPLAY;
   } else {
      ctl_XW_matchTagName_combo._lbfind_and_select_item(matchName, 'E', true);
   }
}

void XW_set_controls(XW_TagSettings settings) 
{
   if (XW_schemes:[currentScheme()].tagIndentStyle == XW_SS_SYNTAXINDENT) {
      ctl_XW_useSyntaxIndent_radio.p_value = 1;
      ctl_XW_matchParentIndent_radio.p_value = 0;
   } else {
      ctl_XW_useSyntaxIndent_radio.p_value = 0;
      ctl_XW_matchParentIndent_radio.p_value = 1;
   }

   ctl_XW_matchTagName_combo.p_enabled = true;
   updateTagMatchList(settings.matchTagName);
   //say(settings.generalSettings.hasEndTag ? 1 : 0);
   ctl_XW_endTag_check.p_value = settings.generalSettings.hasEndTag ? 1 : 0;
   ctl_XW_insertEndTag_check.p_value = settings.generalSettings.insertEndTags ? 1 : 0;

   if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMode == XW_CWS_WRAP) {
      ctl_XW_wrapTagContent_radio.p_value = 1;
      ctl_XW_noWrap_radio.p_value = 0;
      ctl_XW_preserveContent_check_radio.p_value = 0;
   }
   else if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMode == XW_CWS_IGNORE) {
      ctl_XW_wrapTagContent_radio.p_value = 0;
      ctl_XW_noWrap_radio.p_value = 1;
      ctl_XW_preserveContent_check_radio.p_value = 0;
   }
   else if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMode == XW_CWS_PRESERVE) {
      ctl_XW_wrapTagContent_radio.p_value = 0;
      ctl_XW_noWrap_radio.p_value = 0;
      ctl_XW_preserveContent_check_radio.p_value = 1;
   } else {//say("NOTHING");
   }

   if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMethod == XW_CWS_FIXEDWIDTH) {
      ctl_XW_fixedWidth_radio.p_value = 1;
      ctl_XW_autoWidth_radio.p_value = 0;
      ctl_XW_fixedRightMargin_radio.p_value = 0;
      ctl_XW_parentRightMargin_radio.p_value = 0;
   }
   else if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMethod == XW_CWS_AUTOWIDTH) {
      ctl_XW_fixedWidth_radio.p_value = 0;
      ctl_XW_autoWidth_radio.p_value = 1;
      ctl_XW_fixedRightMargin_radio.p_value = 0;
      ctl_XW_parentRightMargin_radio.p_value = 0;
   }
   else if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMethod == XW_CWS_FIXEDRIGHT) {
      ctl_XW_fixedWidth_radio.p_value = 0;
      ctl_XW_autoWidth_radio.p_value = 0;
      ctl_XW_fixedRightMargin_radio.p_value = 1;
      ctl_XW_parentRightMargin_radio.p_value = 0;
   }
   else if (XW_schemes:[currentScheme()].tagSettings:[currentTag()].contentWrapSettings.wrapMethod == XW_CWS_PARENT) {
      ctl_XW_fixedWidth_radio.p_value = 0;
      ctl_XW_autoWidth_radio.p_value = 0;
      ctl_XW_fixedRightMargin_radio.p_value = 0;
      ctl_XW_parentRightMargin_radio.p_value = 1;
   }
   ctl_XW_fixedWidthMax_check.p_value = settings.contentWrapSettings.useFixedWidthMRC ? 1 : 0;
   ctl_XW_autoWidthMax_check.p_value = settings.contentWrapSettings.useAutoWidthMRC ? 1 : 0;
   ctl_XW_includeTags_check.p_value = settings.contentWrapSettings.includeTags ? 1 : 0;
   ctl_XW_preserveContent_check.p_value = settings.contentWrapSettings.preserveWidth ? 1 : 0;
   ctl_XW_fixedWidthCol_text.p_text = settings.contentWrapSettings.fixedWidthCol;
   ctl_XW_fixedWidthMRC_text.p_text = settings.contentWrapSettings.fixedWidthMRC;
   ctl_XW_autoWidthMRC_text.p_text = settings.contentWrapSettings.autoWidthMRC;
   ctl_XW_fixedRightCol_text.p_text = settings.contentWrapSettings.fixedRightCol;

   XW_set_controls2(settings);
}
void XW_set_controls2(XW_TagSettings settings) 
{
   ctl_XW_startTagSeparate_check.p_value = settings.tagLayoutSettings.separateStartTag ? 1 : 0;
   ctl_XW_endTagSeparate_check.p_value = settings.tagLayoutSettings.separateEndTag ? 1 : 0;
   if (settings.tagLayoutSettings.indentMethod == XW_TLS_MATCHEXT) {
      //say("HERE 1");
      ctl_XW_TLSmatchExt_radio.p_value = 1;
      ctl_XW_TLSindent_radio.p_value = 0;
   }
   else if (settings.tagLayoutSettings.indentMethod == XW_TLS_INDENT) {
      //say("HERE 2");
      ctl_XW_TLSmatchExt_radio.p_value = 0;
      ctl_XW_TLSindent_radio.p_value = 1;
   }//else say("NO INDENT METHOD");
   ctl_XW_check_IndentFromClose.p_value = (settings.tagLayoutSettings.indentFrom == XW_TLS_AFTERCLOSING) ? 1 : 0;
   ctl_XW_indentSpaces_text.p_text = settings.tagLayoutSettings.indentSpaces;
   ctl_XW_lineBreaksBefore_text.p_text = settings.tagLayoutSettings.lineBreaksBefore;
   ctl_XW_lineBreaksAfter_text.p_text = settings.tagLayoutSettings.lineBreaksAfter;
}

void ctl_XW_schemes_list.rbutton_up(int x=-1, int y=-1)
{
   XW_showContextMenu("_XW_schemes_list_menu",x,y);
}

void ctl_XW_tag_list.rbutton_up(int x=-1, int y=-1)
{
   XW_showContextMenu("_XW_tag_list_menu",x,y);
}

void XW_showContextMenu(_str menuName, int x=-1, int y=-1)
{
   int index = 0;
   index = find_index(menuName,oi2type(OI_MENU));
   if( index==0 ) {
      return;
   }
   int mh = p_active_form._menu_load(index,'P');
   if( mh<0) {
      _str msg = "Unable to load menu \"":+menuName:+"\"";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   if( x==y && x==-1 ) {
      x=VSDEFAULT_INITIAL_MENU_OFFSET_X; y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
      x=mou_last_x('m')-x; y=mou_last_y('m')-y;
      _lxy2dxy(p_scale_mode,x,y);
      _map_xy(p_window_id,0,x,y,SM_PIXEL);
   }
   // Show the menu
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   //message(mh'  '_menu_set_state(mh, "XW_addDTDTags", MF_GRAYED, 'M')'  '_menu_set_state(mh, "XWgui_deleteTag", MF_GRAYED, 'M'));
   int status=_menu_show(mh,flags,x,y);
   _menu_destroy(mh);
}

_command void XWgui_newScheme() 
{
   _str newSchemeName = show("-modal _XW_newSchemeForm", currentScheme());

   if (newSchemeName != "") {
      loadSchemeList(newSchemeName);
   }
}

_command void XWgui_deleteScheme() 
{
   _str current = currentScheme();//messageNwait('*'current'*');
   //message("Delete Scheme");
   if (current == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml') || current == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html')) {
   //if (XW_schemes:[current].htmlDefault || XW_schemes:[current].xmlDefault) {
      _message_box("Can not delete a default scheme.");
      return;
   }
   ctl_XW_schemes_list._lbdelete_item();
   XW_schemes._deleteel(current);
   ctl_XW_schemes_list._lbtop();
   ctl_XW_schemes_list._lbselect_line();
   ctl_XW_schemes_list_on_change();
   _str schemeFilename = XW_schemeNameToSchemeFileName(current);
   delete_file(schemeFilename);
}

_command void XWgui_useSchemeWith() 
{
   //currentSchemeWhenNewSchemeCalled = currentScheme();

   show("-modal _XW_form_newUseDefault", currentScheme());

}

_command void XWgui_setXMLDefault() name_info(',')
{
    _str current = currentScheme();

    if (current == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'html')) {
       _message_box("Can not set "current" to be the default XML scheme.");
       return;
    }

   _SetXMLWrapFlags(XW_DEFAULT_SCHEME, current, 'xml');
   loadSchemeList(current, false);
}
_command void XWgui_setHTMLDefault() name_info(',')
{
    _str current = currentScheme();

    if (current == _GetXMLWrapFlags(XW_DEFAULT_SCHEME, 'xml')) {
       _message_box("Can not set "current" to be the default HTML scheme.");
       return;
    }

    _SetXMLWrapFlags(XW_DEFAULT_SCHEME, current, 'html'); 
   loadSchemeList(current, false);
}

_command void XWgui_saveScheme() 
{
   _str current = currentScheme();
   typeless i;
   // Traverse the elements in hash table
//    for (i._makeempty();;) {
//        XW_schemes._nextel(i);
//        if (i._isempty()) break;
       XW_saveXWScheme(XW_schemes:[current]);
       XW_schemes_temp:[current] = XW_schemes:[current];

//    }
       loadSchemeList(current, false);
}

_command void XWgui_importScheme() 
{
   typeless result=_OpenDialog('-new -mdi -modal',
        'Import Scheme',
        '',      // Initial wildcards
        'Schemes (*.xml)',
        OFN_FILEMUSTEXIST,
        '',      // Default extension
        '',      // Initial filename
        ''       // Initial directory
        );
   if (result=='') {
      //return(COMMAND_CANCELLED_RC);
   }
   _message_box("Import Scheme "result);
}

_command void XWgui_exportScheme() 
{
   _message_box("Export Scheme");
}

_command void XWgui_newTag() 
{
   show('-modal _textbox_form',
             'Enter New Tag Name',
             0, //Flags
             '',//Width
             'Enter New Tag Name dialog',//Help item
             '',//Buttons and captions
             '',//retrieve name
             'New Tag Name:' //prompt
             );
   //remove whitespace around name
   _str name = strip(_param1);
   if (!XW_schemes:[currentScheme()].caseSensitive) {
      name = lowcase(name);
   }
   if (name!='') {
      //messageNwait(_param1);
      _str current = currentTag();
      if (!XW_schemes:[currentScheme()].tagSettings._indexin(current)) {
         current = XW_DEFAULT_TAGNAME;
      }
      if (XW_schemes:[currentScheme()].tagSettings._indexin(name)) {
         message("Tag name already in use.");
         return;
      }
      if (name == "") {
         message("Invalid tag name.");
         return;
      }
      XW_schemes:[currentScheme()].tagSettings:[name] = XW_schemes:[currentScheme()].tagSettings:[current];
      XW_schemes:[currentScheme()].tagSettings:[name].name = name;
      ctl_XW_schemes_list_on_change(name);
   }
}

_command void XWgui_deleteTag() 
{
   int status = ctl_XW_tag_list._lbfind_selected(true);
   while (!status) {
      if (!_deleteTag())
         break;
      //move to the next selected line only if the previous delete did not
      //leave me already on a selected line
      if (!ctl_XW_tag_list._lbisline_selected()) {
         status = ctl_XW_tag_list._lbfind_selected(false);
      }
   }
   ctl_XW_tag_list._lbtop();
   ctl_XW_tag_list._lbselect_line();
}

static _str currentDefaultUseIndex() 
{
   _str displayText = strip(ctl_XW_tag_list._lbget_seltext());
   if (substr(displayText, 1, length(XW_UW_DTDDISPLAY)) == XW_UW_DTDDISPLAY) {
      return XW_UW_DTD' 'substr(displayText, length(XW_UW_DTDDISPLAY) + 1);
   } else if (substr(displayText, 1, length(XW_UW_SCHEMADISPLAY)) == XW_UW_SCHEMADISPLAY) {
      return XW_UW_SCHEMA' 'substr(displayText, length(XW_UW_SCHEMADISPLAY) + 1);
   } else if (substr(displayText, 1, length(XW_UW_EXTDISAPLAY)) == XW_UW_EXTDISAPLAY) {
      return XW_UW_EXT' 'substr(displayText, length(XW_UW_EXTDISAPLAY) + 1);
   } else if (substr(displayText, 1, length(XW_UW_MODEDISPLAY)) == XW_UW_MODEDISPLAY) {
      return XW_UW_MODE' 'substr(displayText, length(XW_UW_MODEDISPLAY) + 1);
   }
   return '';
}

static boolean _deleteDefaultUse() 
{
   _str currentUse = currentDefaultUseIndex();
   if (currentUse == '') {
      return true;
   }
//    if (XW_schemes:[currentScheme()].useWithDefault._indexin(currentUse)) {
//       XW_schemes:[currentScheme()].useWithDefault._deleteel(currentUse);
//    }
   ctl_XW_scheme_defaults._lbdelete_item();
   //messageNwait("Delete Tag");//_XML_Wrapping_form.ctl_XW_close
   return true;
}
_command void XWgui_deleteDefaultUse() 
{
   printHashTable(useWithSchemeHash);
   int status = ctl_XW_scheme_defaults._lbfind_selected(true);
   while (!status) {
      if (!_deleteDefaultUse())
         break;
      //move to the next selected line only if the previous delete did not
      //leave me already on a selected line
      if (!ctl_XW_scheme_defaults._lbisline_selected()) {
         status = ctl_XW_scheme_defaults._lbfind_selected(false);
      }
   }
   ctl_XW_scheme_defaults._lbtop();
   ctl_XW_scheme_defaults._lbselect_line();
   printHashTable(useWithSchemeHash);
}

/**
 * Given a tag name in a scheme, determines if another tag gets 
 * it's settings based on this one. 
 * 
 * @return boolean true if another tag in the scheme tries to 
 *         match this one, otherwise returns false.
 */
static boolean isTagReferenceByAnother(_str matchTarget)
{
   _str tagName[];
   _str current = currentScheme();
   getTagNamesInScheme(current, tagName);
   int i;
   for (i = 0; i < tagName._length(); i++) {
      if (XW_schemes:[current].tagSettings:[tagName[i]].matchTagName == matchTarget) {
         return true;
      }
   }
   return false;
}

static boolean _deleteTag() 
{
   _str current = currentTag();
   if (current == XW_DEFAULT_TAGNAME) {
      _message_box("Can not delete default tag.");
      return false;
   }
   if (isTagReferenceByAnother(currentTag())) {
      _str result = _message_box("Another tag references this tag.  Really delete this tag?", '', MB_YESNO|MB_ICONQUESTION);
      if (result==IDNO) {
         return false;
      }
   }
   if (current == XW_COMMENT_DISPLAY) {
      _str promtMessage = 'Really delete the comment tag?';
      if (!XW_CommentsDefaultToNoWrap ) {
         strappend(promtMessage, '  Comment Formatting will be disabled.');
         _str result = _message_box(promtMessage, '', MB_YESNO|MB_ICONQUESTION);
         if (result==IDNO) {
            return false;
         }
      }
   }
   if (current == XW_PROC_TAGNAME_DISPLAY) {
      _str promtMessage = 'Really delete the processing instruction tag?';
      if (!XW_ProcTagsDefaultToNoWrap ) {
         strappend(promtMessage, '  Formatting of processing instructions will be disabled.');
         _str result = _message_box(promtMessage, '', MB_YESNO|MB_ICONQUESTION);
         if (result==IDNO) {
            return false;
         }
      }
   }
   if (XW_schemes:[currentScheme()].tagSettings._indexin(current)) {
      XW_schemes:[currentScheme()].tagSettings._deleteel(current);
   }
   ctl_XW_tag_list._lbdelete_item();
   //messageNwait("Delete Tag");//_XML_Wrapping_form.ctl_XW_close
   return true;
}

/**
 * Decide whether or not, based on current context, the add DTD
 * tags to tags list box method menu item should be enabled or
 * disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_XW_addDTDTags(CMDUI &cmdui,int target_wid,_str command)
{
   //say("OnUpdate_XWaddDTDTags");
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   //return(MF_GRAYED);
   _str lang = p_LangId;
   if (!XW_isSupportedLanguage2(lang)) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

int _onupdate_XW_addDTDTags()
{
   //say('_onupdate_XW_addDTDTags()');
   if ( !_mdi.p_child || !_mdi.p_child._isEditorCtl()) {
      return(MF_GRAYED);
   }
   return(MF_GRAYED);
   _str lang = p_LangId;
   if (!XW_isSupportedLanguage2(lang)) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

_command void XW_addDTDTags()
{
   int wid, status, line_no, tag_flags;
   _str msg, tag_filename, tagname, tag_type, file_name, class_name;

   if (!_find_control('ctl_XW_tag_list') || !file_exists(_GetDialogInfoHt('currentBufferName'))) {
      return;
   }

   if(true) {
      // User wants us to get tags from current file's DTD
      wid=_mdi.p_child;
      if( !wid._isEditorCtl() || !wid._LanguageInheritsFrom('xml') || substr(wid.p_mode_name,1,3)!='XML' ) {
         msg="No DTD specified or cannot get elements from DTD";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      tag_filename=wid._xml_GetConfigTagFile();
      //say(_clex_xmlGetConfig());
      if( tag_filename!="" ) {
         tag_close_db(tag_filename);
         status = tag_read_db(tag_filename);
         if( status>=0 ) {
            status=tag_find_global(VS_TAGTYPE_tag,0,0);
            while( !status ) {
               tag_get_info(tagname,tag_type,file_name,line_no,class_name,tag_flags);
               XW_TagSettings newTag = XW_schemes:[currentScheme()].tagSettings:[XW_DEFAULT_TAGNAME];
               newTag.name = tagname;
               if (!XW_schemes:[currentScheme()].tagSettings._indexin(tagname)) {
                  XW_schemes:[currentScheme()].tagSettings:[tagname] = newTag;
                  ctl_XW_tag_list._lbadd_item(tagname);
                  //XW_schemes:[currentScheme()].modified = true;
               }
               status=tag_next_global(VS_TAGTYPE_tag,0,0);
            }
            tag_reset_find_in_class();
            ctl_XW_tag_list._lbsort();
         }
      }else{
         //message("No tag_filename");
         _str tagNames[];
         int window_id;
         get_window_id(window_id);   // Remember current window
         findAllTagsInFile(_GetDialogInfoHt('currentBufferName'), tagNames);
         activate_window(window_id); 
         int i;
         for (i = 0; i < tagNames._length(); i++) {
            XW_TagSettings newTag = XW_schemes:[currentScheme()].tagSettings:[XW_DEFAULT_TAGNAME];
            newTag.name = tagNames[i];
            if (!XW_schemes:[currentScheme()].tagSettings._indexin(tagNames[i])) {
               XW_schemes:[currentScheme()].tagSettings:[tagNames[i]] = newTag;
               ctl_XW_tag_list._lbadd_item(tagNames[i]);
            }
         }
         ctl_XW_tag_list._lbsort();
      }
      tag_close_db(tag_filename);
   }
}

static void xml_html_options2()
{  
   show("-modal _XW_form", 'xml', xw_buf_name(), XW_getCurrentScheme(xw_buf_name()));
}
/**
 * Used to display the tag configurations dialog from the cuurent documents 
 * setting dialog. 
 */
_command void xml_html_options3()
{  
   show("-modal _XW_form", 'xml', xw_buf_name(), XW_getCurrentScheme(xw_buf_name())); 
}

_command void xml_html_document_options() name_info(","VSARG2_READ_ONLY)
{  
   XW_gui_currentDocOptions();
}

void ctl_XW_optionsXML_button.lbutton_up()
{
   //show("-modal _XW_Options_form");
   int _ok_wid=_control ctl_XW_optionsXML_button;
   _str ext='xml';//_Ext2LangId(_extension.p_text);
   _str form_name='_'ext'_extform';
   int index=find_index(form_name,oi2type(OI_FORM));
   
   show('-modal 'form_name);
   if (_iswindow_valid(_ok_wid)) {
      p_window_id=_ok_wid;_set_focus();
   }
}

void ctl_XW_optionsHTML_button.lbutton_up()
{
   //show("-modal _XW_Options_form");
   int _ok_wid =_control ctl_XW_optionsHTML_button;
   _str ext='html';//_Ext2LangId(_extension.p_text);
   _str form_name ='_'ext'_extform';
   int index = find_index(form_name,oi2type(OI_FORM));

   show('-modal 'form_name);
   if (_iswindow_valid(_ok_wid)) {
      p_window_id = _ok_wid;_set_focus();
   }
}

static boolean tagSettingsNotEqual(XW_TagSettings (&settingsA):[], XW_TagSettings (&settingsB):[]) {
   if (settingsA._length() != settingsB._length()) {
      return true;
   }
   typeless iter;
   for (iter._makeempty(); true;) {
      settingsA._nextel(iter);
      if (iter._isempty()) break;
      if (!settingsB._indexin(iter) || (!(settingsA:[iter].name :== settingsB:[iter].name)) || (settingsA:[iter].matchTagName != settingsB:[iter].matchTagName) || (settingsA:[iter].generalSettings != settingsB:[iter].generalSettings) || (settingsA:[iter].contentWrapSettings != settingsB:[iter].contentWrapSettings) || (settingsA:[iter].tagLayoutSettings != settingsB:[iter].tagLayoutSettings)) {
         return true;
      }
   }
   return false;
}

static boolean schemesNotEqual(XW_Scheme& schemeA, XW_Scheme& schemeB) {
   if (tagSettingsNotEqual(schemeA.tagSettings, schemeB.tagSettings) || (!(schemeA.Name :== schemeB.Name)) || (schemeA.tagIndentStyle != schemeB.tagIndentStyle) || (schemeA.caseSensitive != schemeB.caseSensitive) || (schemeA.useWithDefault._length() != schemeB.useWithDefault._length())) {
      return true;
   }
   int i;
   for (i = 0; i < schemeA.useWithDefault._length(); i++) {
      if ((schemeA.useWithDefault[i].type != schemeB.useWithDefault[i].type) || (schemeA.useWithDefault[i].value != schemeB.useWithDefault[i].value)) {
         return true;
      }
   }
   return false;
}

_command void xwsm() name_info(',')
{

}

static boolean SchemesModified()
{
   if (XW_schemes == null || XW_schemes_temp == null) {
      return true;
   }
   if (XW_schemes._length() != XW_schemes_temp._length()) {
      return true;
   }
   typeless iter;
   for (iter._makeempty(); true;) {
      XW_schemes._nextel(iter);
      if (iter._isempty()) break;
      if (!XW_schemes_temp._indexin(iter) || schemesNotEqual(XW_schemes:[iter], XW_schemes_temp:[iter])) {
         return true;
      }
   }
   return false;
}

static _str onClosingCurrentScheme = '';

void ctl_XW_close.on_create(_str lang, _str currentBufferName, _str currentBufferScheme)
{
   _SetDialogInfoHt('lang', lang);
   _SetDialogInfoHt('currentBufferScheme', currentBufferScheme);
   _SetDialogInfoHt('currentBufferName', currentBufferName);
   if (XWAutoDetect) {
      ctl_XW_schemes_list.p_height = ctl_XW_tag_list.p_height - (ctl_XW_scheme_defaults.p_height + 500);
      ctl_XW_scheme_defaults.p_visible = true;
      ctl_XW_use_with_label.p_visible = true;
   } else {
      ctl_XW_schemes_list.p_height = ctl_XW_tag_list.p_height;
      ctl_XW_scheme_defaults.p_visible = false;
      ctl_XW_use_with_label.p_visible = false;
   }

   XW_schemes_temp = XW_schemes;

   loadSchemeList(currentBufferScheme);
}
void ctl_XW_close.lbutton_up()
{
   onClosingCurrentScheme = currentScheme();
   typeless status;
   if (SchemesModified()) {
   //if (true) {
      _str helpmsg="Save Modified Schemes?";
      status=_message_box(helpmsg, 'SlickEdit', MB_YESNOCANCEL);
      if( status == IDYES) {
         XWclearState();
         XWgui_saveScheme();
      }else if( status == IDCANCEL) {
         return;
      } else {
         XW_schemes = XW_schemes_temp;
         XW_schemes_temp._makeempty();
      }
   }
   if (status != IDCANCEL) {
      //filenameToXWdocStatHash:[tempBuffName].scheme = onClosingCurrentScheme;
   }
   p_active_form._delete_window();
}

////////////////////////////////////////////////////////////////
defeventtab _XW_form_doc_options;

static void loadSchemeNames() {
   _str schemeNames[];
   XW_schemeNamesM(schemeNames);
   int i;
   XW_selectSchemeDB._lbclear();
   //load all the found schemes
   for (i=0; i<schemeNames._length(); i++) {
      XW_selectSchemeDB._lbadd_item(schemeNames[i]);
   }

   if (p_active_form.p_name == '_XW_form_doc_options') { 
      XW_selectSchemeDB._lbfind_and_select_item(_GetDialogInfoHt('currentBufferScheme'), 'E', true);
   }
   XW_selectSchemeDB._lbselect_line();
   XW_selectSchemeDB.p_text = XW_selectSchemeDB._lbget_seltext();
}

void _ctXWSel_ok.on_create(_str lang, _str currentBufferName, _str currentBufferScheme)
{
   _SetDialogInfoHt('lang', lang);
   _SetDialogInfoHt('currentBufferName', currentBufferName);
   _SetDialogInfoHt('currentBufferScheme', currentBufferScheme);

   loadSchemeNames();

   if (filenameToXWdocStatHash._indexin(currentBufferName) && filenameToXWdocStatHash:[currentBufferName].featureOptions & XWflagsSetFlag) {
      XW_clt_CWcurrentDoc.p_value = ((filenameToXWdocStatHash:[currentBufferName].featureOptions & XWcontentWrapFlag) ? 1 : 0);
      XW_clt_TLcurrentDoc.p_value = ((filenameToXWdocStatHash:[currentBufferName].featureOptions & XWtagLayoutFlag) ? 1 : 0);
   } else {
      XW_clt_CWcurrentDoc.p_value = (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang) ? 1 : 0);
      XW_clt_TLcurrentDoc.p_value = (_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, lang) ? 1 : 0);
   }
   if (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang)) {
      XW_clt_CWcurrentDoc.p_enabled = true;
   } else {
      XW_clt_CWcurrentDoc.p_enabled = false;
   }
   if (_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, lang)) {
      XW_clt_TLcurrentDoc.p_enabled = true;
   } else {
      XW_clt_TLcurrentDoc.p_enabled = false;
   }
}
void XW_selectSchemeDB.on_change(int reason)
{
}
void ctl_XW_configureSchemes_button.lbutton_up()
{  
   _str currentBufferName = '';
   _str currentBufferScheme = '';
   _str lang = '';
   if (p_active_form.p_name == '_XW_form_doc_options') { 
      currentBufferScheme = _GetDialogInfoHt('currentBufferScheme');
      currentBufferName   = _GetDialogInfoHt('currentBufferName');
      lang = _GetDialogInfoHt('lang');
   } else {
      currentBufferScheme = XW_selectSchemeDB.p_text;
      lang = _get_language_form_lang_id();
   }
   show("-modal _XW_form", lang, currentBufferName, currentBufferScheme);

   loadSchemeNames();

   if (p_active_form.p_name != '_XW_form_doc_options') { 
      XW_selectSchemeDB._lbfind_and_select_item(currentBufferScheme, 'E', true);
   }
}

//Stores current ext of buffer when the Current Document Options dialog opened
//static _str doc_options_lang_temp = '';
void _XW_form_doc_options.on_create()
{

}
static XW_schemeMatchTargets matchCandidates;
static void XW_gui_currentDocOptions() 
{
   _str buf_name = xw_buf_name();
   _str buf_scheme = XW_getCurrentScheme(buf_name);
   show("-modal _XW_form_doc_options", xw_p_LangId(), buf_name, buf_scheme);
}

static void printHashTable(typeless ht:[]) 
{
   typeless el;
   for (el._makeempty();;) {
      ht._nextel(el);
      if (el._isempty()) break;
      say(el'|'ht:[el]);
   }
}

void _ctXWSel_ok.lbutton_up()
{
   //Selected scheme on close
   _str selectedScheme = cleanXWSchemeName(XW_selectSchemeDB.p_text);
   if (filenameToXWdocStatHash._indexin(_GetDialogInfoHt('currentBufferName')) && XW_schemes._indexin(selectedScheme)) {
      filenameToXWdocStatHash:[_GetDialogInfoHt('currentBufferName')].scheme = selectedScheme;
      int origFeatureOptions = filenameToXWdocStatHash:[_GetDialogInfoHt('currentBufferName')].featureOptions;
      int flagsSet = origFeatureOptions & XWflagsSetFlag;
      int origCWFlag = origFeatureOptions & XWcontentWrapFlag;
      int origTLFlag = origFeatureOptions & XWtagLayoutFlag;
      int newCWFlag = ((XW_clt_CWcurrentDoc.p_value == 1) ? XWcontentWrapFlag : 0);
      int newTLFlag = ((XW_clt_TLcurrentDoc.p_value == 1) ? XWtagLayoutFlag : 0);
      if ((origCWFlag != newCWFlag) || origTLFlag != newTLFlag) {
         flagsSet = XWflagsSetFlag;
      }
      //say('Setting doc options. '(flagsSet | newCWFlag | newTLFlag));
      filenameToXWdocStatHash:[_GetDialogInfoHt('currentBufferName')].featureOptions = flagsSet | newCWFlag | newTLFlag;

      //Did we assign a new scheme?
      if (XWAutoDetect && _GetDialogInfoHt('currentBufferScheme') != selectedScheme) {
         //printHashTable(useWithSchemeHash);
         _str checkBoxPrompts[];
         _str matchTypes[];
         checkBoxPrompts._makeempty();
         //get possible scheme match criteria for this file.

         //printHashTable(useWithSchemeHash);
         //say(matchCandidates.DtdFilename' 'matchCandidates.SchemeFilename' 'matchCandidates.filenameExt' 'matchCandidates.langExt);

         if (matchCandidates.DtdFilename != '') {
            if (!useWithSchemeHash._indexin(XWDTDMatch' 'matchCandidates.DtdFilename) || useWithSchemeHash:[XWDTDMatch' 'matchCandidates.DtdFilename] != selectedScheme) {
               //checkBoxPrompts[0] = "-CHECKBOX Use DTD "matchCandidates.DtdFilename":"0;
               checkBoxPrompts[0] = "-CHECKBOX Make '"selectedScheme"' the default scheme for files using "matchCandidates.DtdFilename":"0;
               matchTypes[0] = XWDTDMatch' 'matchCandidates.DtdFilename;
            }
         }
         if (matchCandidates.SchemeFilename != '') {
            if (!useWithSchemeHash._indexin(XWSchemeMatch' 'matchCandidates.SchemeFilename) || useWithSchemeHash:[XWSchemeMatch' 'matchCandidates.SchemeFilename] != selectedScheme) {
               //checkBoxPrompts[checkBoxPrompts._length()] = "-CHECKBOX Use schema "matchCandidates.SchemeFilename":"0;
               checkBoxPrompts[checkBoxPrompts._length()] = "-CHECKBOX Make '"selectedScheme"' the default scheme for files using "matchCandidates.SchemeFilename":"0;
               matchTypes[matchTypes._length()] = XWSchemeMatch' 'matchCandidates.SchemeFilename;                                      
            }
         }
         if (matchCandidates.filenameExt != '') {
            if (!useWithSchemeHash._indexin(XWExtMatch' 'matchCandidates.filenameExt) || useWithSchemeHash:[XWExtMatch' 'matchCandidates.filenameExt] != selectedScheme) {
               //checkBoxPrompts[checkBoxPrompts._length()] = "-CHECKBOX Have file extension ."matchCandidates.filenameExt":"0;
               checkBoxPrompts[checkBoxPrompts._length()] = "-CHECKBOX Make '"selectedScheme"' the default scheme for files with extension ."matchCandidates.filenameExt":"0;
               matchTypes[matchTypes._length()] = XWExtMatch' 'matchCandidates.filenameExt;
            }
         }
         if (false && matchCandidates.langExt != '') {
            if (!useWithSchemeHash._indexin(XWLangMatch' 'matchCandidates.langExt) || useWithSchemeHash:[XWLangMatch' 'matchCandidates.langExt] != selectedScheme) {
               checkBoxPrompts[checkBoxPrompts._length()] = "-CHECKBOX Use language mode "matchCandidates.langExt":"0;
               matchTypes[matchTypes._length()] = XWLangMatch' 'matchCandidates.langExt;
            }
         }
         int result = 0;
         _str formCaption = XW_SM_FormCaption1:+selectedScheme:+XW_SM_FormCaption2;
         formCaption = 'XML/HTML Formatting Default Schemes';
         switch (checkBoxPrompts._length()) {
         case 1:
            result = textBoxDialog(formCaption,     // Form caption
                                       0,             // Flags
                                       0,             // Use default textbox width
                                       XW_SM_HelpItem, // Help item
                                       "OK",            // Buttons and captions
                                       "",               // Retrieve Name
                                       checkBoxPrompts[0]);
            if (result == 1) {
               if (_param1 == 1) useWithSchemeHash:[matchTypes[0]] = selectedScheme;
            }
            break;
         case 2:
            result = textBoxDialog(formCaption,     // Form caption
                                       0,             // Flags
                                       0,             // Use default textbox width
                                       XW_SM_HelpItem, // Help item
                                       "OK",            // Buttons and captions
                                       "",               // Retrieve Name
                                       checkBoxPrompts[0],
                                       checkBoxPrompts[1]);
            if (result == 1) {
               if (_param1 == 1) useWithSchemeHash:[matchTypes[0]] = selectedScheme;
               if (_param1 == 2) useWithSchemeHash:[matchTypes[1]] = selectedScheme;
            }
            break;
         case 3:
            result = textBoxDialog(formCaption,     // Form caption
                                       0,             // Flags
                                       0,             // Use default textbox width
                                       XW_SM_HelpItem, // Help item
                                       "",            // Buttons and captions
                                       "",               // Retrieve Name
                                       checkBoxPrompts[0],
                                       checkBoxPrompts[1],
                                       checkBoxPrompts[2]);
            if (result == 1) {
               if (_param1 == 1) useWithSchemeHash:[matchTypes[0]] = selectedScheme;
               if (_param1 == 2) useWithSchemeHash:[matchTypes[1]] = selectedScheme;
               if (_param1 == 3) useWithSchemeHash:[matchTypes[2]] = selectedScheme;
            }
            break;
         case 4:
            result = textBoxDialog(formCaption,     // Form caption
                                       0,             // Flags
                                       0,             // Use default textbox width
                                       XW_SM_HelpItem, // Help item
                                       "",            // Buttons and captions
                                       "",               // Retrieve Name
                                       checkBoxPrompts[0],
                                       checkBoxPrompts[1],
                                       checkBoxPrompts[2],
                                       checkBoxPrompts[3]);
            if (result == 1) {
               if (_param1 == 1) useWithSchemeHash:[matchTypes[0]] = selectedScheme;
               if (_param1 == 2) useWithSchemeHash:[matchTypes[1]] = selectedScheme;
               if (_param1 == 3) useWithSchemeHash:[matchTypes[2]] = selectedScheme;
               if (_param1 == 4) useWithSchemeHash:[matchTypes[3]] = selectedScheme;
            }
            break;
            default:
         }
         //printHashTable(useWithSchemeHash);
      }
   }
   //say(cleanXWSchemeName(XW_selectSchemLB._lbget_seltext()));
   p_active_form._delete_window();
}

defeventtab _XW_newSchemeForm;
void _XW_newSchemeForm.on_create(_str currentSchemeWhenNewSchemeCalled)
{
   _str filenames[];
   XW_schemeNamesM(filenames);
   int i;
   ctl_XW_newSchemeName_text.p_text = "newScheme";
   XW_newSchemLB._lbclear();
   //load all the found schemes
   for (i=0; i<filenames._length(); i++) {
      XW_newSchemLB._lbadd_item(filenames[i]);
   }
   if (currentSchemeWhenNewSchemeCalled != ""){
      XW_newSchemLB._lbi_search('', currentSchemeWhenNewSchemeCalled, 'E');
   } else XW_newSchemLB._lbtop();
   XW_newSchemLB._lbselect_line();
}

static _str cleanNewName(_str newName) 
{
   newName = strip(translate(newName,'','*','',0));
   newName = translate(newName, '_', ' ', '');
   //check that it is a valid filename for both Unix and Windows
   return newName;
}
void _ctXWCreate_ok.lbutton_up()
{
   _str newName = ctl_XW_newSchemeName_text.p_text;
   newName = cleanNewName(newName);
   _str fromName = cleanXWSchemeName(XW_newSchemLB._lbget_seltext());
   if (newName == "" || XW_schemes._indexin(newName)) {
      message("Invalid scheme name.");
      return;
   }
   if (!XW_schemes._indexin(fromName)) {
      fromName = _GetXMLWrapFlags(XW_DEFAULT_SCHEME, xw_p_LangId());
   }
   p_active_form._delete_window(newName);
   XW_schemes:[newName] = XW_schemes:[fromName];
   XW_schemes:[newName].Name = newName;
}

//debug code
boolean XW_UW_validValue(int type, _str& value) 
{
   value = strip(value);
   if (value == '') {
      return false;
   }
   return true;
}

defeventtab _XW_form_newUseDefault;
void _XW_form_newUseDefault.on_create(_str currentSchemeName)
{
   _SetDialogInfoHt('currentSchemeName', currentSchemeName);
   ctl_radio_newUseExt.p_value = 1;
   ctl_radio_newUseDTD.p_value = 0;
   ctl_radio_newUseSchema.p_value = 0;
   ctl_newUseValue_text.p_text = '';
}

void _ctl_XWnewUseOK.lbutton_up()
{
   //message('Handle the new use here');
   int type;
   if (ctl_radio_newUseExt.p_value == 1) {
      type = XW_UW_EXT;
   } else if (ctl_radio_newUseDTD.p_value == 1) {
      type = XW_UW_DTD;
   } else if (ctl_radio_newUseSchema.p_value == 1) {
      type = XW_UW_SCHEMA;
   } else if (ctl_radio_newUseMode.p_value == 1) {
      type = XW_UW_MODE;
   }
   _str value = ctl_newUseValue.p_text;
   if (XW_UW_validValue(type, value)) {
      _str hashKey = type' 'value;
      XW_SchemeUseWith newUseWith;
      newUseWith.type = type;
      newUseWith.value = value;
      if (useWithSchemeHash._indexin(hashKey)) {
         //say('saved new use with 'hashKey);
         XW_schemes:[_GetDialogInfoHt('currentSchemeName')].useWithDefault[XW_schemes:[_GetDialogInfoHt('currentSchemeName')].useWithDefault._length()] = newUseWith;
         useWithSchemeHash:[hashKey] = _GetDialogInfoHt('currentSchemeName');
      } else {
         //say('saved new use with 'hashKey);
         XW_schemes:[_GetDialogInfoHt('currentSchemeName')].useWithDefault[XW_schemes:[_GetDialogInfoHt('currentSchemeName')].useWithDefault._length()] = newUseWith;
         useWithSchemeHash:[hashKey] = _GetDialogInfoHt('currentSchemeName');
      }
   }else {
   }
   p_active_form._delete_window();
}

_str getSymbolTransaliasFile(_str lang = p_LangId) 
{
   if (_create_config_path()) {
      message('Unable to find config path.');
      return '';
   }
   _str filename = _ConfigPath() :+ lang :+ XW_SYMBOLTRANSALIASFILESUFFIX;
   if (!file_exists(filename)) {
      //Copy a default one over
      _str defaultfilename = get_env('VSROOT');
      _maybe_append_filesep(defaultfilename);
      defaultfilename = defaultfilename :+ 'sysconfig' :+ FILESEP :+ 'aliases' :+ FILESEP :+ '$8' :+ XW_DEFAULTSYMBOLTRANSALIASFILE;
      if (file_exists(defaultfilename)) {
         se.alias.AliasFile aliasFile;
         aliasFile.open(defaultfilename);
         profileName := getAliasLangProfileName(lang):+'/symboltrans';
         aliasFile.setProfile(profileName);
         aliasFile.save(filename);
         aliasFile.close();

      } else {
         //message('Unable to find existing doc comment alias file for extension 'lang'.');
      }
   }

   return filename;
}

void autoSymbolTransEditor(_str lang) 
{
   _str filename = getSymbolTransaliasFile(lang);

   // now launch the alias dialog
   typeless result=show('-modal -xy -new _alias_editor_form', filename, false, '', SYMTRANS_ALIAS_FILE, lang);
   return;
}
