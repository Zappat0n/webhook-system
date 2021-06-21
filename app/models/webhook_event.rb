# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  belongs_to :webhook_endpoint, inverse_of: :webhook_events

  validates :event, presence: true
  validates :payload, presence: true

  scope :update_response, lambda { |response|
                            update(response: {
                                     headers: response.headers.to_h,
                                     code: response.code.to_i,
                                     body: response.body.to_s
                                   })
                          }
end
