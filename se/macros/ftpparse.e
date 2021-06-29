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
#include "ftp.sh"
#import "makefile.e"
#import "ftp.e"
#import "stdprocs.e"
#endregion

int _ftpMonthToNumber(_str month)
{
   month_number := 0;
   month=lowcase(strip(month));
   switch( month ) {
   case 'jan':
   case 'january':
      month_number=1;
      break;
   case 'feb':
   case 'february':
      month_number=2;
      break;
   case 'mar':
   case 'march':
      month_number=3;
      break;
   case 'apr':
   case 'april':
      month_number=4;
      break;
   case 'may':
      month_number=5;
      break;
   case 'jun':
   case 'june':
      month_number=6;
      break;
   case 'jul':
   case 'july':
      month_number=7;
      break;
   case 'aug':
   case 'august':
      month_number=8;
      break;
   case 'sep':
   case 'september':
      month_number=9;
      break;
   case 'oct':
   case 'october':
      month_number=10;
      break;
   case 'nov':
   case 'november':
      month_number=11;
      break;
   case 'dec':
   case 'december':
      month_number=12;
      break;
   }

   return(month_number);
}

/**
 * Return a string representing a date+time suitable for 
 * sorting. 
 * 
 * @param year 
 * @param month 
 * @param day 
 * @param time 
 * 
 * @return _str 
 */
_str _ftpMakeMtime(_str year, _str month, _str day, _str time)
{
   if ( !isinteger(month) ) {
      month = _ftpMonthToNumber(month);
   }
   if ( length(month) == 1 ) {
      month = '0'month;
   }
   if ( length(day) == 1 ) {
      day = '0'day;
   }
   res :=  year:+month:+day:+time;
   return res;
}

