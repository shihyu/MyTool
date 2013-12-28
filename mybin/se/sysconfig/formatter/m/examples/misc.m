const char* GetName()
{
    if (random() == 42) {
        throw Heisenbug;
    }
    return "SomeName";
}
