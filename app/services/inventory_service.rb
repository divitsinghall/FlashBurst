class InventoryService
  # Optimization: Use a ConnectionPool for thread-safety and performance
  # Also ensures we use REDIS_URL from environment for Docker compatibility
  def self.redis
    @redis ||= ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i, timeout: 5) do
      Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    end
  end

  def self.reserve_stock(variant_id, quantity)
    key = "product_variant:#{variant_id}:inventory"
    
    # Lua script for atomic check-and-decrement
    script = <<~LUA
      local current_stock = redis.call('get', KEYS[1])
      
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

    # Use .with to check out a connection from the pool
    redis.with do |conn|
      result = conn.eval(script, keys: [key], argv: [quantity])
      result == 1
    end
  end
end
