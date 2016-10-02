# Unexceptional

Provides a Result class for more elegant, exception-free error handling.
Especially useful for processing input that could be invalid for many different reasons.

## API Docs

[http://www.rubydoc.info/github/jarrett/unexceptional/master/Unexceptional/Result](http://www.rubydoc.info/github/jarrett/unexceptional/master/Unexceptional/Result)

## Examples

    Result.try(
      ->    { Result.ok 2 },
      ->(i) { Result.ok 3 * i }
    )
    # => Result.ok(6)
    
    
    Result.try(
      ->    { Result.ok 2 },
      ->(_) { Result.err :uh_oh },
      ->(i) { Result.ok 3 * i }
    )
    # => Result.err(:uh_oh)
    
    
    Result.try(
      ->         { Result.ok [1, 2] },
      ->((a, b)) { Result.ok a + b }
    )
    # => Result.ok(3)
    
    
    Result.map_while([1, 2]) do |i|
      Result.ok i * 2
    end
    # => Result.ok([1, 2])
    
    
    Result.map_while([1, 2, 3]) do |i|
      if i == 2
        Result.err '2 is invalid'
      elsif i == 3
        raise 'This is never executed because Result.map_while aborts on the previous element.'
      else
        Result.ok i * 2
      end
    end
    # => Result.err('2 is invalid')
    
    
    Result
      .err(:uh_oh)
      .and_then { 'This block never executes' }
    # => Result.err(:uh_oh)
    
    
    Result
      .ok('This value gets dropped')
      .and_then(Result.ok('This is the final value'))
    # => Result.ok('This is the final value')
    
    
    Result
      .ok(3)
      .and_then { |v| v * 2 }
    # => Result.ok(6)
    
    
    Result
      .ok('This value gets dropped')
      .and_then
    # => Result.ok