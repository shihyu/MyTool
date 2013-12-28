////////////////////////////////////////////////////////////////////////////////////
// $Revision: 40327 $
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
#import "ftp.e"
#import "ftpparse.e"
#import "stdprocs.e"
#endregion


static int _sftpParseDir_UNIX(FtpConnProfile *fcp_p,SftpDirectory *pdirlist)
{
   FtpFile file;
   int i;

   // Now massage the directory buffer into an ftp directory struct
   _str filter=strip(fcp_p->remoteFileFilter);
   if( filter=="" ) filter=FTP_ALLFILES_RE;
   int status=0;
   for( i=0;i<pdirlist->names._length();++i ) {
      _str line=pdirlist->names[i].longname;
      if( line=="" ) {
         // This should never happen
         continue;
      }
      _str attribs='';
      _str refs='';
      _str owner='';
      _str rest1='';
      parse line with attribs refs owner rest1;

      _str group='';
      // size must be typeless in case it is larger than an int
      typeless size='';
      _str rest2='';
      parse rest1 with group size rest2;

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

      _str month='';
      _str day='';
      _str yeartime='';
      _str filename='';
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
         // Skip it. This can happen on OS/390 machines with a filename that
         // is all spaces.
         continue;
      }
      if( filename=="." || filename==".." ) continue;
      if( !(file.type&FTPFILETYPE_DIR) &&
          filter!=FTP_ALLFILES_RE ) {
         boolean match=false;
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

      _str year='';
      _str time='';
      if( yeartime=="" ) {
         // This should never happen
         yeartime="00:00";
      }
      if( pos(':',yeartime) ) {
         // There is a time instead of a year - use the current year???
         _str cur_month='';
         _str cur_year='';
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

      file.owner=owner;

      file.group=group;

      if( !isinteger(refs) ) {
         refs="0";
      }
      file.refs= (int)refs;

      // Add it to the array
      fcp_p->remoteDir.files[fcp_p->remoteDir.files._length()]=file;
   }

   return(status);
}

static int _sftpParseDir_DEFAULT(FtpConnProfile *fcp_p,SftpDirectory *pdirlist)
{
   return(_sftpParseDir_UNIX(fcp_p,pdirlist));
}

// Fill the connection profile's remote directory member with directory data
int _sftpCreateDir(FtpConnProfile *fcp_p,SftpDirectory *pdirlist)
{
   fcp_p->remoteDir._makeempty();
   fcp_p->remoteDir.flags=0;

   int status=0;
   switch( fcp_p->system ) {
   case FTPSYST_UNIX:
      status=_sftpParseDir_UNIX(fcp_p,pdirlist);
      break;
   default:
      status=_sftpParseDir_DEFAULT(fcp_p,pdirlist);
   }

   return(status);
}

