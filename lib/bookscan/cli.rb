#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'optparse'
require 'bookscan/commands'

module Bookscan
  class CLI
    def initialize
      @options = Hash.new
      @options[:debug] = false
    end

    def execute(argv)
      begin
        @opt = OptionParser.new
        @opt.on('--version', 'show version') { version;exit }
        @opt.on('--help', 'show this message') { usage;exit }
        @opt.on('--debug', 'debug mode') { @options[:debug] = true }
        cmd_argv = @opt.order!(argv)
        cmd = cmd_argv.shift
        Commands.new(cmd_argv,@options).send(cmd)
      rescue =>e
        puts e
        usage
        raise e if @options[:debug]
      end
    end

    def usage(e=nil)
      puts @opt
      puts "\nCommands:\n"
      COMMANDS.each { |c|
        puts "    " + c
      }
    end
    
    def version
      File.open(File.dirname(__FILE__) + '/../../VERSION',"r") { |file|
        puts file.gets
      }
    end
    
    class << self
      def run(argv)
        self.new.execute(argv)
      end
    end
  end
end
