#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'mutter'
require 'bookscan/group'
module Bookscan
  class Groups < Array
    def hashes
      h = Array.new
      each do |group|
        h << group.hash
      end
      h
    end

    def by_hash(hash)
      i = to_index(hash)
      return nil unless i
      at(i)
    end

    def to_index(hash)
      each_index do |i|
        return i if hash == at(i).hash
      end
      nil
    end

    def to_s
      table = Mutter::Table.new(:delimiter => '|') do
        column :style => :green
        column
        column
        column
        column
        column
      end
      # table << ["#","Date","num","price","status"]
      each do |group|
         table << group.to_a
      end
      table.to_s if length > 0
    end

    def book(book_id)
      each do |g|
        return g.books.by_id(book_id) if g.books.has?(book_id)
      end
    end

  end
end
