int& GetSomething();
typedef int*& (*SomeFnPtrRef)(char);

char& boid(int& r1, int*&r2, int&)
{
   long& x = (long&)r1;
}




