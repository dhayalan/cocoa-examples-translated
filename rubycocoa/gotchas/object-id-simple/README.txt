This directory shows that sometimes the following statement
is false when the array is an NSArray.

   array[0].object_id == array[0].object_id

If the object at location 0 is an Objective-C object, it can
get a new "Ruby half" (aka Ruby Proxy) each time it's
extracted. 

1.rb is an example that shows the object_id changing each
time an array element is extracted. 

2.rb should show the changing object_id for an NSDictionary
and NSString. It also shows that it doesn't happen for an
NSButton.

3.rb goes even further. It shows that you can extract an
NSTextField gazillions of times without ever losing object
identity. In ../singleton-death, you can see a case where a
CoreData object sometimes retains its identity and sometimes
doesn't. 
   
