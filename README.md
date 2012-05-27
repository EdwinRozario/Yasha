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
<p>class Generals < Yasha</p>
<p>  self.database_is 'history'</p>
<p>  self.table_is 'generals'</p>
<p>end</p>

<h3>Check if database and database exists and create them in Class definition</h3>


#Note
1. Database and tables for Yasha can be made with Yasha only.
2. For every table entry Yasha will provide an index. Object.select(:index => 5).index = 5
3. Dont name any fields in table as index. All the table will have a default field index.