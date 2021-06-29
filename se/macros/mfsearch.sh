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
#pragma option(metadata,"mfsearch.e")

// time comparision ops
enum MFFILE_FILE_STAT_TIME_OP {
   MFFILE_STAT_TIME_NONE = 0,
   MFFILE_STAT_TIME_DATE,
   MFFILE_STAT_TIME_BEFORE,
   MFFILE_STAT_TIME_AFTER,
   MFFILE_STAT_TIME_RANGE,
   MFFILE_STAT_TIME_NOT_RANGE,
};

struct MFFIND_FILE_STATS {
   long max_file_size;

   int  modified_file_op;
   long modified_file_time1;
   long modified_file_time2;
};

extern void _mffind_file_stats_init(_str file_stats, MFFIND_FILE_STATS& info);
extern bool _mffind_file_stats_test(_str filename, MFFIND_FILE_STATS& info);
extern long _mffind_file_stats_get_file_size(_str file_stats);
extern int  _mffind_file_stats_get_file_modified(_str file_stats, _str& ft1, _str& ft2);


