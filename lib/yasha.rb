require 'rubygems'
require 'redis'
require 'json'
require 'ostruct'

class Yasha

  attr_accessor :database, :table, :database_id, :table_id, :counter_key, :host, :port, :redis_connection, :table_struct
  
  def initialize
    @database = nil
    @database_id = nil
    @table = nil
    @table_id = nil
    @host = "127.0.0.1"
    @port = 6379
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
    @redis_connection = Redis.new(:host => @host,:port => @port)
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

  def self.host_is host
    @host = host
  end

  def self.port_is port
    @port = port
  end

  def self.database_is name
    self.initial_check
    @database = name

    yasha_databases = JSON.parse(@redis_connection.get("YashA:DataBases"))
    @database_id = yasha_databases.index(name)
  end

  def self.table_is name
    @table = name

    p "YashA:#{@database}"

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

    row_index = @redis_connection.get(@counter_key)

    row.each do |key, value|
      yasha_key = "YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:#{row_index}"
      @redis_connection.set(yasha_key, row_index)
    end
    
    @redis_connection.set("YashA:Row:#{@database_id}:#{@table_id}:#{row_index}", row.to_json)
    @redis_connection.incr(@counter_key)
  end

###SELECT###

  def self.select_by_condition key, value, limit = nil
    result_indexs = []
    rows = @redis_connection.keys("YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:*")
    rows = rows.slice(0, limit) if not limit.nil?
    rows.each do |row|
      result_indexs << @redis_connection.get(row)
    end
    return result_indexs
  end

  def self.select_by_conditions query, limit = nil, internal = nil
    result_indexs = []

    query.each do |key, value|
      condition_indexs = self.select_by_condition(key, value, limit)
      result_indexs = result_indexs.empty? ? condition_indexs : result_indexs & condition_indexs
      return nil if result_indexs.empty? or condition_indexs.empty?
    end
    
    results = []

    result_indexs.uniq.each do |index|
      row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{index}"))
      row["index"] = index
      results << (internal.nil? ? OpenStruct.new(row) : row)
    end

    return results

  end

  def self.select_by_index index
    return nil if index > @redis_connection.get(@counter_key).to_i - 1 or index < 0
    row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{index}"))
    row["index"] = index
    return OpenStruct.new(row)
  end

  def self.select_rows number
    result_list = []

    number.times do |id|
      row = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{id}"))
      row["index"] = id
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
    when (query.has_key? :index) then return self.select_by_index(query[:index])
    when (query.has_key? :limit and not query.has_key? :conditions) then return self.select_all(query[:limit])
    when (query.has_key? :limit and query.has_key? :conditions) then return self.select_by_conditions(query[:conditions], query[:limit])
    when (not query.has_key? :limit and query.has_key? :conditions) then return self.select_by_conditions(query[:conditions])
    else return nil
    end

  end

###UPDATE###

  def self.update_index index, updation
    rows = @redis_connection.keys("YashA:#{@database_id}:#{@table_id}:*:*:#{index}")
    rows.each do |row|
      @redis_connection.del(row)
    end
   
    row_data = JSON.parse(@redis_connection.get("YashA:Row:#{@database_id}:#{@table_id}:#{index}"))
    row_data.each do |key, value|
      row_data[key] = updation[key]  if updation.keys.include? key
    end
    @redis_connection.del("YashA:Row:#{@database_id}:#{@table_id}:#{index}")


    row_data.each do |key, value|
      new_key = "YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:#{index}"
      @redis_connection.set(new_key, index)
    end

    @redis_connection.set("YashA:Row:#{@database_id}:#{@table_id}:#{index}", row_data.to_json)

  end

  def self.update_row row, updation

    row_index = row["index"]
    row.delete("index")
    updated_row = updation

    row.each do |key, value|
      if updation.keys.include? key
        yasha_key = "YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:#{row_index}"
        @redis_connection.del(yasha_key)
      else
        updated_row[key] = value
      end
    end

    updation.each do |key, value|
      yasha_key = "YashA:#{@database_id}:#{@table_id}:#{@table_struct.index(key)}:#{value}:#{row_index}"
      @redis_connection.set(yasha_key, row_index)
    end
    
    @redis_connection.set("YashA:Row:#{@database_id}:#{@table_id}:#{row_index}", updated_row.to_json)
      
  end

  def self.update updation

    if updation.has_key? :index
      self.update_index updation[:index], updation[:set]
    else
      return false if updation[:conditions].nil?
      rows = self.select_by_conditions(updation[:conditions], nil, 0)
      return false if rows.nil?

      rows.each do |row|
        self.update_row(row, updation[:set])
      end
    end

  end

