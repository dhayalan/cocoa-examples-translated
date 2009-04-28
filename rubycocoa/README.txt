If you add a new project, you might be interested in
sandbox/bin/testify. It will convert an Xcode project into
one that:

1) has a Rakefile to build it.
2) has its loadpath adjusted so as not to load local gems
   and libraries (so that you won't accidentally produce a
   version that is missing dependencies).
3) has a test directory with the correct load-path hackery
   to let you test the app with Shoulda and Assert{2.0}.

Just go to the project's root directory and run testify.
   
   
