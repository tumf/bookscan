#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'bookscan/cli'
Bookscan::CLI::run(ARGV)
exit

require 'optparse'


require 'rubygems'
require 'highline'
require 'mutter'

require 'moat';include Moat

load_passwords

Moat::SITES[@site] = {:username => username, :password => password }
show_credentials_for(@site) if @generated
save_passwords