###DELETE###

  def self.delete_by_index index
    rows = @redis_connection.keys("YashA:#{@database_id}:#{@table_id}:*:*:#{index}")
    rows.each do |row|
      @redis_connection.del(row)
    end

    @redis_connection.del("YashA:Row:#{@database_id}:#{@table_id}:#{index}")
  end

  def self.delete_all
    rows = @redis_connection.keys("YashA:#{@database_id}:#{@table_id}:*") + @redis_connection.keys("YashA:Row:#{@database_id}:#{@table_id}:*")
    rows.each do |row|
      @redis_connection.del(row)
    end
    @redis_connection.set(@counter_key, 0)
  end

  def self.delete_by_condition conditions

    self.delete_all if conditions == "all"

    rows = self.select_by_conditions(conditions, nil, 0)
    return false if rows.nil?
    
    rows.each do |row|
      self.delete_by_index row["index"]
    end

  end

  def self.delete deletion

    if deletion.has_key? :index
      self.delete_by_index deletion[:index]
    else
      self.delete_by_condition deletion[:conditions]
    end

  end

end


##########
# USAGE #
#########


#class Job < Yasha
#  if self.is_database 'history'
#    puts "DB Exists"
#    self.database_is 'history'
#  else
#    puts "DB Dosent Exist"
#    self.create_database 'history'
#  end

#  if self.is_table 'generals', 'history'
#    puts "Table Exists"
#    self.table_is 'generals'
#  else
#    puts "Table Dosent Exist"
#    self.create_table 'generals', 'name', 'alias', 'nationality'
#  end
#end

#Job.details

#Job.insert({"name" => "VasiliChuikov", "alias" => "SaviorStalingrad", "nationality" => "Russian"}) #WF
#Job.insert({"name" => "MontGomery", "alias" => "DesertStorm", "nationality" => "British"}) #WF
#Job.insert({"name" => "Fermanshtine", "alias" => "BerlinGuard", "nationality" => "German"}) #WF
#Job.insert({"name" => "DouglasMcAurthor", "alias" => "BeBack", "nationality" => "USA"}) #WF
#Job.insert({"name" => "ErwinRomell", "alias" => "DesertFox", "nationality" => "German"}) #WF
#Job.insert({"name" => "Patton", "alias" => "TheTank", "nationality" => "USA"}) #WF
#Job.insert({"name" => "Fredrik Paulo", "alias" => "Barbarosa", "nationality" => "German"}) #WF

#Job.select(:index => 5) #WF
#Job.select #WF
#Job.select(:limit => 6) #WF
#Job.select(:conditions => {"name" => "Patton"}) #WF
#Job.select(:conditions => {"nationality" => "German"}, :limit => 2) #WF
#Job.select(:conditions => {"nationality" => "German", "name" => "*o*", "alias" => "*t*"}) #WF

#Job.update(:set => {"name" => "WalterModel", "alias" => "BulgeBat"}, :conditions => {"name" => "Fermanshtine"}) #WF
#Job.update(:set => {"name" => "Fermanchtine", "alias" => "BerlinGuard", "nationality" => "German"}, :index => 2) #WF

#Job.delete(:index => 1) #WF
#Job.delete(:conditions => {"nationality" => "USA"}) #WF
#Job.delete(:conditions => "all") #WF

