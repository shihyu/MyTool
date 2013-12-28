void consume(Node *n, int x)
{
    while (n && [n isdead]) {
        eat(n);
        n = [n next];
    }

    do {
        n = [n next];
    } while (n && [n isdead]);
	bork();
}
