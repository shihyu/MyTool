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
#include "math.sh"
#import "main.e"
#import "markfilt.e"
#import "stdprocs.e"
#import "slickc.e"
#import "clipbd.e"
#import "c.e"
#endregion

  static int index;
  static _str input;
  static _str exp_stack;
  static _str sym;
  static bool gstrict_id_checking;
  static _str gdefine_names;  // name1=value1 name2=value2
                              // "=" for null
  static _str gdefault_value;
  static _str gwarning;             // Warning message with one %s.
  static _str *gpalready_warned_list; // List of space delimited variable names

  // By default, leading zeros indicate octal numbers like C++,Java, and C#.
  // Cobol programmers might like to set this to 1.
  // Warning: This variable effects ALL macro commands which do mathematical
  // expression calculation (seek, math, add select expression, etc.)
  bool def_leading_zero_is_decimal;

/**
 * <p>
 * Adds selected text and inserts result below the last line of the selection.  If no operator
 * exists between two adjacent numbers, addition is assumed.  '$' and ',' characters are stripped
 * from the line before the expression is evaluated.  The result of each line is added.  Accepts
 * expressions supported by the math commands.  See <b>math</b> command for information on expression.
 * Select text first with one of the commands <b>select_char</b>, <b>select_line</b>, or <b>select_block</b>.
 * </p>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @see select_char
 * @see select_line
 * @see select_block
 * @see math
 * @see mathx
 * @see matho
 * @see mathb
 * @categories Selection_Functions
 */
_command void add() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION)
{
   if ( _select_type()!='' ) {
      column_math('+');
   } else {
      message(get_message(TEXT_NOT_SELECTED_RC));
   }
}

/**
 * Adds or multiplies the result of evaluating each sub line of a selected 
 * area of text.
 * 
 * @return  Returns 0 if successful.  Otherwise 1 (syntax error) is returned.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 */
_str column_math(_str default_operator)
{
   typeless result=0;
   typeless status=0;
   first_col := 0;
   last_col := 0;
   buf_id := 0;
   _str type = _select_type();
   _get_selinfo(first_col,last_col,buf_id);
   if (type == "LINE") {
      first_col = 1;
   }
   if ( default_operator=='+' ) {
      result=0;
   } else {
      result=1;
   }
   filter_init();
   typeless tempresult="";
   line := "";
   for (;;) {
      status= filter_get_string(line);
      if ( status ) { break; }
      if ( line=='' ) { continue; }   /* Ignore blank lines. */
#if 0
      // When converting data from mainframe or data base might want
      // to striping leading zeros so the data is not interpreted
      // as octal numbers.
      line=strip(line,"L",'0');
#endif
      status=eval_exp(tempresult,line,10);
      if ( status!=0) {
         if (isinteger(status)) {
            message(get_message(status));
         } else {
            message(status);
         }
         return(1);
      } else {
        if ( default_operator=='+' ) {
           result += tempresult;
        } else {
           result *= tempresult;
        }
      }
   }
   _end_select();
   insert_line(substr('',1,first_col-1):+result);
   return(0);
}
/** 
 * @param hex 0xNNNN, xNNNN, or NNNN  represent a valid hex number 
 *        0NNNN for an Octal number 0bNNNN, 
 *        bNNNN  represent a valid binary number
 * @param base     input base. Defaults to 16.
 * 
 * @return Returns <i>number</i> of base 16 or <i>base</i> specified in base 
 * 10.  Only bases 2, 8, and 16 are supported.  If <i>number</i> is invalid, '' 
 * is returned.  Binary numbers may start with 'b'.  Hex numbers may start with 
 * '0x' or 'x'.  Octal numbers may start with the digit '0'.
 *  
 * A trailing 'L' indicates that the number should be treated as a 64-bit integer. 
 * A trailing 'U' indicates that the number should be treated as unsigned. 
 * 'U' and 'L' can be used in combination. 
 * 
 * @categories String_Functions
 */
