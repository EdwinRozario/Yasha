#Yasha Gem
Enables to make an SQL like data structure using Redis. And use it as an ORM for SQL.

#Installation

<tt>gem install yasha</tt>

#Requirements 
<tt>redis(2.2.2)</tt>
<tt>json(1.5.3)</tt>

#Usage
<tt>require 'yasha'</tt>

<h3>Define Class</h3>
  class Generals < Yasha
    self.database_is 'history'
    self.table_is 'generals'
  end

<h3></h3>

#Note
1. Database and tables for Yasha can be made with Yasha only.
2. For every table entry Yasha will provide an index. Object.select(:index => 5).index = 5
3. Dont name any fields in table as index. All the table will have a default field index.