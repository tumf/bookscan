# -*- coding: utf-8 -*-
require "rubygems"
require "mechanize"

require "bookscan"
require "bookscan/groups"
require "bookscan/book"

module Bookscan
  class Agent < Mechanize
    def initialize
      super
      max_history = 0
    end

    def getr path
      get(BSURL + path)
    end
    
    def login id,password
      getr("/login.php")
      form = page.forms[0]
      form.fields.find{|f| f.name == "email" }.value = id
      form.fields.find{|f| f.name == "password" }.value = password
      submit(form)
    end

    def login?
      getr("/mypage.php")
      /さんのおかげです/ =~ page.body # => OK
    end

    def logout
      getr("/history.php?logout=1")
    end

    def tuned
      bs = Books.new
      getr("/tunelablist.php")
      page.search("td").each do |td|
        if TUNED_PATTERN =~ td.to_s
          a = td.at("a") 
          book = Book.new
          book.title = $1
          book.url = a.attributes["href"].value.to_s
          book.group_url = "/tunelablist.php"
          bs << book
        end
      end
      bs
    end

    def tuning
      bs = Books.new
      getr("/tunelabnowlist.php")
      page.search("td").each do |td|
        if TUNED_PATTERN =~ td.to_s
          book = Book.new
          book.title = $1
          book.group_url = "/tunelabnowlist.php"
          bs << book
        end
      end
      bs
    end

    def tune book,type
      getr(book.group_url)
      page.search("a[@class=downloading]").each do |u|
        if u.text == "変換" and
            /_#{book.isbn}/ =~ u.attributes["href"].value.to_s
          click(u)
          page.forms.first["optimize_type"] = type;
          page.forms.first["cover_flg"] = "1";
          page.forms.first.submit
          puts "tune %s " % [book.title]
          return true
        end
      end
    end

    def groups
      r = Groups.new
      getr("/history.php")
      page.search("table.table5").each do |table|
        if /依頼したもの一覧/ =~  table.to_s
          table.search("tr").each do |tr|
            if /決済完了/ =~ tr.to_s
              g = Group.new
              g.import(tr)
              r << g
            end
          end
        end
      end
      r
    end

    def group_urls
      getr("/history.php")
      urls = Array.new
      page.search("a/@href").each do |url|
        urls << "/" + url if(/bookdetail/ =~ url)
      end
      urls
    end

    def books group
      bs = Books.new
      getr(group.url)
      page.search("a[@class=downloading]").each do |u|
        next if u.text == "PDFダウンロード" or 
          u.text == "変換"
        book = Book.new
        book.title = u.text.to_s
        book.url = u.attributes["href"].value.to_s
        book.group_url = group.url
        bs << book
      end
      bs
    end

    def allbooks
      books = Books.new
      group_urls.each do |url|
        getr(url)
        page.search("a[@class=downloading]").each do |u|
          next if u.text == "PDFダウンロード" or 
            u.text == "変換"
          book = Book.new
          book.title = u.text.to_s
          book.url = u.attributes["href"].value.to_s
          book.group_url = url
          books[book.isbn] = book
        end
      end
      books
    end

    def download(url,path)
      get(url)
      page.save(path)
    end

    def download2 isbn,type,dir
      getr("/tunelablist.php")
      page.search("a[@class=download]").each do |a|
        if /^#{type}_.*_#{isbn}.*\.pdf$/ =~ a.text
          click(a)
          path =  dir + "/" + a.text
          puts "Download %s" % [path]
          page.save(path)
        end
      end
    end

  end
end
