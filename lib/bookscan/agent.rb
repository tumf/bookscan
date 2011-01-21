# -*- coding: utf-8 -*-
require "rubygems"
require "mechanize"
require 'httpclient'
require 'progressbar'

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

    def tuning?(book,type)
      @tuning = tuning unless @tuning
      @tuning.each { |b|
        return true if b.title == type+"_"+book.title
      }
      false
    end

    def tune(book,type,is_premium = true)
      if is_premium
        max_queue = 10
      else
        max_queue = 1
      end

      @tuning = tuning unless @tuning
      # チューニングいっぱい
      raise "tune queue is full" if @tuning.length >= max_queue
      # チューニング
      return false if tuning?(book,type)
      # tune
      getr(book.tune_url)
      page.forms.first["optimize_type"] = type;
      page.forms.first["cover_flg"] = "1";
      page.forms.first.submit
      tuned = book.clone
      tuned.title = type +"_"+book.title
      @tuning << tuned
      tuned
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
          books[book.book_id] = book
        end
      end
      books
    end

    def download(url,path)
      url = URI.parse(url)
      cli = HTTPClient.new
      @cookie_jar.cookies(url).each do |cookie|
        cli.cookie_manager.parse(cookie.to_s,url)
      end

      length = 0;total = 0
      res = cli.head(url)
      if res.status == 302
        url = URI.parse(res.header["Location"].to_s)
      end
      total = cli.head(url).header["Content-Length"].to_s.to_i
      t = Thread.new {
        conn = cli.get_async(url)
        io = conn.pop.content
        ::File::open(path, "wb") { |f|
          while str = io.read(40)
            f.write str
            length += str.length
          end
        }
      }
      pbar = ProgressBar.new("Loading",total)
      while length >= total 
        sleep 1
        pbar.set(length)
      end
      pbar.finish
      t.join
    end

  end
end
