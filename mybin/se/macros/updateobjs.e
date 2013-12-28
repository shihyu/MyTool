////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44188 $
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
#import "main.e"
#import "search.e"
#import "stdprocs.e"
#import "toolbar.e"
#endregion

///////////////////////////////////////////////////////////////////////////////
// This macro is used to update the user's vusrobjs.e file to work
// properly with version 10.0 or higher of the editor.
// 
// The main objective is to map the toolbar bitmaps
// to the new toolbar icon files.
// 
// The second objective is to rename their customized toolbars
// to 'old' so that they will get the changes in their new toolbars.
// 

// Map standard toolbar names to 'old' toolbar names
static _str gFormMap:[] = {
   "_tbstandard_form"        => "old_tbstandard_form",
   "_tbtagging_form"         => "old_tbtagging_form",
   "_tbdebugbb_form"         => "old_tbdebugbb_form",
   "_tbedit_form"            => "old_tbedit_form",
};

// Map old bitmap names to new bitmap names
static _str gBitmapMap:[] = {
   "bbapi.bmp"               => "bbapi_index.ico",
   "bbbeauty.bmp"            => "bbbeautify.ico",
   "bbbkshfl.bmp"            => "bbshift_left.ico",
   "bbbkshfr.bmp"            => "bbshift_right.ico",
   "bbblank.bmp"             => "bbblank.ico",
   "bbbottom.bmp"            => "bbbottom.ico",
   "bbbuflst.bmp"            => "bblist_buffers.ico",
   "bbcalc.bmp"              => "bbcalculator.ico",
   "bbcascd.bmp"             => "bbcascade.ico",
   "bbcbfind.bmp"            => "bbclass_browser_find.ico",
   "bbchkin.bmp"             => "bbcheckin.ico",
   "bbchkout.bmp"            => "bbcheckout.ico",
   "bbcomp.bmp"              => "bbcompile.ico",
   "bbcopy.bmp"              => "bbcopy.ico",
   "bbcprmt.bmp"             => "bbshell.ico",
   "bbcut.bmp"               => "bbcut.ico",
   "bbdbgaddwatch.bmp"       => "bbdebug_add_watch.ico",
   "bbdbgbreakpoints.bmp"    => "bbdebug_breakpoints.ico",
   "bbdbgclearbp.bmp"        => "bbdebug_clear_breakpoints.ico",
   "bbdbgclearex.bmp"        => "bbdebug_clear_exceptions.ico",
   "bbdbgcontinue.bmp"       => "bbdebug_continue.ico",
   "bbdbgdisablebp.bmp"      => "bbdebug_disable_breakpoints.ico",
   "bbdbgdisableex.bmp"      => "bbdebug_disable_exceptions.ico",
   "bbdbgdown.bmp"           => "bbdebug_down.ico",
   "bbdbgexceptions.bmp"     => "bbdebug_exceptions.ico",
   "bbdbggotopc.bmp"         => "bbdebug_show_next_statement.ico",
   "bbdbgrestart.bmp"        => "bbdebug_restart.ico",
   "bbdbgruncursor.bmp"      => "bbdebug_run_to_cursor.ico",
   "bbdbgstepdeep.bmp"       => "bbdebug_step_deep.ico",
   "bbdbgstepinstr.bmp"      => "bbdebug_step_instruction.ico",
   "bbdbgstepinto.bmp"       => "bbdebug_step_into.ico",
   "bbdbgstepout.bmp"        => "bbdebug_step_out.ico",
   "bbdbgstepover.bmp"       => "bbdebug_step_over.ico",
   //"bbdbgsteppast.bmp"       => "bbdebug_step_past.ico",
   "bbdbgstop.bmp"           => "bbdebug_stop.ico",
   "bbdbgsuspend.bmp"        => "bbdebug_suspend.ico",
   "bbdbgtoggle3.bmp"        => "bbdebug_toggle_breakpoint3.ico",
   "bbdbgtogglebp.bmp"       => "bbdebug_toggle_breakpoint.ico",
   "bbdbgtoggleen.bmp"       => "bbdebug_toggle_enabled.ico",
   "bbdbgtoggleex.bmp"       => "bbdebug_add_exception.ico",
   "bbdbgtop.bmp"            => "bbdebug_top.ico",
   "bbdbgup.bmp"             => "bbdebug_up.ico",
   "bbdbgvcrcontinue.bmp"    => "bbdebug_continue.ico",
   "bbdbgvcrrestart.bmp"     => "bbdebug_restart.ico",
   "bbdebug.bmp"             => "bbdebug.ico",
   "bbdiff.bmp"              => "bbdiff.ico",
   "bbexec.bmp"              => "bbexecute.ico",
   "bbexit.bmp"              => "bbexit.ico",
   "bbfcthlp.bmp"            => "bbfunction_help.ico",
   "bbffile.bmp"             => "bbfind_file.ico",
   //"bbfilcmp.bmp"            => "bbfile_compare.ico",
   "bbfind.bmp"              => "bbfind.ico",
   "bbfindn.bmp"             => "bbfind_next.ico",
   "bbfnfile.bmp"            => "bbfind_file.ico",
   "bbfnhdr.bmp"             => "bbshow_procs.ico",
   "bbftp.bmp"               => "bbftp.ico",
   "bbfword.bmp"             => "bbfind_word.ico",
   "bbgobmk.bmp"             => "bbbookmarks.ico",
   "bbhexed.bmp"             => "bbhex.ico",
   "bbhidcbk.bmp"            => "bbhide_code_block.ico",
   "bbhidsel.bmp"            => "bbhide_selection.ico",
   "bbhtanchor.bmp"          => "bbhtml_anchor.ico",
   "bbhtapplet.bmp"          => "bbhtml_applet.ico",
   "bbhtbody.bmp"            => "bbhtml_body.ico",
   "bbhtbold.bmp"            => "bbhtml_bold.ico",
   "bbhtcaption.bmp"         => "bbhtml_table_caption.ico",
   "bbhtcenter.bmp"          => "bbhtml_center.ico",
   "bbhtcode.bmp"            => "bbhtml_code.ico",
   //"bbhtem.bmp"              => "bbhtml_emphasis.ico",
   "bbhtfont.bmp"            => "bbhtml_font.ico",
   "bbhtfont2.bmp"           => "bbhtml_font.ico",
   "bbhthead.bmp"            => "bbhtml_head.ico",
   "bbhthead3.bmp"           => "bbhtml_head.ico",
   "bbhtheader.bmp"          => "bbhtml_table_header.ico",
   "bbhthline.bmp"           => "bbhtml_hline.ico",
   "bbhtimage.bmp"           => "bbhtml_image.ico",
   "bbhtitalic.bmp"          => "bbhtml_italic.ico",
   "bbhtlink.bmp"            => "bbhtml_link.ico",
   "bbhtlist.bmp"            => "bbhtml_list.ico",
   //"bbhtoption.bmp"          => "bbhtml_option.ico",
   "bbhtparagraph.bmp"       => "bbhtml_paragraph.ico",
   "bbhtrgbcolor.bmp"        => "bbhtml_rgb_color.ico",
   "bbhtright.bmp"           => "bbhtml_right.ico",
   "bbhtscript.bmp"          => "bbhtml_script.ico",
   "bbhtstyle.bmp"           => "bbhtml_style.ico",
   "bbhttable.bmp"           => "bbhtml_table.ico",
   "bbhttarget.bmp"          => "bbhtml_anchor.ico",
   "bbhttcol.bmp"            => "bbhtml_table_cell.ico",
   "bbhttrow.bmp"            => "bbhtml_table_row.ico",
   "bbhtuline.bmp"           => "bbhtml_underline.ico",
   "bbhtview.bmp"            => "bbhtml_preview.ico",
   "bbisel.bmp"              => "bbindent_selection.ico",
   "bblcase.bmp"             => "bblowcase.ico",
   //"bblistds.bmp"            => "bblist_data_sets.ico",
   //"bblistjb.bmp"            => "bblist_jobs.ico",
   "bblstclp.bmp"            => "bbclipboards.ico",
   "bblstmem.bmp"            => "bblist_symbols.ico",
   "bbmake.bmp"              => "bbmake.ico",
   "bbmax.bmp"               => "bbmaximize_window.ico",
   "bbmenued.bmp"            => "bbmenu_editor.ico",
   "bbmerge.bmp"             => "bbmerge.ico",
   "bbminall.bmp"            => "bbiconize_all.ico",
   "bbmktags.bmp"            => "bbmake_tags.ico",
   "bbmplay.bmp"             => "bbmacro_execute.ico",
   "bbmrec.bmp"              => "bbmacro_record.ico",
   "bbnew.bmp"               => "bbnew.ico",
   "bbnexter.bmp"            => "bbnext_error.ico",
   "bbnfunc.bmp"             => "bbnext_tag.ico",
   "bbnxtbuf.bmp"            => "bbnext_buffer.ico",
   "bbnxtwin.bmp"            => "bbnext_window.ico",
   "bbopen.bmp"              => "bbopen.ico",
   "bbpaste.bmp"             => "bbpaste.ico",
   "bbpfunc.bmp"             => "bbprev_tag.ico",
   "bbpgdn.bmp"              => "bbpage_down.ico",
   "bbpgup.bmp"              => "bbpage_up.ico",
   "bbpmatch.bmp"            => "bbfind_matching_paren.ico",
   "bbpoptag.bmp"            => "bbpop_tag.ico",
   "bbprint.bmp"             => "bbprint.ico",
   "bbprvbuf.bmp"            => "bbprev_buffer.ico",
   "bbprvwin.bmp"            => "bbprev_window.ico",
   "bbptag.bmp"              => "bbprev_tag.ico",
   "bbqmark.bmp"             => "bbsdkhelp.ico",
   "bbredo.bmp"              => "bbredo.ico",
   "bbreflow.bmp"            => "bbreflow.ico",
   "bbrefs.bmp"              => "bbfind_refs.ico",
   "bbreplac.bmp"            => "bbreplace.ico",
   "bbs2t.bmp"               => "bbspaces_to_tabs.ico",
   "bbsave.bmp"              => "bbsave.ico",
   "bbselcbk.bmp"            => "bbselect_code_block.ico",
   "bbseldis.bmp"            => "bbselective_display.ico",
   "bbsetbmk.bmp"            => "bbset_bookmark.ico",
   "bbshall.bmp"             => "bbshow_all.ico",
   "bbsmrec.bmp"             => "bbmacro_stop.ico",
   "bbspell.bmp"             => "bbspell.ico",
   "bbstepover.bmp"          => "bbdebug_step_over.ico",
   "bbt2s.bmp"               => "bbtabs_to_spaces.ico",
   "bbtbed.bmp"              => "bbtoolbars.ico",
   "bbtileh.bmp"             => "bbtile_horizontal.ico",
   "bbtilev.bmp"             => "bbtile_vertical.ico",
   "bbtool1.bmp"             => "bbtool08.ico",
   "bbtool2.bmp"             => "bbtool09.ico",
   "bbtool3.bmp"             => "bbtool26.ico",
   "bbtool4.bmp"             => "bbtool27.ico",
   "bbtool5.bmp"             => "bbtool08.ico",
   "bbtool6.bmp"             => "bbtool08.ico",
   "bbtool7.bmp"             => "bbtool08.ico",
   "bbtool8.bmp"             => "bbtool08.ico",
   "bbtool9.bmp"             => "bbtool08.ico",
   "bbtop.bmp"               => "bbtop.ico",
   "bbuisel.bmp"             => "bbunindent_selection.ico",
   "bbundo.bmp"              => "bbundo.ico",
   "bbupcase.bmp"            => "bbupcase.ico",
   "bbvcflk.bmp"             => "bbvc_lock.ico",
   "bbvcfulk.bmp"            => "bbvc_unlock.ico",
   "bbvclver.bmp"            => "bbvc_history.ico",
   "bbvcvdif.bmp"            => "bbvc_diff.ico",
   "bbvsehelp.bmp"           => "bbvsehelp.ico",
   "bbxmlval.bmp"            => "bbxml_validate.ico",
   "bbxmlwel.bmp"            => "bbxml_wellformedness.ico",
};

