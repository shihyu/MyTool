@interface StandardRep
+ (NSString)convertTo: (id)tyrep 
           maxColumns: (int)maxcol, ...;
@end

class Foo : public Bar
{
public:
    Foo();
    Foo(int cap, bool resize = false);
    virtual char* baz() = 0;
};


Foo::Foo(int cap, bool resize) : a(cap), b(resize)
{
}
