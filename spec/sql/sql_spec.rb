module MotionModel

  class Record
    include MotionModel::Model
    include MotionModel::SQLModelAdapter

    columns :name, :type
  end

  describe "SQL generation" do

    before do
      MotionModel::Store.config(MotionModel::SQLDBAdapter.new)
      @alpha = Record.new(id: 123, name: "alpha", type: "bravo")
    end

    describe "INSERT" do
      it "normally" do
        @alpha.insert_sql.should == <<-SQL.strip
          INSERT INTO "records" ("name", "type", "id") VALUES ("alpha", "bravo", 123);
        SQL
      end

      it "omits the ID when not set" do
        alpha = Record.new(name: "alpha", type: "bravo")
        alpha.insert_sql.should == <<-SQL.strip
          INSERT INTO "records" ("name", "type") VALUES ("alpha", "bravo");
        SQL
      end
    end

    describe "SELECT" do
      it "for a SELECT of all records" do
        Record.scoped.to_sql.should == <<-SQL.strip
          SELECT "records".* FROM "records";
        SQL
      end

      it "for a SELECT with a simple WHERE clause" do
        Record.where(name: "alpha").to_sql.should == <<-SQL.strip
          SELECT "records".* FROM "records" WHERE ("records"."name" = "alpha");
        SQL
      end

      it "for a SELECT with a WHERE clause with two terms" do
        Record.where(name: "alpha", type: "bravo").to_sql.should == <<-SQL.strip
          SELECT "records".* FROM "records" WHERE ("records"."name" = "alpha") AND ("records"."type" = "bravo");
        SQL
      end

      it "with a LIMIT" do
        Record.limit(12).to_sql.should == <<-SQL.strip
          SELECT "records".* FROM "records" LIMIT 12;
        SQL
      end

      it "with an ORDER" do
        Record.order(name: :desc).to_sql.should == <<-SQL.strip
          SELECT "records".* FROM "records" ORDER BY "records"."name" DESC;
        SQL
      end
    end

    it "UPDATE" do
      #@alpha.stub!(:'new_record?', return: false)
      @alpha.update_sql.should == <<-SQL.strip
        UPDATE "records" SET "name" = "alpha", "type" = "bravo" WHERE ("records"."id" = #{@alpha.id});
      SQL
    end

    it "for a DELETE" do
      @alpha.delete_sql.should == <<-SQL.strip
        DELETE FROM "records" WHERE ("records"."id" = #{@alpha.id});
      SQL
    end

    it "for delete_all" do
      Record.delete_all_sql.should == <<-SQL.strip
        DELETE FROM "records";
      SQL
    end

  end

end
