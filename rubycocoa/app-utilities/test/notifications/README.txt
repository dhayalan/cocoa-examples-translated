As far as I can tell, you can't unit-test things that
require the run loop to be running. At least, I can't get
NSApp.stop to actually stop it. 

That means testing the behavior of
NSDistributedNotificationCenters or things built on top of
them have to fake with regular notifications. 
