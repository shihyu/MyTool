void boid(char const *c, unsigned int len, char d)
{
   std::for_each(c, c+len,
                 [ = ](char x)->char{return (d + x);});
}
