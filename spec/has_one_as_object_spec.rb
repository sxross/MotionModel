class User
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name => :string

  has_one :profile
end

class Profile
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :email => :string

  belongs_to :user

end

describe 'has_one behaviors' do
  before do
    User.destroy_all
    Profile.destroy_all
  end

  it 'can create a has_one relation' do
    user = User.create(name: 'Sam')
    profile = user.profile.create(email: 'ss@gmail.com')

    User.first.profile.should.is_a?(Profile)
    User.first.profile.email.should == 'ss@gmail.com'
  end

  it 'can assign a has_one relation' do
    user = User.create(name: 'Sam')
    user.profile = Profile.create(email: 'ss@gmail.com')

    User.first.profile.should.is_a?(Profile)
    User.first.profile.email.should == 'ss@gmail.com'
  end

  it 'can get parent from a has_one create relation' do
    user = User.create(name: 'Sam')
    profile = user.profile.create(email: 'ss@gmail.com')

    Profile.first.user.should.is_a?(User)
    Profile.first.user.name.should == 'Sam'

    User.first.profile.user.should.is_a?(User)
    User.first.profile.user.name.should == 'Sam'
  end

  it 'can get parent from a has_one assigned relation' do
    user = User.create(name: 'Sam')
    user.profile = Profile.create(email: 'ss@gmail.com')

    Profile.first.user.should.is_a?(User)
    Profile.first.user.name.should == 'Sam'

    User.first.profile.user.should.is_a?(User)
    User.first.profile.user.name.should == 'Sam'
  end
end
