namespace :simulate do
  desc "Simulate race condition"
  task race: :environment do
    puts "Starting race condition simulation..."

    # 1. Reset ProductVariant
    # We use a specific ID to ensure we're always working on the same record
    variant = ProductVariant.first_or_create!(name: "Hot Item", inventory_count: 100)
    variant.update!(inventory_count: 100)
    puts "Initial inventory: #{variant.inventory_count}"

    # 2. Spawn 150 concurrent threads (Increased from 50 to ensure overselling/race condition)
    threads = []
    150.times do |i|
      threads << Thread.new do
        # 3. Try to purchase
        # We instantiate a new connection or ensure we are using a separate connection/model instance
        # Rails connection pool should handle this.
        Rails.application.executor.wrap do
          v = ProductVariant.find(variant.id)
          
          if v.inventory_count > 0
            # Artificial delay to heighten race condition chance
            sleep(rand(0.01..0.05))
            v.decrement!(:inventory_count)
            # puts "Thread #{i} bought item."
          end
        end
      end
    end

    threads.each(&:join)

    # 4. Print final inventory
    final_count = variant.reload.inventory_count
    puts "Final inventory: #{final_count}"
    
    if final_count < 0
      puts "FAILURE: Inventory became negative! Race condition confirmed."
    elsif final_count != 50
      puts "FAILURE: Inventory is #{final_count}, expected 50. Race condition (Lost Update) confirmed?"
    else
      puts "SUCCESS: Inventory is 50. No race condition observed with 50 threads/100 items."
      puts "Note: To observe negative inventory (overselling), try increasing threads > 100."
    end
  end
end