// Most Windows NT FTP servers return UNIX style directory listings,
// but some Microsoft FTP servers, namely "Microsoft FTP Service (Version 4.0)",
// return directory listings that look like this:
//
// 09-02-98  01:37PM       <DIR>          backup-19980901
// 10-02-98  10:33AM       <DIR>          code
// 08-05-98  10:04AM       <DIR>          SAVE
// 09-02-98  01:31PM       <DIR>          TEMPLATES
// 10-13-98  02:50PM       <DIR>          WEB
// 10-02-98  04:44PM       12444          rodney.txt
static int _ftpParseDir_WINNT(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;
   bool unix_style;

   unix_style=true;   // true=Windows NT host returns a UNIX style listing

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   word := "";
   parse line with word .;
   if( substr(word,1,length("total"))=="total" ) {
      // Get rid of the "total n" line
      _delete_line();
   }
   attribs := "";
   owner := "";
   group := "";
   date := "";
   month := "";
   day := "";
   year := "";
   yeartime := "";
   filename := "";
   typeless time="";
   mtime := "";
   typeless size = 0;
   _str refs=0;
   status := 0;

   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      year="";
      time="";
      if( pos(':i\-:i\-:i #:i\::i(AM|PM) ',line,1,'ir') ) {
         // A Windows NT FTP server that has decided to do things differently
         unix_style=false;
         attribs=substr("",1,length("drwxrwxrwx"),'-');
         refs=0;
         owner="";
         group="";
         parse line with date time size filename;
         if( size=='<DIR>' ) {
            // Directory
            size=0;
            attribs='d':+substr(attribs,2);
         }
         _str mm,dd,yy;
         parse date with mm '-' dd '-' yy;
         month=strip(mm,'L','0');
         switch( (int)month ) {
         case 1:
            month='Jan';
            break;
         case 2:
            month='Feb';
            break;
         case 3:
            month='Mar';
            break;
         case 4:
            month='Apr';
            break;
         case 5:
            month='May';
            break;
         case 6:
            month='Jun';
            break;
         case 7:
            month='Jul';
            break;
         case 8:
            month='Aug';
            break;
         case 9:
            month='Sep';
            break;
         case 10:
            month='Oct';
            break;
         case 11:
            month='Nov';
            break;
         case 12:
            month='Dec';
            break;
         }
         day=strip(dd,'L','0');
         year=yy;
         time=lowcase(time);
         ampm := "";
         if( pos('am|pm',substr(time,1,length(time)-1),1,'r') ) {
            ampm=substr(time,length(time-1));
            time=substr(time,1,length(time-1));
         }
         _str hour, minute;
         parse time with hour ':' minute;
         if( ampm=='pm' ) {
            hour= (int)hour+12;
         }
         if( length(hour)==1 ) hour='0':+hour;
         time=hour':'minute;
         mtime = yy:+mm:+dd:+time;
      } else {
         #if 1
         rest := "";
         yeartime="";
         parse line with attribs refs owner rest;
         parse rest with group size month day yeartime filename;
         // We are testing for the following case of no group field:
         //
         // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin
         //
         // OR
         //
         // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin -> .xsession
         if( !isinteger(size) ) {
            // This usually means that there was no group id. QNX and some
            // UNIX ftp servers do not give a group id.
            group="";
            parse rest with size month day yeartime filename;
         }
         #else
         parse line with attribs refs owner group size month day yeartime filename;
         #endif
      }

      if( attribs=="" ) {
         // This should never happen
         attribs=substr("",1,length("drwxrwxrwx"),'-');
      }
      file.attribs=attribs;
      file.type=0;
      if( lowcase(substr(file.attribs,1,1))=='d' ) {
         // We have a directory
         file.type |= FTPFILETYPE_DIR;
      }
      if( lowcase(substr(file.attribs,1,1))=='l' ) {
         // We have a link
         file.type |= (FTPFILETYPE_DIR|FTPFILETYPE_LINK);
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      _str fcase= (unix_style)?('e'):('i');
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename,fcase) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( year=="" || time=="" ) {
         if( yeartime=="" ) {
            // This should never happen
            yeartime="00:00";
         }
         if( pos(':',yeartime) ) {
            // There is a time instead of a year - use the current year???
            cur_month := cur_year := "";
            parse _date('U') with cur_month '/' . '/' cur_year;
            time=yeartime;
            if( (int)cur_month<_ftpMonthToNumber(month) ) {
               year= (int)cur_year - 1;
            } else {
               year=cur_year;
            }
         } else {
            // There is year instead of a time
            year=yeartime;
            time="00:00";
         }
      }
      if( !isinteger(year) ) {
         // This should never happen
         year=0;
      }
      file.year= (int)year;
      file.time=time;
      if ( mtime == '' ) {
         mtime = _ftpMakeMtime(year, month, day, time);
      }
      file.mtime = mtime;

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

static int _ftpParseDir_HUMMINGBIRD(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   return( _ftpParseDir_WINNT(fcp_p,remote_dir,filter) );
}

// OS/2. This sample listing was taken from an OS/2 Warp host running
// IBM TCP/IP v4.1.
//
// A directory listing looks like this:
//
//                0           DIR   11-11-98   14:52  BABYLON
//                0           DIR   11-12-98   11:41  CITIDNS
//                0           DIR   11-12-98   11:41  CITIWEB
//          1943759      A          10-08-98   15:53  dinodisk.zip
//          3082704      A          11-23-98   23:54  dinosaur.zip
//          1941886      A          09-28-98   18:36  dinostickers.zip
//          2087479      A          09-23-98   23:34  nowsell.zip
static int _ftpParseDir_OS2(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   word := "";
   parse line with word .;
   if( substr(word,1,length("total"))=="total" ) {
      // Get rid of the "total n" line
      _delete_line();
   }

   typeless status=0;
   typeless refs=0;
   typeless size=0;
   owner := "";
   group := "";
   attribs := "";
   date := "";
   time := "";
   month := "";
   day := "";
   year := "";
   mtime := "";
   filename := "";

   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      refs=0;
      owner="";
      group="";
      //parse line with size attribs date time filename;
      typeless p1,p2,p3,p4,p5;
      parse line with p1 p2 p3 p4 p5;
      if( pos('^:i\-:i\-:i$',p2,1,'er') ) {
         // Normally, the second field is attribs. In this case, however,
         // there are no attribs, so it is the date.
         size=p1;
         attribs="";
         date=p2;
         time=p3;
         filename=p4;
      } else {
         size=p1;
         attribs=p2;
         date=p3;
         time=p4;
         filename=p5;
      }
      _str mm, dd, yy;
      parse date with mm '-' dd '-' yy;
      month=strip(mm,'L','0');
      if( !isinteger(month) ) {
         month='???';
      } else {
         switch( (int)month ) {
         case 1:
            month='Jan';
            break;
         case 2:
            month='Feb';
            break;
         case 3:
            month='Mar';
            break;
         case 4:
            month='Apr';
            break;
         case 5:
            month='May';
            break;
         case 6:
            month='Jun';
            break;
         case 7:
            month='Jul';
            break;
         case 8:
            month='Aug';
            break;
         case 9:
            month='Sep';
            break;
         case 10:
            month='Oct';
            break;
         case 11:
            month='Nov';
            break;
         case 12:
            month='Dec';
            break;
         }
      }
      day=strip(dd,'L','0');
      year=yy;
      // Time will get appended later
      mtime = yy:+mm:+dd;

      file.attribs=attribs;
      file.type=0;
      if( attribs=='DIR' ) {
         // We have a directory
         file.type |= FTPFILETYPE_DIR;
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;
      if( !isinteger(year) ) {
         year=0;
      }
      file.year= (int)year;

      if( time=="" ) {
         time="0:00";
      }
      mtime :+= time;
      file.time=time;
      file.mtime = mtime;

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// VOS runs on Stratus machines.
//
// A directory listing looks like this:
//
//
// Files: 2  Blocks: 4
//
//  w      3  seq       97-11-25 13:44:18  abbreviations
//  w      1  seq       97-10-15 12:52:15  start_up.cm
//
//
// Dirs: 15
//
//  m      1  98-09-23 11:23:30  abars
//  m      1  98-08-19 09:16:58  cv
//  m      1  97-12-05 16:42:47  fred_derf
//  m      1  97-12-05 16:42:47  guest2
//  m      1  98-06-22 15:01:15  jon_schmidt
//  m      1  97-12-05 16:42:46  Louisiana_Lottery
//  m      1  97-12-13 15:47:37  ron_stering
//  m      1  97-12-05 16:42:46  spectra
//  m      1  97-12-05 16:42:46  temp
//  m      1  98-09-23 16:13:03  test
//  m      1  98-08-31 11:41:56  testing_qt
//  m      2  98-04-06 15:58:08  tim_mcelroy
//  m      1  98-05-29 16:20:26  travis_burnette
//  m      1  98-10-15 09:18:37  vslick
//  m      1  98-09-28 18:27:25  wsftp
//
//
// Links: 0
//
static int _ftpParseDir_VOS(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   typeless status=0;
   month := "";
   day := "";
   year := "";
   date := "";
   time := "";
   filename := "";
   attribs := "";
   typeless blocks="";
   orgtype := "";

   // Files
   top();up();
   status=search('^Files\: :i','@ir');
   if( !status ) {
      // Found some files
      line := "";
      get_line(line);
      typeless noffiles="";
      parse line with 'Files:' noffiles .;
      noffiles= (int)strip(noffiles);
      // Start counting lines at the first non-blank line
      line="";
      for(;;) {
         if( down() ) break;
         get_line(line);
         if( line!="" ) break;
      }
      up();
      if( line!="" ) {
         int i;
         for( i=1;i<=noffiles;++i ) {
            if( down() ) {
               // Unexpected end of listing
               status=1;
               break;
            }
            get_line(line);
            if( line=="" ) {
               // Unexpected end of listing
               status=1;
               break;
            }

            file.owner="";
            file.group="";
            file.refs=0;
            parse line with attribs blocks orgtype date time filename;
            if( filename=="" ) {
               // Skip it. This can happen with a filename that
               // is all spaces.
               continue;
            }
            file.type=0;
            if( filename=="." || filename==".." ) continue;
            if( !(file.type&FTPFILETYPE_DIR) &&
                filter!=FTP_ALLFILES_RE ) {
               match := false;
               _str list=filter;
               while( list!="" ) {
                  _str filespec=parse_file(list);
                  filespec=strip(filespec,'B','"');
                  if( filespec=="" ) continue;
                  if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
                     // Found a match
                     match=true;
                     break;
                  }
               }
               if( !match ) continue;
            }
            file.filename=filename;
            file.attribs=attribs;
            file.size=blocks;
            _str yy, mm, dd;
            parse date with yy '-' mm '-' dd;
            month=strip(mm,'L','0');
            day=strip(dd,'L','0');
            if( !isinteger(day) ) {
               // This should never happen
               day=0;
            }
            year=yy;
            if( !isinteger(year) ) {
               // This should never happen
               year=0;
            }
            switch( (int)month ) {
            case 1:
               month='Jan';
               break;
            case 2:
               month='Feb';
               break;
            case 3:
               month='Mar';
               break;
            case 4:
               month='Apr';
               break;
            case 5:
               month='May';
               break;
            case 6:
               month='Jun';
               break;
            case 7:
               month='Jul';
               break;
            case 8:
               month='Aug';
               break;
            case 9:
               month='Sep';
               break;
            case 10:
               month='Oct';
               break;
            case 11:
               month='Nov';
               break;
            case 12:
               month='Dec';
               break;
            }
            file.month=month;
            file.day= (int)day;
            file.year= (int)year;
            file.time=time;
            file.mtime = yy:+mm:+dd:+time;

            // Add it to the array
            fcp_p->remoteDir.files[fcp_p->remoteDir.files._length()]=file;
         }
      }
   }
   if( status ) return(status);

   // Dirs
   top();up();
   status=search('^Dirs\: :i','@ir');
   if( !status ) {
      // Found some directories
      line := "";
      get_line(line);
      typeless nofdirs="";
      parse line with 'Dirs:' nofdirs .;
      nofdirs= (int)strip(nofdirs);
      // Start counting lines at the first non-blank line
      line="";
      for(;;) {
         if( down() ) break;
         get_line(line);
         if( line!="" ) break;
      }
      up();
      if( line!="" ) {
         int i;
         for( i=1;i<=nofdirs;++i ) {
            if( down() ) {
               // Unexpected end of listing
               status=1;
               break;
            }
            get_line(line);
            if( line=="" ) {
               // Unexpected end of listing
               status=1;
               break;
            }

            file.owner="";
            file.group="";
            file.refs=0;
            parse line with attribs blocks date time filename;
            if( filename=="" ) {
               // Skip it. This can happen with a filename that
               // is all spaces.
               continue;
            }
            file.type=FTPFILETYPE_DIR;
            if( filename=="." || filename==".." ) continue;
            if( !(file.type&FTPFILETYPE_DIR) &&
                filter!=FTP_ALLFILES_RE ) {
               match := false;
               _str list=filter;
               while( list!="" ) {
                  _str filespec=parse_file(list);
                  filespec=strip(filespec,'B','"');
                  if( filespec=="" ) continue;
                  if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
                     // Found a match
                     match=true;
                     break;
                  }
               }
               if( !match ) continue;
            }
            file.filename=filename;
            file.attribs=attribs;
            file.size=blocks;
            _str yy, mm, dd;
            parse date with yy '-' mm '-' dd;
            month=strip(mm,'L','0');
            day=strip(dd,'L','0');
            if( !isinteger(day) ) {
               // This should never happen
               day=0;
            }
            year=yy;
            if( !isinteger(year) ) {
               // This should never happen
               year=0;
            }
            switch( (int)month ) {
            case 1:
               month='Jan';
               break;
            case 2:
               month='Feb';
               break;
            case 3:
               month='Mar';
               break;
            case 4:
               month='Apr';
               break;
            case 5:
               month='May';
               break;
            case 6:
               month='Jun';
               break;
            case 7:
               month='Jul';
               break;
            case 8:
               month='Aug';
               break;
            case 9:
               month='Sep';
               break;
            case 10:
               month='Oct';
               break;
            case 11:
               month='Nov';
               break;
            case 12:
               month='Dec';
               break;
            }
            file.month=month;
            file.day= (int)day;
            file.year= (int)year;
            file.time=time;
            file.mtime = yy:+mm:+dd:+time;

            // Add it to the array
            fcp_p->remoteDir.files[fcp_p->remoteDir.files._length()]=file;
         }
      }
   }
   if( status ) return(status);

   // Links
   top();up();
   status=search('^Links\: :i','@ir');
   if( !status ) {
      // Found some links
      line := "";
      get_line(line);
      typeless noflinks="";
      parse line with 'Links:' noflinks .;
      noflinks= (int)strip(noflinks);
      // Start counting lines at the first non-blank line
      line="";
      for(;;) {
         if( down() ) break;
         get_line(line);
         if( line!="" ) break;
      }
      up();
      if( line!="" ) {
         int i;
         for( i=1;i<=noflinks;++i ) {
            if( down() ) {
               // Unexpected end of listing
               status=1;
               break;
            }
            get_line(line);
            if( line=="" ) {
               // Unexpected end of listing
               status=1;
               break;
            }

            file.owner="";
            file.group="";
            file.refs=0;
            file.attribs="";
            file.size=0;
            parse line with date time filename;
            if( filename=="" ) {
               // Skip it. This can happen with a filename that
               // is all spaces.
               continue;
            }
            file.type=FTPFILETYPE_DIR|FTPFILETYPE_LINK;
            if( filename=="." || filename==".." ) continue;
            if( !(file.type&FTPFILETYPE_DIR) &&
                filter!=FTP_ALLFILES_RE ) {
               match := false;
               _str list=filter;
               while( list!="" ) {
                  _str filespec=parse_file(list);
                  filespec=strip(filespec,'B','"');
                  if( filespec=="" ) continue;
                  if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
                     // Found a match
                     match=true;
                     break;
                  }
               }
               if( !match ) continue;
            }
            file.filename=filename;
            _str yy, mm, dd;
            parse date with yy '-' mm '-' dd;
            month=strip(mm,'L','0');
            day=strip(dd,'L','0');
            if( !isinteger(day) ) {
               // This should never happen
               day=0;
            }
            year=yy;
            if( !isinteger(year) ) {
               // This should never happen
               year=0;
            }
            switch( (int)month ) {
            case 1:
               month='Jan';
               break;
            case 2:
               month='Feb';
               break;
            case 3:
               month='Mar';
               break;
            case 4:
               month='Apr';
               break;
            case 5:
               month='May';
               break;
            case 6:
               month='Jun';
               break;
            case 7:
               month='Jul';
               break;
            case 8:
               month='Aug';
               break;
            case 9:
               month='Sep';
               break;
            case 10:
               month='Oct';
               break;
            case 11:
               month='Nov';
               break;
            case 12:
               month='Dec';
               break;
            }
            file.month=month;
            file.day= (int)day;
            file.year= (int)year;
            file.time=time;
            file.mtime = yy:+mm:+dd:+time;

            // Add it to the array
            remote_dir.files[remote_dir.files._length()] = file;
         }
      }
   }

   return(status);
}

