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

extern int _hi_add_files(_str,int,int,int);
extern int _hi_insert_helpfile_list(_str);
extern int _hi_new_idx_file(_str);
extern int _hi_hit_list(_str pszHelpPrefix, _str pszFilename, int InitTable, int LBWid, int CompleteMatch);
extern int _winhelpfind(_str pszFilename,_str pszKeyword,int HelpType,int ListBoxFormat);
extern _str _winhelptitle(_str pszFilename);
extern int _hthelp_open(_str filename);
extern int _hthelp_command(_str,_str options="");
extern _str _hthelp_info(_str s);
extern int _hthelp_goto(_str s1, _str s2="");
extern int _hthelp_goto_topic(_str topic,_str offset);
extern int _hthelp_click(int x, int y, _str options);
extern int _hthelp_list_keywords(int list_wid);
extern int _hthelp_list_topics(int list_wid, _str text);
extern int _hthelp_FindInit();
extern int _hthelp_FindSelectWords(int list_wid, int cursorWordIndex);
extern int _hthelp_FindInsertTopics(int list_wid);
extern int _hthelp_FindGetCursorWordIndex(_str lastSearch,var offset);
extern int _hthelp_FindInsertWords(int list_wid, int cursorWordIndex);
extern int _hthelp_Find(_str lastSearch);
extern int _hthelp_FindShowSelected();
extern int _hthelp_FindSetOptions(_str p1, _str p2);
extern int _hthelp_close();
extern int _hthelp_print(_str,typeless &);
extern int HTMLHelpAvailable();

