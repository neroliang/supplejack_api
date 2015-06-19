# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'json'

namespace :concepts do
  task :all => ['import_concepts', 'import_source_authorities', 'bind_records', 'index']

	desc 'Import concepts'
  task import_concepts: :environment do
    puts 'Importing concepts'

    file = File.read("#{Rails.root}/db/concepts.json")
    concepts_hash = JSON.parse(file)

    concepts_hash.each do |concept|
    	existing_concept = SupplejackApi::Concept.where(concept_id: concept['concept_id']).first
    	SupplejackApi::Concept.create(concept) if existing_concept.nil?
    end
  end

  desc 'Import source authorities'
  task import_source_authorities: :environment do
    puts 'Importing source authorities'

    file = File.read("#{Rails.root}/db/source_authorities.json")
    source_authorities_hash = JSON.parse(file)

    SupplejackApi::SourceAuthority.delete_all

    source_authorities_hash.each do |source_authority|
    	concept = SupplejackApi::Concept.where(concept_id: source_authority['concept_id']).first
    	concept.source_authorities << SupplejackApi::SourceAuthority.create!(source_authority) if concept
    end
  end

  desc 'Import binding records'
  task bind_records: :environment do
    puts 'Binding records with concepts'
    file = File.read("#{Rails.root}/db/binding_records.json")
    records_hash = JSON.parse(file)

    records_hash.each do |item|
      record = SupplejackApi::Record.custom_find(item['record_id'])
      concept_ids = item['concept_id']
      concept_ids.each do |concept_id|
        concept = SupplejackApi::Concept.custom_find(concept_id)
        record.concepts << concept
        record.save
      end
    end
  end

  desc 'Index Concepts and Records'
  task index: :environment do
    Sunspot.session = Sunspot::Rails.build_session
    SupplejackApi::Concept.all.map(&:index!)
    ::Record.all.map(&:index!)
  end

  desc 'Clear all concepts, source authorities'
  task reset: :environment do
    Sunspot.session = Sunspot::Rails.build_session
    Sunspot.remove_all
    SupplejackApi::Concept.delete_all
    SupplejackApi::SourceAuthority.delete_all
    ::Record.delete_all
  end

end