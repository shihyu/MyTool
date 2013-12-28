////////////////////////////////////////////////////////////////////////////////////
// $Revision: 41143 $
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
#import "markfilt.e"
#import "stdprocs.e"
#endregion

  static int index;
  static _str input;
  static _str exp_stack;
  static _str sym;
  static boolean gstrict_id_checking;
  static _str gdefine_names;  // name1=value1 name2=value2
                              // "=" for null
  static _str gdefault_value;
  static _str gwarning;             // Warning message with one %s.
  static _str *gpalready_warned_list; // List of space delimited variable names

  // By default, leading zeros indicate octal numbers like C++,Java, and C#.
  // Cobol programmers might like to set this to 1.
  // Warning: This variable effects ALL macro commands which do mathematical
  // expression calculation (seek, math, add select expression, etc.)
  boolean def_leading_zero_is_decimal;

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
   int first_col=0;
   int last_col=0;
   int buf_id=0;
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
   _str line="";
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
           result=result+tempresult;
        } else {
           result=result*tempresult;
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
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
typeless hex2dec(_str hex,int base=16)
{
   hex=strip(hex);
   int sign= 1;
   if ( substr(hex,1,1)=='-' ) {
      sign= -1;
      hex=substr(hex,2);
   }
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

   boolean doHex    = (base==16 && length(hex) <= 8);
   boolean doOctal  = (base==8 && length(hex) <= 10);
   boolean doBinary = (base==2 && length(hex) <= 32);

   typeless result=0;
   for (;;) {
      _str ch=upcase(substr(hex,1,1));
      if ( ch=='' ) { break; }
      int i=pos(ch,'0123456789ABCDEF');
      if ( ! i ) { return(''); }
      if ( doHex && i <= 16 ) {
         result = (result << 4) | (i-1);
      } else if ( doOctal && i <= 8 ) {
         result = (result << 3) | (i-1);
      } else if ( doBinary && i <= 2 ) {
         result = (result << 1) | (i-1);
      } else {
         result=result*base -1 +i;
      }
      hex=substr(hex,2);
   }
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
 * @param number          decimal number
 * @param base          may be 2 or 8 or 16.
 * @categories String_Functions
 */
_str dec2hex(long number, typeless base="")
{
   _str prefix="";
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
   if ( base == 16 && (number & 0xFFFFFFFFFFFFFFFF) == number ) {
      while ( number != 0 ) {
         digit := (int)(number & 0xF);
         result = substr("0123456789ABCDEF",digit+1,1):+result;
         number = number >> 4;
         number = number & 0xFFFFFFFFFFFFFFF;
      }
   } else if ( base == 8 && (number & 0xFFFFFFFFFFFFFFFF) == number ) {
      while ( number != 0 ) {
         digit := (int)(number & 0x7);
         result = digit:+result;
         number = number >> 3;
         number = number & 0x1FFFFFFFFFFFFFFF;
      }
   } else if ( base == 2 && (number & 0xFFFFFFFFFFFFFFFF) == number ) {
      while ( number != 0 ) {
         digit := (int)(number & 0x1);
         result = digit:+result;
         number = number >> 1;
         number = number & 0x7FFFFFFFFFFFFFFF;
      }
   } else {
      if ( number<0 ) {
         sign='-';
         number=-number;
      }
      while ( number>0 ) {
         int i=number intdiv base;
         result=substr('0123456789ABCDEF',number-i*base+1,1):+result;
         number=i;
      }
   }

   if ( result=='' ) { result='0'; } /* number must have been 0 */
   if (base==8 && result=='0') {
      return('0');
   }
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
static _str math_base(_str input,int base,_str num_prefix)
{
   input=prompt(input);
   int i=lastpos('=',input);
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
   _str msg="";
   if ( base!=10 && pos('-',result) ) {
      number=_negative2dec(result,base,msg);
      msg=msg' result='dec2hex(number,base);
   } else {
      typeless temp=hex2dec(result,base);
      if ( pos('.',temp) ) {   /* Can't display float in hex. */
         msg='dec='temp;
      } else {
         if ( pos('-',temp) ) {
            number=dec2hex(_negative2dec(temp,10,msg));
         } else {
            number=dec2hex(temp);
         }
         msg='dec='temp' hex='number;
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
   _str line='math'num_prefix " "input'= 'result;
   //command_put(line);sticky_message(msg);
   append_retrieve_command(line);
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
   _str ch="";
   typeless value=0;
   sym=substr(input,index,1);
   //IF is is the start of a decimal number or operator
   if ( pos(sym,'123456789.><!=~#^&|+-/*%()') ||
      (sym:=='0' && substr(input,index+1,1):=='.') ) {
      if ( isinteger(sym) || sym=='.' ) {
        int oldi=index;
        if ( sym=='.' ) { index=index+1; }
        sym=substr(input,index,1);
        if ( ! isinteger(substr(input,index,1)) ) { exp_error(); }
        int j=verify(input,'0123456789','',index);
        if ( ! j ) { j=length(input)+1; }
        index=j;
        sym=substr(input,index,1);
        if ( sym=='.' ) {
          index=index+1;
          j=verify(input,'0123456789','',index);
          if ( ! j ) { j=length(input)+1; }
          index=j;
          sym=substr(input,index,1);
        }
        if ( upcase(sym)=='E' ) {
          index=index+1;
          sym=substr(input,index,1);
          if ( sym=='+' || sym=='-' ) {
            index=index+1;
          }
          if ( ! isinteger(substr(input,index,1)) ) { exp_error(); }
          j=verify(input,'0123456789','',index);
          if ( ! j ) { j=length(input)+1; }
        }
        sym=substr(input,oldi,j-oldi);
        index=j;
      } else if ( sym=='*' ) {
        index=index+1;
        if ( substr(input,index,1)=='*' ) {
          index=index+1;
          sym='#';
        }
      } else if ( sym=='>' ) {
         index=index+1;
         switch (substr(input,index,1)) {
         case '>':
            index=index+1;
            sym='>>';
            break;
         case '=':
            index=index+1;
            sym='>=';
            break;
         }
      } else if ( sym=='<' ) {
        index=index+1;
        switch (substr(input,index,1)) {
        case '<':
           index=index+1;
           sym='<<';
           break;
        case '=':
           index=index+1;
           sym='<=';
           break;
        }
      } else if ( sym=='=' ) {
         index=index+1;
         switch (substr(input,index,1)) {
         case '=':
            index=index+1;
            sym='==';
            break;
         default:
            exp_error();
         }
      } else if ( sym=='!' ) {
         index=index+1;
         switch (substr(input,index,1)) {
         case '=':
            index=index+1;
            sym='!=';
            break;
         }
      } else if ( sym=='&' ) {
         index=index+1;
         switch (substr(input,index,1)) {
         case '&':
            index=index+1;
            sym='&&';
            break;
         }
      } else if ( sym=='|' ) {
         index=index+1;
         switch (substr(input,index,1)) {
         case '|':
            index=index+1;
            sym='||';
            break;
         }
      } else {
        index=index+1;
      }
   } else if ( sym=='0' ) {
      _str first_ch=upcase(substr(input,index+1,1));
      if ( first_ch=='X' ) {
         lex_number(16,verify(input,'0123456789ABCDEFabcdef','',index+2));
      } else if ( first_ch=='B' ) {
         lex_number(2,verify(input,'01','',index+2));
      } else {
         index=index-1;
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
        index=index+1;
        if ( index>length(input) ) { break; }
        ch=substr(input,index,1);
        if ( ! isalnum(ch) ) {
          if ( ch!='_' ) { break; }
          //ch='-'
        }
        sym=sym:+ch;
      }
      if (gdefine_names!="") {
         if (gdefine_names=="=") {
            value="";
         } else {
            value=eq_name2value(sym,gdefine_names);
         }
         // strip off trailing 'U' or 'L' from number
         last_ch := upcase(last_char(value));
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
         index=find_index(sym,VAR_TYPE);
         if ( ! index ) {
            rc=nls("Can't find variable '%s'",sym);_resume();
         }
         sym= _get_var(index);
      }
   } else {
      exp_error();
   }

}
static void lex_number(int base,int j)
{
   if ( ! j ) { j=length(input)+1; }
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
   } else if ( op=='#' ) {
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
   '#'=>15,  // Raise to power operator
};
static void exp()
{
   _str orig_sym="";
   _str op_stack[];
   op_stack[0]='$';
   int vtop=0;
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
   index=1;input=source;nextsym();
   exp_stack='';
   exp();
   if ( sym!='$' ) {
      exp_error();
   }
   result=strip(exp_stack);
   if ( base!=10 && base!='' ) {
      typeless l;
      parse result with l ".";
      result=dec2hex(l,base);
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
#define MILLER_RABIN_SAMPLES 32

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
   int d=1;
   int k=31;
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
   int max_primes=0;
   _str best_series='';
   for (i=1; i<400; i+=2) {
      int j=i;
      int num_primes=0;
      _str this_series='';
      while (j < 100000) {
         this_series=this_series' 'j;
         if (isprime(j)) {
            ++num_primes;
            this_series=this_series'*';
         }
         j=j*2+1;
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
_command boolean isprime(int n=0, boolean exact=false)
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
_command int nextprime(int n=0, boolean exact=false)
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
boolean ishexnum(_str num)
{
   boolean out = false;
   int start = length(num);
   int i = start;
   for (i = start; i > 0; --i) {
      if (out) {
         return false;
      }
      _str ch = lowcase(substr(num,i,1));
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
boolean isapprox(typeless value, typeless target, typeless range)
{
   return ( value >= target-range && value <= target+range );
}
