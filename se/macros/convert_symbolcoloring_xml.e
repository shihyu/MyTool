/* 
 
CONVERT FROM:
<SymbolColoring
	version="1.0"
	productName="SlickEdit"
	productVersion="14.0.0.0">
	<Scheme
		name="All symbols - Silver"
		compatibleWith="Crispy;Eggshell;Grayscale;Harvest;Pumpkin;Silver;Wintergreen">
		<Rule
			name="Local variable"
			regexType=""
			classRE=""
			nameRE=""
			kinds="lvar"
			attributesOn=""
			attributesOff="static"
			parentColor="*CFG_WINDOW_TEXT*"
			fg="0xA000"
			fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
      </Rule>
 
TO: 
  <profile n="All symbols - Silver">
     <p n="__compatible_with" v="Crispy;Eggshell;Grayscale;Harvest;Pumpkin;Silver;Wintergreen"/>
     <p n="Local variable">
         <attrs position="100" regex_type="" class_re="" name_re="" kinds="lvar"  attributes_on=""
                attributes_off="static" parent_color="*CFG_WINDOW_TEXT*" fg="0xA000" font_flags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR"/>
     /p>
  </profile>
 
 
*/

#pragma option(pedantic,on)
#include "slick.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"
#import "main.e"
#import "se/color/SymbolColorRule.e"
#import "se/color/SymbolColorRuleBase.e"

static se.color.SymbolColorRule  _symbol_coloring_load_one_old_rule(int handle, int property_node) {
   attrs_node:=property_node;
   ruleName:=_xmlcfg_get_attribute(handle,property_node,'name');
   se.color.ColorInfo c;
   se.color.SymbolColorRule rule;
   rule.m_colorInfo = c;

   rule.m_ruleName            = ruleName;
   rule.m_regexOptions        = _xmlcfg_get_attribute(handle, attrs_node, "regexType");
   rule.m_classRegex          = _xmlcfg_get_attribute(handle, attrs_node, "classRE");
   rule.m_nameRegex           = _xmlcfg_get_attribute(handle, attrs_node, "nameRE");
   rule.setTagTypes(_xmlcfg_get_attribute(handle, attrs_node, "kinds"));
   se.color.SymbolColorRuleBase scc;
   rule.m_attributeFlagsOn    = scc.parseTagFlags(_xmlcfg_get_attribute(handle, attrs_node, "attributesOn"));
   rule.m_attributeFlagsOff   = scc.parseTagFlags(_xmlcfg_get_attribute(handle, attrs_node, "attributesOff"));

   isValid := true;
   se.color.ColorInfo color;
   color.m_parentName = se.color.SymbolColorRuleBase.parseColorName(_xmlcfg_get_attribute(handle, attrs_node, "parentColor"));
   fg := _hex2dec(_xmlcfg_get_attribute(handle, attrs_node, "fg"), 16, isValid);
   if (!isValid) fg=0x000000;
   color.m_foreground = fg;
   bg := _hex2dec(_xmlcfg_get_attribute(handle, attrs_node, "bg"), 16, isValid);
   if (!isValid) bg=0xffffff;
   color.m_background = bg;
   color.m_fontFlags  = se.color.ColorInfo.parseFontFlags(_xmlcfg_get_attribute(handle, attrs_node, "fontFlags"));
   rule.m_colorInfo = color;

   return rule;
}

static void _convert_symbolcoloring_profile_to_xmlcfg(int handle,int scheme_node) {
   profileName:=_xmlcfg_get_attribute(handle,scheme_node,"name");
   if (profileName=='') {
      // We are lost
      return;
   }
   se.color.SymbolColorRuleBase rb;
   rb.m_name=profileName;
   rb.m_ruleList._makeempty();
   __compatible_with:=_xmlcfg_get_attribute(handle,scheme_node,"compatibleWith");
   if (__compatible_with == null) __compatible_with="";
   rb.setCompatibleColorSchemes(split2array(__compatible_with, ";"));


   child:=_xmlcfg_get_first_child(handle,scheme_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (child>=0) {
      if (_xmlcfg_get_name(handle,child)!='Rule') {
         child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         continue;
      }

      rule:=_symbol_coloring_load_one_old_rule(handle,child);
      if (rule != null) {
         rb.addRule(rule);
      }


      child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
   rb.saveProfile();
}

static void _convert_symbolcoloring_profiles_to_xmlcfg(_str filename) {
   handle:=_xmlcfg_open(arg(1),auto status);
   if (handle<0) {
      return;
   }
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/SymbolColoring/Scheme",array);
   for (i:=0;i<array._length();++i) {
      _convert_symbolcoloring_profile_to_xmlcfg(handle,array[i]);
   }
   _xmlcfg_close(handle);
}

defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   _convert_symbolcoloring_profiles_to_xmlcfg(filename);
}
