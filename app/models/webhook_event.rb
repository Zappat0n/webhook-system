class WebhookEvent < ApplicationRecord
  belongs_to :webhook_endpoint, inverse_of: :webhook_events

  validates :event, presence: true
  validates :payload, presence: true
end
