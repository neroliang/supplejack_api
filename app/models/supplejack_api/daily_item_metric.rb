# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class DailyItemMetric
    include Mongoid::Document
    include Mongoid::Timestamps
  
    store_in collection: 'daily_metrics'

    embeds_many :primary_collection_metrics, class_name: 'SupplejackApi::PrimaryCollectionMetric'
    accepts_nested_attributes_for :primary_collection_metrics
  
    field :total_active_records,  type: Integer
    field :day,                   type: Date
  
    index created_at: 1
  end
end