typeless hex2dec(_str hex,int base=16)
{
   // handle special case numbers
   if (hex == "nan" || hex == "infinity" || hex == "-infinity") {
      return hex;
   }
   // determine if the number has a leading sign
   sign := 1;
   hex=strip(hex);
   if ( substr(hex,1,1)=='-' ) {
      sign= -1;
      hex=substr(hex,2);
   }

   // determine if this is a long (64-bit) integer, and if it should be read as unsigned
   isUnsigned := isLong := false;
   while (upcase(_last_char(hex)) == 'L' || upcase(_last_char(hex)) == 'U') {
      if (upcase(_last_char(hex)) == 'L') {
         isLong = true;
      } else {
         isUnsigned = true;
      }
      hex=substr(hex,1,length(hex)-1);
   }

   // determine number base
   if ( upcase(substr(hex,1,2))=='0B' ) {
      hex=substr(hex,3);
      base=2;
   } else if ( upcase(substr(hex,1,1))=='B' ) {
      hex=substr(hex,2);
      base=2;
   } else if ( upcase(substr(hex,1,2))=='0X' ) {
      base=16;
      hex=substr(hex,3);
   } else if ( upcase(substr(hex,1,1))=='X' ) {
      hex=substr(hex,2);
      base=16;
   } else if (substr(hex,1,1)=='0' && base=="") {
      base=8;
      hex=substr(hex,2);
      if (hex=='') {  // Converting hex 0?
         hex=0;
      }
   }
   if ( hex=='' ) {   /* bad input. return null*/
     return('');
   }

   // determine if this is a long integer (based on it's length)
   if (!isLong) {
      isLong = isLong || (base==16 && length(hex) > 8);
      isLong = isLong || (base== 8 && length(hex) > 10);
      isLong = isLong || (base== 2 && length(hex) > 32);
   }
   if (!isLong && base==10 && (pos('.',hex) || pos('e',hex,1,'i'))) {
      if (sign<0) {
         return '-'hex;
      }
      return hex;
   }

   // can we use shifts to put together the number?
   bits := (isLong? 64:32);
   doHex    := (base==16 && length(hex) <= (bits intdiv 4) && !isUnsigned);
   doOctal  := (base== 8 && length(hex) <= (bits intdiv 3) && !isUnsigned);
   doBinary := (base== 2 && length(hex) <= (bits intdiv 1) && !isUnsigned);
   haveDot  := false;
   base2_exponent := 0;

   // parse the number
   typeless result = 0;
   for (;;) {
      ch := upcase(substr(hex,1,1));
      if ( ch=='' ) { break; }
      long i = pos(ch,'0123456789ABCDEF');
      if ( ! i ) {
         if (ch == '.' && doHex && !haveDot) {
            haveDot=true;
            hex=substr(hex,2);
            continue;
         }
         if (ch == 'P' && doHex) {
            break;
         }
         return(''); 
      }
      if (isLong) i = (long)i;
      i--;
      if ( doHex && i < 16 ) {
         result = (result * 16) + i;
         if (haveDot) base2_exponent -= 4;
      } else if ( doOctal && i < 8 ) {
         result = (result * 8) + i;
      } else if ( doBinary && i < 2 ) {
         result = (result * 2) + i;
      } else {
         result *= base;
         result += i;
      }
      hex = substr(hex,2);
   }

   // what if we find a floating hex number
   ch := upcase(substr(hex,1,1));
   if (ch == 'P') {
      exp_negative := false;
      exponent := 0;
      hex=substr(hex,2);
      ch = upcase(substr(hex,1,1));
      if (ch == '-' || ch == '+') {
         exp_negative = (ch == '-');
         hex=substr(hex,2);
      }
      for (;;) {
         ch = upcase(substr(hex,1,1));
         if ( ch=='' ) { break; }
         typeless i = pos(ch,'0123456789');
         if ( ! i ) { return(''); }
         exponent = (exponent * 10) + (i-1);
         hex=substr(hex,2);
      }
      if (exp_negative) exponent = -exponent;
      base2_exponent += exponent;
   }

   // now apply the base2 exponent if we have one
   if (base2_exponent) {
      exponent := abs(base2_exponent);
      while (exponent > 0) {
         if (base2_exponent < 0) {
            result /= 2.0;
         } else {
            result *= 2.0;
         }
         --exponent;
      }
   }

   // finally, take care of negation
   return(result*sign);
}
/* Input:  */
/*      number          decimal number  */
/*      [base]          may be 2 or 8 or 16. */
/* Output:  base=16    0xNNNN */
/*          base=8     0NNNN */
/*          base=2     0bNNNN */
/* If number is invalid '' is returned */


/** 
 * @return  Returns <i>number</i> converted to base 16 or base specified.  
 * <i>base</i> must be one of the values 2, 8, or 16.  If <i>number</i> is 
 * invalid, '' is returned.  Binary numbers are prefixed with the string "0b".  
 * Hex numbers are prefixed with "x".  Octal numbers are prefixed with the digit '0'.
 * <p>
 * Output:  base=16    0xNNNN 
 *          base=8     0NNNN 
 *          base=2     0bNNNN 
 * <p> 
 *  
 * @param number          decimal number
 * @param base          may be 2 or 8 or 16. 
 *  
 * @categories String_Functions 
 * @see _dec2hex() 
 */
