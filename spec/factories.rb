require 'factory_girl'
require 'libertree/model'

FactoryGirl.define do
  factory :server, :class => Libertree::Model::Server do
    sequence(:ip) { |n|
      m = n / 256 # integer division
      "192.168.#{m}.#{n}"
    }
    public_key OpenSSL::PKey::RSA.new(2048, 65537).public_key.to_pem
  end

  factory :member, :class => Libertree::Model::Member do
    sequence(:username) { |n| "member#{n}" }
    server
  end

  factory :post, :class => Libertree::Model::Post do
    sequence(:text) { |n| "Post #{n}" }
    sequence(:remote_id, 1000)
    public true
  end

  factory :comment, :class => Libertree::Model::Comment do
    sequence(:remote_id, 1000)
  end
end