static int updatePictureProperties()
{
   // replace all picture styles to the highlight style
   top();
   replace("p_style=PSPIC_AUTO_BUTTON", "p_style=PSPIC_HIGHLIGHTED_BUTTON", "e*");
   top();
   replace("p_style=PSPIC_FLAT_BUTTON", "p_style=PSPIC_HIGHLIGHTED_BUTTON", "e*");

   // PS_PIC_DEFAULT_TRANSPARENT is obsolete. If you want transparency, then
   // create an image with transparency.
   top();
   replace("p_style=PSPIC_DEFAULT_TRANSPARENT", "p_style=PSPIC_DEFAULT", "e*");

   // start from the top
   top();
   _begin_line();

   int count=0;
   int status=0;
   for (;;) {

      // look for p_picture
      status = search("p_picture", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str bitmap;
      parse line with leading "p_picture" "=" bitmap ";";

      // strip quotes
      if (first_char(bitmap) == "'") {
         bitmap = strip(bitmap, 'B', "'");
      } else if (first_char(bitmap) == '"') {
         bitmap = strip(bitmap, 'B', '"');
      }

      // needs update?
      if (gBitmapMap._indexin(bitmap)) {

         // get the new bitmap name
         bitmap = gBitmapMap:[bitmap];

         // check if the bitmap exists
         if (bitmap_path_search(bitmap) != '') {
            // replace the line
            replace_line(leading :+ "p_picture='" :+ bitmap :+ "';");
            count++;
         }

      }

      // next please
      down();_begin_line();
   }

   return count;
}

static void updateOldForms()
{
   // start from the top
   top();
   _begin_line();

   int status=0;
   for (;;) {

      // look for _form
      status = search("_form", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str trailing;
      _str form_name;
      parse line with leading "_form " form_name trailing;

      form_name = strip(form_name);
      if (gFormMap._indexin(form_name)) {

         // get the new bitmap name
         form_name = gFormMap:[form_name];

         // replace the line
         replace_line(leading :+ "_form " :+ form_name :+ " " :+ trailing);
      }

      // next please
      down();_begin_line();
   }
}

static void updateToolbarForms()
{
   int toolbarUpdateMap:[];
   int i,n=def_toolbartab._length();
   for (i = 0; i < n; ++i) {
      if (def_toolbartab[i].FormName=="_tbcontext_form" ||
          def_toolbartab[i].FormName=="_tbdebug_sessions_form" ||
          ((def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) &&
           (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) == 0 &&
           (def_toolbartab[i].tbflags & TBFLAG_NO_CAPTION) == 0)) {
         toolbarUpdateMap:[def_toolbartab[i].FormName] = i;
      }
   }

   // start from the top
   top();
   _begin_line();

   int status=0;
   for (;;) {
      // look for _form
      status = search("_form", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str trailing;
      _str form_name;
      parse line with leading '_form ' form_name trailing;

      form_name = strip(form_name);
      if (toolbarUpdateMap._indexin(form_name)) {
         down();
         for (;;) {
            get_line(line);
            if (verify(line,'{}','M')) break;

            _str name, value;
            parse line with name "=" value ";";
            name = strip(name); value = strip(value);
            if (name :== 'p_eventtab2') {
               if (value :== '_toolbar_etab2') {
                  parse line with leading 'p_eventtab2' '=' '_toolbar_etab2;' trailing;
                  replace_line(leading:+'p_eventtab2=_qtoolbar_etab2;':+trailing);
               }
               break;
            }
            if (down()) break;
         }
      }

      // next please
      down();_begin_line();
   }
}

static int updateUserObjects(_str path)
{
   // open a temporary view
   int orig_wid, temp_wid;
   int status = _open_temp_view(path, temp_wid, orig_wid);
   if (status) {
      return status;
   }

   // save the old search options
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   int num_icons_changed = updatePictureProperties();
   if (num_icons_changed > 10) updateOldForms();
   updateToolbarForms();

   // save the file
   if (p_modify) {
      status=save('',SV_OVERWRITE);
   }

   // cleanup
   restore_search(s1,s2,s3,s4,s5);
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   // that's all folks
   return 0;
}

static void testIcons()
{
   int numMissing=0;
   _str missingBitmaps='';
   boolean errors=false;
   typeless i;
   for (i._makeempty();;) {
      gBitmapMap._nextel(i);
      if (i._isempty()) break;
      if (bitmap_path_search(gBitmapMap:[i]) == '') {
         missingBitmaps = missingBitmaps :+ gBitmapMap:[i] :+ "\n";
         ++numMissing;
      }
   }
   if (missingBitmaps=='') {
      _message_box("No missing bitmaps");
   } else {
      _message_box(numMissing :+ " missing bitmaps:\n\n":+missingBitmaps);
   }
}

defmain()
{
   // test mode?
   if (arg(1) == 'testIcons') {
      testIcons();
      return 0;
   }

   // expecting a single file name as an argument
   if (arg(1) == '') {
      message("usage: updateobjs <filename.e>");
      return 1;
   }

   // update the icons
   updateUserObjects(arg(1));

   // that's all folks
   return 0;
}
