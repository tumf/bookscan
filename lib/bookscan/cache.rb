#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'pstore'

module Bookscan
  class Cache < PStore

    def groups
      gs = nil
      transaction do |ps|
        gs = ps["groups"]
      end
      raise "No groups in cache. Exceute 'bookscan update' first." unless gs
      gs
    end

    def tuned
      ts = nil
      transaction do |ps|
        ts = ps["tuned"]
      end
      ts_uniq = Books.new
      ts.each { |t|
        unless ts_uniq.find { |i| i.title == t.title }
          ts_uniq << t
        end
      }
      return ts_uniq.compact
    end

    def tuned?(book,type)
      b = tuned.by_id(book.book_id,type)
      return false unless b
      b.book_id == book.book_id and b.tune_type == type 
    end

    def books(group = nil)
      if group
        groups.each do |g|
          return g.books if g.hash == group.hash
        end
      else
        bs = Books.new
        groups.each do |g|
          g.books.each { |b| bs << b }
        end
        return bs
      end
    end

  end
end

