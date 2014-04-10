require 'spec_helper'

module SupplejackApi
  describe ApiRecord::FragmentHelpers do
    let(:record) { FactoryGirl.build(:record_with_fragment, record_id: 1234) }
  
    describe '#before_save' do
      its 'shouuld call merge_fragments' do
        record.should_receive(:merge_fragments)
        record.save
      end
    end
  
    describe 'merge_fragments' do
      let(:record) { FactoryGirl.build(:record_with_fragment) }
      let(:primary) { record.fragments.first }
      let(:secondary) { record.fragments.last }
  
      it 'should delete any existing merged fragment' do
        record.merged_fragment = FactoryGirl.build(:fragment)
        record.save
        record.merged_fragment.should be_nil
      end
  
      context 'one fragment' do
        it 'should not save the merged fragment' do
          record.merge_fragments
          record.merged_fragment.should be_nil
        end
      end
  
      context 'multiple fragments' do
        before(:each) do
          record.fragments << FactoryGirl.build(:fragment, name: 'James Smith', email: ['js@google.com'])
          record.save!
        end
  
        context 'single value fields' do
          it 'should store the first non-nil value of the field' do
            primary.name = nil
            record.save
            record.merged_fragment.name.should eq 'James Smith'
          end
        end
  
        context 'multi-value fields' do
          it 'should store the merged values of the field' do
            record.merged_fragment.email.should eq ['jdoe@example.com', 'js@google.com']
          end
  
          it 'should not return duplicate values' do
            primary.email = ['jdoe@example.com', 'js@google.com']
            record.save
            record.merged_fragment.email.should eq ['jdoe@example.com', 'js@google.com']
          end
  
          it 'should not return nil values' do
            secondary.email = nil
            record.save
            record.merged_fragment.email.should eq ['jdoe@example.com']
          end
        end
      end
    end
  
    describe '#method_missing' do
      let(:record) { FactoryGirl.create(:record_with_fragment) }
  
      context 'no fragments' do
        let(:record) { FactoryGirl.create(:record) }
  
        it 'should return nil' do
          record.nz_citizen.should be_nil
        end
      end
  
      context 'single fragment' do
        it 'should return a single value field from merged_fragment' do
          record.name.should eq 'John Doe'
        end
  
        its 'returns an array for an empty mutli-value field' do
          record.children.should eq []
        end
      end
  
      context 'multiple fragments' do
        before(:each) do
          record.fragments << FactoryGirl.build(:fragment, email: ['joe@gmail.com'])
          record.save!
        end
  
        it 'should return a single value field from merged_fragment' do
          record.name.should eq 'John Doe'
        end
  
        it 'should return the multi-value field values from merged_fragment' do
          record.email.should eq ['jdoe@example.com', 'joe@gmail.com']
        end
      end
    end
  
    describe '#find_fragment' do
      before { record.save }
  
      let!(:fragment) { record.fragments.create(source_id: 'thumbnails_enrichment') }
  
      it 'should find a fragment by source_id' do
        record.find_fragment('thumbnails_enrichment').should eq fragment
      end
  
      it 'should return nil when it doesn\'t find a fragment' do
        record.find_fragment('nlnzcat').should be_nil
      end
    end
  
    describe '#primary_fragment' do
      let(:record) { FactoryGirl.build(:record) }
      before { record.save }
  
      it 'returns the fragment with priority 0' do
        fragment1 = record.fragments.create(name: 'John', priority: 1)
        fragment0 = record.fragments.create(name: 'John', priority: 0)
        record.primary_fragment.should eq fragment0
      end
  
      it 'returns a new fragment with priority 0' do
        record.primary_fragment.should be_a Fragment
        record.primary_fragment.priority.should eq 0
      end
  
      it 'should build a primary fragment with default attributes' do
        record.primary_fragment(name: 'John').name.should eq 'John'
      end
    end
  
    describe '#sorted_fragments' do
      it 'returns a list of fragments sorted by priority' do
        record.fragments.build(priority: 10)
        record.fragments.build(priority: -1)
        record.fragments.build(priority: 5)
  
        record.sorted_fragments.map(&:priority).should eq [-1,0,5,10] 
      end
    end
  end
end
