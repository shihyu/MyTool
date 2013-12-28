#include <string>

typedef void (*ActionFn)(int& index, const char* n);

void Run(ActionFn f, const char* txt, int*& nr)
{
    static int x;

    nr = &x;
    (*f)(x, txt);

    // C++11 rvalue reference.
    std::string&& s = std::string();
}


