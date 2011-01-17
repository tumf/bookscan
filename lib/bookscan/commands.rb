#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "highline/import"

$:.unshift('/Users/tumf/projects/keystorage/lib')
require "keystorage"

require "bookscan/agent"
require "bookscan/cache"

module Bookscan
  class Commands
    def initialize(cmd_options,options)
      @options = options
      @command_options = cmd_options
      @agent = Agent.new
      @cache_file =  ENV['HOME']+"/.bookscan.cache"
      @cache = Cache.new(@cache_file)
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
      hash = false

      opt = OptionParser.new
      opt.on('-a','--all', 'update all cache') do
        all = true
      end
      opt.on('-g HASH','--group=HASH', 'update group') do |v|
        hash = v
      end
      opt.parse!(@command_options)

      gs = @agent.groups
      if all
        gs.each_index do |index|
          gs[index].books = @agent.books(gs[index])
        end
      elsif hash
        i = gs.to_index(hash)
        gs[i].books = @agent.books(gs[i]) if gs[i]
      else
        gs.each_index do |index|
          gs[index].books = @cache.books(gs[index])
        end
      end
      @cache.transaction do |cache|
        cache["groups"] = gs
      end

    end

    def groups
      gs = @cache.groups
      puts gs.to_s
    end

    def list
      gs = @cache.groups

      opt = OptionParser.new
      hash = nil
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.parse!(@command_options)

      unless hash
        puts gs.to_s
        hash = ask('Enter hash: ',gs.hashes) do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end

      g = gs.by_hash(hash)
      puts g.books.to_s
    end

    def download
      opt = OptionParser.new
      directory = "."
      hash = nil
      opt.on('-d DIR','--directory=DIR', 'download directory') do |v|
        directory = v
      end
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.parse!(@command_options)
      book_id = @command_options.shift

      gs = @cache.groups
      unless book_id
        unless hash
          puts gs.to_s
          hash = ask('Enter hash: ',gs.hashes) do |q|
            q.validate = /\w+/
            q.readline = true
          end
          g = gs.by_hash(hash)

          puts g.books.to_s

          book_id = ask('Enter book id: ',g.books.ids) do |q|
            q.validate = /\w+/
            q.readline = true
          end

        end
      end
      book = gs.book(book_id)
      # download
      start
      path = directory + "/" +book.filename
      puts "download: " + path
      @agent.download(book.url,path)
    end

    def tune
      
    end

    def tuned

    end

  end
end
