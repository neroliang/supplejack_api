# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module SupplejackApi
  describe ApplicationController do
    routes { SupplejackApi::Engine.routes }
  
    before(:each) do
      @controller = ApplicationController.new
      @controller.stub(:render) { nil }
    end

    describe '#authenticate_user!' do
      before(:each) do
        @controller.stub(:params) { { api_key: '12345' } }
        @controller.stub(:request) { double(:request, ip: '1.1.1.1', format: :json) }
        @user = FactoryGirl.create(:user)
        @user.stub(:update_daily_activity) {  nil }
        @controller.stub(:current_user) {  @user }
      end

      it 'should set the current_user' do
        @controller.authenticate_user!
        @controller.current_user.should eq @user
      end

      it 'updates the tracked fields for the user' do
        @user.should_receive(:update_tracked_fields)
        @controller.authenticate_user!
      end

      it 'updates the daily activity for the user' do
        @user.should_receive(:update_daily_activity)
        @controller.authenticate_user!
      end

      it 'verifies the user limits' do
        @user.should_receive(:check_daily_requests)
        @controller.authenticate_user!
      end

      it 'saves the user' do
        @user.should_receive(:save)
        @controller.authenticate_user!
      end

      context 'user over daily requests limit' do
        it 'returns a error message' do
          @user.stub(:over_limit?) { true }
          @controller.should_receive(:render).with({ json: { errors: 'You have reached your maximum number of api requests today' }, status: :forbidden })
          @controller.authenticate_user!
        end
      end

      context 'api_key not found' do
        it 'returns a error message' do
          @controller.stub(:current_user) {  nil }
          @controller.should_receive(:render).with({ json: { errors: 'Invalid API Key' }, status: :forbidden})
          @controller.authenticate_user!
        end
      end

      context 'api key not provided' do
        it 'returns a error message' do
          @controller.stub(:params) {  { api_key: ''} }
          @controller.should_receive(:render).with({ json: { errors: 'Please provide a API Key' }, status: :forbidden })
          @controller.authenticate_user!
        end
      end

      context 'wrong format' do
        it 'returns a error message in the default format' do
          @controller.stub(:params) { {} }
          @controller.stub(:request) { double(:request, format: :css).as_null_object }
          @controller.should_receive(:render).with({ json: { errors: 'Please provide a API Key' }, status: :forbidden })
          @controller.authenticate_user!
        end
      end
    end
  end
end
