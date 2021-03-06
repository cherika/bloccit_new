class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :favorites, dependent: :destroy

  # we register an inline callback directly after the before_save callback.
  before_save {self.email = email.downcase}
  before_save :new_name
  before_save {self.role ||= :member}
  before_create :generate_auth_token
  # a regular expression which defines a specific character pattern that we want to match against a string
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  # we use validates function to ensure that name is present and has max/min length
  validates :name, length: { minimum: 1, maximum: 100}, presence: true

  # when a new user is created, they will be created with a valid password
  validates :password, presence: true, length: {minimum: 6}, if: "password_digest.nil?"
  # when updating a user's password, the updated password is also 6 characters long
  validates :password, length: {minimum: 6}, allow_blank: true

  # we validate that email is present, unique, case insensitive, has min/max length, and properly formatted
  validates :email,
            presence: true,
            uniqueness: {case_sensitive: false},
            length: {minimum: 3, maximum: 100},
            format: {with: EMAIL_REGEX}

  has_secure_password

  enum role: [:member, :admin, :moderator]

  def new_name
    capitalized_name = []
    self.name.to_s.split(" ").each do |word|
      capitalized_name << "#{word[0].capitalize}#{word[1..-1]}"
    end
    self.name = capitalized_name.join(" ")
  end

  def favorite_for(post)
    favorites.where(post_id: post.id).first
  end

  def avatar_url(size)
    gravatar_id = Digest::MD5::hexdigest(self.email).downcase
    "http://gravatar.com/avatar/#{gravatar_id}.png?s=#{size}"
  end

  def generate_auth_token
    loop do
      self.auth_token = SecureRandom.base64(64)
      break unless User.find_by(auth_token: auth_token)
    end
  end
end
