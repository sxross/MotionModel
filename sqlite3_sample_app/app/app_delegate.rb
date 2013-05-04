class Todo
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter

  columns name: :string
  columns created_at: :datetime
  columns updated_at: :datetime
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)

    MotionModel::Store.config(MotionModel::FMDBAdapter.new('test.db'))
    Todo.create_table unless Todo.table_exists?

    Todo.create(name: "Todo for #{Time.now}")

    Todo.all.to_a.each do |todo|
      puts todo
    end

    true
  end
end
