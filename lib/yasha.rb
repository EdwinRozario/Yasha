require 'rubygems'
require 'redis'
require 'json'

class Yasha

  attr_accessor :database, :table, :database_id, :table_id
  
  def initialize
    @database = nil
    @database_id = nil
    @table = nil
    @table_id = nil
    @redis_connection = nil
    initial_check
  end

###CHECKS###

  def self.initialize_redis
    @redis_connection.set("YashA:DataBases", [].to_json)
  end

  def self.initial_check
    @redis_connection = Redis.new
    self.initialize_redis if @redis_connection.get("YashA:DataBases").nil?
  end

  def self.is_database name
    self.initial_check    
    JSON.parse(@redis_connection.get("YashA:DataBases")).include? name
  end

  def self.is_table table, database
    JSON.parse(@redis_connection.get("YashA:#{database}")).include? table
  end

###CREATE###

  def self.create_database name
    self.initial_check
    @redis_connection.set("YashA:#{name}", [].to_json)
    yasha_databases = JSON.parse(@redis_connection.get("YashA:DataBases"))
    yasha_databases << name
    @redis_connection.set("YashA:DataBases", yasha_databases.to_json)
    @database = name
  end

  def self.create_table table_name, *fields
    tables = JSON.parse(@redis_connection.get("YashA:#{@database}"))
    tables << table_name
    @redis_connection.set("YashA:#{@database}", tables.to_json)
    @redis_connection.set("YashA:#{@database}:#{table_name}", fields.join("||"))
    @table = table_name
  end

###SETTING###

  def self.database_is name
    self.initial_check
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
  if self.is_database 'history'
    puts "DB Exists"
  else
    puts "DB Dosent Exist"
    self.create_database 'history'
  end

  if self.is_table 'generals', 'history'
    puts "Table Exists"
  else
    puts "Table Dosent Exist"
    self.create_table 'generals', 'name', 'alias', 'nationality'
  end

  if self.is_database 'history'
    puts "DB Exists in Recheck"
  else
    puts "DB Dosent Exist in recheck"
  end

  if self.is_table 'generals', 'history'
    puts "Table Exists in Recheck"
  else
    puts "Table dosent exist in Recheck"
  end

end

Job.details

###############
