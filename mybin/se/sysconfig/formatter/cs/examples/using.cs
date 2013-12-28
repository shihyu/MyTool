void Boid(byte[] m)
{
	using (ISink s = acquireSink(),ISrc hdr = makeHeader()) {
		s.Feed(hdr);
		s.Feed(m);
	}
        triggerCallbacks();
}
