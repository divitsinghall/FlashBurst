module Mutations
  class CheckoutCreate < BaseMutation
    argument :variant_id, ID, required: true

    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve(variant_id:)
      # 1. Attempt to reserve stock via Redis
      if InventoryService.reserve_stock(variant_id, 1)
        # 2. If successful, enqueue background job
        OrderCreationJob.perform_later(variant_id)
        
        {
          success: true,
          message: "Order placed successfully!"
        }
      else
        # 3. If failed, return failure
        {
          success: false,
          message: "Out of stock!"
        }
      end
    end
  end
end