_str dec2hex(long number, typeless base="")
{
   // handle special case numbers
   if (number == "nan" || number == "infinity" || number == "-infinity") {
      return number;
   }
   prefix := "";
   if ( base != '' ) {
      if ( base=='2' ) {
         prefix='0b';
      } else if ( base=='8' ) {
         prefix='0';
      } else {
         prefix='0x';
      }
   } else {
      base=16;
      prefix='0x';
   }
   if ( ! isinteger(number) ) { return(''); }

   sign := "";
   result := "";
   // IF this number is within the range of an unsigned 64 bit int or a signed 64 bit int
   within_64bit_range := (number <= 18446744073709551615 && number>=-9223372036854775808L);
   within_32bit_range := (number <= 4294967295 && number>=-2147483648);
   if ( base == 16 && within_64bit_range ) {
      if (within_32bit_range) {
         while ( number != 0 ) {
            digit := (int)(number & 0xF);
            result = substr("0123456789ABCDEF",digit+1,1):+result;
            number = number >> 4;
            number = number & 0xFFFFFFF;
         }
      } else {
         while ( number != 0 ) {
            digit := (int)(number & 0xF);
            result = substr("0123456789ABCDEF",digit+1,1):+result;
            number = number >> 4;
            number = number & 0xFFFFFFFFFFFFFFFL;
         }
      }
   } else if ( base != 10 && within_64bit_range) {
      if ( number<0 ) {
         // Convert number to be unsigned
         hexdigits:=substr(dec2hex(number,16),3);
         number=hex2dec('0x0'hexdigits,10);
      }
      while ( number > 0 ) {
         digit := (number % base);
         result=substr('0123456789ABCDEF',digit+1,1):+result;
         number = number intdiv base;
      }
   } else {
      if ( number<0 ) {
         sign='-';
         number=-number;
      }
      while ( number > 0 ) {
         i := number intdiv base;
         digit := (number % base);
         result=substr('0123456789ABCDEF',digit+1,1):+result;
         number=i;
      }
   }

   if ( result=='' ) { result='0'; } /* number must have been 0 */
   if (base==8 && "x":+result=="x0") {
      return('0');
   }
   //say('res='sign:+prefix:+result);
   return(sign:+prefix:+result);
}
/** 
 * <p>Evaluates Slick-C&reg; <i>expression</i> given and places the results on the 
 * command line.  Unlike the Slick-C&reg; translator, octal numbers may be specified 
 * by prefixing the number with a 0 and binary numbers may be specified by 
 * prefixing the number with '0b' or 'b'.  If no operator is specified between 
 * two unary expressions, addition is assumed.</p>
 * 
 * <p>Not all Slick-C&reg; operators are supported.</p>
 * 
 * @param expression can have the following unary operators:
 * <dl>
 * <dt>~</dt><dd>bitwise complement</dd>
 * <dt>-</dt><dd>Negation</dd>
 * <dt>+</dt><dd>No change</dd>
 * </dl>
 * 
 * <p>The available binary operators are listed below from lowest to highest 
 * precedence.  A comma after the operator indicates that the next operator is 
 * of the same precedence.</p>
 * 
 * <dl>
 * <dt>|</dt><dd>bitwise or</dd>
 * <dt>^</dt><dd>xor</dd>
 * <dt>&</dt><dd>bitwise and</dd>
 * <dt><<,</dt><dd>shift left</dd>
 * <dt>>></dt><dd> shift right</dd>
 * <dt>+,</dt><dd>addition</dd>
 * <dt>blank(s),</dt><dd>Implied addition.</dd>
 * <dt>-</dt><dd>subtraction</dd>
 * <dt>/,</dt><dd>division</dd>
 * <dt>*,</dt><dd>multiplication</dd>
 * <dt>%,</dt><dd> remainder</dd>
 * <dt>**</dt><dd>power</dd>
 * </dl>
 * 
 * @see mathx
 * @see matho
 * @see mathb
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command void math(_str expr="")
{
   math_base(expr,10,'');

}
/**
 * 
 * <p>Evaluates Slick-C&reg; <i>expression</i> given and places the result on the 
 * command line in hexadecimal.  Unlike the Slick-C&reg; translator, octal numbers 
 * may be specified by prefixing the number with a 0 and binary numbers may be 
 * specified by prefixing the number with '0b' or 'b'.  If no operator is 
 * specified between two unary expressions, addition is assumed.</p>
 * 
 * <p>Not all Slick-C&reg; operators are supported.  See <b>math</b> command for a 
 * list of operators.</p>
 * 
 * @see matho
 * @see math
 * @see mathb
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command void mathx(_str expr="")
{
   math_base(expr,16,'x');

}
/** 
 * <p>Evaluates Slick-C&reg; <i>expression</i> given and places the result on the 
 * command line in octal.  Unlike the Slick-C&reg; translator, octal numbers may be 
 * specified by prefixing the number with a 0 and binary numbers may be 
 * specified by prefixing the number with '0b' or 'b'.  If no operator is 
 * specified between two unary expressions, addition is assumed.</p>
 * 
 * <p>Not all Slick-C&reg; operators are supported.  See <b>math</b> command for a 
 * list of operators.</p>
 * 
 * @see mathx
 * @see math
 * @see mathb
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command void matho(_str expr="")
{
   math_base(expr,8,'o');

}
/** 
 * <p>Evaluates Slick-C&reg; <i>expression</i> given and places the result on the 
 * command line in octal.  Unlike the Slick-C&reg; translator, octal numbers may be 
 * specified by prefixing the number with a 0 and binary numbers may be 
 * specified by prefixing the number with '0b' or 'b'.  If no operator is 
 * specified between two unary expressions, addition is assumed.</p>
 * 
 * <p>Not all Slick-C&reg; operators are supported.  See math command for a list 
 * of operators.</p>
 * 
 * @see mathx
 * @see math
 * @see matho
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command void mathb(_str expr="")
{
   math_base(expr,2,'b');

}
/** 
 * @return Returns non-decimal <i>negative_number</i> converted to a 16, 32, 
 * or 64 bit number.  This function is useful for displaying negative 
 * hexadecimal typed numbers (long, int, short).  The <i>msg</i> variable is set 
 * to the number of bits required to represent the negative number.
 * 
 * @example
 * <pre>
 * defmain()
 * {
 *    result=_negative2dec('-f',16,msg);
 *    result=dec2hex(result,16);
 *    message(msg' result='result);
 * }
 * </pre>
 * 
 * @categories Buffer_Functions
 * 
 */
long _negative2dec(long result,int base,_str &msg)
{
   typeless number="";
   parse result with '-' number ;
   number=hex2dec(number,base);
   if ( number<pow(2,15) ) {
      msg='16 bit';
      number=(pow(2,16))-number;
   } else if ( number<pow(2,31) ) {
      msg='32 bit';
      number=(pow(2,32))-number;
   } else {
      /* 64 bits should be big enough.  Have up to 106 bits. */
      msg='64 bit';
      number=(pow(2,64))-number;
   }
   return(number);

}

