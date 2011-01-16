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

    def to_s
      table = Mutter::Table.new(:delimiter => '|') do
        column :style => :green
        column
        column
        column
        column
      end
      # table << ["#","Date","num","price","status"]
      each do |group|
        table << group.to_a
      end
      table.to_s
    end
  end
end
