# frozen_string_literal: true

require 'test_helper'

class AnalyzeJobTest < ActiveSupport::TestCase
  describe 'progress_message' do
    it 'should return required message' do
      job = AnalyzeJob.create(project: create(:project))
      job.progress_message.must_equal "Analyzing project #{job.project.name}"
    end
  end
end
