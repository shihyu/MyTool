@implementation AppDelegate

- (id)initWith: (NSString*)aName{
    self = [super init];
    if (self) {
            [defaultCenter addObserver:self
                                                     selector:@selector(handleEnteredFullScreenNotification:)
                                                         name:aName
                                                       object:mainWin];
        m_lionWindowSetupComplete = YES;
        if(macOSX_Version() >= Lion) {
            m_lionWindowSetupComplete = NO;
        }
    }
    return self;
}

- (void)dealloc{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if(m_dockMenu != nil) {
        [m_dockMenu release];
        m_dockMenu = nil;
    }
    [super dealloc];
}
@end
