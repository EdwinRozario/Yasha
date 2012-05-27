#Yasha Gem
Enables to make an SQL like data structure using Redis. And use it as an ORM for SQL.

#Installation

<tt>gem install yasha</tt>

#Requirements 
<tt>redis(2.2.2)</tt>
<tt>json(1.5.3)</tt>

#Require
<tt>require 'yasha'</tt>

##Define Class
    class Generals < Yasha
      self.database_is 'history' #Setting database for class
      self.table_is 'generals'   #Setting table for the calss
    end

##Check if database and tabe exists and create them in Class definition
    class Job < Yasha
      if self.is_database 'history'    #Checks if database exist
        self.database_is 'history'
      else
        self.create_database 'history' #Creates database
      end

      if self.is_table 'generals', 'history'                          #Checks if table exist in database
         self.table_is 'generals'
      else
         self.create_table 'generals', 'name', 'alias', 'nationality' #Creating table. First argument is table name and rest fields for the table.
       end
    end

##INSERT Operation
    Job.insert({"name" => "MontGomery", "alias" => "DesertStorm", "nationality" => "British"}) #argument is a hash with fields as keys and data for each field as value  
    Job.insert({"name" => "DouglasMcAurthor", "alias" => "BeBack", "nationality" => "USA"})
    Job.insert({"name" => "ErwinRomell", "alias" => "DesertFox", "nationality" => "German"})

##SELECT Operations
    Job.select                                                          #Selects every row in the table. Return value will be an array of objects
    Job.select(:index => 5)                                             #Select rows with index 5
    Job.select(:limit => 6)                                             #Select first 6 rows
    Job.select(:conditions => {"name" => "Patton"})                     #Select row with name = 'patton'
    Job.select(:conditions => {"nationality" => "German"}, :limit => 2) #Select first 2 rows with nationality = 'German'
    Job.select(:conditions => {"name" => "Erwin*"})                     #Select rows with name like "Erwin%"

##UPDATE rows
    Job.update(:set => {"name" => "VasiliChuikov", "alias" => "SaviourStalingrad"}, :conditions => {"name" => "MontGomery"}) #Updating row with condition
    Job.update(:set => {"name" => "Fermanchtine", "alias" => "BerlinGuard", "nationality" => "German"}, :index => 2)         #Updating row with index

##DELETE rows
    Job.delete(:index => 1)                             #Delete row with index
    Job.delete(:conditions => {"nationality" => "USA"}) #Delete row with condition
    Job.delete(:conditions => "all")                    #Delete all rows(Truncate)

#Note
1. Database and tables for Yasha can be made with Yasha only.
2. For every table entry Yasha will provide an index. Object.select(:index => 5).index = 5
3. Dont name any fields in table as index. All the table will have a default field index.