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

    def books(group)
      groups.each do |g|
        return g.books if g.hash == group.hash
      end
    end

  end
end

