////////////////////////////////////////////////////////////////////////////////////
// Copyright 2020 SlickEdit Inc. 
// You may modifycopyand distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit namelogos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnifyhold harmless and defend SlickEdit from and 
//       against any lossdamageclaims or lawsuitsincluding attorney's fees
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#ifndef MATH_SH
#define MATH_SH
#pragma option(metadata,"math.e")

/** 
 * Useful numerical constants computed to 80 or 81 digits.
 */
namespace math {

   /**
    * Pi calculated to 80 digits.
    */
   const Pi = "3.141592653589793238462643383279502884197169399375105820974944592307816406286209";

   /**
    * Phi - golden ratio
    */
   const Phi = "1.618033988749894848204586834365638117720309179805762862135448622705260462818902";

   /**
    * e - Euler's number
    */
   const Euler = "2.718281828459045235360287471352662497757247093699959574966967627724076630353548";

   /**
    * sqrt(2) - Square root of 2
    */
   const Sqrt2 = "1.414213562373095048801688724209698078569671875376948073176679737990732478462107";

   /**
    * log(2)
    */
   const Log2 = "0.6931471805599453094172321214581765680755001343602552541206800094933936219696947";

   /**
    * log(10)
    */
   const Log10 = "2.302585092994045684017991454684364207601101488628772976033327900967572609677352";

   /**
    * Gauß’s constant (Guass's constant)
    */
   const G = "0.8346268416740731862814297327990468089939930134903470024498273701036819927095264";

   /**
    * Laplace limit
    */
   const Laplace = "0.6627434193491815809747420971092529070562335491150224175203925349909718530865113";

};


#endif // MATH.SH
