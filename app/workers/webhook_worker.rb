require 'http.rb'

class WebhookWorker
  include Sidekiq::Worker

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find_by(id: webhook_event_id)
    return unless webhook_event

    webhook_endpoint = webhook_event.webhook_endpoint
    return unless webhook_endpoint

    response = post_query(webhook_event, webhook_endpoint)

    webhook_event.update(response: {
                           headers: response.headers.to_h,
                           code: response.code.to_i,
                           body: response.body.to_s
                         })

    raise FailedRequestError unless response.status.sucess?
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
