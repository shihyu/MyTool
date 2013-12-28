void eval(const char* x)
{
    if (!x) 
        @throw (BadParam);

    return (eval_intern(x, gEnvironment));
}
