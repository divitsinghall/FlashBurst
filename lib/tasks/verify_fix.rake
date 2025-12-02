namespace :verify do
  desc "Verify fix with Redis Atomic Reservation"
  task fix: :environment do
    puts "Starting verification of the fix..."

    # 1. Reset ProductVariant and Redis
    variant = ProductVariant.first_or_create!(name: "Hot Item", inventory_count: 100)
    variant.update!(inventory_count: 100)
    
    # Initialize Redis key
    redis_pool = InventoryService.redis
    key = "product_variant:#{variant.id}:inventory"
    redis_pool.with { |r| r.set(key, 100) }
    
    puts "Initial inventory (DB): #{variant.inventory_count}"
    puts "Initial inventory (Redis): #{redis_pool.with { |r| r.get(key) }}"

    # 2. Spawn 150 concurrent threads
    threads = []
    success_count = 0
    mutex = Mutex.new

    150.times do |i|
      threads << Thread.new do
        # 3. Try to purchase via Service (simulating Mutation)
        Rails.application.executor.wrap do
          if InventoryService.reserve_stock(variant.id, 1)
            mutex.synchronize { success_count += 1 }
            # In real app, job would run here. We can simulate job delay or just trust the service.
            # The job decrements DB.
            OrderCreationJob.perform_now(variant.id)
          end
        end
      end
    end

    threads.each(&:join)

    # 4. Print final inventory
    final_db_count = variant.reload.inventory_count
    final_redis_count = redis_pool.with { |r| r.get(key).to_i }
    
    puts "Final inventory (DB): #{final_db_count}"
    puts "Final inventory (Redis): #{final_redis_count}"
    puts "Successful purchases: #{success_count}"

    if final_redis_count < 0
      puts "FAILURE: Redis inventory became negative!"
    elsif final_db_count < 0
      puts "FAILURE: DB inventory became negative!"
    elsif final_redis_count != 0
      puts "FAILURE: Redis inventory should be 0 (sold out), got #{final_redis_count}"
    elsif final_db_count != 0
      puts "FAILURE: DB inventory should be 0 (sold out), got #{final_db_count}"
    elsif success_count != 100
      puts "FAILURE: Should have sold exactly 100 items, sold #{success_count}"
    else
      puts "SUCCESS: Inventory is 0. Exactly 100 items sold. No race condition."
    end
  end
end
