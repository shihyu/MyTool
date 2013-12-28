public int boid()
{
   // No parens.
   throw new Badness(EC_BAD); 

   // Has parens.
   throw (new Badness(EC_DEFINITELY_BAD)); 
   
   // Has parens.
   return (1);
   return (1+2); 

   // No parens
   return 2; 
   return 2+1; 
}
