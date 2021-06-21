# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  has_many :webhook_events, inverse_of: :webhook_endpoint

  validates :subscriptions, length: { minimum: 1 }, presence: true
  validates :url, presence: true

  def subscribed?(event)
    (subscriptions & ['*', event]).any?
  end
end
