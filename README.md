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
      self.database 'history' #Setting database for class
      self.table 'generals'   #Setting table for the calss
    end

##Check if database and table exists and create them in Class definition
    class Generals  < Yasha
      if self.database? 'history'    #Checks if database exist
        self.database 'history'
      else
        self.create_database 'history' #Creates database
      end

      if self.table? 'generals', 'history'                          #Checks if table exist in database
         self.table 'generals'
      else
         self.create_table 'generals', 'name', 'alias', 'nationality' #Creating table. First argument is table name and rest fields for the table.
       end
    end

##INSERT Operation
    Generals.insert({"name" => "MontGomery", "alias" => "DesertStorm", "nationality" => "British"}) #argument is a hash with fields as keys and data for each field as value  
    Generals.insert({"name" => "DouglasMcAurthor", "alias" => "BeBack", "nationality" => "USA"})
    Generals.insert({"name" => "ErwinRomell", "alias" => "DesertFox", "nationality" => "German"})

##SELECT Operations
    Generals.select                                                          #Selects every row in the table. Return value will be an array of objects. Each object.feild name will give the vale of the selected row.
    Generals.select(:index => 5)                                             #Select rows with index 5
    Generals.select(:limit => 6)                                             #Select first 6 rows
    Generals.select(:conditions => {"name" => "Patton"})                     #Select row with name = 'patton'
    Generals.select(:conditions => {"nationality" => "German"}, :limit => 2) #Select first 2 rows with nationality = 'German'
    Generals.select(:conditions => {"name" => "Erwin*"})                     #Select rows with name like "Erwin%"

##UPDATE rows
    Generals.update(:set => {"name" => "VasiliChuikov", "alias" => "SaviourStalingrad"}, :conditions => {"name" => "MontGomery"}) #Updating row with 
    condition. Hash in :set is the new values.
    Generals.update(:set => {"name" => "Fermanchtine", "alias" => "BerlinGuard", "nationality" => "German"}, :index => 2)         #Updating row with index

##DELETE rows
    Generals.delete(:index => 1)                             #Delete row with index
    Generals.delete(:conditions => {"nationality" => "USA"}) #Delete row with condition
    Generals.delete(:conditions => "all")                    #Delete all rows(Truncate)

#Note
1. Database and tables for Yasha can be made with Yasha only.
2. For every table entry Yasha will provide an index. Object.select(:index => 5).index = 5
3. Dont name any fields in table as index. All the table will have a default field index.
