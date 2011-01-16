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
    end
    
    class << self
      def run(argv)
        self.new.execute(argv)
      end
    end
  end
end