/**
 * Returns info for hexadecimal or decimal integer at the 
 * cursor. 
 *  
 * @param input_base         (output only) Set to 2, 8, 10, or 
 *                           16 depending on type of integer
 *                           found.
 * @param preserveCursorPos  If true, cursor position is 
 *                           preserved. Otherwise, cursor is
 *                           placed at the beginning of the
 *                           complete integer (not just digits).
 * 
 * @return Returns decimal or hexadecimal digits excluding 
 *         leading or trailing syntax.
 */
_str _cur_integer(int &input_base,bool preserveCursorPos=true,int &complete_match_len=0) {
   save_pos(auto p);
   int embedded=_EmbeddedStart(auto orig_values);
   index = _FindLanguageCallbackIndex('-%s-cur-integer');
   if ( index ) {
      input=call_index(input_base, complete_match_len,index);
   } else {
      /* 
        Attempt to pick up the following format numbers.

         Rexx: '<hhh>'X
         C++: 0x<hhh>  0x12a
              0x123'456
         Perl:0x123_456
         C++:  0b11'11
             0o7711
         VB: &h<hhh>   &h12a
         MASM: <hhh>H  FFH
         unicode char: \\u<hhh>   \u0123
         hex char: \\x<hhh>       0x1234
         regex hex char: \\N{U+<hhh>}   Just match U+<hhhh>  U+12a
         XML: &#x<hhh>;  &#x12a;
         Verilog and SystemVerilog:  32'hC000_1234;  32'SHC000_1234;
         0xffffffff
         0xffff
         0b11111111111111111111111111111111

         Match is a little bit fuzzy on leading charcters
         so searching backwards matches multiple leading
         characters better.
         
      */
      bool check_for_dollar_hex=false;
      if (p_lexer_name=='') {
         check_for_dollar_hex=true;
      } else if(!_clex_is_identifier_start_char('$')) {
         check_for_dollar_hex=true;
      }
      re := '((\\|)[uU]{#0:h})';
      re:+='|':+'(''([sS]|)[hH]{#0[0-9a-fA-F_]#})';   // Verilog and SystemVerilog
      if (check_for_dollar_hex) {
         re:+='|':+'(\${#0:h})';
      }
      re:+='|':+'((&|)[hH]{#0:h})';
      re:+='|':+'(((&\#|\#))[xX]{#0:h};)';
      re:+='|':+'((0|)[xX]{#0[0-9a-fA-F][0-9a-fA-F_'']@})';
      re:+='|':+'({#0()0[bB][01][01_'']@})';
      re:+='|':+'({#0()0[oO][0-7][0-7_'']@})';
      re:+='|':+'({#0:h}[hH])';
      re:+='|':+'([0-9a-f]''[xX])';
      re:+='|':+'((U|)\+{#0:h})';
      status:=search('('re')|?|^','@R-');
      //say('_cur_integer status='status' ln='p_line' col='p_col);
      complete_match_len=match_length();
      if(match_length()>1) {
         //say('case1');
         input=get_match_text(0);
         input=stranslate(input,'','_');
         input=stranslate(input,'',"'");
         if (length(input)==0) input=0;
         if (strieq(substr(input,1,2),'0b') && pos('0[bB][01_]#',input,1,'r')==1 && pos('')==length(input)) {
            input_base=2;
            //input=substr(input,3);
         } else if (strieq(substr(input,1,2),'0o') && pos('0[oO][0-7_]#',input,1,'r')==1 && pos('')==length(input)) {
            input_base=8;
            //input=substr(input,3);
         } else {
            input_base=16;
         }
      } else {
         //say('case2');
         if (_clex_find(0,'g')==CFG_NUMBER) {
            status=search('{#0[0-9][0-9_'']@}|?|^','@R-');
         } else {
            status=search('{#0:i}|?|^','@R-');
         }
         if(match_length()) {
            input=get_match_text(0);
            if (!isdigit(substr(input,1,1))) {
               input='';
            } else {
               input=stranslate(input,'','_');
               input=stranslate(input,'',"'");
               complete_match_len=match_length();
            }
            input_base=10;
         }
         //say('input='input);
      }
   }
   if(preserveCursorPos) restore_pos(p);
   _EmbeddedEnd(orig_values);
   return input;
}
static _str math_base(_str input,int base,_str num_prefix)
{
   if (input=='' && _isEditorCtl(false)) {
      int input_base;
      input=_cur_integer(input_base);
      if (input!='') {
         if (input_base==16) {
            input='0x'input;
         } else if(input_base==8) {
            input='o'input;
         } else if(input_base==2) {
            input='b'input;
         }
      }
   }
   if (input=='') {
      input=prompt(input);
   }
   i := lastpos('=',input);
   if (i && (i==1 || !pos(substr(input,i-1,1),'=!><'))) {
      input=substr(input,1,i-1);
   }
   //messageNwait('math_base: input='input);
   typeless result=0;
   typeless status=eval_exp(result,input,base);
   if (status!=0) {
      if (isinteger(status)) {
         message(get_message(status));
      } else {
         message(status);
      }
      return(1);
   }
   /* IF base not 10 and result is negative. */
   typeless number="";
   msg := "";
   if ( base!=10 && pos('-',result) ) {
      number=_negative2dec(result,base,msg);
      msg :+= ' result='dec2hex(number,base);
   } else {
      typeless temp=hex2dec(result,base);
      //say('temp='temp' r='result' base='base);
      if ( pos('.',temp) || (lowcase(substr(result,1,2))!='0x' && lowcase(substr(result,1,1))!='x' && pos('e',temp,1,'i'))) {   /* Can't display float in hex. */
         msg='dec='_pretty_number(temp);
      } else {
         if ( pos('-',temp) ) {
            number=dec2hex(_negative2dec(temp,10,msg));
         } else {
            number=dec2hex(temp);
         }
         msg='dec='_pretty_number(temp)' hex='number;
         /*
           It would be nice to display hex numbers with
           high bit set as negative decimal number.
           // If this could be a negative decimal number
           if (substr(number,3,1)=='F') {
              //msg=msg' -dec='temp;
           }
         */
      }
   }
   _str pretty=result;
   if (base==10) {
      pretty=_pretty_number(result);
   }
   _str line='math'num_prefix " "input'= 'pretty;
   //command_put(line);sticky_message(msg);
   //append_retrieve_command(line);
   if (base==10) {
      _copy_text_to_clipboard(result);
   } else if (base==16) {
      if (substr(result,1,2)=='0x') {
         result=substr(result,3);
      }
      _copy_text_to_clipboard(result);
   } else if (base==8) {
      if (substr(result,1,1)=='o') {
         result=substr(result,2);
      } else if (substr(result,1,1)==0 && isdigit(substr(result,2,1))) {
         result=substr(result,2);
      }
      _copy_text_to_clipboard(result);
   } else if (base==2) {
      if (substr(result,1,2)=='0b') {
         result=substr(result,3);
      }
      _copy_text_to_clipboard(result);
   } else {
      _copy_text_to_clipboard(result);
   }
   msg :+= " (result copied clipboard)";
   sticky_message(line'  'msg);
   return(0);

}
static void exp_error()
{
   rc=nls('Syntax error');
   _resume();

}
static void exp_error_msg(_str msg)
{
   rc=msg;
   _resume();

}
static void nextsym()
{
   /* Skip leading spaces */
   index=verify(input,' '\t,'',index);
   if ( ! index ) {
      sym='$';return;
   }
   ch := "";
   typeless value=0;
   sym=substr(input,index,1);
   //IF is is the start of a decimal number or operator
   if ( pos(sym,'123456789.><!=~#^&|+-/*%()') ||
      (sym:=='0' && substr(input,index+1,1):=='.') ) {
      if ( isinteger(sym) || sym=='.' ) {
        int oldi=index;
        if ( sym=='.' ) { index++; }
        sym=substr(input,index,1);
        if ( ! isinteger(substr(input,index,1)) ) { exp_error(); }
        j := verify(input,'0123456789','',index);
        if ( ! j ) { j=length(input)+1; }
        index=j;
        sym=substr(input,index,1);
        if ( sym=='#' ) {
           base:=substr(input,oldi,j-oldi);
           if (isinteger(base)) {
              index++;
              j=verify(input,'0123456789ABCDEFabcdef','',index);
              if ( ! j ) { j=length(input)+1; }
              num:=substr(input,index,j-index);
              index=j;
              sym=hex2dec(num, (int)base);
              return;
           }
        }
        if ( sym=='.' ) {
          index++;
          j=verify(input,'0123456789','',index);
          if ( ! j ) { j=length(input)+1; }
          index=j;
          sym=substr(input,index,1);
        }
        if ( upcase(sym)=='E' ) {
          index++;
          sym=substr(input,index,1);
          if ( sym=='+' || sym=='-' ) {
            index++;
          }
          if ( ! isinteger(substr(input,index,1)) ) { exp_error(); }
          j=verify(input,'0123456789','',index);
          if ( ! j ) { j=length(input)+1; }
        }
        sym=substr(input,oldi,j-oldi);
        index=j;
      } else if ( sym=='*' ) {
        index++;
        if ( substr(input,index,1)=='*' ) {
          index++;
          sym='**';
        }
      } else if ( sym=='>' ) {
         index++;
         switch (substr(input,index,1)) {
         case '>':
            index++;
            sym='>>';
            break;
         case '=':
            index++;
            sym='>=';
            break;
         }
      } else if ( sym=='<' ) {
        index++;
        switch (substr(input,index,1)) {
        case '<':
           index++;
           sym='<<';
           break;
        case '=':
           index++;
           sym='<=';
           break;
        }
      } else if ( sym=='=' ) {
         index++;
         switch (substr(input,index,1)) {
         case '=':
            index++;
            sym='==';
            break;
         default:
            exp_error();
         }
      } else if ( sym=='!' ) {
         index++;
         switch (substr(input,index,1)) {
         case '=':
            index++;
            sym='!=';
            break;
         }
      } else if ( sym=='&' ) {
         index++;
         switch (substr(input,index,1)) {
         case '&':
            index++;
            sym='&&';
            break;
         }
      } else if ( sym=='|' ) {
         index++;
         switch (substr(input,index,1)) {
         case '|':
            index++;
            sym='||';
            break;
         }
      } else {
        index++;
      }
   } else if ( sym=='0' ) {
      first_ch := upcase(substr(input,index+1,1));
      if ( first_ch=='X' ) {
         hex_index := index;
         j := verify(input,'0123456789ABCDEFabcdef','',index+2);
         if ( ! j ) { j=length(input)+1; }
         index=j;
         sym=substr(input,index,1);
         if ( sym=='.' ) {
           index++;
           j=verify(input,'0123456789ABCDEFabcdef','',index);
           if ( ! j ) { j=length(input)+1; }
           index=j;
           sym=substr(input,index,1);
         }
         if ( upcase(sym)=='P' ) {
           index++;
           sym=substr(input,index,1);
           if ( sym=='+' || sym=='-' ) {
             index++;
           }
           if ( ! isinteger(substr(input,index,1)) ) { exp_error(); }
           j=verify(input,'0123456789','',index);
           if ( ! j ) { j=length(input)+1; }
           index=j;
           sym=substr(input,index,1);
         }

         sym=substr(input,index,1);

         end_index := index;
         index = hex_index;
         lex_number(16,end_index);

      } else if ( first_ch=='B' ) {
         lex_number(2,verify(input,'01','',index+2));
      } else {
         index--;
         if (def_leading_zero_is_decimal) {
            int i=verify(input,'0123456789','',index+1);
            if (i && pos(substr(input,i,1),'abcdef')) {
               exp_error_msg('Invalid decimal number');
            }
            if (!i) i=length(input)+1;
            sym=substr(input,index+1,i-index-1);
            index=i;
         } else {
            int i=verify(input,'01234567','',index+1);
            if (i && pos(substr(input,i,1),'89abcdef')) {
               exp_error_msg('Invalid octal number');
            }
            lex_number(8,i);
         }
      }
   } else if ( !gstrict_id_checking && upcase(sym)=='X' && pos(substr(input,index+1,1),'0123456789ABCDEFabcdef') ) {
      lex_number(16,verify(input,'0123456789ABCDEFabcdef','',index+1));
   } else if ( !gstrict_id_checking && upcase(sym)=='O' && pos(substr(input,index+1,1),'01234567') ) {
      lex_number(8,verify(input,'01234567','',index+1));
   } else if ( !gstrict_id_checking && upcase(sym)=='B' && pos(substr(input,index+1,1),'01') ) {
      lex_number(2,verify(input,'01','',index+1));
   } else if ( isalpha(sym) || sym=='_') {
      /* get the variable. */
      for (;;) {
        index++;
        if ( index>length(input) ) { break; }
        ch=substr(input,index,1);
        if ( ! isalnum(ch) ) {
          if ( ch!='_' ) { break; }
          //ch='-'
        }
        sym :+= ch;
      }
      if (gdefine_names!="") {
         if (gdefine_names=="=") {
            value="";
         } else {
            value=eq_name2value(sym,gdefine_names);
         }
         // strip off trailing 'U' or 'L' from number
         last_ch := upcase(_last_char(value));
         if (!isnumber(value) && isnumber(substr(value,1,length(value)-1)) && (last_ch=='U' || last_ch=='L')) {
            value=substr(value,1,length(value)-1);
         }
         if (!isnumber(value)) {
            value=hex2dec(strip(value));
            if (value=="") {
               if (gwarning!='' && !pos(' 'sym' ',*gpalready_warned_list,1,'i')) {
                  *gpalready_warned_list=*gpalready_warned_list' 'sym' ';
                  _message_box(nls(gwarning,sym));
               }
            }
         }
         sym=value;
         if (!isnumber(sym)) {
            sym=gdefault_value;
         }
      } else {
         index2:=find_index(sym,VAR_TYPE);
         if ( ! index2 ) {
            rc=nls("Can't find variable '%s'",sym);_resume();
         }
         sym= _get_var(index2);
      }
   } else {
      exp_error();
   }

}
static void lex_number(int base,int j)
{
   if ( ! j ) { j=length(input)+1; }
   // look for trailing 'U' or 'L' (unsigned or long)
   if (verify(input,'ULul','M',j)) {
      j = verify(input,'ULul','',j);
      if ( ! j ) { j=length(input)+1; }
   }
   sym=substr(input,index+1,j-index-1);
   sym=hex2dec(sym,base);
   if ( sym:=='' ) {
     exp_error();
   }
   index=j;
}
static void unary_exp()
{
   typeless e1="";
   if ( sym=='-' ) {
      nextsym();
      unary_exp();
      parse exp_stack with e1 exp_stack ;
      exp_stack=-e1 " "exp_stack;
   } else if ( sym=='~' ) {
      nextsym();
      unary_exp();
      parse exp_stack with e1 exp_stack ;
      exp_stack=~e1 " "exp_stack;
   
   } else if ( sym=='!' ) {
      nextsym();
      unary_exp();
      parse exp_stack with e1 exp_stack ;
      exp_stack=!e1 " "exp_stack;
   } else if ( sym=='+' ) {
      nextsym();
      unary_exp();
   } else if ( sym=='(' ) {
      nextsym();
      exp();
      if ( sym!=')' ) { exp_error(); }
      nextsym();
   } else if ( ! verify(sym,'.0123456789eE+-') ) {  /* float? */
      /* This if statement should check for float more closely. */
      exp_stack=sym " "exp_stack;
      nextsym();
   } else {
      exp_error();
   }

}
static void reduce_dualop(_str op="")
{
   typeless e1, e2;
   parse exp_stack with e2 e1 exp_stack ;
   if ( op=='&' ) {
      exp_stack=(e1&e2) " "exp_stack;
   } else if ( op=='|' ) {
      exp_stack=(e1|e2) " "exp_stack;
   } else if ( op=='+' ) {
      exp_stack=e1+e2 " "exp_stack;
   } else if ( op=='-' ) {
      exp_stack=e1-e2 " "exp_stack;
   } else if ( op=='*' ) {
      exp_stack=e1*e2 " "exp_stack;
#if 0
   } else if ( op=='???' ) {
      exp_stack=e1 intdiv e2 " "exp_stack
#endif
   } else if ( op=='%' ) {
      exp_stack=(e1%e2)" "exp_stack;
   } else if ( op=='/' ) {
      exp_stack=(e1/e2)" "exp_stack;
   } else if ( op=='**' ) {
      exp_stack=pow(e1,e2)" "exp_stack;
   } else if ( op=='^' ) {
      exp_stack=(e1^e2) " "exp_stack;
   } else if ( op=='||' ) {
      exp_stack=(e1||e2) " "exp_stack;
   } else if ( op=='&&' ) {
      exp_stack=(e1&&e2) " "exp_stack;
   } else if ( op=='==' ) {
      exp_stack=(e1==e2) " "exp_stack;
   } else if ( op=='!=' ) {
      exp_stack=(e1!=e2) " "exp_stack;
   } else if ( op=='<=' ) {
      exp_stack=(e1<=e2) " "exp_stack;
   } else if ( op=='>=' ) {
      exp_stack=(e1>=e2) " "exp_stack;
   } else if ( op=='>' ) {
      exp_stack=(e1>e2) " "exp_stack;
   } else if ( op=='<' ) {
      exp_stack=(e1<e2) " "exp_stack;
   } else if ( op=='<<' ) {
      exp_stack=(e1<<e2) " "exp_stack;
   } else if ( op=='>>' ) {
      exp_stack=(e1>>e2)" "exp_stack;
   }
}
static int prec_tab:[]={
   '$'=>0,

   '||'=>3,   //??
   '&&'=>4,   //??

   '|'=>6,   //??
   '^'=>7,   //??
   '&'=>8,   //??

   '!='=>9,  //??
   '=='=>9,  //??

   '<'=>10,
   '>'=>10,
   '<='=>10,
   '>='=>10,

   ':+'=>11,
   '<<'=>12,
   '>>'=>12,
   '+'=>13,
   '-'=>13,
   '*'=>14,
   '/'=>14,
   '%'=>14,
   '**'=>15,  // Raise to power operator
};
static void exp()
{
   orig_sym := "";
   _str op_stack[];
   op_stack[0]='$';
   vtop := 0;
   for (;;) {
      unary_exp();
      if ( !prec_tab._indexin(sym) || sym=='$') {  /* Not binary operator? */
         if ( verify(sym,'.0123456789eE+-') ) {  /* not a float */
             break;
         }
         orig_sym=sym;
         sym='+';
      } else {
         orig_sym='';
      }
      while ( prec_tab:[op_stack[vtop]]>=prec_tab:[sym] ) {
         reduce_dualop(op_stack[vtop]);
         --vtop;
      }
      op_stack[++vtop]=sym;
      if ( orig_sym=='' ) {
         nextsym();
      } else {
         sym=orig_sym;
      }
   }
   for (; vtop>0; --vtop) {
      reduce_dualop(op_stack[vtop]);
   }
}
/* Upon successful evaluation 0 is returned and */
/* result is set. On error 1 is returned.  */

