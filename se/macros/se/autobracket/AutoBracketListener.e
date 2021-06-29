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
#require "se/autobracket/IAutoBracket.e"
#import "se/ui/AutoBracketMarker.e"
#import "se/lang/api/LanguageSettings.e"
#import "codehelp.e"
#import "recmacro.e"
#import "slickc.e"
#import "os2cmds.e"
#import "tbterminal.e"
#endregion

namespace se.autobracket;

using namespace se.lang.api;

using se.ui.AutoBracketMarker;

static _str g_AutoBracketInterfaces:[] = {
   "ansic"           => "se.lang.cpp.CPPAutoBracket",
   "c"               => "se.lang.cpp.CPPAutoBracket",

   "m"               => "se.lang.objectivec.ObjectiveCAutoBracket",

   "cs"              => "se.lang.generic.CSharpAutoBracket",

   "d"               => "se.lang.generic.DAutoBracket",

   "lua"             => "se.lang.generic.LuaAutoBracket",

   "phpscript"       => "se.lang.generic.PerlAutoBracket",
   "pl"              => "se.lang.generic.PerlAutoBracket",
   "py"              => "se.lang.generic.PythonAutoBracket",
   "coffeescript"    => "se.lang.generic.CoffeeScriptAutoBracket",
   "scala"           => "se.lang.generic.ScalaAutoBracket",

   "markdown"        => "se.lang.markdown.MarkdownAutoBracket",

   "matlab"          => "se.lang.matlab.MatlabAutoBracket",

   "html"            => "se.lang.xml.XMLAutoBracket",
   "xml"             => "se.lang.xml.XMLAutoBracket",
   "vpj"             => "se.lang.xml.XMLAutoBracket",
   "vpw"             => "se.lang.xml.XMLAutoBracket",
   "docbook"         => "se.lang.xml.XMLAutoBracket",

   "as"              => "se.lang.generic.GenericAutoBracket",
   "awk"             => "se.lang.generic.GenericAutoBracket",
   "cfscript"        => "se.lang.generic.GenericAutoBracket",
   "cg"              => "se.lang.generic.GenericAutoBracket",
   "ch"              => "se.lang.generic.GenericAutoBracket",
   "css"             => "se.lang.generic.GenericAutoBracket",
   "e"               => "se.lang.generic.GenericAutoBracket",
   "java"            => "se.lang.generic.GenericAutoBracket",
   "js"              => "se.lang.generic.GenericAutoBracket",
   "jsl"             => "se.lang.generic.GenericAutoBracket",
   
   "powershell"      => "se.lang.generic.GenericAutoBracket",
   "tcl"             => "se.lang.generic.GenericAutoBracket",
   "vera"            => "se.lang.generic.GenericAutoBracket",
   "verilog"         => "se.lang.generic.GenericAutoBracket",
   "systemverilog"   => "se.lang.generic.GenericAutoBracket",
   "r"   => "se.lang.generic.GenericAutoBracket",
};

class AutoBracketListener {
   private static bool s_cancelInsert = false;

   static void cancelBracketInsert()
   {
      s_cancelInsert = true;
   }

   private static IAutoBracket getInterface(_str langID)
   {
      IAutoBracket ab = null;
      classname := g_AutoBracketInterfaces:[langID];
      if (!classname || classname :== '') {
         if (p_lexer_name!='') {
            // Default to smarter code if have color coding
            classname = "se.lang.generic.GenericAutoBracket";
         } else {
            classname = "se.autobracket.DefaultAutoBracket";
         }
      }
      if (find_index(classname, ACLASS_TYPE)) {
         ab._construct(classname);
      }
      return ab;
   }

   private static bool getSettings(_str key, _str &close_ch, bool &insertPad)
   {
      if (p_readonly_mode || p_hex_mode == HM_HEX_ON) {
         return(false);
      }
      keyEnabled := false;
      insertPad = false;
      close_ch = '';
      opts := LanguageSettings.getAutoBracket(p_LangId);
      ab := getInterface(p_LangId);
      if (ab == null) {
         return(false);
      }
      if (opts & AUTO_BRACKET_ENABLE) {
         switch (key) {
         case '(':
            close_ch = ')';
            keyEnabled = (opts & AUTO_BRACKET_PAREN) ? true : false;
            insertPad = (opts & AUTO_BRACKET_PAREN_PAD) ? true : false;
            break;

         case '[':
            close_ch = ']';
            keyEnabled = (opts & AUTO_BRACKET_BRACKET) ? true : false;
            insertPad = (opts & AUTO_BRACKET_BRACKET_PAD) ? true : false;
            break;

         case '<':
            close_ch = '>';
            keyEnabled = (opts & AUTO_BRACKET_ANGLE_BRACKET) ? true : false;
            insertPad = (opts & AUTO_BRACKET_ANGLE_BRACKET_PAD) ? true : false;
            break;

         case '"':
            close_ch = '"';
            keyEnabled = (opts & AUTO_BRACKET_DOUBLE_QUOTE) ? true : false;
            break;

         case "'":
            close_ch = "'";
            keyEnabled = (opts & AUTO_BRACKET_SINGLE_QUOTE) ? true : false;
            break;

         default:
            keyEnabled = ab.getSettings(key, opts, close_ch, insertPad);
            break;
         }
         if (keyEnabled && close_ch != '') {
            return ab.onKey(key);
         }
      }
      return(false);
   }

