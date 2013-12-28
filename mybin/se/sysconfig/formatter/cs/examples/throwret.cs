private void eval(String x)
{
    if (!x) 
        throw (new BadParam());

    return (eval_intern(x, gEnvironment));
}
