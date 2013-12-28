typedef char const* volatile * t1;
typedef const char* t2;
typedef char* t3;

class SomeClass;
void action(void (*f1)(int**,char&), void (*)(), void (SomeClass::*meth_ptr)(), 
            void (SomeClass::*member_ptr));

char* boid(char* i, int& x, int*& y, int **&z, char* arr[][], void* vv)
{
    int val = 0;
    int *a(&val);
    int& b(*a);
    int*& c(a);
    int **d = z;

    a = (int*)vv;
}