/** 
 * Evaluates <i>expression</i> and places the result in the variable 
 * <i>result</i> in the <i>base</i> specified.  <i>base</i> may be 2,8, 10, or 
 * 16.
 * 
 * @return  Returns 0 if successfuland result is set. On error 1 is returned.
 * @categories Miscellaneous_Functions
 */
int eval_exp(_str &result,_str source,int base, ...)
{
   gstrict_id_checking=arg()>3;
   gdefine_names=arg(4);
   gdefault_value=arg(5);
   gwarning=arg(6);
   gpalready_warned_list= &arg(7);
   if (arg()>=4 && gdefine_names=="") gdefine_names="=";
   source=stranslate(source,'',',');
   source=stranslate(source,'','$');
   _suspend();
   if ( rc ) {
      if (isinteger(rc) && rc<0 ) {
         message(get_message(rc));
         return(rc);
      }
      if ( rc==1 ) {  /* No error? */
         return(0);
      } else {
         return(rc);
      }
   }
   index=1;
   input=source;
   nextsym();
   exp_stack='';
   exp();
   if ( sym!='$' ) {
      exp_error();
   }
   result=strip(exp_stack);
   if ( base!=10 && base!='' ) {
      if (!isinteger(result) && isnumber(result)) {
         // Result could be 134e1
         result=(typeless)result+0;
      }
      // Can't convert floating point number to hex.
      /*typeless l;
      parse result with l ".";
      result=dec2hex(l,base);*/
      result=dec2hex((typeless)result,base);
   }
   if ( result=='' ) {
      /* dec2hex will fail to convert float to hex or octal. */
      message(nls('Computation resulted in floating point number %s',exp_stack));
   }
   rc=1;_resume();
   // never hit this return
   return(1);
}


