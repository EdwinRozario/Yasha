require 'rubygems'
require 'redis'
require 'json'
require 'ostruct'

class Yasha

  attr_accessor :database, :table, :database_id, :table_id, :counter_key
  
  def initialize
    @database = nil
    @database_id = nil
    @table = nil
    @table_id = nil
    @redis_connection = nil
    @table_struct = nil
    @counter_key = nil
    self.initial_check
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
    @database_id = yasha_databases.index(name)
  end

  def self.create_table table_name, *fields
    tables = JSON.parse(@redis_connection.get("YashA:#{@database}"))
    tables << table_name
    @redis_connection.set("YashA:#{@database}", tables.to_json)
    @redis_connection.set("YashA:#{@database}:#{table_name}", fields.to_json)
    @table = table_name
    @table_struct = fields
    @table_id = tables.index(table_name) 
    @counter_key = "YashA:counter:#{@database_id}:#{@table_id}"
    @redis_connection.set(@counter_key, 0)
  end

###SETTING###

  def self.database_is name
    self.initial_check
    @database = name

    yasha_databases = JSON.parse(@redis_connection.get("YashA:DataBases"))
    @database_id = yasha_databases.index(name)
  end

  def self.table_is name
    @table = name

    tables = JSON.parse(@redis_connection.get("YashA:#{@database}"))
    @table_id = tables.index(name)

    @table_struct = JSON.parse(@redis_connection.get("YashA:#{@database}:#{name}"))

    @counter_key = "YashA:counter:#{@database_id}:#{@table_id}"
  end
  
  def self.details
    puts "Current Database: #{@database}, Table: #{@table}"
  end

###INSERT###

  def self.insert row

    row.keys.each do |field|
      return "#{field} not in table." if not @table_struct.include? field
    end    

    @table_struct.each do |field|
      row[field] = nil if not row.keys.include? field 
    end

    row_id = @redis_connection.get(@counter_key)

    row.each do |key, value|
      yasha_key = "YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:#{row_id}"
      @redis_connection.set(yasha_key, row_id)
    end
    
    @redis_connection.set("YashA:Row:#{@database_id}:#{@table_id}:#{row_id}", row.to_json)
    @redis_connection.incr(@counter_key)
  end

###SELECT###

  def self.select_by_condition key, value, limit = nil
    result_ids = []
    rows = @redis_connection.keys("YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:*")
    rows = rows.slice(0, limit) if not limit.nil?
    rows.each do |row|
      result_ids << @redis_connection.get(row)
    end
    return result_ids
  end

  def self.select_by_conditions query, limit = nil
    result_ids = []

    query.each do |key, value|
      condition_ids = self.select_by_condition(key, value, limit)     
      result_ids = result_ids.empty? ? condition_ids : result_ids & condition_ids
      return [] if result_ids.empty? or condition_ids.empty?
    end
    
    results = []

    result_ids.uniq.each do |id|
      row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{id}"))
      results << OpenStruct.new(row)
    end

    return results

  end

  def self.select_by_id id
    return nil if id > @redis_connection.get(@counter_key).to_i - 1 or id < 0
    row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{id}"))
    return OpenStruct.new(row)
  end

  def self.select_rows number
    result_list = []

    number.times do |id|
      row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{id}"))
      result_list << OpenStruct.new(row)      
    end

    result_list.length == 1 ? result_list[0] : result_list

  end

  def self.select_all limit = nil
    limit.nil? ? self.select_rows(@redis_connection.get(@counter_key).to_i) : self.select_rows(limit)
  end

  def self.select query = nil

    return self.select_all if query.nil?

    case
    when (query.has_key? :id) then return self.select_by_id(query[:id])
    when (query.has_key? :limit and not query.has_key? :conditions) then return self.select_all(query[:limit])
    when (query.has_key? :limit and query.has_key? :conditions) then return self.select_by_conditions(query[:conditions], query[:limit])
    when (not query.has_key? :limit and query.has_key? :conditions) then return self.select_by_conditions(query[:conditions])
    else return nil
    end

  end

end


##########
# USAGE #
#########


class Job < Yasha
  if self.is_database 'history'
    puts "DB Exists"
    self.database_is 'history'
  else
    puts "DB Dosent Exist"
    self.create_database 'history'
  end

  if self.is_table 'generals', 'history'
    puts "Table Exists"
    self.table_is 'generals'
  else
    puts "Table Dosent Exist"
    self.create_table 'generals', 'name', 'alias', 'nationality'
  end

end

Job.details

#Job.insert({"name" => "VasiliChuikov", "alias" => "SaviorStalingrad", "nationality" => "Russian"}) #WF
#Job.insert({"name" => "MontGomery", "alias" => "DesertStorm", "nationality" => "British"}) #WF
#Job.insert({"name" => "Fermanshtine", "alias" => "BerlinGuard", "nationality" => "German"}) #WF
#Job.insert({"name" => "DouglasMcAurthor", "alias" => "BeBack", "nationality" => "USA"}) #WF
#Job.insert({"name" => "ErwinRomell", "alias" => "DesertFox", "nationality" => "German"}) #WF
#Job.insert({"name" => "Patton", "alias" => "TheTank", "nationality" => "USA"}) #WF
#Job.insert({"name" => "Fredrik Paulo", "alias" => "Barbarosa", "nationality" => "German"}) #WF

#Job.select(:id => 5).name #WF
#Job.select #WF
#Job.select(:limit => 6) #WF
#Job.select(:conditions => {"name" => "Patton"}) #WF
#Job.select(:conditions => {"nationality" => "German"}, :limit => 2) #WF
#Job.select(:conditions => {"nationality" => "German", "name" => "*o*", "alias" => "*t*"}) #WF

###############
