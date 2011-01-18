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
      ts
    end

    def tuned?(book,type)
      tuned.has?(book.book_id) and tuned.by_id(book.book_id).tune_type == type
    end

    def books(group = nil)
      if group
        groups.each do |g|
          return g.books if g.hash == group.hash
        end
      else
        bs = Books.new
        groups.each do |g|
          bs += g.books
        end
        bs
      end
    end

  end
end

