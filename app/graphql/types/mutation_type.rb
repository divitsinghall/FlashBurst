# frozen_string_literal: true

  class MutationType < Types::BaseObject
    field :checkout_create, mutation: Mutations::CheckoutCreate
  end
