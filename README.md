## Remodel
Remodel is a lightweight Ruby ORM system that provides an interface to search, save, update, and insert into a database.

### Basic Model features
Every model in Remodel has access to built-in class and instance  methods by inheriting from the SQLObject base class. Table names are generated using ActiveSupport/Inflector's tabelize method, but can be overridden with the table_name=(table_name) class method.
```rb
  class Cat < SQLObject
  end

  Cat.table_name #=> "cats"
  Cat.table_name = "kitties"
  Cat.table_name #=> "kitties"
```
These methods enable interaction with the table associated with that model. Query methods return objects built from entries in the database.
```rb
  Cat.all #=> Array of all Cats stored in database
  Cat.find(3) #=> Finds and returns the Cat with id == 3
  Cat.where({name: "Tom", color: "orange"}) #=> Finds the Cat that matches given SQL conditions
```

The #save method will create or update entries to the table based on whether or not that entry already exists.
```rb
  garfield = Cat.new({name: "Garfield", color: "orange"})
  garfield.save #=> Saves this object as a new entry
  garfield.color = "gray" #=> Attribute names have built-in getters and setters
  garfield.save #=> Updates this cat's entry in the database to reflect changes
```
