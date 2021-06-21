# frozen_string_literal: true

class AddSuscriptionsToWebhookEndpoints < ActiveRecord::Migration[6.1]
  def change
    add_column :webhook_endpoints, :subscriptions, :jsonb, default: ['*']
  end
end
