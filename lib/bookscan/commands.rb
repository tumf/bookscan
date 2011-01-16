#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'pstore'

require "rubygems"
require "highline/import"

$:.unshift('/Users/tumf/projects/keystorage/lib')
require "keystorage"

require "bookscan/agent"

module Bookscan
  class Commands
    def initialize(cmd_options,options)
      @options = options
      @command_options = cmd_options
      @agent = Agent.new
      @cache_file =  ENV['HOME']+"/.bookscan.cache"
    end
    def login
      email = ask('Enter email: ') do |q|
        q.validate = /\w+/
      end

      ok = false
      while(!ok) 
        password = ask("Enter your password: ") do |q|
          q.validate = /\w+/
          q.echo = false
        end

        @agent.login(email,password)
        if @agent.login? # => OK
          ok = true
          Keystorage.set("bookscan",email,password)
          puts "login OK"
        else
          puts "password mismatch"
        end

      end
    end

    def logout
      Keystorage.delete("bookscan")
    end

    def start
      return true if @agent.login?
      email =  Keystorage.list("bookscan").shift
      if email
        @agent.login(email,Keystorage.get("bookscan",email))
        unless @agent.login?
          login
        end
      else
        login
      end
    end

    def update
      start
      all = false
      opt = OptionParser.new
      opt.on('-a','--all', 'update all cache') do
        all = true
      end
      opt.on('-g HASH','--group=HASH', 'update group') do |v|
        hash = v
      end
      opt.parse(@command_options)
      PStore.new(@cache_file).transaction do |cache|
        cache["groups"] = @agent.groups
      end
    end

    def groups
      gs = nil
      PStore.new(@cache_file).transaction do |ps|
        gs = ps["groups"]
      end
      raise "No groups in cache do 'bookscan update' first." unless gs
      puts gs.to_s
    end

    def list
      gs = nil
      PStore.new(@cache_file).transaction do |ps|
        gs = ps["groups"]
      end
      raise "No groups in cache do 'bookscan update' first." unless gs

      opt = OptionParser.new
      hash = nil
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.parse(@command_options)

      unless hash
        puts ps["groups"].to_s
        hash = ask('Enter hash: ',ps["groups"].hashes) do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end

      @agent.logout
    end
    
  end
end
