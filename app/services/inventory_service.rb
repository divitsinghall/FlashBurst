class InventoryService
  # We use a global Redis connection. In a real app, this might be injected or from a pool.
  # Assuming REDIS constant is defined in an initializer, or we create a new connection.
  # For simplicity in this task, we can use Redis.new if REDIS isn't defined, 
  # but best practice is a shared connection.
  
  def self.redis
    @redis ||= Redis.new
  end

  def self.reserve_stock(variant_id, quantity)
    key = "product_variant:#{variant_id}:inventory"
    
    # Lua script for atomic check-and-decrement
    # KEYS[1] = inventory key
    # ARGV[1] = quantity to decrement
    script = <<~LUA
      local current_stock = redis.call('get', KEYS[1])
      
      -- If key doesn't exist, we can't reserve. 
      -- In a real app, we might fallback to DB or treat as 0.
      if not current_stock then
        return 0
      end
      
      if tonumber(current_stock) >= tonumber(ARGV[1]) then
        redis.call('decrby', KEYS[1], ARGV[1])
        return 1
      else
        return 0
      end
    LUA

    # eval returns the result of the script
    # 1 = success, 0 = failure
    result = redis.eval(script, keys: [key], argv: [quantity])
    
    result == 1
  end
end
