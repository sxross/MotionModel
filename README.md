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
  
Getting Going
================

If you are using Bundler, put this in your Gemfile:

```
gem motion_model
```

then do:

```
bundle install
```

If you are not using Bundler:

```
gem install motion_model
```

then put this in your Rakefile after requiring `motion/project`:

```
require 'motion_model'
```


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
    
    Note that finders always return a proxy (`FinderQuery`). You must use `first`, `last`, or `all`
    to get useful results.
    
    ```ruby  
    @tasks = Task.where(:owner).eq('jim')   # => A FinderQuery.
    @tasks.all                              # => An array of matching results.
    @tasks.first                            # => The first result
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
    Task.serialize_to_file('tasks.dat')
  end
  ```
  
  Note that the this serialization of any arbitrarily complex set of relations
  is automatically handled by `NSCoder` provided you conform to the coding
  protocol. When you declare your columns, `MotionModel` understands how to
  serialize your data so you need take no further action.
  
  **Warning**: As of this release, persistence will serialize only one
  model at a time and not your entire data store. This will be fixed next.
  
  * Relations now are usable, although not complete fleshed out:
  
  ```ruby
  class Task
    include MotionModel::Model
    columns     :name => :string
    has_many    :assignees
  end
  
  class Assignee
    include MotionModel::Model
    columns     :assignee_name => :string
    belongs_to  :task
  end
  
  # Create a task, then create an assignee as a
  # related object on that task
  a_task = Task.create(:name => "Walk the Dog")
  a_task.assignees.create(:assignee_name => "Howard")
  
  # See? It works.
  a_task.assignees.assignee_name      # => "Howard"
  Task.first.assignees.assignee_name  # => "Howard"
  
  # Create another assignee but don't save
  # Add to assignees collection. Both objects
  # are saved.
  another_assignee = Assignee.new(:name => "Douglas")
  a_task.assignees << another_assignee  # adds to relation and saves both objects
  
  # The count of assignees accurately reflects current state
  a_task.assignees.count              # => 2
  
  # And backreference access through belongs_to works.
  Assignee.first.task.name            # => "Walk the Dog"
  ```
  
  At this point, there are a few methods that need to be added
  for relations, and they will.
  
  * delete
  * destroy

* Core extensions work. The following are supplied:

  - String#humanize
  - String#titleize
  - String#empty?
  - String#singularize
  - String#pluralize
  - NilClass#empty?
  - Array#empty?
  - Hash#empty?
  - Symbol#titleize
  
  Also in the extensions is a debug class to log stuff to the console.
  This may be preferable to `puts` just because it's easier to spot in
  your code and it gives you the exact level and file/line number of the
  info/warning/error in your console output:
  
  - Debug.info(message)
  - Debug.warning(message)
  - Debug.error(message)
  - Debug.silence / Debug.resume to turn on and off logging
  - Debug.colorize (true/false) for pretty console display
  
  Finally, there is an inflector singleton class based around the one
  Rails has implemented. You don't need to dig around in this class
  too much, as its core functionality is exposed through two methods:
  
  String#singularize
  String#pluralize
  
  These work, with the caveats that 1) The inflector is English-language
  based; 2) Irregular nouns are not handled; 3) Singularizing a singular
  or pluralizing a plural makes for good cocktail-party stuff, but in
  code, it mangles things pretty badly.
  
  You may want to get into customizing your inflections using:
  
  - Inflector.inflections.singular(rule, replacement)
  - Inflector.inflections.plural(rule, replacement)
  - Inflector.inflections.irregular(rule, replacement)
  
  These allow you to add to the list of rules the inflector uses when
  processing singularize and pluralize. For each singular rule, you will
  probably want to add a plural one. Note that order matters for rules,
  so if your inflection is getting chewed up in one of the baked-in
  inflections, you may have to use Inflector.inflections.reset to empty
  them all out and build your own.
  
  Of particular note is Inflector.inflections.irregular. This is for words
  that defy regular rules such as 'man' => 'men' or 'person' => 'people'.
  Again, a reversing rule is required for both singularize and 
  pluralize to work properly.

Things In The Pipeline
----------------------

- More robust id assignment
- Adding validations and custom validations

Problems/Comments
------------------

Please **raise an issue** on GitHub if you find something that doesn't work, some
syntax that smells, etc.

If you want to stay on the bleeding edge, clone yourself a copy (or better yet, fork
one).

Then be sure references to motion_model are commented out or removed from your Gemfile
and/or Rakefile and put this in your Rakefile:

```
require "~/github/local//MotionModel/lib/motion_model.rb"
```

The `~/github/local` is where I cloned it, but you can put it anyplace. Next, make
sure you are following the project on GitHub so you know when there are changes.

Submissions/Patches
------------------

Obviously, the ideal one is a pull request from your own fork, complete with passing
specs.

Really, even a failing spec or some proposed code is fine. I really want to make
this a decent tool for RubyMotion developers who need a straightforward data
modeling and persistence framework.