// VMS runs on VAX machines.
//
// A directory listing looks like this:
//
// SYS$USER:[ANONYMOUS]
//
// ARA0003.GIR;1               1  20-OCT-1998 03:45 [OVERHEAD,ANONYMOUS] (RWED,RWED,RE,RE)
// ARA0007.DAT;1               1  20-OCT-1998 03:44 [OVERHEAD,ANONYMOUS] (RWED,RWED,RE,RE)
// ARI0001.GIR;1               1  20-OCT-1998 03:45 [OVERHEAD,ANONYMOUS] (RWED,RWED,RE,RE)
// CUTFTP32.EXE;1             65  27-OCT-1996 14:35 [OVERHEAD,ANONYMOUS] (RWED,RE,RE,RE)
// DCLCOMPLETE.ZIP;4          81  11-APR-1997 10:32 [RAY] (RWED,RWED,R,RE)
// DUMPER.CLD;19               8  15-JAN-1988 16:27 [OVERHEAD,ANONYMOUS] (RWED,RE,E,RE)
// DUMPER.EXE;2               96  17-JUN-1989 10:34 [OVERHEAD,ANONYMOUS] (RWED,RE,E,RE)
// DUMPER.HLP;10              17   6-FEB-1988 20:03 [OVERHEAD,ANONYMOUS] (RWED,RE,E,RE)
// FILESERV_HELP.TXT;1
//                             7   9-OCT-1996 08:39 [ARCHIVES] (RWED,RWED,,RE)
// GRI.DIR;1                   1   1-MAR-1994 12:44 [SMITHG] (RWE,RWE,RE,RE)
// INFO-VAX.DIR;1             17  27-JAN-1990 15:13 [SYSTEM] (RWE,RE,RE,RE)
// IPCD.DIR;1                  1   9-MAR-1994 23:30 [OVERHEAD,ANONYMOUS] (RWE,RE,RE,RE)
// LOGIN.COM;2                 1  18-FEB-1994 14:38 [OVERHEAD,ANONYMOUS] (RWED,RE,,)
//
//
// Total of 297 blocks in 13 files.
static int _ftpParseDir_VMS(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   typeless status=0;
   filename := "";
   name := "";
   ext := "";
   ver := "";
   day := "";
   month := "";
   year := "";
   typeless size="";
   date := "";
   time := "";
   owner := "";
   group := "";
   attribs := "";
   rest := "";

   // First non-blank line will be the current working directory
   line := "";
   top();up();
   for( ;; ) {
      if( down() ) break;
      get_line(line);
      if( line!="" ) break;
   }
   // Move off the cwd line and look for the start of the listing
   found_it := false;
   for( ;; ) {
      if( down() ) break;
      get_line(line);
      if( line!="" ) {
         found_it=true;
         break;
      }
   }
   if( found_it ) {
      for(;;) {
         get_line(line);
         if( line=="" ) break;   // Done
         file.attribs="";
         file.day=0;
         file.group="";
         file.month="";
         file.refs=0;
         file.size=0;
         file.time="";
         file.year=0;
         file.type=0;
         parse line with filename rest;
         parse filename with name '.' ext ';' ver;
         if( upcase(ext)=='DIR' ) {
            filename=name;
            file.type=FTPFILETYPE_DIR;
         }

         if( filename=="." || filename==".." ) {
            if( down() ) break;
            continue;
         }
         if( !(file.type&FTPFILETYPE_DIR) &&
             filter!=FTP_ALLFILES_RE ) {
            match := false;
            _str list=filter;
            while( list!="" ) {
               _str filespec=parse_file(list);
               filespec=strip(filespec,'B','"');
               if( filespec=="" ) continue;
               if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
                  // Found a match
                  match=true;
                  break;
               }
            }
            if( !match ) {
               if( down() ) break;
               continue;
            }
         }

         file.filename=filename;
         if( rest=="" ) {
            // The rest of the info for this file is offset on the next line
            if( down() ) {
               // Unexpected end of listing
               status=1;
               break;
            }
            get_line(line);
            if( line!="" && substr(line,1,1)=="" ) {
               rest=strip(line);
            }
         }
         parse rest with size date time owner attribs .;
         parse date with day '-' month '-' year;
         if( !isinteger(size) ) {
            // Sometimes VMS expresses sizes like this: 5/6.
            // Do not know what it means, but we decide to
            // use the first number.
            parse size with size '/' .;
         }
         if( isinteger(size) ) {
            file.size = size;
         }
         if( isinteger(day) && month!="" && isinteger(year) ) {
            file.day= (int)day;
            file.month=month;
            file.year= (int)year;
         }
         file.time=time;
         file.mtime = _ftpMakeMtime(year, month, day, time);
         file.owner=owner;
         file.attribs=attribs;

         // Add it to the array
         remote_dir.files[remote_dir.files._length()] = file;

         if( down() ) break;
      }
   }

   return(status);
}

