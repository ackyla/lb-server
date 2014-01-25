# -*- coding: utf-8 -*-
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require 'json_expressions/rspec'
require 'factory_girl'
FactoryGirl.definition_file_paths = [
    File.join(Padrino.root, 'factories'),
    File.join(Padrino.root, 'test', 'factories'),
    File.join(Padrino.root, 'spec', 'factories')
]
FactoryGirl.find_definitions

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include FactoryGirl::Syntax::Methods
  conf.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  conf.before(:each) do
    DatabaseCleaner.start
  end

  conf.after(:each) do
    DatabaseCleaner.clean
  end

  conf.after(:all) do
    if Padrino.env == :test
      FileUtils.rm_rf(Dir["#{Padrino.root}/spec/support/uploads"])
    end
  end
end

if defined?(CarrierWave)
  constants = Object.constants.map{|name| Object.const_get(name)}

  constants.select{|c| c.class == Class and c < CarrierWave::Uploader::Base }.each do |klass|
    next if klass.anonymous?
    klass.class_eval do
      def cache_dir
        "#{Padrino.root}/spec/support/uploads/tmp"
      end

      def store_dir
        "#{Padrino.root}/spec/support/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
      end
    end
  end
end

# You can use this method to custom specify a Rack app
# you want rack-test to invoke:
#
#   app Server::
#   app Server::.tap { |a| }
#   app(Server::) do
#     set :foo, :bar
#   end
#
def app(app = nil, &blk)
  @app ||= block_given? ? app.instance_eval(&blk) : app
  @app ||= Padrino.application
end

shared_examples_for "response" do
  subject { last_response }
  it{ should be_ok }
end

shared_examples_for "json" do
  subject { last_response.body }
  it "JSONがパターンとマッチする" do
    should match_json_expression(pattern)
  end
end

shared_examples_for "422" do |count|
  let(:pattern) {{
      message: "Unprocessable Entity",
      errors: count.times.map{{
          field: wildcard_matcher,
          messages: wildcard_matcher
        }
      }
    }
  }
  
  it "バリデーションに引っかかると422が返ってくる" do
    expect(last_response.status).to eq(422)
  end

  it_behaves_like "json"
end

shared_examples_for "404" do
  let(:pattern) {{
      message: "Not Found"
    }
  }

  it "パラメータが足りないと404が返ってくる" do
    expect(last_response.status).to eq(404)
  end

  it_behaves_like "json"
end

shared_examples_for "401" do
  let(:pattern) {{
      message: "Bad credentials"
    }
  }

  it "認証できないと401が返ってくる" do
    expect(last_response.status).to eq(401)
  end

  it_behaves_like "json"
end
