MotionModel -- Simple Model, Validation, and Input Mixins for RubyMotion
================

MotionModel is for cases where Core Data is too heavy to lift but you are
still intending to work with your data.

MotionModel is a bunch of "I don't ever want to have to write that code
again if I can help it" things extracted into modules. The four modules
are:

- ext: Core Extensions that provide a few Rails-like niceties. Nothing
  new here, moving on...
  
- model.rb: You can read about it in "What Model Can Do" but it's a
  mixin that provides you accessible attributes, row indexing,
  serialization for persistence, and some other niceties like row
  counting.
  
- validatable.rb: Provides a basic validation framework for any
  arbitrary class. Right now, it can only validate for presence,
  but expect that to change soon.
  
- input_helpers: Hooking an array up to a data form, populating
  it, and retrieving the data afterwards can be a bunch of code.
  Not something I'd like to write more often that I have to. These
  helpers are certainly not the focus of this release, but
  I am using these in an app to create Apple-like input forms in
  static tables.

What Model Can Do
================

You can define your models and their schemas in Ruby. For example:

```ruby
class Task
  include MotionModel::Model

  columns :name        => :string,
          :description => :string,
          :due_date    => :date
end

class MyCoolController
  def some_method
    @task = Task.create :name => 'walk the dog',
                :description => 'get plenty of exercise. pick up the poop',
                :due_date => '2012-09-15'
   end
end
```

Models support default values, so if you specify your model like this, you get defaults:

```ruby
class Task
  include MotionModel::Model
  
  columns :name     => :string,
          :due_date => {:type => :date, :default => '2012-09-15'}
end
```          

You can also include the `Validations` module to get field validation. For example:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::Validations

  columns :name        => :string,
          :description => :string,
          :due_date    => :date
  validates :name => :presence => true
end

class MyCoolController
  def some_method
    @task = Task.new :name => 'walk the dog',
                 :description => 'get plenty of exercise. pick up the poop',
                 :due_date => '2012-09-15'

    show_scary_warning unless @task.valid?
  end
end
```

*Important Note*: Type casting occurs at initialization and on assignment. That means
If you have a field type `int`, it will be changed from a string to an integer when you
initialize the object of your class type or when you assign to the integer field in your class.

```ruby
a_task = Task.create(:name => 'joe-bob', :due_date => '2012-09-15')     # due_date is cast to NSDate

a_task.due_date = '2012-09-19'    # due_date is cast to NSDate
```

Model Instances and Unique IDs
-----------------

It is assumed that models can be created from an external source (JSON from a Web 
application or NSCoder from the device) or simply be a stand-alone data store. 
To identify rows properly, the model tracks a special field called `:id`. If it's
already present, it's left alone. If it's missing, then it is created for you.
Each row id is guaranteed to be unique, so you can use this when communicating
with a server or syncing your rowset to a UITableView.

Things That Work
-----------------

* Models, in general, work. They aren't ultra full-featured, but more is in the
  works. In particular, finders are just coming online. All column data may be
  accessed by member name, e.g., `@task.name`.
  
  * Finders are implemented using chaining. Here is an examples:

    ```ruby  
    @tasks = Task.where(:assigned_to).eq('bob').and(:location).contains('seattle')
    @tasks.all.each { |task| do_something_with(task) }
    ```
    
    You can use a block with find:
    
    ```ruby  
    @tasks = Task.find{|task| task.name =~ /dog/i && task.assigned_to == 'Bob'}
    ```

    You can perform ordering using either a field name or block syntax. Here's an example:

    ```ruby
    @tasks = Task.order(:name).all                                  # Get tasks ordered ascending by :name
    @tasks = Task.order{|one, two| two.details <=> one.details}.all # Get tasks ordered descending by :details
    ```

* Serialization is part of MotionModel. So, in your `AppDelegate` you might do something like this:

  ```ruby
    @tasks = Task.deserialize_from_file('tasks.dat')
  ```
  
  and of course on the "save" side:
  
  ```ruby
    @tasks.serialize_to_file('tasks.dat')
  end
  ```
  
  Note that the this serialization of any arbitrarily complex set of relations
  is automatically handled by `NSCoder` provided you conform to the coding
  protocol. When you declare your columns, `MotionModel` understands how to
  serialize your data so you need take no further action.
  
* Relations, in principle work. This is a part I'm still noodling over
  so it's not really safe to use them. In any case, how I expect it will
  shake out is that one-to-one or one-to-many will be supported out of
  the box, but you will have to take some extra steps to implement
  many-to-many, just as you would in Rails' `has_many :through`.

* Core extensions work. The following are supplied:

  - String#humanize
  - String#titleize
  - String#empty?
  - NilClass#empty?
  - Array#empty?
  - Hash#empty?
  - Symbol#titleize

Things In The Pipeline
----------------------

- More tests!
- More robust id assignment
- Testing relations
- Adding validations and custom validations
- Did I say more tests?

Problems/Comments
------------------

Please raise an issue if you find something that doesn't work, some
syntax that smells, etc.
