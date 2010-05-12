class AddBelongsToFieldsToLiveStreamSeries < ActiveRecord::Migration
  def self.up
    add_column :live_stream_series, :band_id, :integer, {:null => false, :default => 0}
    add_column :live_stream_series, :api_user_id, :integer, {:null => false, :default => 0}
  end

  def self.down
    remove_column :live_stream_series, :api_user_id
    remove_column :live_stream_series, :band_id
  end
end
