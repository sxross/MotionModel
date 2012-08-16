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
  helpers are certainly not the focus of this strawman release, but
  I am using these in an app to create Apple-like input forms in
  static tables. I expect some churn in this module.

What Model Can Do
================

You can define your models and their schemas in Ruby. For example:

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

You can also include the `Validations` module to get field validation. For example:

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

* Serialization using `NSCoder` works. Basically, you might do something like this
  in your `AppDelegate`:
  <pre><code>
  def load_data
    if File.exist? documents_file("my_fine.dat")
      error_ptr = Pointer.new(:object)
      
      data = NSData.dataWithContentsOfFile(documents_file('my_fine.dat'), options:NSDataReadingMappedIfSafe, error:error_ptr)
      
      if data.nil?
        error = error_ptr[0]
        show_user_scary_warning error
      else
        @my_data_tree = NSKeyedUnarchiver.unarchiveObjectWithData(data)
      end
    else
      show_user_first_time_welcome
    end
  end
  </code></pre>
  
  and of course on the "save" side:
  
  <code><pre>
  error_ptr = Pointer.new(:object)

  data = NSKeyedArchiver.archivedDataWithRootObject App.delegate.events
  unless data.writeToFile(documents_file('my_fine.dat'), options: NSDataWritingAtomic, error: error_ptr)
    error = error_ptr[0]
    show_scary_message error
  end
  </pre></code>
  
  Note that the archiving of any arbitrarily complex set of relations is
  automatically handled by `NSCoder` provided you conform to the coding
  protocol. When you declare your columns, `MotionModel` understands how
  to serialize your data so you need take no further action.
  
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
