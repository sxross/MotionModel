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
  before {User.destroy_all; Profile.destroy_all}

  it 'can create a has_one relation' do

    u = User.create(name: 'Sam')
    p = u.profile.create(email: 'ss@gmail.com')

    User.first.profile.first.should.is_a?(Profile)
    User.first.profile.first.email.should == 'ss@gmail.com'
  end

  it 'can assign a has_one relation' do
    u = User.create(name: 'Sam')
    p = u.profile.create(email: 'ss@gmail.com')

    u.profile = Profile.create(email: 'yy@gmail.com')

    User.first.profile.first.should.is_a?(Profile)
    User.first.profile.first.email.should == 'yy@gmail.com'

  end
end
