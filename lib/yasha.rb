require 'rubygems'
require 'redis'

class Yasha

  @database = nil
  @table = nil

  attr_accessor :database, :table
  
  def initialize
    @database = nil
    @table = nil
  end

  def self.database_is name
    @database = name
  end

  def self.table_is name
    @table = name
  end
  
  def self.details
    puts "#{@database}:#{@table}"
  end
  
end

##########
# USAGE #
#########

class Job < Yasha
  self.database_is 'Mad'
  self.table_is 'Fest'
end

Job.details
