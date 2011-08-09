# -*- coding: utf-8 -*-
require 'helper'
require 'bookscan/agent'
require 'pp'
class TestBookscan < Test::Unit::TestCase
  context "Bookscan::Agent" do
    should "access to bookscan" do
      agent = Bookscan::Agent.new
      agent.getr("/")
    end
  end
end
