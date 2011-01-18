#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "highline/import"

require "keystorage"

require "bookscan"
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
          gs[index].books = @cache.books(gs[index]) rescue {}
        end
      end
      ts  = @agent.tuned

      @cache.transaction do |cache|
        cache["groups"] = gs
        cache["tuned"] = ts
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

    def ask_tuned_book_id(book_id,type)
      unless type
        type = ask('Enter tune type: ',TUNE_TYPES) do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end
      ts = @cache.tuned
      ts.collect! do |i|
        i if i.tune_type == type
      end.compact!
      raise "No tuned in cache. Exceute 'bookscan update' first." unless ts.length > 0
      unless book_id
        puts ts.to_s
        book_id = ask('Enter book id: ',ts.ids) do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end
      ts.by_id(book_id)
    end

    def ask_book_id(book_id,hash)
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
      gs.book(book_id)
    end

    def download
      opt = OptionParser.new
      directory = "."
      hash = nil
      type = nil
      dry_run = false
      opt.on('-d DIR','--directory=DIR', 'download directory') do |v|
        directory = v
      end
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.on('-t TYPE','--tuned=TYPE', 'download tuned') do |v|
        type = v
      end
      opt.on('--dry-run', 'dry-run mode') do |v|
        dry_run = true
      end
      opt.parse!(@command_options)
      book_id = @command_options.shift

      if book_id == "all"
        if type
          bs = @cache.tuned
        else
          bs = @cache.books
        end
        bs.each { |book|
          if Dir.glob(directory + "/**/*" + book.book_id + "*.pdf").length == 0
            path = directory + "/" +book.filename
            puts "download: " + path
            unless dry_run
              start
              @agent.download(book.url,path)
            end
          end
        }
      else
        if type
          book = ask_tuned_book_id(book_id,type)
        else
          book = ask_book_id(book_id,hash)
        end
        
        # download
        path = directory + "/" +book.filename
        puts "download: " + path
        unless dry_run
          start
          @agent.download(book.url,path)
        end
      end

    end

    def tune
      opt = OptionParser.new
      hash = nil
      dry_run = false
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.on('--dry-run', 'dry-run mode') do |v|
        dry_run = true
      end
      opt.parse!(@command_options)
      book_id = @command_options.shift
      type =  @command_options.shift
      unless type
        type = ask('Enter tune type: ',TUNE_TYPES) do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end

      if book_id == "all"
        tuned = @cache.tuned
        bs = @cache.books
        bs.each { |book|
          unless @cache.tuned?(book,type)
            # tune
            unless dry_run
              start
            end
            puts "tune for %s: %s" % [type, book.title] if dry_run or @agent.tune(book,type)
          end
        }
      else
        book = ask_book_id(book_id,hash)
        # tune
        puts "tune for %s: %s" % [type, book.title]
        unless dry_run
          start
          @agent.tune(book,type)
        end
      end
    end

    def tuning
      start
      books = @agent.tuning
      puts books.to_s
    end

    def tuned
      puts @cache.tuned.to_s
    end

  end
end