// Miller-Rabin primality test algorithm, using 32 samples
// Theoretical error rate is 2^-32, providing integer is at
// most 32-bit.

static int seed = 231;
int random(int low, int high)
{
   int i;
   for (i=481; i<511; i++) {
      seed = 1 + seed*seed % (13*(high-low+31) + 143*i);
      if (seed < 0) {
         seed = -seed;
      }
   }
   return (seed % (high-low+1)) + low;
}

static int witness(int a, int n)
{
   d := 1;
   k := 31;
   int m=n-1;
   while (k>0 && (m>>k)==0) {
      --k;
   }
   while (k>=0) {
      int x = d;
      d = (d*d) % n;
      //_message_box("a="a" d="d" x="x" k="k);
      if (d==1 && x!=1 && x!=n-1) {
         return 1;
      }
      if ((m>>k) & 1) {
         d = (d*a) % n;
      }
      --k;
   }

   //_message_box("d="d);
   return (d!=1)? 1:0;
}

// This function was used to find the lowest seed for the
// series S(n+1) = 2*S(n)+1, such that the most numbers in the
// series are primes.  This is useful for resizing a hash table
// dynamically but still hopefully landing on a prime number
// to use for the number of buckets.
//
// The winning result was (* indicates prime):
//     89* 179* 359* 719* 1439* 2879* 5759 11519* 23039* 46079 92159
//
/*
_command findseed()
{
   max_primes := 0;
   best_series := "";
   for (i=1; i<400; i+=2) {
      int j=i;
      num_primes := 0;
      this_series := "";
      while (j < 100000) {
         this_series :+= ' 'j;
         if (isprime(j)) {
            ++num_primes;
            this_series :+= '*';
         }
         j = j*2+1;
      }
      if (num_primes >= max_primes) {
         max_primes = num_primes;
         best_series=this_series;
      }
   }
   _message_box("The best seed for the series is "best_series);
   insert_line(best_series);
}
*/

