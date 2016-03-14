module Unexceptional
  class Result
    # Pass true or false and an error value. If the first argument is `true`, returns an
    # ok `Result`. If the first argument is false, returns an err `Result` wrapping the
    # error value.
    def self.check(condition, error)
      condition ? ok : err(error)
    end
  
    # Returns a new `Result` respresenting failure. Accepts an optional error value.
    def self.err(err)
      new false, nil, err
    end
  
    # Pass a block and a collection. The block must accept a member of the collection and
    # return a `Result`.
    # 
    # If all members succeed, returns a `Result` wrapping all the mapped members:
    #
    #     Result.map([1, 2]) do |i|
    #       Result.ok i * 2
    #     end
    #     # => Result.ok([1, 2])
    # 
    # Aborts on the first failure:
    #
    #     Result.map([1, 2, 3]) do |i|
    #       if i == 2
    #         Result.err '2 is invalid'
    #       elsif i == 3
    #         raise 'This is never executed because Result.map aborts on the previous element.'
    #       else
    #         Result.ok i * 2
    #       end
    #     end
    #     # => Result.err('2 is invalid')
    def self.map_while(collection)
      Result.ok(
        collection.map do |member|
          result = yield member
          if result.err?
            return result
          else
            result.unwrap
          end
        end
      )
    end
    
    # Returns a new `Result` respresenting success. Accepts an optional result value.
    def self.ok(val = nil)
      new true, val, nil
    end
  
    # Given a block, runs an ActiveRecord transaction. The block must return a `Result`.
    # If the `Result` is an error, rolls back the transaction. Either way, returns the
    # `Result`. You must call `require 'active_record'` before you call this method.
    def self.transaction
      unless defined?(ActiveRecord)
        raise 'ActiveRecord is not defined'
      end
      result = nil
      ActiveRecord::Base.transaction do
        result = yield
        if result.err?
          raise ActiveRecord::Rollback
        end
      end
      result
    end
    
    # Tries to run a list of procs, aborting on the first failure, if any. Each proc must
    # return a `Result`--either ok or err. Aborts on the first err, if any, returning the
    # failed `Result`. If all procs return ok, returns the last `Result`.
    # 
    #     Result.try(
    #       ->    { Result.ok 2 },
    #       ->(i) { Result.ok 3 * i }
    #     )
    #     # => Result.ok(6)
    #     
    #     Result.try(
    #       ->    { Result.ok 2 },
    #       ->(_) { Result.err :uh_oh },
    #       ->(i) { Result.ok 3 * i }
    #     )
    #     # => Result.err(:uh_oh)
    # 
    # You can also pass tuples through and pattern-match:
    # 
    #     Result.try(
    #       ->         { Result.ok [1, 2] },
    #       ->((a, b)) { Result.ok a + b }
    #     )
    #     # => Result.ok(3)
    # 
    # If you need to initialize a lot of objects along the way, passing them through the
    # various procs via pattern-matching can be unwieldy. In that case, you can use the
    # `#set` method along with instance variables:
    # 
    #     Result.try(
    #       -> { set :a, Result.ok(2) },
    #       -> { set :b, Result.ok(@a * 3) },
    #       -> { Result.ok(@b * 4) }
    #     )
    #     # => Result.ok(24)
    # 
    # This defines `#set` on whatever object is currently `self`. If `#set` was previously
    # defined, it'll be temporarily overwritten.
    def self.try(*procs)
      if procs.empty?
        raise 'Must past at least one proc to Result.try'
      end
      procs.inject(nil) do |last_result, proc|
        # Ruby 2.2 introduced Binding#receiver. But to support Ruby <= 2.1, we use eval.
        ctx = proc.binding.eval('self')
        
        # Extend ctx's metaclass with the #set method, saving the previous #set if any.
        class << ctx
          if method_defined? :set
            alias_method :__set_before_try, :set
          end
          
          def set(var, result)
            if result.ok?
              instance_variable_set '@' + var.to_s, result.unwrap
            end
            result
          end
        end
        
        # Maybe call the proc, maybe with arguments.
        if last_result.nil?
          result = proc.call
        elsif !last_result.is_a?(Result)
          raise "Each proc in Result.try must return a Result, but proc returned #{last_result.inspect}"
        elsif last_result.ok?
          if proc.parameters.length == 0
            result = proc.call
          else
            result = proc.call last_result.unwrap
          end
        else
          result = last_result
        end
        
        # Undo the changes to ctx's metaclass.
        class << ctx
          if method_defined? :__set_before_try
            alias_method :set, :__set_before_try
          else
            remove_method :set
          end
        end
        
        # Return the result of the current proc.
        result
      end
    end
    
    # If this `Result` is an err, returns self:
    #
    #     Result
    #       .err(:uh_oh)
    #       .and_then { 'This block never executes' }
    #     # => Result.err(:uh_oh)
    # 
    # If this `Result` is ok, then the behavior depends on what you passed to `and_then`:
    # 
    #     # Passing a single argument:
    #     Result
    #       .ok('This value gets dropped')
    #       .and_then(Result.ok('This is the final value'))
    #     # => Result.ok('This is the final value')
    #     
    #     # Passing a block:
    #     Result
    #       .ok(3)
    #       .and_then { |v| v * 2 }
    #     # => Result.ok(6)
    #     
    #     # Passing nothing:
    #     Result
    #       .ok('This value gets dropped')
    #       .and_then
    #     # => Result.ok
    def and_then(next_result = nil)
      if @ok
        if block_given?
          yield
        elsif next_result
          next_result
        else
          Result.ok
        end
      else
        self
      end
    end
    
    # Yields this `Result` if this `Result` is an err.
    def if_err
      yield self.err if !@ok
      self
    end
    
    # Yields this `Result` if this Result is ok.
    def if_ok
      yield self.val if @ok
      self
    end
    
    # Returns the inner err value. Raises if this `Result` is ok.
    def err
      if !@ok
        @err
      else
        raise "Called #err, but Result was ok."
      end
    end
  
    # Returns true if this Result is an err, false if this Result is ok.
    def err?
      !@ok
    end
    
    def initialize(ok, val, err) # :nodoc:
      @ok = ok
      @val = val
      @err = err
    end
    
    # Returns true if this Result is ok, false if this Result is an err.
    def ok?
      @ok
    end
    
    # Returns the inner success value. Raises if this Result is an err.
    def unwrap
      if @ok
        @val
      else
        raise "Called #unwrap on error: #{@err.inspect}"
      end
    end
    alias_method :ok, :unwrap
  end
end