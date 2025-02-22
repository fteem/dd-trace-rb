# typed: false
require 'spec_helper'

require 'ddtrace/profiling/events/stack'

RSpec.describe Datadog::Profiling::Events do
  describe Datadog::Profiling::Events::Stack do
    describe '::new' do
      subject(:event) do
        described_class.new(
          timestamp,
          frames,
          total_frame_count,
          thread_id,
          trace_id,
          span_id,
          trace_resource_container
        )
      end

      let(:timestamp) { double('timestamp') }
      let(:frames) { double('frames', collect: []) }
      let(:total_frame_count) { double('total_frame_count') }
      let(:thread_id) { double('thread_id') }
      let(:trace_id) { double('trace_id') }
      let(:span_id) { double('span_id') }
      let(:trace_resource_container) { double('trace_resource_container') }

      it do
        is_expected.to have_attributes(
          timestamp: timestamp,
          frames: frames,
          total_frame_count: total_frame_count,
          thread_id: thread_id,
          trace_id: trace_id,
          span_id: span_id,
          trace_resource_container: trace_resource_container
        )
      end
    end
  end

  describe Datadog::Profiling::Events::StackSample do
    describe '::new' do
      subject(:event) do
        described_class.new(
          timestamp,
          frames,
          total_frame_count,
          thread_id,
          trace_id,
          span_id,
          trace_resource_container,
          cpu_time_interval_ns,
          wall_time_interval_ns
        )
      end

      let(:timestamp) { double('timestamp') }
      let(:frames) { double('frames', collect: []) }
      let(:total_frame_count) { double('total_frame_count') }
      let(:thread_id) { double('thread_id') }
      let(:trace_id) { double('trace_id') }
      let(:span_id) { double('span_id') }
      let(:trace_resource_container) { double('trace_resource_container') }
      let(:cpu_time_interval_ns) { double('cpu_time_interval_ns') }
      let(:wall_time_interval_ns) { double('wall_time_interval_ns') }

      it do
        is_expected.to have_attributes(
          timestamp: timestamp,
          frames: frames,
          total_frame_count: total_frame_count,
          thread_id: thread_id,
          trace_id: trace_id,
          span_id: span_id,
          trace_resource_container: trace_resource_container,
          cpu_time_interval_ns: cpu_time_interval_ns,
          wall_time_interval_ns: wall_time_interval_ns
        )
      end
    end
  end
end