/**
 * Test if the given integer is a prime number.
 * 
 * @param n       number to test
 * @param exact   use exact algorith, rather than fast approximate algorithm
 * 
 * @return 'true' if the number is prime, or believed to be prime.
 */
_command bool isprime(int n=0, bool exact=false)
{
   if (n <= 3) {
      message(n" is a prime number.");
      return true;
   }

   if (n % 2 == 0) {
      message(n" is divisible by 2.");
      return false;
   }
   if (n % 3 == 0) {
      message(n" is divisible by 3.");
      return false;
   }
   if (n > 5 && n % 5 == 0) {
      message(n" is divisible by 5.");
      return false;
   }

   int i;
   if (exact) {
      for (i=7; i*i<n; i+=2) {
         if (n % i == 0) {
            message(n" is divisible by "i".");
            return false;
         }
      }
   } else {
      for (i=1; i<32; i++) {
         int a = random(1, n-1);
         if (witness(a, n)) {
            message(n" is a composite number.");
            return false;
         }
      }
   }

   message(n" is a prime number.");
   return true;
}

/**
 * Find the next prime number starting from 'n'
 * 
 * @param 'n'     number to test
 * @param exact   use exact algorith, rather than fast approximate algorithm
 * 
 * @return the next prime number >= 'n'
 */
