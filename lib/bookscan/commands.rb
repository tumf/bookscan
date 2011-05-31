#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "highline/import"

require "keystorage"

require "bookscan"
require "bookscan/agent"
require "bookscan/cache"

module Bookscan
  COMMANDS = ["list","help", "login","logout","download","tune","update",
             "groups","tuned","tuning"]

  class Commands
    def initialize(cmd_options,options)
      @options = options
      @command_options = cmd_options
      @agent = Agent.new
      @cache_file =  ENV['HOME']+"/.bookscan.cache"
      @cache = Cache.new(@cache_file)
      @help = false
      @banner = ""
    end

    def help
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = "command"
      return opt if @help
      @help = true
      command = @command_options.shift
      raise "Unknown command: " + command unless COMMANDS.include?(command)
      opt = send(command)
      opt.banner="Usage: bookscan [options] #{command} #{@banner}"
      puts opt

    end

    def login
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = ""
      return opt if @help

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
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = ""
      return opt if @help

      Keystorage.delete("bookscan")
    end

    def update
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
      @banner = ""
      return opt if @help

      start
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
          books = @cache.books(gs[index]) rescue {}

          if gs[index].completed?
            if (books == nil or books.length == 0)
              gs[index].books = @agent.books(gs[index])
            else
              gs[index].books = books
            end
          end

        end
      end
      ts  = @agent.tuned

      @cache.transaction do |cache|
        cache["groups"] = gs
        cache["tuned"] = ts
      end
    end

    def groups
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = ""
      return opt if @help
      gs = @cache.groups
      puts gs.to_s
    end

    def list
      gs = @cache.groups

      opt = OptionParser.new
      hash = nil;type = nil;pattern = ".*"
      browsing = true;
      opt.on('-g HASH','--group=HASH', 'group hash') { |v|  hash = v; browsing = false }
      opt.on('-t TYPE','--tuned=TYPE', 'download tuned') { |v| type = v; browsing = false }
      opt.on('-m PATTERN','--match=PATTERN','pattern match') { |v| pattern  = v; browsing = false }
      opt.parse!(@command_options)
      @banner = "[command options]"
      return opt if @help

      if hash or browsing
        puts ask_group(hash,gs).books.to_s
      else
        if type
          bs = @cache.tuned.delete_if { |i| !(/#{pattern}/ =~ i.title) or i.tune_type != type }
        else
          bs = @cache.books.delete_if { |i| !(/#{pattern}/ =~ i.title) }
        end
        puts bs.to_s
      end
    end

    def download
      opt = OptionParser.new
      directory = "."
      hash = nil;type = nil;pattern = ".*"; dry_run = false
      opt.on('-d DIR','--directory=DIR', 'download directory') do |v|
        directory = v
      end
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.on('-t TYPE','--tuned=TYPE', 'download tuned') do |v|
        type = v
      end
      opt.on('-m PATTERN','--match=PATTERN','pattern match') do |v|
        pattern  = v
      end
      opt.on('--dry-run', 'dry-run mode') do |v|
        dry_run = true
      end
      opt.parse!(@command_options)
      @banner = "[command options] isbn|all"
      return opt if @help

      book_id = @command_options.shift

      if book_id == "all"
        if type
          bs = @cache.tuned.select { |i|
            /#{pattern}/ =~ i.title
          }
        else
          bs = @cache.books.select { |i|
            /#{pattern}/ =~ i.title
          }
        end
        bs.each { |book|
          next unless book.tune_type == type
          if Dir.glob(directory + "/**/*" + book.book_id + "*.pdf").length == 0
            path = directory + "/" +book.filename
            puts "=> " + path
            unless dry_run
              start
              @agent.download(book.url,path)
            end
          end
        }
      else
        if type
          book = ask_tuned_book_id(book_id,type,pattern)
        else
          book = ask_book_id(book_id,hash,pattern)
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
      hash = nil; pattern = ".*"; dry_run = false; to = nil
      opt.on('-g HASH','--group=HASH', 'group hash') do |v|
        hash = v
      end
      opt.on('--dry-run', 'dry-run mode') do |v|
        dry_run = true
      end
      opt.on('-m PATTERN','--match=PATTERN','pattern match') do |v|
        pattern  = v
      end
      opt.on('--to=dest', 'file to external storage: e.g. Dropbox') do |v|
        to = v
      end
      opt.parse!(@command_options)
      @banner = "[command options] isbn|all tune_type"
      return opt if @help

      book_id = @command_options.shift
      type = ask_tune_type(@command_options.shift)

      if book_id == "all"
        start unless dry_run
        unless dry_run
          @cache.transaction do |cache|
            cache["tuned"] = @agent.tuned
          end
        end
        @cache.books(hash).each { |book|
          next unless /#{pattern}/ =~ book.title
          unless @cache.tuned?(book,type)
            # tune
            puts "tune for %s: %s" % [type, book.title] if dry_run or @agent.tune(book,{:type => type, :to => to, :is_premium => true})
            # puts "tune for %s: %s" % [type, book.title]
          end
        }
      else
        book = ask_book_id(book_id,hash,pattern)
        # tune
        puts "tune for %s: %s" % [type, book.title]
        unless dry_run
          start
          @agent.tune(book,{:to => to,:type => type})
        end
      end
    end

    def tuning
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = ""
      return opt if @help

      start
      books = @agent.tuning
      puts books.to_s
    end

    def tuned
      opt = OptionParser.new
      opt.parse!(@command_options)
      @banner = ""
      return opt if @help
      puts @cache.tuned.to_s
    end

    private


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

    def ask_group(hash,gs)
      unless hash
        puts gs.to_s
        hash = ask('Enter hash ([q]uit): ',gs.hashes << 'q') do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end
      raise SystemExit if hash == "q"

      gs.by_hash(hash)
    end

    def ask_tune_type(type)
      unless type
        type = ask('Enter tune type ([q]uit): ',TUNE_TYPES.clone << 'q') do |q|
          q.validate = /\w+/
          q.readline = true
        end
      end
      raise SystemExit if type == "q"
      type
    end

    def ask_tuned_book_id(book_id,type,pattern)
      type = ask_tune_type(type)

      ts = @cache.tuned.delete_if do |i|
        i.tune_type != type
      end

      raise "No tuned in cache. Exceute 'bookscan update' first." unless ts.length > 0
      return ask_book_id_pattern(book_id,ts,pattern)
    end

    def ask_book_id_pattern(book_id,books,pattern)
      bs = books.clone.delete_if { |i|
        !(/#{pattern}/ =~ i.title)
      }
      unless book_id
        puts bs.to_s
        book_id = ask('Enter book id ([q]uit): ',bs.ids << 'q') do |q|
          q.validate = /\w+/
          q.readline = true
        end
        raise SystemExit if book_id == "q"
      end
      bs.by_id(book_id)
    end

    def ask_book_id(book_id,hash,pattern)
      unless  pattern == ".*"
        return ask_book_id_pattern(book_id,@cache.books,pattern)
      end

      gs = @cache.groups
      unless book_id
        g = ask_group(hash,gs)
        puts g.books.to_s
        book_id = ask('Enter book id ([q]uit): ',g.books.ids << 'q') do |q|
          q.validate = /\w+/
          q.readline = true
        end
        raise SystemExit if book_id == "q"
      end
      gs.book(book_id)
    end

  end
end
