class DisableTooltipSelectors < ActiveRecord::Migration
  def change
    Tooltip.find_each do |tooltip|
      tooltip.update_attributes key_enabled: true,
        selector_enabled: false
    end
  end
end
