class OrderCreationJob < ApplicationJob
  queue_as :default

  def perform(variant_id)
    # 1. Create the Order
    # In a real app, we might pass user_id, payment_info, etc.
    Order.create!(product_variant_id: variant_id, status: 'pending')

    # 2. Sync inventory to DB (Optional but good for consistency)
    # Since we already decremented in Redis, we should reflect that in DB eventually.
    # However, simply decrementing blindly might be risky if we rely solely on Redis.
    # But given the prompt says "sync the final count to PostgreSQL", we should do it.
    # We use decrement! which is atomic in DB, but we don't check for > 0 here 
    # because Redis already guaranteed the reservation.
    
    ProductVariant.find(variant_id).decrement!(:inventory_count)
  end
end
