if defined?(FMDB)
  module MotionModel

    Object.send(:remove_const, :Student) if defined?(Student)
    class Student
      include MotionModel::Model
      include MotionModel::SQLModelAdapter

      columns :name
    end

    Object.send(:remove_const, :Program) if defined?(Program)
    class Program
      include MotionModel::Model
      include MotionModel::SQLModelAdapter

      columns :type
    end

    Object.send(:remove_const, :Course) if defined?(Course)
    class Course
      include MotionModel::Model
      include MotionModel::SQLModelAdapter

      columns :title
    end

    describe Join do

      describe "one to one" do
        before do
          @join = Join.new(Student, :program)
        end

        it "should generate to_sql_str correctly" do
          @join.to_sql_str.should == <<-SQL.strip
            LEFT INNER JOIN "programs" ON "programs"."id" = "students"."program_id"
          SQL
        end

        it "should generate selects correctly" do
          @join.selects
        end
      end

    end

  end
end
