class CreateWebhookEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_events do |t|

      t.timestamps
    end
  end
end
