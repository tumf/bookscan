# -*- coding: utf-8 -*-
require 'helper'
require 'bookscan/agent'
require 'pp'
class TestBookscan < Test::Unit::TestCase
  context "Bookscan::Agent" do
    should "access to bookscan" do
      Bookscan::Agent.new {|agent|
        agent.getr("/")
        assert(/ブックスキャン/ =~ agent.page.body,"access to top")
      }
    end
  end
end
