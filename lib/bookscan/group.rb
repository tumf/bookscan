#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
module Bookscan
  class Group
    attr_reader :hash,:date,:num,:price,:payment
    def to_a
      [@hash,@date,@num,@price,@payment]
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
