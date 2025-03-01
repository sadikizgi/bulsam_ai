class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: { message: "İsim alanı boş bırakılamaz" }
  validates :email, presence: { message: "Email alanı boş bırakılamaz" }
  validates :password, presence: { message: "Şifre alanı boş bırakılamaz" }
  validate :password_complexity

  has_many :cars, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :car_trackings, dependent: :destroy
  has_many :property_trackings, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Admin kontrolü için method
  def admin?
    admin
  end

  private

  def password_complexity
    return if password.blank? || password =~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$/

    errors.add :password, 'şunları içermelidir: en az 8 karakter, bir büyük harf, bir küçük harf ve bir sayı'
  end
end
