# -*- coding: utf-8 -*-
module Bookscan
  BSURL = "http://system.bookscan.co.jp"
  TUNE_TYPES = ["ipad","iphone4","kindle3","kindledx","android","sonyreader","nook","jpg"]
  TUNED_PATTERN = /((iphone4|ipad|kindle3|kindledx|android|sonyreader|nook|jpg)_([^>]*\.pdf))/
end
