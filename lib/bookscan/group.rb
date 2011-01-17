#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'bookscan/book'
module Bookscan
  class Group
    attr_reader :hash,:date,:num,:price,:payment
    attr_accessor :books

    def initialize
      @books = Books.new
    end

    def to_a
      [@hash,@date,@num,@price,@payment]
    end

    def url
      "/bookdetail.php?hash=" + @hash
    end

    def import(tr)
      a = Array.new
      tr.search("td").each do |td|
        a << td.text.to_s
      end
      if /hash=(.+)/ =~ tr.at("a/@href")
        @hash = $1
      end
      # puts url

      @date = a[0]
      @num = a[1]
      @price =  a[2]
      @payment = a[3]
    end
  end
end