_command int nextprime(int n=0, bool exact=false)
{
   if (n > 2 && n % 2 == 0) {
      n++;
   }

   for (;;n+=2) {
      if (isprime(n,exact)) {
         return(n);
      }
   }
}

/**
 * @return Returns true value if <i>string</i> is a valid
 * hex number.
 *
 * @categories String_Functions
 *
 */
bool ishexnum(_str num)
{
   out := false;
   start := length(num);
   int i = start;
   for (i = start; i > 0; --i) {
      if (out) {
         return false;
      }
      ch := lowcase(substr(num,i,1));
      if (! (isdigit(ch) || ch == 'a' || ch == 'b' || ch == 'c' || ch == 'd' || ch == 'e' || ch == 'f')) {
         out = true;
      }
      if (ch == 'x' || ch == 'X') {
         if (i == 1 || (substr(num, i-1, 1) == 0 && i - 1 == 1)) {
            return true;
         }
      }
   }
   return true;
}

/**
 * @return Returns true if value is within +/- range of the target. 
 *  
 * @param value   value to test 
 * @param target  target value 
 * @param range   amount of tolerance    
 */
bool isapprox(typeless value, typeless target, typeless range)
{
   return ( value >= target-range && value <= target+range );
}
/**
 * Pretty format a decimal, hexadecimal, or binary number. 
 *  
 * @param number    Input number. Maybe have leading "0x" or 
 *                  "0b"
 * @param base      Input base.
 * @param sepchar   Separator character. Typically ',' for 
 *                  decimal numbers and ' ' (space) for
 *                  hexadecimal or binary numbers.
 * @param sepchar_every  Insert separator character at intervals
 *                       of this count. Typically this is 3 for
 *                       decimal numbers, 4 for hexadecimal
 *                       numbers, and 8 for binary numbers.
 * 
 * @return Returns the pretty formatting number.
 */
_str _pretty_number(_str number,int base=10,_str sepchar=',',int sepchar_every=3) {
   sign := "";
   suffix := "";
   if (base==10) {
      if (substr(number,1,1)=='-') {
         sign='-';
         number=substr(number,2);
      }
      j:=pos('.',number);
      if (!j) {
         j=pos('e',number,1,'i');
      }
      if (j) {
         suffix=substr(number,j);
         number=substr(number,1,j-1);
      }
   }
   prefix := "";
   if(substr(number,1,2)=='0x') {
      prefix='0x';
      number=substr(number,3);
   } else if(substr(number,1,2)=='0b') {
      prefix='0b';
      number=substr(number,3);
   }
   count := 0;
   for (i:=length(number);i>1;--i,++count) {
      if (count+1==sepchar_every) {
         number=substr(number,1,i-1):+sepchar:+substr(number,i);
         count= -1;
      }
   }
   return sign:+prefix:+number:+suffix;
}
