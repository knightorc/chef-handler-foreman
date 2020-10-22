Version 0.2.3 (2020-10-22)

* Fix literal '\n' to "\n" so  template/cookbook\_file output is converted to include a new line
* Fix/Happen action :Symbol rather than Array of :Symbol

Version 0.2.2 (2020-07-08)

* Support Chef 15/16 clients using updated legacy type 2 way.
* Fix double `/` in concatenated url
* Since we're behind a smartproxy switch back to reports rather that config\_reports

Version 0.2.1 ???

Version 0.2.0 ???

Version 0.1.2

* compatibility with configuration via chef-client cookbook
* why-run reports resources as pending
* Chef 13 compatibility

Version 0.1.1

* node name is always reported downcased

Version 0.1.0

* add support for chef-clients running on Windows

Version 0.0.9
* add more configuration options - whitelisting and blacklisting attributes
* support for attributes caching

Version 0.0.1 - 0.0.8
* handlers for uploading facts and reports
