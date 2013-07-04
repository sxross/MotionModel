Object.send(:remove_const, :Team) if defined?(Team)
Object.send(:remove_const, :TeamMember) if defined?(TeamMember)
class Team
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name, :string
  has_many :team_members
end

class TeamMember
  include MotionModel::Model
  include MotionModel::FMDBModelAdapter
  columns :name, :string
  columns :can_fly, :boolean
  belongs_to :team
end

 describe "Chain queries on associations" do

  before do
    MotionModel::Store.config(MotionModel::FMDBAdapter.new('spec.db', reset: true, ns_log: false))
    Team.create_table
    TeamMember.create_table
    @the_a_team = Team.create(:name => "The A Team")
    @murdock = TeamMember.create(:name => "Murdock", :can_fly => true, :team => @the_a_team)
    @ba = TeamMember.create(:name => "B. A. Baracus", :can_fly => false, :team => @the_a_team)
    @hannibal = TeamMember.create(:name => "Hannibal", :can_fly => true, :team => @the_a_team)
    @faceman = TeamMember.create(:name => "Faceman", :can_fly => true, :team => @the_a_team)
    @superman = TeamMember.create(:name => "Superman", :can_fly => true)
  end

  describe :has_many do
    it "should be possible to chain queries on a has_many association" do
      @the_a_team.team_members.where(:can_fly => true).order(:name).to_a.should == [
        @faceman, @hannibal, @murdock
      ]
    end
  end

end