// VM and VM/ESA runs on IBM S/390 machines.
//
// Some info on VM/ESA accessing CMS minidisks provided by Robley Hall:
//
// CMS is a simulated 3090 disk.
//
// The columnar output of the raw file listing is as follows:
// name type(ext) rectype reclen nofrecs nofblocks date time vol_serno
// Notes:
//  o type:      Like an extension
//  o rectype:   v=variable, f=fixed
//  o nofblocks: A block size is typically 4096
//  o vol_serno: Volume serial number.
//  o There are no folders in a file listing. There are only files on a
//    minidisk.
//
// Getting and putting files on the same minidisk:
// get $$keys$$.savecms
// put $$keys$$.savecms
//
// Getting and putting files from one mindisk to another:
// ???
//
// Changing to a particular minidisk example:
//
//   CWD robley.191
//
// where robley.191 is a minidisk.
//
// Notes:
//  o '191' and '190' are typical minidisks on all VM/ESA hosts.
//
// A directory listing looks like this:
//
// $$KEYS$$ SAVECMS  V         59         24          1 10/21/98 12:10:56 ROB191
// $$NT$$   USERDATA F         34          1          1 11/04/98 17:41:03 ROB191
// A        OUT      V         74        292          5 10/16/98 16:31:10 ROB191
// ALL      NOTEBOOK V         80        434          4 11/03/98 16:33:14 ROB191
// CAFFCOPY TNDX0    F        148          5          1 11/04/98 17:28:18 ROB191
// CONFEREN GDLINES  V         74        863         10 12/04/91 10:15:36 ROB191
// CTLCAFR  $STAIRS  V         73         40          1  7/24/98  7:35:29 ROB191
// DITTO    OUTPUT   F        132        104          4 11/04/98 17:48:21 ROB191
// DIT110   DITPROF  F         80          2          1 11/04/98 17:43:10 ROB191
// EXEC     PACKLIB  V      15532         18          7 11/04/98 14:55:33 ROB191
//
// or this:
//
// $$KEYS$$ SAVECMS  V         59         24          1 1998-10-21 12:10:56 ROB191
// $$NT$$   USERDATA F         34          1          1 1998-11-04 17:41:03 ROB191
// A        OUT      V         74        292          5 1998-10-16 16:31:10 ROB191
// ALL      NOTEBOOK V         80        434          4 1998-11-03 16:33:14 ROB191
// CAFFCOPY TNDX0    F        148          5          1 1998-11-04 17:28:18 ROB191
// CONFEREN GDLINES  V         74        863         10 1991-12-04 10:15:36 ROB191
// CTLCAFR  $STAIRS  V         73         40          1 1998-07-24  7:35:29 ROB191
// DITTO    OUTPUT   F        132        104          4 1998-11-04 17:48:21 ROB191
// DIT110   DITPROF  F         80          2          1 1998-11-04 17:43:10 ROB191
// EXEC     PACKLIB  V      15532         18          7 1998-11-04 14:55:33 ROB191
//
//
// NOT SUPPORTED
// =============
// SFS file system looks like this:
//
// EDISK             DIR        -          -          -  1/13/95 14:00:39 -
// FIRST    PART     V         91         31          1  9/04/97 15:11:43 -
// INDEX    HTML     V         91         45          1  1/15/02  0:05:22 -
// INDEX    OHTML    V         91         45          1  1/14/02  0:05:22 -
// LAST1    PART     V         71          8          1  2/10/95 11:27:59 -
// LAST2    PART     V         70          5          1  2/10/95 11:28:14 -
// LSVOWNER          DIR        -          -          -  1/13/95 14:00:43 -
// UBVM     CC       V          1          0          0 11/29/99 11:06:50 -
// VM_UTIL           DIR        -          -          -  1/13/95 11:52:42 -
// WEBSHARE          DIR        -          -          -  1/13/95 14:00:52 -
// WEBSHARE FILELIST V         69         30          1  1/13/95 10:41:28 -
// 242-1    DJD      V          1          0          0  3/23/01  8:14:41 -
// 342-1    DJD      V          1          0          0  8/31/00  6:25:46 -
// 355-1    DJD      V          1          0          0  9/01/00  5:43:34 -
static int _ftpParseDir_VM(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   filename := "";
   type := "";
   rectype := "";
   reclen := "";
   nofrecs := "";
   size := "";
   date := "";
   time := "";
   volserial := "";
   attribs := "";
   owner := "";
   group := "";
   _str refs=0;
   year := "";
   month := "";
   day := "";
   line := "";

   // Now massage the directory buffer into an ftp directory struct
   typeless status=0;
   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      #if 1
      file.type=0;
      parse line with filename type rectype reclen nofrecs size date time volserial .;
      if( time=='-' && upcase(type)=='DIR' ) {
         // This is an SFS directory
         type='';
         rectype='';
         parse line with filename . reclen nofrecs size date time volserial .;
         file.type=FTPFILETYPE_DIR;
      }
      attribs=rectype;
      refs=0;
      owner=volserial;
      group="";
      #else
      file.type=0;
      parse line with filename type rectype reclen nofrecs size date time volserial .;
      attribs=rectype;
      refs=0;
      owner=volserial;
      group="";
      #endif

      file.attribs=attribs;

      if( filename=="" ) {
         // Skip it
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( type!="" ) {
         // Make a name.ext filename out of it
         filename :+= ".":+type;
      }
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( pos('-',date) ) {
         // Y2K 4-digit year, hyphenated date
         parse date with year '-' month '-' day;
      } else {
         // 2-digit year, slashed date
         parse date with month '/' day '/' year;
      }
      if( month=="" ) {
         // This should never happen
         month="???";
      } else {
         switch( (int)month ) {
         case 1:
            month='Jan';
            break;
         case 2:
            month='Feb';
            break;
         case 3:
            month='Mar';
            break;
         case 4:
            month='Apr';
            break;
         case 5:
            month='May';
            break;
         case 6:
            month='Jun';
            break;
         case 7:
            month='Jul';
            break;
         case 8:
            month='Aug';
            break;
         case 9:
            month='Sep';
            break;
         case 10:
            month='Oct';
            break;
         case 11:
            month='Nov';
            break;
         case 12:
            month='Dec';
            break;
         }
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month
      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;
      if( !isinteger(year) ) {
         year="0000";
      }
      file.year= (int)year;

      file.time=time;

      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// MVS runs on IBM S/390 machines.
//
// A file listing looks like this:
//
//  Name     VV.MM   Created       Changed      Size  Init   Mod   Id
// ALLJ2     01.00 1998/08/07 1998/08/07 11:24     2     2     0 TODD
// ALLJ3     01.00 1998/08/07 1998/08/07 11:25     8     8     0 TODD
// APPCPMOM  01.00 1996/06/26 1996/06/26 10:15    15    15     0 SVTSCU
// ASCHPMOM  01.00 1996/06/26 1996/06/26 10:16    12    12     0 SVTSCU
// BPXPRMAA  01.11 1997/07/15 1998/10/16 00:13   212   127     0 TODD
// BPXPRMOM  01.15 1997/04/27 1998/09/15 15:50   175   102     0 TODD
// BPXPRM00  01.30 1996/08/09 1996/11/21 09:31    82    77     0 HUANGY
// BPZPRMAP  01.00 1998/08/07 1998/08/07 11:35     8     8     0 TODD
// CLOCKSV   01.04 1996/06/21 1998/10/25 12:09     6     5     0 RALEY
// CLRMAN    01.00 1990/01/29 1990/01/29 10:48     1     1     0 RALEY
// COFVLFSV  01.06 1991/06/09 1997/04/28 14:14    24    31    23 RALEY
// COMMNDJ2  01.00 1998/08/07 1998/08/07 11:26     1     1     0 TODD
// COMMNDJ3  01.00 1998/08/07 1998/08/07 11:26     1     1     0 TODD
// COMMNDSV  01.00 1997/04/27 1997/04/27 12:33     3     3     0 RALEY
// COMMND00  01.02 1997/04/27 1998/03/02 19:57    12    12     0 RALEY
// CONSOL00  01.01 1996/12/02 1997/03/11 18:56    52    50     0 RALEY
// COUPLESV  01.02 1996/06/21 1996/10/21 23:13    34    34     2 RALEY
// COUPLESX  01.00 1996/10/10 1996/10/10 18:33     1     1     0 RALEY
//
//
// A dataset listing looks like this:
//
// Volume Unit    Referred Ext Used Recfm Lrecl BlkSz Dsorg Dsname
// SCPMV5 3380   1999/03/01  1   45  FB      80 23440  PO  CLARK
// SCPMV5 3380   1999/03/02  2    6  FB      80  3120  PO  ISPF.ISPPROF
// OS39R6 3390   1998/11/22  2  158  FB      80  3120  PO  POSTINST
// OS39R6 3390   1998/10/29  1   69  VBM   8205 27998  PO  POSTINST.DOC
// SCPMV5 3380   1999/03/02  1    8  VBA    125   129  PS  SPFLOG1.LIST
static int _ftpParseDir_MVS(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   created := "";
   parse line with . . created .;
   datasets := false;
   if( !pos('^:i/:i/:i$',created,1,'er') ) {
      volume_or_name := "";
      parse line with volume_or_name .;
      if( lowcase(volume_or_name)=="volume" ) {
         // This is a listing of datasets
         datasets=true;
         fcp_p->remoteDir.flags |= FTPDIRTYPE_MVS_VOLUME;
      }
      // Get rid of the headings line
      _delete_line();
   }

   typeless status=0;
   owner := "";
   group := "";
   time := "";
   volume := "";
   unit := "";
   date := "";
   ext := "";
   used := "";
   recfm := "";
   lrecl := "";
   dsorg := "";
   filename := "";
   month := "";
   day := "";
   year := "";
   attribs := "";
   vv := "";
   mm := "";
   init := "";
   mod := "";
   typeless refs=0;
   typeless size=0;

   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      if( datasets ) {
         owner="";
         time="";
         size=0;
         parse line with volume unit date ext used recfm lrecl . dsorg filename;
         if( filename=="" ) {
            if( volume=="Pseudo" && unit=="Directory" ) {
               // We got a line like:
               //
               // Pseudo Directory                                              DIRNAME
               dsorg="Directory";
               // No date provided, so use today's date and put it in
               // MVS form.
               date=_date('U');
               parse date with month'/'day'/'year;
               date=year'/'month'/'day;
               parse line with "Pseudo Directory" filename;
               filename=strip(filename);
            } else {
               // The unit field is probably blank, so reparse
               unit="";
               parse line with volume date ext used recfm lrecl . dsorg filename;
            }
         }
         // We need this to distinquish between partitioned datasets (PDS)
         // and sequential datasets.
         attribs=upcase(dsorg);
      } else {
         parse line with filename vv '.' mm created date time size init mod owner .;
         attribs="";
      }

      refs=0;
      group="";

      file.attribs=attribs;
      if( datasets && (attribs=="PO" || attribs=="POU" || attribs=="DIRECTORY") ) {
         file.type=FTPFILETYPE_DIR;
      } else {
         file.type=0;
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      parse date with year '/' month '/' day;
      if( !isinteger(year) ) {
         // This should never happen - use the current year?
         cur_month := "";
         cur_year := "";
         parse _date('U') with cur_month '/' . '/' cur_year;
         if( (int)cur_month<_ftpMonthToNumber(month) ) {
            year= (int)cur_year - 1;
         } else {
            year=cur_year;
         }
      }
      file.year= (int)year;

      if( !isinteger(month) ) {
         // This should never happen
         month="???";
      } else {
         switch( (int)month ) {
         case 1:
            month='Jan';
            break;
         case 2:
            month='Feb';
            break;
         case 3:
            month='Mar';
            break;
         case 4:
            month='Apr';
            break;
         case 5:
            month='May';
            break;
         case 6:
            month='Jun';
            break;
         case 7:
            month='Jul';
            break;
         case 8:
            month='Aug';
            break;
         case 9:
            month='Sep';
            break;
         case 10:
            month='Oct';
            break;
         case 11:
            month='Nov';
            break;
         case 12:
            month='Dec';
            break;
         }
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( time=="" ) {
         time="0:00";
      }
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// OS/400 runs on AS/400 machines.
//
// A directory listing looks like this:
//
// JWW             16384 10/30/98 14:36:37 *FILE      $CONTENTS
// JWW                                     *MEM       $CONTENTS.CONTENTS
// JWW           1269760 11/02/98 13:34:29 *FILE      C
// JWW                                     *MEM       C.CMDTOKEN
// JWW              6255 11/13/98 16:05:57 *STMF      m4r3.mtr
// JWW               661 11/13/98 16:05:57 *STMF      m4r3.log
// JWW              1519 11/10/98 11:23:58 *STMF      m4r30002.TID
// JWW             23552 11/11/98 17:32:18 *DIR       tiddata/
static int _ftpParseDir_OS400(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   attribs := "";
   _str refs=0;
   owner := "";
   group := "";
   size := "";
   date := "";
   time := "";
   type := "";
   filename := "";
   rest := "";
   month := "";
   day := "";
   year := "";

   // Now massage the directory buffer into an ftp directory struct
   typeless status=0;
   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      line := "";
      get_line(line);
      if( line=="" ) break;   // Done

      attribs="";
      refs=0;
      group="";

      parse line with owner size date time type filename .;
      parse line with owner rest;

      _str p1,p2,p3,p4,p5;
      parse rest with p1 p2 p3 p4 p5 .;
      if( p5=="" ) {
         // Assume there is no size, date or time fields
         size="0";
         date="";
         time="";
         type=p1;
         filename=p2;
      } else {
         size=p1;
         date=p2;
         time=p3;
         type=p4;
         filename=p5;
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }

      file.attribs=attribs;

      file.type=0;
      if( lowcase(type)=="*dir" || _last_char(filename)=='/' ) {
         filename=strip(filename,'T','/');
         file.type |= FTPFILETYPE_DIR;
      }

      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      parse date with month '/' day '/' year;
      if( !isinteger(year) ) {
         // This should never happen - use the current year?
         cur_month := "";
         cur_year := "";
         parse _date('U') with cur_month '/' . '/' cur_year;
         if( (int)cur_month<_ftpMonthToNumber(month) ) {
            year= (int)cur_year - 1;
         } else {
            year=cur_year;
         }
      }
      file.year= (int)year;

      if( !isinteger(month) ) {
         // This should never happen
         month="???";
      } else {
         switch( (int)month ) {
         case 1:
            month='Jan';
            break;
         case 2:
            month='Feb';
            break;
         case 3:
            month='Mar';
            break;
         case 4:
            month='Apr';
            break;
         case 5:
            month='May';
            break;
         case 6:
            month='Jun';
            break;
         case 7:
            month='Jul';
            break;
         case 8:
            month='Aug';
            break;
         case 9:
            month='Sep';
            break;
         case 10:
            month='Oct';
            break;
         case 11:
            month='Nov';
            break;
         case 12:
            month='Dec';
            break;
         }
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( time=="" ) {
         time="0:00";
      }
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// Novell Netware 4.11 or greater running on a PC.
//
// A directory listing looks like a normal UNIX listing, or like this:
//
// total 0
// - [RWCE-FM-] igofm                             268 May 28 11:56 wproot.sf
// - [RWCE-FM-] pyu.ou=wl.                    3965250 Mar 30 18:35 py
// - [RWCE-FM-] jnguy.ou=wl.                     1072 Jan 13 16:51 keylock.gif
// - [RWCE-FM-] mhong.ou=wl.                      838 Jan 13 17:12 keylock.ico
// - [RWCE-FM-] bcars                          787510 Apr 01 14:14 kansit2.bmp
// - [RWCE-FM-] jlee.ou=wl.                       838 Jan 13 17:26 keylocka.ico
// - [RWCE-FM-] jnguy.ou=wl.                      838 Jan 13 16:59 keylock.bmp
// - [RWCE-FM-] jlee.ou=wl.                      3494 Jan 13 17:36 keylock2.ico
// - [RWCE-FM-] jbant                          403677 Aug 31 08:10 jbant
// - [RWCE-FM-] bscha.ou=wl.                   234992 Feb 05 15:26 bcsha
// d [RWCE-FM-] nwill.ou=agh.                     512 Sep 24 12:03 ksx
// d [RWCE-FM-] gbeck.ou=hou.                     512 Apr 14 14:41 distdb
// d [RWCE-FM-] gboon.ou=wl.                      512 Apr 01 15:53 catalina
// d [RWCE-FM-] fshao                             512 Jan 12 15:17 certsvcs
// d [RWCE-FM-] ymatu                             512 Jan 10 18:35 plex
// d [RWCE-FM-] gmods.ou=wl.                      512 Apr 26 11:53 gmods
static int _ftpParseDir_NETWARE(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;
   bool unix_style;

   unix_style=true;   // true=Netware host returns a UNIX style listing

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   word := "";
   parse line with word .;
   if( substr(word,1,length("total"))=="total" ) {
      // Get rid of the "total n" line
      _delete_line();
   }

   typeless refs=0;
   owner := "";
   group := "";
   attribs := "";
   month := "";
   day := "";
   year := "";
   yeartime := "";
   filename := "";
   size := "";
   rest := "";
   time := "";

   typeless status=0;
   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      dir := "";
      p2 := "";
      parse line with . p2 .;
      if( substr(p2,1,1)=='[' && _last_char(p2)==']' ) {
         // A Netware FTP server that has decided to do things differently
         unix_style=false;
         refs=0;
         group="";
         parse line with dir attribs owner size month day yeartime filename;
         // Only want a 3-char month
         if( length(month)>3 ) {
            month=substr(month,1,3);
         }
         day=strip(day,'L','0');
      } else {
         #if 1
         parse line with attribs refs owner rest;
         parse rest with group size month day yeartime filename;
         // We are testing for the following case of no group field:
         //
         // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin
         //
         // OR
         //
         // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin -> .xsession
         if( !isinteger(size) ) {
            // This usually means that there was no group id. QNX and some
            // UNIX ftp servers do not give a group id.
            group="";
            parse rest with size month day yeartime filename;
         }
         #else
         parse line with attribs refs owner group size month day yeartime filename;
         #endif
      }

      if( attribs=="" ) {
         // This should never happen
         attribs=substr("",1,length("drwxrwxrwx"),'-');
      }
      file.attribs=attribs;
      file.type=0;
      if( unix_style ) {
         if( lowcase(substr(file.attribs,1,1))=='d' ) {
            // We have a directory
            file.type |= FTPFILETYPE_DIR;
         }
         if( lowcase(substr(file.attribs,1,1))=='l' ) {
            // We have a link
            file.type |= (FTPFILETYPE_DIR|FTPFILETYPE_LINK);
         }
      } else {
         if( lowcase(dir)=="d" ) {
            file.type |= FTPFILETYPE_DIR;
         }
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      fcase := 'e';
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename,fcase) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( yeartime=="" ) {
         // This should never happen
         yeartime="00:00";
      }
      if( pos(':',yeartime) ) {
         // There is a time instead of a year - use the current year???
         cur_month := "";
         cur_year := "";
         parse _date('U') with cur_month '/' . '/' cur_year;
         time=yeartime;
         if( (int)cur_month<_ftpMonthToNumber(month) ) {
            year= (int)cur_year - 1;
         } else {
            year=cur_year;
         }
      } else {
         // There is year instead of a time
         year=yeartime;
         time="00:00";
      }
      if( !isinteger(year) ) {
         // This should never happen
         year=0;
      }
      file.year= (int)year;
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// MACOS runs on Apple machines.
//
// A directory listing looks like this:
//
// <xmp>
// -rwx------       28952     4850    33802 Nov 06 13:59 Filename with Spaces
// drwx------             folder          1 Mar 10 18:47 admin
// drwx------             folder         13 May 26 12:01 Analog
// -rwx------        2192      332     2524 Nov 17 23:20 Default.html
// drwx------             folder          4 Aug 16 11:02 docs
// drwx------             folder          3 May 26 12:02 Documentation
// -rwx------     2415846        0  2415846 Aug 19 06:44 Error CGI Log
// -rwx------           0    35553    35553 Jul 28 10:16 error.acgi
// -rwx------        2792     1454     4246 Oct 22 14:45 error.html
// drwx------             folder          7 Mar 10 18:48 Examples
// drwx------             folder         20 Aug 16 14:57 Images
// -rwx------        6572        0     6572 Aug 11 16:38 index-temp.shtml
// </xmp>
static int _ftpParseDir_MACOS(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   word := "";
   parse line with word .;
   if( substr(word,1,length("total"))=="total" ) {
      // Get rid of the "total n" line
      _delete_line();
   }

   typeless refs=0;
   owner := "";
   group := "";
   attribs := "";
   rest := "";
   size := "";
   month := "";
   day := "";
   year := "";
   yeartime := "";
   filename := "";
   time := "";

   typeless status=0;
   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      refs="0";
      owner="";
      group="";
      parse line with attribs rest;

      if( attribs=="" ) {
         // This should never happen
         attribs=substr("",1,length("drwxrwxrwx"),'-');
      }
      file.attribs=attribs;

      file.type=0;
      if( lowcase(substr(file.attribs,1,1))=='d' ) {
         // We have a directory
         file.type |= FTPFILETYPE_DIR;
         parse rest with . size month day yeartime filename;
      } else {
         if( lowcase(substr(file.attribs,1,1))=='l' ) {
            // We have a link
            file.type |= (FTPFILETYPE_DIR|FTPFILETYPE_LINK);
         }
         parse rest with . . size month day yeartime filename;
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( yeartime=="" ) {
         // This should never happen
         yeartime="00:00";
      }
      if( pos(':',yeartime) ) {
         // There is a time instead of a year - use the current year???
         cur_month := "";
         cur_year := "";
         parse _date('U') with cur_month '/' . '/' cur_year;
         time=yeartime;
         if( (int)cur_month<_ftpMonthToNumber(month) ) {
            year= (int)cur_year - 1;
         } else {
            year=cur_year;
         }
      } else {
         // There is year instead of a time
         year=yeartime;
         time="00:00";
      }
      if( !isinteger(year) ) {
         // This should never happen
         year=0;
      }
      file.year= (int)year;
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

// VxWorks runs on embedded machines.
//
// A directory listing looks like this:
//
// <xmp>
//   size          date       time       name
// --------       ------     ------    --------
//      512    Jan-01-1980  00:00:00   .                 <DIR>
//      512    Jan-01-1980  00:00:00   ..                <DIR>
//     6775    Jan-01-1980  00:00:00   ABCports.tcl
//    79179    Jan-01-1980  00:00:00   accapi.tcl
//       68    Jan-01-1980  00:00:00   addarp.dat
//     7986    Jan-01-1980  00:00:00   AddArpNP0.tcl
//     7255    Jan-01-1980  00:00:00   AddArpNP1.tcl
//     7255    Jan-01-1980  00:00:00   AddArpNP2.tcl
//     7255    Jan-01-1980  00:00:00   AddArpNP3.tcl
//      512    Jan-01-1980  00:00:00   pico              <DIR>
// </xmp>
static int _ftpParseDir_VXWORKS(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct

   // Move past the column headers to the first actual entry
   line := "";
   word := "";
   top();up();
   while( !down() ) {
      get_line(line);
      parse line with word .;
      word=strip(word);
      if( isinteger(word) ) break;
   }
   up();

   size := "";
   date := "";
   time := "";
   rest := "";
   filename := "";
   attribs := "";
   owner := "";
   group := "";
   refs := "";
   month := "";
   day := "";
   year := "";

   typeless status=0;
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      #if 1
      parse line with size date time rest;
      // We do this just in case filenames-with-spaces are supported, so
      // we do not mistakenly parse off part of the filename and think
      // it is attributes.
      rest=strip(rest);
      i := lastpos('[ \t]',rest,'','er');
      if( i ) {
         if( upcase(substr(rest,i+1))=='<DIR>' ) {
            filename=strip(substr(rest,1,i-1));
            attribs='<DIR>';
         }
      } else {
         filename=rest;
         attribs="";
      }
      #else
      parse line with size date time filename attribs .;
      #endif

      owner="";
      group="";
      refs=0;

      file.attribs=attribs;
      file.type=0;
      if( upcase(file.attribs)=='<DIR>' ) {
         // We have a directory
         file.type |= FTPFILETYPE_DIR;
      }

      if( filename=="" ) {
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      parse date with month'-'day'-'year;
      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      day=strip(day,'L','0');
      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( year=="" ) {
         // This should never happen
         parse _date('U') with . '/' . '/' year;
      }
      if( !isinteger(year) ) {
         // This should never happen
         year=0;
      }
      file.year= (int)year;
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

static int _ftpParseDir_UNIX(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   FtpFile file;

   // Now massage the directory buffer into an ftp directory struct
   top();
   line := "";
   get_line(line);
   word := "";
   parse line with word .;
   if( substr(word,1,length("total"))=="total" ) {
      // Get rid of the "total n" line
      _delete_line();
   }

   attribs := "";
   refs := "";
   owner := "";
   group := "";
   size := "";
   rest1 := "";
   rest2 := "";
   month := "";
   day := "";
   year := "";
   yeartime := "";
   filename := "";
   time := "";

   typeless status=0;
   top();up();
   for(;;) {
      if( down() ) break;
      if( _line_length(false)==_line_length(true) ) break;   // Last line had no linebreak

      get_line(line);
      if( line=="" ) break;   // Done
      parse line with attribs refs owner rest1 ;
      parse rest1 with group size rest2 ;

      // Special cases:
      // 1. No group field (typically QNX hosts):
      //
      // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin
      //
      // OR
      //
      // lrwxr-xr-x   1 root           9 Aug 19  1997 .Xbegin -> .xsession
      //
      // 2. Group name has spaces in the name (UNIX host with LDAP groups from a Windows server):
      //
      // -rwxr-xr-x    1 userid   Domain Users       81 Jul 28 15:22 foo.cpp

      if( !isinteger(size) ) {
         // Case 1 OR Case 2
         if( isinteger(group) ) {
            // Case 1: no group field
            group = '';
            parse rest1 with size rest2;
         } else if( !isinteger(group) ) {
            // Case 2: group name has spaces in the name
            parse rest1 with group ':i','er' +0 size rest2;
            group = strip(group);
            size = strip(size);
         }
      }

      parse rest2 with month day yeartime filename;
      if( isinteger(month) && !isinteger(day) ) {
         // European style date (day month year)
         parse rest2 with day month yeartime filename;
      }

      if( attribs=="" ) {
         // This should never happen
         attribs=substr("",1,length("drwxrwxrwx"),'-');
      }
      file.attribs=attribs;
      file.type=0;
      if( lowcase(substr(file.attribs,1,1))=='d' ) {
         // We have a directory
         file.type |= FTPFILETYPE_DIR;
      }
      if( lowcase(substr(file.attribs,1,1))=='l' ) {
         // We have a link
         file.type |= (FTPFILETYPE_DIR|FTPFILETYPE_LINK);
      }

      if( filename=="" ) {
         /* Skip it. This can happen on OS/390 machines with a filename that
          * is all spaces.
          */
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            _str filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _RemoteFilespecMatches(fcp_p,filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      file.filename=filename;

      if( !isinteger(size) ) {
         size="0";
      }
      file.size = size;

      if( month=="" ) {
         // This should never happen
         month="???";
      }
      file.month=substr(month,1,3);   // Only allow first 3 chars of month

      if( !isinteger(day) ) {
         day="0";
      }
      file.day= (int)day;

      if( yeartime=="" ) {
         // This should never happen
         yeartime="00:00";
      }
      if( pos(':',yeartime) ) {
         // There is a time instead of a year - use the current year???
         cur_month := "";
         cur_year := "";
         parse _date('U') with cur_month '/' . '/' cur_year;
         time=yeartime;
         if( (int)cur_month<_ftpMonthToNumber(month) ) {
            year= (int)cur_year - 1;
         } else {
            year=cur_year;
         }
      } else {
         // There is year instead of a time
         year=yeartime;
         time="00:00";
      }
      if( !isinteger(year) ) {
         // This should never happen
         year=0;
      }
      file.year= (int)year;
      file.time=time;
      file.mtime = _ftpMakeMtime(year, month, day, time);

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      remote_dir.files[remote_dir.files._length()] = file;
   }

   return(status);
}

static int _ftpParseDir_DEFAULT(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter)
{
   return( _ftpParseDir_UNIX(fcp_p,remote_dir,filter) );
}

/** 
 * Parse a raw directory listing into a FtpDirectory object. 
 *
 * @param fcp_p         Connection profile.
 * @param remote_dir    FtpDirectory object to fill.
 * @param filter        Filter to apply to filenames. Only 
 *                      filenames that match the filter are
 *                      included.
 * @param src_filename  Source file containing raw listing.
 *
 * @return 0 on success.
 */
int _ftpParseDir(FtpConnProfile* fcp_p, FtpDirectory& remote_dir, _str filter, _str src_filename)
{
   remote_dir._makeempty();
   remote_dir.flags = 0;

   if( src_filename == '' ) {
      return(1);
   }

   orig_view_id := p_window_id;
   temp_view_id := 0;
   typeless status = _open_temp_view(src_filename,temp_view_id,orig_view_id,"+ftext");
   if( status != 0 ) {
      msg :=  'Could not open file "':+src_filename:+'".  ':+_ftpGetMessage(status);
      ftpConnDisplayError(fcp_p,msg);
      return(status);
   }
   p_window_id = temp_view_id;

   // Sanity please
   if( !filter || filter == '' ) {
      filter = FTP_ALLFILES_RE;
   }

   switch( fcp_p->system ) {
   case FTPSYST_WINNT:
      status = _ftpParseDir_WINNT(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_HUMMINGBIRD:
      status = _ftpParseDir_HUMMINGBIRD(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_OS2:
      status = _ftpParseDir_OS2(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_VOS:
      status = _ftpParseDir_VOS(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_VMS:
   case FTPSYST_VMS_MULTINET:
      status = _ftpParseDir_VMS(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_VM:
   case FTPSYST_VMESA:
      status = _ftpParseDir_VM(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_MVS:
      if( substr(fcp_p->remoteCwd,1,1) == '/' ) {
         // The MVS host is using an HFS file system which mimics Unix
         status = _ftpParseDir_UNIX(fcp_p,remote_dir,filter);
      } else {
         // The MVS host is using PDS (Partitioned Data Set) format
         status = _ftpParseDir_MVS(fcp_p,remote_dir,filter);
      }
      break;
   case FTPSYST_OS400:
      status = _ftpParseDir_OS400(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_NETWARE:
      status = _ftpParseDir_NETWARE(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_MACOS:
      status = _ftpParseDir_MACOS(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_VXWORKS:
      status = _ftpParseDir_VXWORKS(fcp_p,remote_dir,filter);
      break;
   case FTPSYST_UNIX:
      status = _ftpParseDir_UNIX(fcp_p,remote_dir,filter);
      break;
   default:
      status = _ftpParseDir_DEFAULT(fcp_p,remote_dir,filter);
   }

   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(status);
}

/** 
 * Create a local directory listing and store in FtpDirectory 
 * object. 
 *
 * @param fcp_p      Connection profile.
 * @param local_dir  (out) FtpDirectory object to fill.
 * @param filter     Filter to apply to filenames. Only 
 *                   filenames that match the filter are
 *                   included. 
 * @param local_cwd  Local directory to list contents for.
 *
 * @return 0 on success.
 */
int _ftpGenLocalDir(FtpConnProfile* fcp_p, FtpDirectory& local_dir, _str filter, _str local_cwd)
{
   FtpFile file;

   local_dir._makeempty();
   local_dir.flags=0;
   _maybe_append_filesep(local_cwd);
   filespec :=  local_cwd:+ALLFILES_RE;
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   if( orig_view_id=="" ) return(1);
   status := insert_file_list(_maybe_quote_filename(filespec):+' +ADV');
   if( status ) {
      // Error
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      return(status);
   }

   size := "";
   date := "";
   time := "";
   attribs := "";
   filename := "";

   // Fill in the file list. The format is:
   //
   // 11444   7-15-1997  10:15p ----A  ftp.c
   #if 1
   filter=ALLFILES_RE;
   #endif
   top();up();
   for(;;) {
      file._makeempty();
      if( down() ) break;
      if( _line_length(true)==_line_length(false) ) break;
      line := "";
      get_line(line);
      parse line with size date time attribs filename;
      if( filename=="." || filename==".." ) {
         continue;
      }
      if( !pos('d',lowcase(attribs),1,'e') &&
          filter!=ALLFILES_RE ) {
         match := false;
         _str list=filter;
         while( list!="" ) {
            filespec=parse_file(list);
            filespec=strip(filespec,'B','"');
            if( filespec=="" ) continue;
            if( _FilespecMatches(filespec,filename) ) {
               // Found a match
               match=true;
               break;
            }
         }
         if( !match ) continue;
      }
      if( !isinteger(size) ) {
         // Probably the "<DIR>" of a directory
         size=0;
      }

      file._makeempty();
      file.filename=filename;
      file.type=0;
      if( pos('d',lowcase(attribs),1,'e') ) {
         // Directory name
         file.type |= FTPFILETYPE_DIR;
      }
      local_dir.files[local_dir.files._length()] = file;
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(0);
}
