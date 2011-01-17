#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'digest/md5'
require 'rubygems'
require 'mutter'

module Bookscan
  class Books < Array
    def to_s
      table = Mutter::Table.new(:delimiter => '|') do
        column :style => :green
        column :width => 60
      end
      
      each do |b|
        table << [b.id,b.title]
      end
      table.to_s if length > 0
    end

    def ids
      a = Array.new
      each do |b|
        a << b.id
      end
      a
    end

    def by_id(book_id)
      each do |b|
        return b if b.id == book_id
      end
    end

    def has?(book_id)
      each do |b|
        return true if b.id == book_id
      end
      false
    end
  end

  class Book
    attr_accessor :url,:title,:group_url

    def to_s
      @title
    end

    def filename
      return @title if isbn
      if /(.*)\.pdf$/ =~ @title
        return $1 + "_" + id + ".pdf"
      end
      raise "Can't make filename"
    end

    def isbn
      return $1 if /_([0-9a-zA-Z]+)_s\.pdf$/ =~ @title
      return $1 if /_([0-9a-zA-Z]+)\.pdf$/ =~ @title
    end

    def id
      return isbn if isbn
      Digest::MD5.hexdigest(@title).to_s[1,10]
    end

  end
end
