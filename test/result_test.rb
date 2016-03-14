require 'test_helper'

class ResultTest < Minitest::Test
  include Unexceptional
  
  def test_try
    # Success.
    result = Result.try(
      ->    { Result.ok(2)     },
      ->(v) { Result.ok(v * 3) },
      ->(v) { Result.ok(v - 1) }
    )
    assert result.ok?
    refute result.err?
    assert_equal 5, result.unwrap
    
    # Failure partway through.
    result = Result.try(
      ->    { Result.ok(2)     },
      ->(v) { Result.err :foo  },
      ->(v) { Result.err :bar  },
      ->(v) { Result.ok(v - 1) },
      ->(v) { Result.err :baz  },
      ->(v) { Result.ok(v * 3) }
    )
    assert result.err?
    refute result.ok?
    assert_equal :foo, result.err
    
    # Pattern-matching tuples.
    result = Result.try(
      ->         { Result.ok [1, 2] },
      ->((a, b)) { Result.ok a + b }
    )
    assert_equal 3, result.unwrap
    
    # Setting locals.
    result = Result.try(
      -> { set :a, Result.ok(2); },
      -> { set :b, Result.ok(@a * 3) },
      -> { set :c, Result.err(@b * 4) },
      -> { set :d, Result.ok(@c * 5) }
    )
    assert result.err?
    refute result.ok?
    assert_equal 24, result.err
    
    # Setting locals with an object that already has a #set method.
    o = MetaclassExample.new
    result = nil
    assert_equal :before, o.set
    o.instance_eval do
      result = Result.try(
        -> { set :a, Result.ok(2); },
        -> { set :b, Result.ok(@a * 3) },
        -> { set :c, Result.err(@b * 4) },
        -> { set :d, Result.ok(@c * 5) }
      )
    end
    assert_equal :before, o.set
    assert result.err?
    refute result.ok?
    assert_equal 24, result.err
  end
  
  def test_map_while
    # Success.
    result = Result.map_while([1, 2, 3, 4]) do |num|
      Result.ok(num * 2)
    end
    assert result.ok?
    refute result.err?
    assert_equal [2, 4, 6, 8], result.unwrap
    
    # Failure
    mapped = []
    result = Result.map_while([1, 2, false, 4]) do |num|
      mapped << num
      if num.is_a? Integer
        Result.ok(num * 2)
      else
        Result.err "#{num.inspect} isn't an integer"
      end
    end
    assert_equal [1, 2, false], mapped
    assert result.err?
    refute result.ok?
    assert_equal "false isn't an integer", result.err
  end
  
  def test_transaction
    require File.expand_path(File.join(File.dirname(__FILE__), 'active_record_helper'))
    
    # Success.
    assert_equal 0, User.count
    result = Result.transaction do
      user = User.create! id: 101
      assert_equal 1, User.count
      Result.ok user
    end
    assert_equal 1, User.count
    assert result.ok?
    refute result.err?
    assert_equal 101, result.unwrap.id
    
    # Failure.
    User.destroy_all
    assert_equal 0, User.count
    result = Result.transaction do
      User.create id: 101
      assert_equal 1, User.count
      Result.err 'Uh-oh'
    end
    assert_equal 0, User.count
    assert result.err?
    refute result.ok?
    assert_equal 'Uh-oh', result.err
  end
  
  # Verifies that we can manipulate metaclasses as we expect.
  def test_metaclass
    o = MetaclassExample.new
    assert_equal :before, o.set
    class << o
      alias_method :__set_before_try, :set
      def set
        :after
      end
    end
    assert_equal :after, o.set
    class << o
      alias_method :set, :__set_before_try
    end
    assert_equal :before, o.set
  end
  
  class MetaclassExample
    def set
      :before
    end
  end
end