# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class PrimaryCollectionMetric
    include Mongoid::Document
    include Mongoid::Timestamps
  
    store_in collection: 'daily_metrics'
  
    embedded_in :daily_item_metric, class_name: 'SupplejackApi::DailyItemMetric'

    field :name,                 type: String
    field :total_active_records, type: Integer
    field :total_new_records,    type: Integer
    field :category_metrics,     type: Array
    field :usage_type_metrics,   type: Array
  end
end
