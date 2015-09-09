# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class DisplayCollectionMetric
    include Mongoid::Document
    include Mongoid::Timestamps

    before_save :replace_periods
    after_save :replace_unicode_periods
    after_find :replace_unicode_periods

    store_in collection: 'daily_metrics'

    embedded_in :daily_item_metric, class_name: 'SupplejackApi::DailyItemMetric'

    field :name,                 type: String
    field :total_active_records, type: Integer
    field :total_new_records,    type: Integer
    field :category_counts,      type: Hash
    field :copyright_counts,     type: Hash

    def replace_periods
      if self.category_counts.present?
        self.category_counts  = Hash[self.category_counts. map(&key_replacer(".", "\u2024"))]
      end
      if self.copyright_counts.present?
        self.copyright_counts = Hash[self.copyright_counts.map(&key_replacer(".", "\u2024"))]
      end
    end

    def replace_unicode_periods
      if self.category_counts.present?
        self.category_counts  = Hash[self.category_counts. map(&key_replacer("\u2024", "."))]
      end
      if self.copyright_counts.present?
        self.copyright_counts = Hash[self.copyright_counts.map(&key_replacer("\u2024", "."))]
      end
    end

    private
    def key_replacer(target, replacement)
      ->(kv) do
        key, value = kv

        [key.gsub(target, replacement), value]
      end
    end
  end
end
