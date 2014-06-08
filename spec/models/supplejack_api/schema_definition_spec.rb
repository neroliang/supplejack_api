# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module SupplejackApi
  describe SchemaDefinition do

    class ExampleSchema
      include SchemaDefinition

      namespace :dc, url: 'http://purl.org/dc/elements/1.1/'

      string :title,                  search_boost: 10, search_as: [:fulltext], namespace: :dc
      string :display_collection
      string :primary_collection,     multi_value: true,  search_as: [:filter]
      boolean :is_natlib_record,                          search_as: [:filter]
      integer :year do
        multi_value true
        store false
        search_as [:filter]
        search_value do |record|
          record.date.map { |date| Date.parse(date).year rescue nil}.compact if record.date
        end
      end
      datetime :syndication_date,                         search_as: [:filter]
      string :text, solr_name: :text

      group :default do
        fields [
          :title,
          :year
        ]
      end

      group :verbose do
        includes [:default]
        fields [
          :locations
        ]
      end

      group :everything do
        includes [:default, :verbose]
        fields [
          :id
        ]
      end

      role :admin
      role :user

      role :developer do
        default true
        field_restrictions (
          {
            creator: { 'John Smith' => ['attachments', 'location'] },
            thumbnail_url: { /^http:\/\/secret/ => ['thumbnail_url'] }
          }
        )
        record_restrictions (
          {
            is_catalog_record: true
          }
        )
      end
    end


    describe '#fields' do

      it "prefixes the field name with the namespace" do
        ExampleSchema.fields[:dc_title].should_not be_nil
        ExampleSchema.fields[:title].should be_nil
      end

      it "describes dc_title" do
        ExampleSchema.fields[:dc_title].name.should eq :dc_title
        ExampleSchema.fields[:dc_title].type.should eq :string
        ExampleSchema.fields[:dc_title].search_boost.should eq 10
        ExampleSchema.fields[:dc_title].search_as.should eq [:fulltext]
        ExampleSchema.fields[:dc_title].namespace.should eq :dc
      end

      it 'describes display_collection' do
        ExampleSchema.fields[:display_collection].name.should eq :display_collection
        ExampleSchema.fields[:display_collection].type.should eq :string
      end

      it 'describes primary_collection' do
        ExampleSchema.fields[:primary_collection].name.should eq :primary_collection
        ExampleSchema.fields[:primary_collection].type.should eq :string
        ExampleSchema.fields[:primary_collection].multi_value.should be_true
        ExampleSchema.fields[:primary_collection].search_as.should eq [:filter]
      end

      it 'describes is_natlib_record' do
        ExampleSchema.fields[:is_natlib_record].name.should eq :is_natlib_record
        ExampleSchema.fields[:is_natlib_record].type.should eq :boolean
      end

      it 'describes year' do
        ExampleSchema.fields[:year].name.should eq :year
        ExampleSchema.fields[:year].type.should eq :integer
        ExampleSchema.fields[:year].multi_value.should be_true
        ExampleSchema.fields[:year].store.should be_false
        ExampleSchema.fields[:year].search_as.should eq [:filter]
        ExampleSchema.fields[:year].search_value.should be_a Proc
      end

      it 'describes syndication_date' do
        ExampleSchema.fields[:syndication_date].name.should eq :syndication_date
        ExampleSchema.fields[:syndication_date].type.should eq :datetime
        ExampleSchema.fields[:syndication_date].search_as.should eq [:filter]
      end

      it 'describes text' do
        ExampleSchema.fields[:text].name.should eq :text
        ExampleSchema.fields[:text].type.should eq :string
        ExampleSchema.fields[:text].solr_name.should eq :text
      end
    end

    describe '#groups' do
      it 'returns all the groups defined' do
        ExampleSchema.groups.keys.should eq([:default, :verbose, :everything])
      end

      describe '#fields' do
        it 'returns a list of fields in a group' do
          ExampleSchema.groups[:default].fields.should eq([:title, :year])
        end
      end

      context 'includes groups' do
        it 'includes another group of fields' do
          ExampleSchema.groups[:verbose].fields.should eq([:title, :year, :locations])
        end

        it 'includes multiple groups of fields' do
          ExampleSchema.groups[:everything].fields.should eq([:title, :year, :locations, :id])
        end
      end
    end

    describe '#roles' do
      it 'should all the roles defined' do
        ExampleSchema.roles.keys.should eq([:admin, :user, :developer])
      end

      context 'field_restrictions' do
        let(:restrictions) { ExampleSchema.roles[:developer].field_restrictions }

        it 'should create a restriction on the attachments and location fields if the creator is John Smith' do
          restrictions[:creator].should eq( {'John Smith' => ['attachments', 'location']} )
        end

        it 'should create a restriction on the thumbnail_url field if contains a value (matches regex)' do
          restrictions[:thumbnail_url].should eq( {/^http:\/\/secret/ => ['thumbnail_url']} )
        end
      end

      context 'record_restrictions' do
        let(:restrictions) { ExampleSchema.roles[:developer].record_restrictions }

        it 'should create a restriction on records where is_catalog_record is true' do
          restrictions[:is_catalog_record].should be_true
        end

        it 'should not create a restriction if none are set' do
          ExampleSchema.roles[:admin].record_restrictions.should be_nil
        end
      end

      context 'default' do
        it 'should set the developer role as default' do
          ExampleSchema.default_role.name.should eq :developer
        end

        it 'should not set the admin role as default' do
          ExampleSchema.default_role.name.should_not eq :admin
        end
      end
    end

  end
end
