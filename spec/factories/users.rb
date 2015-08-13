FactoryGirl.define do
  factory :user do
    sequence(:name)  {|n| "Sebastian #{n}"}
    sequence(:email)  {|n| "sebastian#{n}@doe.com"}
    active true

    factory :inactive_user do
      active false
    end
  end
end
