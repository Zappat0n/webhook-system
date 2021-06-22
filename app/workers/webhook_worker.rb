# frozen_string_literal: true

require 'http'

class WebhookWorker
  include Sidekiq::Worker

  sidekiq_options retry: 10, dead: false
  sidekiq_retry_in do |retry_count|
    jitter = rand(30.seconds..10.minutes).to_i

    (retry_count**5) + jitter
  end

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find_by(id: webhook_event_id)
    return unless webhook_event

    webhook_endpoint = webhook_event.webhook_endpoint
    return unless webhook_endpoint

    return unless webhook_endpoint.subscribed?(webhook_event.event) && webhook_endpoint.enabled?

    response = post_query(webhook_event, webhook_endpoint)

    webhook_event.update_response(response)

    raise FailedRequestError unless response.status.sucess?
  rescue OpenSSL::SSL::SSLError
    webhook_event.update(response: { error: 'TLS_ERROR' })
    raise FailedRequestError
  rescue HTTP::ConnectionError
    webhook_event.update(response: { error: 'CONNECTION_ERROR' })
    webhook_endpoint.disable!
  rescue HTTP::TimeoutError
    webhook_event.update(response: { error: 'TIMEOUT_ERROR' })
  end

  private

  def post_query(webhook_event, webhook_endpoint)
    HTTP.timeout(30).headers(
      'User-Agent': 'rails_webhook_system/1.0',
      'Content-Type': 'application/json'
    ).post(
      webhook_endpoint.url,
      body: {
        event: webhook_event.event,
        payload: webhook_event.payload
      }.to_json
    )
  end

  class FailedRequestError < StandardError; end
end
