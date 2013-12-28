void munge(int& x)
{
    if (x > 10 || x < 0) {
        x = 0;
    }

    switch (x) {
    case 0:
        x++;
        break;
    default:
        x += 3;
    }
	bork();
}
