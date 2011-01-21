#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'digest/md5'
require 'uri'
require 'rubygems'
require 'mutter'

require 'bookscan'
module Bookscan
  class Books < Array
    def to_s
      table = Mutter::Table.new(:delimiter => '|') do
        column :style => :green
        column :width => 100
      end
      
      each do |b|
        table << [b.book_id,b.title_short]
      end
      table.to_s if length > 0
    end

    def ids
      a = Array.new
      each do |b|
        a << b.book_id
      end
      a
    end

    def by_id(book_id,type = nil)
      each do |b|
        next if type and b.tune_type != type
        return b if b.book_id == book_id
      end
      nil
    end

    def has?(book_id)
      each do |b|
        return true if b.book_id == book_id
      end
      false
    end
  end

  class Book
    attr_accessor :url,:title,:group_url
    def tune_url
      "/bookoptimize.php?hash=%s&d=%s&filename=%s" % [hash,d,URI.encode(@title)]
    end
    def d
      return $1 if /.*download.php\?d=([^&]+)/ =~ @url
    end
    def hash
      return $1 if /.*bookdetail.php\?hash=(.*)/ =~ @group_url
    end

    def to_s
      @title
    end

    def title_short
      @title.sub(/\.pdf$/,"").
        sub(/_s$/,"").
        sub(/_[0-9a-zA-Z]+$/,"")
    end

    def filename
      return @title if isbn
      if /(.*)\.pdf$/ =~ @title
        return $1 + "_" + book_id + ".pdf"
      end
      raise "Can't make filename"
    end

    def tune_type
      if TUNED_PATTERN =~ title
        return $2
      end
      nil
    end

    def isbn
      return $1 if /_([0-9a-zA-Z]+)_s\.pdf$/ =~ @title
      return $1 if /_([0-9a-zA-Z]+)\.pdf$/ =~ @title
    end

    def book_id
      return isbn if isbn
      title = @title
      if TUNED_PATTERN =~ title
        title = $3
      end
      title.gsub!(/_s\.pdf$/,".pdf")
      Digest::MD5.hexdigest(title).to_s[1,10]
    end

  end
end

