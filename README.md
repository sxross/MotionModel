[![Code Climate](https://codeclimate.com/github/sxross/MotionModel.png)](https://codeclimate.com/github/sxross/MotionModel)[![Build Status](https://travis-ci.org/sxross/MotionModel.png)](https://travis-ci.org/sxross]/MotionModel)

MotionModel: Models, Relations, and Validation for RubyMotion
================

MotionModel is a DSL for cases where Core Data is too heavy to lift but you are
still intending to work with your data, its types, and its relations. It also provides for
data validation and actually quite a bit more.

File                 | Module                    | Description
---------------------|---------------------------|------------------------------------
**ext.rb**           | N/A                       | Core Extensions that provide a few Rails-like niceties. Nothing new here, moving on...
**model.rb**         | MotionModel::Model        | You should read about it in "[What Model Can Do](#what-model-can-do)". Model is the raison d'etre and the centerpiece of MotionModel.
**validatable.rb**   | MotionModel::Validatable  | Provides a basic validation framework for any arbitrary class. You can also create custom validations to suit your app's unique needs.
**input_helpers**    | MotionModel::InputHelpers | Helps hook a collection up to a data form, populate the form, and retrieve the data afterwards. Note: *MotionModel supports Formotion for input handling as well as these input helpers*.
**formotion.rb**     | MotionModel::Formotion    | Provides an interface between MotionModel and Formotion
**transaction.rb**   | MotionModel::Model::Transactions | Provides transaction support for model modifications

MotionModel is MIT licensed, which means you can pretty much do whatever
you like with it. See the LICENSE file in this project.

* [Getting Going](#getting-going)
* [Bugs, Features, and Issues, Oh My!](#bugs-features-and-issues-oh-my)
* [What Model Can Do](#what-model-can-do)
* [Model Data Types](#model-data-types)
* [Validation Methods](#validation-methods)
* [Model Instances and Unique IDs](#model-instances-and-unique-ids)
* [Using MotionModel](#using-motionmodel)
* [Transactions and Undo/Cancel](#transactions-and-undocancel)
* [Notifications](#notifications)
* [Core Extensions](#core-extensions)
* [Formotion Support](#formotion-support)
* [Problems/Comments](#problemscomments)
* [Submissions/Patches](#submissionspatches)

## Bugs, Features, and Issues, Oh My!

The reason this is up front here is that in order to respond to your issues
we need you to help us out by reading these guidelines. You can also look at
[Submissions/Patches](#submissionspatches) near the bottom of this README
which restates a bit of this.

That said, all software has bugs, and anyone who thinks otherwise probably is smarter than I am. There are going to be edge cases or cases that our tests don't cover. And that's why open source is great: other people will run into issues we can fix. Other people will have needs we don't have but that are of general utility. And so on.

But… fair is fair. We would make the following requests of you:

* Debug the code as far as you can. Obviously, there are times when you just won't be able to see what's wrong or where there's some squirrely interaction with RubyMotion.
* If you are comfortable with the MotionModel code, please try to write a spec that makes it fail and submit a pull request with that failing spec. The isolated test case helps us narrow down what changed and to know when we have the issue fixed. Two things make this even better:
    1. Our specs become more comprehensive; and
    2. If the issue is an interaction between MotionModel and RubyMotion, it's easier to pass along to HipByte and have a spec they can use for a quick hitting test case. Even better, fix the bug and submit that fix *and* the spec in a pull request.
* If you are not comfortable with the MotionModel code, then go ahead and describe the issue in as much detail as possible, including backtraces from the debugger, if appropriate.

Now, I've belabored the point about bug reporting enough. The point is, if you possibly can, write a spec.

Issues: Please mark your issues as questions or feature requests, depending on which they are. We'll do all we can to review them and answer questions as quickly as possible. For feature requests, you really can implement the feature in many cases and then submit a pull request. If not, we'll leave it open for consideration in future releases.

### Summary

Bugs: Please write a failing spec

Issues: Please mark them as question or request

Changes for Existing Users to Be Aware Of
=================

Please see the CHANGELOG for update on changes.

Version 0.4.4 is the first version to be gem-compatible with RubyMotion 2.0

Version 0.3.8 to 0.4.0 is a minor version bump, not a patch version. Upgrading
to 0.4.0 *will break existing code*. To update your code, simply insert the following line:

```ruby
class ModelWithAdapter
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter # <== Here!

  columns :name
end
```

This change lays the foundation for using other persistence adapters.
If you don't want to update all your models, install the gem:

```
$ gem install motion_model -v 0.3.8
```

or if you are using bundler:

```
gem motion_model, "0.3.8"
```

Version 0.3.8 was the last that did not separate the model and persistence concerns.

Getting Going
================

If you are using Bundler, put this in your Gemfile:

```ruby
gem 'motion_model'
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

If you want to use Bundler from `master`, put this in your Gemfile:

```
gem 'motion_model', :git => 'git@github.com:sxross/MotionModel.git'
```

Note that in the above construct, Ruby 1.8.x hash keys are used. That's because Apple's System Ruby is 1.8.7 and won't recognize keen new 1.9.x hash syntax.

What MotionModel Can Do
================

You can define your models and their schemas in Ruby. For example:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name        => :string,
          :long_name   => :string,
          :due_date    => :date
end

class MyCoolController
  def some_method
    @task = Task.create :name => 'walk the dog',
                :long_name    => 'get plenty of exercise. pick up the poop',
                :due_date     => '2012-09-15'
   end
end
```

Side note: The original documentation on this used `description` for the column that is now `long_name`. It turns out Apple reserves `description` so MotionModel saves you the trouble of finding that particular bug by not allowing you to use it for a column name.

Models support default values, so if you specify your model like this, you get defaults:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name     => :string,
          :due_date => {:type => :date, :default => '2012-09-15'}
end
```

You can also include the `Validatable` module to get field validation. For example:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Validatable

  columns :name        => :string,
          :long_name   => :string,
          :due_date    => :date
  validates :name, :presence => true
end

class MyCoolController
  def some_method
    @task = Task.new :name  => 'walk the dog',
                 :long_name => 'get plenty of exercise. pick up the poop',
                 :due_date  => '2012-09-15'

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

Model Data Types
-----------

Currently supported types are:

* `:string`
* `:text`
* `:boolean`, `:bool`
* `:int`, `:integer`
* `:float`, `:double`
* `:date`
* `:array`

You are really not encouraged to stuff big things in your models, which is why a blob type
is not implemented. The smaller your data, the less overhead involved in saving/loading.

### Special Columns

The two column names, `created_at` and `updated_at` will be adjusted automatically if they
are declared. They need to be of type `:date`. The `created_at` column will be set only when
the object is created (i.e., on first save). The `updated_at` column will change every time
the object is saved.

Validation Methods
-----------------

To use validations in your model, declare your model as follows:

```ruby
class MyValidatableModel
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModel::Validatable

  # All other model-y stuff here
end
```

Here are some sample validations:

    validate :field_name, :presence => true
    validate :field_name, :length => 5..8 # specify a range
    validate :field_name, :email
    validate :field_name, :format

The framework is sufficiently flexible that you can add in custom validators like so:

```ruby
module MotionModel
  module Validatable
    def validate_foo(field, value, setting)
      # do whatever you need to make sure that the value
      # denoted by *value* for the field corresponds to
      # whatever is passed in setting.
    end
  end
end

validate  :my_field, :foo => 42
```

In the above example, your new `validate_foo` method will get the arguments
pretty much as you expect. The value of the
last hash is passed intact via the `settings` argument.

You are responsible for adding an error message using:

    add_message(field, "incorrect value foo #{the_foo} -- should be something else.")

You must return `true` from your validator if the value passes validation otherwise `false`.

An important note about `save` once you include `Validatable`, you have two flavors
of save:

Method                 | Meaning
-----------------------|---------------------------
`save(options)`        |Just saves the data if it is valid (passes validations) or if you have specified `:validate => false`
`save!`                |Saves the data if it is valid, otherwise raises a `MotionModel::Validatable::RecordInvalid` exception

Model Instances and Unique IDs
-----------------

It is assumed that models can be created from an external source (JSON from a Web
application or `NSCoder` from the device) or simply be a stand-alone data store.
To identify rows properly, the model tracks a special field called `:id`. If it's
already present, it's left alone. If it's missing, then it is created for you.
Each row id is guaranteed to be unique, so you can use this when communicating
with a server or syncing your rowset to a UITableView.

Using MotionModel
-----------------

* Your data in a model is accessed in a very ActiveRecord (or Railsey) way.
  This should make transitioning from Rails or any ORM that follows the
  ActiveRecord pattern pretty easy. Some of the finder syntactic sugar is
  similar to that of Sequel or DataMapper.

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

    You can implement some aggregate functions using map/reduce:

```ruby
  @task.all.map{|task| task.number_of_items}.reduce(:+)                # implements sum
  @task.all.map{|task| task.number_of_items}.reduce(:+) / @task.count  #implements average
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
  After the first serialize or deserialize, your model will remember the file
  name so you can call these methods without the filename argument.

  Implementation note: that the this serialization of any arbitrarily complex set of relations
  is automatically handled by `NSCoder` provided you conform to the coding
  protocol (which MotionModel does). When you declare your columns, `MotionModel` understands how to
  serialize your data so you need take no specific action.

  **Warning**: As of this release, persistence will serialize only one
  model at a time and not your entire data store.

  * Relations

  ```ruby
  class Task
    include MotionModel::Model
    include MotionModel::ArrayModelAdapter
    columns     :name => :string
    has_many    :assignees
  end

  class Assignee
    include MotionModel::Model
    include MotionModel::ArrayModelAdapter
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

There are four ways to delete objects from your data store:

* `object.delete     #` just deletes the object and ignores all relations
* `object.destroy    #` deletes the object and honors any cascading declarations
* `Class.delete_all  #` just deletes all objects of this class and ignores all relations
* `Class.destroy_all #` deletes all objects of this class and honors any cascading declarations

The key to how the `destroy` variants work in how the relation is declared. You can declare:

```ruby
  class Task
    include MotionModel::Model
    include MotionModel::ArrayModelAdapter
    columns     :name => :string
    has_many    :assignees
  end
```

and `assignees` will *not be considered* when deleting `Task`s. However, by modifying the `has_many`,

```ruby
has_many    :assignees, :dependent => :destroy
```

When you `destroy` an object, all of the objects related to it, and only those related
to that object, are also destroyed. So, if you call `task.destroy` and there are 5
`assignees` related to that task, they will also be destroyed. Any other `assignees`
are left untouched.

You can also specify:

```ruby
has_many    :assignees, :dependent => :delete
```

The difference here is that the cascade stops as the `assignees` are deleted so anything
related to the assignees remains intact.

Note: This syntax is modeled on the Rails `:dependent => :destroy` options in `ActiveRecord`.

## Hook Methods

During a save or delete operation, hook methods are called to allow you a chance to modify the
object at that point. These hook methods are:

```ruby
before_save(sender)
after_save(sender)
before_delete(sender)
after_delete(sender)
```

MotionModel makes no distinction between destroy and delete when calling hook methods, as it only
calls them when the actual object is deleted. In a destroy operation, during the cascading delete,
the delete hooks are called (again) at the point of object deletion.

Note that the method signatures may be different from previous implementations. No longer can you
declare a hook method without the `sender` argument.

Finally, contrasting hook methods with notifications, the hook methods `before_save` and `after_save`
are called before the save operation begins and after it completes. However, the notification (covered
below) is only issued after the save operation. However... the notification understands whether the
operation was a save or update. Rule of thumb: If you want to catch an operation before it begins,
use the hook. If you just want to know about it when it happens, use the notification.

The delete hooks happen around the delete operation and, again, allow you the option to mess with the
object before you allow the process to go forward (pretty much, the `before_delete` hook does this).

*IMPORTANT*: Returning false in a before hook stops the rest of the operation. So, for example, you
could prevent the deletion of the last admin by writing something like this:

```ruby
def before_delete(sender)
  return false if sender.find(:privilege_level).eq('admin').count < 2
end
```

## Transactions and Undo/Cancel

MotionModel is not ActiveRecord. MotionModel is not a database-backed mapper. The bottom line is that when you change a field in a model, even if you don't save it, you are partying on the central object store. In part, this is because Ruby copies objects by reference, so when you do a find, you get a reference to the object *in the central object store*.

The upshot of this is that MotionModel can be wicked fast because it isn't moving much more than pointers around in memory when you do assignments. However, it can be surprising if you are used to a database-backed mapper.

You could easily build an app and never run across a problem with this, but in the case where you present a dialog with a cancel button, you will need a way to back out. Here's how:

```ruby
# in your form presentation view...
include MotionModel::Model::Transactions

person.transaction do
  result = do_something_that_changes_person
  person.rollback unless result
end

def do_something_that_changes_person
  # stuff
  return it_worked
end
```

You can have nested transactions and each has its own context so you don't wind up rolling back to the wrong state. However, everything that you wrap in a transaction must be wrapped in the `transaction` block. That means you need to have some outer calling method that can wrap a series of delegated changes. Explained differently, you can't start a transaction, have a delegate method handle a cancel button click and roll back the transaction from inside the delegate method. When the block is exited, the transaction context is removed.

Notifications
-------------

Notifications are issued on object save, update, and delete. They work like this:

```ruby
def viewDidAppear(animated)
  super
  # other stuff here to set up your view

  NSNotificationCenter.defaultCenter.addObserver(self, selector:'dataDidChange:',
                                                           name:'MotionModelDataDidChangeNotification',
                                                         object:nil)
end

def viewWillDisappear(animated)
  super
  NSNotificationCenter.defaultCenter.removeObserver self
end

# ... more stuff ...

def dataDidChange(notification)
  # code to update or refresh your view based on the object passed back
  # and the userInfo. userInfo keys are:
  #   action
  #     'add'
  #     'update'
  #     'delete'
end
```

  In your `dataDidChange` notification handler, you can respond to the `MotionModelDataDidChangeNotification` notification any way you like,
  but in the instance of a tableView, you might want to use the id of the object passed back to locate
  the correct row in the table and act upon it instead of doing a wholesale `reloadData`.

  Note that if you do a delete_all, no notifications are issued because there is no single object
  on which to report. You pretty much know what you need to do: Refresh your view.

  This is implemented as a notification and not a delegate so you can dispatch something
  like a remote synch operation but still be confident you will be updating the UI only on the main thread.
  MotionModel does not currently send notification messages that differentiate by class, so if your
  UI presents `Task`s and you get a notification that an `Assignee` has changed:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  has_many :assignees
  # etc
end

class Assignee
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  belongs_to :task
  # etc
end

# ...

task = Task.create :name => 'Walk the dog'  # Triggers notification with a task object
task.assignees.create :name => 'Adam'       # Triggers notification with an assignee object

# ...

# We set up observers for `MotionModelDataDidChangeNotification` someplace and:
def dataDidChange(notification)
if notification.object is_a?(Task)
  # Update our UI
else
  # This notification is not for us because
  # We don't display anything other than tasks
end
```

  The above example implies you are only presenting, say, a list of tasks in the current
  view. If, however, you are presenting a list of tasks along with their assignees and
  the assignees could change as a result of a background sync, then your code could and
  should recognize the change to assignee objects.

Core Extensions
----------------

  - String#humanize
  - String#titleize
  - String#empty?
  - String#singularize
  - String#pluralize
  - NilClass#empty?
  - Array#empty?
  - Hash#empty?
  - Symbol#titleize

  Also in the extensions is a `Debug` class to log stuff to the console.
  It uses NSLog so you will have a separate copy in your application log.
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

Serialization
----------------------

The `ArrayModelAdapter` does not, by default perform any serialization. That's
because how often which parts of your object graph are serialized can affect
application performance. However, you *will* want to use the serialization
features. Here they are:

    YourModel.deserialize_from_file(file_name = nil)

    YourModel.serialize_to_file(file_name = nil)

What happens here? When you want to save a model, you call `serialize_to_file`.
Each model's data must be saved to a different file so name them accordingly.
If you have a model that contains related model objects, you may want to save
both models. But you have complete say over that and *the responsibility to
handle it*.

When you call `deserialize_from_file`, your model is populated from the file
previously serialized.

Formotion Support
----------------------

MotionModel now has support for the cool [Formotion gem](https://github.com/clayallsopp/formotion).
Note that the Formotion project on GitHub appears to be way ahead of the gem on Rubygems, so you
might want to build it yourself if you want the latest gee-whiz features (like `:picker_type`, as
I've shown in this example).

This feature is extremely experimental, but here's how it works:

```ruby
class Event
  include MotionModel::Model
  include MotionModel::Formotion  # <== Formotion support

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => :string
end
```

This declares the class. The only difference is that you include `MotionModel::Formotion`.
If you want to pass additional information on to Formotion, simply include it in the
`:formotion` hash as shown above.

MotionModel has sensible defaults for each type supported, so any field of `:date`
type will default to a date picker in the Formotion form. However, if you want it
to be a string for some reason, just pass in:

```ruby
:date => {:type => :date, :formotion => {:type => :string}}
```

To initialize a form from a model in your controller:

```ruby
@form = Formotion::Form.new(@event.to_formotion('event details'))
@form_controller = MyFormController.alloc.initWithForm(@form)
```

The magic is in: `MotionModel::Model#to_formotion(form_title)`.

The auto_date fields `created_at` and `updated_at` are not sent to
Formotion by default. If you want them sent to Formotion, set the
second argument to true. E.g.,

```ruby
@form = Formotion::Form.new(@event.to_formotion('event details', true))
```

On the flip side you do something like this in your Formotion submit handler:

```ruby
@event.from_formotion!(data)
```

This performs sets on each field. You'll, of course, want to check your
validations before dismissing the form.

Moreover, Formotion support allows you to split one model fields in sections.
By default all fields are put in a single untitled section. Here is a complete
example:

```ruby
class Event
  include MotionModel::Model
  include MotionModel::Formotion  # <== Formotion support

  columns :name => :string,
          :date => {:type => :date, :formotion => {:picker_type => :date_time}},
          :location => {:type => :string, :formotion => {:section => :address}}

  has_formotion_sections :address => {:title => "Address"}
end
```

This will create a form with the `name` and `date` fields presented first, then a
section titled 'Address' will contain the `location` field.

If you want to add a title to the first section, provide a :first_section_title
argument to `to_formotion`:

```ruby
@form = Formotion::Form.new(@event.to_formotion('event details', true, 'First Section Title'))
```

Problems/Comments
------------------

Please **raise an issue** on GitHub if you find something that doesn't work, some
syntax that smells, etc.

If you want to stay on the bleeding edge, clone yourself a copy (or better yet, fork
one).

Then be sure references to motion_model are commented out or removed from your Gemfile
and/or Rakefile and put this in your Rakefile:

```ruby
require "~/github/local/MotionModel/lib/motion_model.rb"
```

The `~/github/local` is where I cloned it, but you can put it anyplace. Next, make
sure you are following the project on GitHub so you know when there are changes.

Submissions/Patches
------------------

Obviously, the ideal patch request is really a pull request from your own fork, complete with passing
specs.

Really, for a bug report, even a failing spec or some proposed code is fine. I really want to make
this a decent tool for RubyMotion developers who need a straightforward data
modeling and persistence framework.
