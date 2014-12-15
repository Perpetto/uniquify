module Uniquify
  def self.included(base)
    base.extend ClassMethods
  end

  def ensure_unique(name)
    begin
      self[name] = yield
    end while self.class.exists?(name => self[name])
  end

  module ClassMethods

    def uniquify(*args, &block)
      options = { :length => 8, :chars => ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a }
      options.merge!(args.pop) if args.last.kind_of? Hash
      args.each do |name|
        before_validation :on => :create do |record|
          if block
            record.ensure_unique(name, &block)
          else
            record.ensure_unique(name) do
              Array.new(options[:length]) { options[:chars].to_a[rand(options[:chars].to_a.size)] }.join
            end
          end
        end
        define_custom_token_finder_for(self, name)
      end
    end


    # ripped from mongoid_token gem
    def define_custom_token_finder_for(klass, field_name = :token)
      klass.define_singleton_method(:"find_by_#{field_name.to_s}") do |token|
        self.find_by(field_name.to_sym => token)
      end

      klass.define_singleton_method :"find_with_#{field_name}" do |*args| # this is going to be painful if tokens happen to look like legal object ids
        args.all?{|arg| arg.to_i != 0 } ? send(:"find_without_#{field_name}",*args) : klass.send(:"find_by_#{field_name.to_s}", args.first)
      end

      # this craziness taken from, and then compacted into a string class_eval
      # http://geoffgarside.co.uk/2007/02/19/activesupport-alias-method-chain-modules-and-class-methods/
      klass.class_eval("class << self; alias_method_chain :find, :#{field_name} if self.method_defined?(:find); end")
    end

  end
end

class ActiveRecord::Base
  include Uniquify
end