   /** 
    * @return 
    * Return 'true' if Auto-Close is enabled for the given key for the current file.
    * 
    * @param key     Key to check (open paren, open brace, etc)
    */
   static bool isEnabledForKey(_str key)
   {
      close_ch := "";
      insertPad := false;
      return getSettings(key, close_ch, insertPad);
   }

   private static void insertTextMarker(_str open_ch, _str close_ch, bool insertPad, int openCol)
   {
      _macro('m', _macro('s'));
      closeCol := p_col;
      p_col = openCol;
      openOffset := _QROffset();
      openLen := length(open_ch);
      if (insertPad) {
         p_col += openLen;
         padOffset := closeCol - p_col;
         _insert_text(" ");
         closeCol += 1;
         _macro_append("p_col -= "padOffset";");
         _macro_call('_insert_text', " ");
         _macro_append("p_col += "padOffset";");
      }
      p_col = closeCol;
      text := (insertPad ? " " : "") :+ close_ch;
      _insert_text(text);
      closeLen := length(close_ch);
      closeOffset := _QROffset() - closeLen;
      colOffset := insertPad ? closeLen + 1 : closeLen;
      p_col -= colOffset;
      _macro_call('_insert_text', text);
      _macro_append("p_col -= "colOffset";");
      AutoBracketMarker.createMarker(close_ch, openOffset, openLen, closeOffset, closeLen);
   }

   private static void addMarker(_str close_ch, bool insertPad, long openOffset, long openLen)
   {
      text := (insertPad ? "  " : "") :+ close_ch;
      _insert_text(text);
      closeLen := length(close_ch);
      closeOffset := _QROffset() - closeLen;
      colOffset := insertPad ? closeLen + 1 : closeLen;
      p_col -= colOffset;

      _macro('m', _macro('s'));
      _macro_call('_insert_text', text);
      _macro_append("p_col -= "colOffset";");
      AutoBracketMarker.createMarker(close_ch, openOffset, openLen, closeOffset, closeLen);
   }

   private static bool onKey(_str key)
   {
      idname:=_ConcurProcessName();
      if (idname!=null && _process_is_interactive_idname(idname)) {
         if (!_process_within_submission()) {
            return false;
         }
      }
      if (_MultiCursorAlreadyLooping()) {
         return false;
      }
      cancelInsert := s_cancelInsert;
      s_cancelInsert = false;
      embedded_status := _EmbeddedStart(auto orig_values);
      result := getSettings(key, auto close_ch, auto insertPad);
      if (result) {
         index := _FindLanguageCallbackIndex("_%s_allow_AutoBracket");
         if (index && !call_index(key,index)) {
            result=false;
         }
      }
      if (result) {
         openCol := p_col;
         // Need to turn back on silast.next_recording_macro
         _macro('M',_macro());
         call_key(key, '', '1');
         if (!s_cancelInsert) {
            openLen := length(key);
            if (p_col > openCol + openLen) {
               insertTextMarker(key, close_ch, insertPad, openCol);
            } else {
               openOffset := _QROffset() - openLen;
               addMarker(close_ch, insertPad, openOffset, openLen);
            }
            RefreshListHelp();
         }
      }
      if (embedded_status == 1) {
         _EmbeddedEnd(orig_values);
      }
      s_cancelInsert = cancelInsert;
      return(result);
   }

   static bool onKeyin(_str key)
   {
      s_cancelInsert = true;  // ensure keyin callback gets canceled
      embedded_status := _EmbeddedStart(auto orig_values);
      result := getSettings(key, auto close_ch, auto insertPad);
      if (result) {
         text := key :+ (insertPad ? "  " : "") :+ close_ch;
         _insert_text(text);
         openLen := length(key);
         closeLen := length(close_ch);
         openOffset := _QROffset() - length(text);
         closeOffset := _QROffset() - closeLen;
         colOffset := closeLen + (insertPad ? 1 : 0);
         p_col -= colOffset;
         AutoBracketMarker.createMarker(close_ch, openOffset, openLen, closeOffset, closeLen);
      }
      if (embedded_status == 1) {
         _EmbeddedEnd(orig_values);
      }
      return(result);
   }

   static void initCallback(_str langID, bool enabled)
   {
      _str keyarray[];
      if (enabled) {
         // add common keys
         keyarray[0] = '(';
         keyarray[1] = '[';
         keyarray[2] = '<';
         keyarray[3] = '"';
         keyarray[4] = "'";

         // add custom keys
         ab := getInterface(p_LangId);
         if (ab != null) {
            ab.init(keyarray);
         }
      }
      _kbd_add_callback(find_index('se.autobracket.AutoBracketListener.onKey', PROC_TYPE), keyarray);
   }
};

