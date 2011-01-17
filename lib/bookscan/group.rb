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
      if completed?
        @status = "完了"
      else
        @status = "未完了"
      end
      [@hash,@date,@num,@price,@payment,@status]
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
      @is_completed = true
      if a[6] == "未完了"
        @is_completed = false
      end
    end
    
    def completed?
      @is_completed
    end

  end
end
