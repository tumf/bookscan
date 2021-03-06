bookscan
========

This is a scraper of Bookscan (http://www.bookscan.co.jp) Service.This is *NOT* a official software of Bookscan.

Install
-------

    gem install bookscan
 
Usage
-----

    bookscan [global options] command [command options]

### GlobalOptions

* --debug
* --help
* --version

### Commands

* help [command]
* login
* logout
* update [-a,--all] [-g,--group=HASH]
* download [--dry-run] [-g,--group=HASH] [-t,--tuned=TYPE] [-m,--match=PATTERN] _id_ | all
* tune [--dry-run]  [-m,--match=PATTERN] _id_ | all _type_
* list [-g,--group=HASH] [-t,--tuned=TYPE] [-m,--match=PATTERN]
* tuning
* groups

Contributing to bookscan
-------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011-2013 Yoshihiro TAKAHARA. See LICENSE.txt for further details.

![http://coderwall.com/tumf](http://api.coderwall.com/tumf/endorsecount.png)

