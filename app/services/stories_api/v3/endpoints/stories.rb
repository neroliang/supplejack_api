# frozen_string_literal: true
module StoriesApi
  module V3
    module Endpoints
      class Stories
        include Helpers

        attr_reader :params, :errors

        def initialize(params)
          @params = params
        end

        def get
          user = params[:user_id]
          user_account = SupplejackApi::User.find_by_api_key(user)

          return create_exception('UserNotFound', { id: user }) unless user_account.present?

          presented_stories = user_account.user_sets.map(&::StoriesApi::V3::Presenters::Story)

          create_response(status: 200, payload: presented_stories)
        end

        def post
          story = params[:story]

          return create_exception('MandatoryParamMissing',
                                  { param: :name }) unless story.is_a?(Hash) && story[:name].present?

          story_name = params[:story][:name]
          new_story = current_user(params).user_sets.create(name: story_name)

          create_response(status: 200, payload: ::StoriesApi::V3::Presenters::Story.new.call(new_story))
        end
      end
    end
  end
end
