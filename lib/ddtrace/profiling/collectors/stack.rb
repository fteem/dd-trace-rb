require 'ddtrace/profiling/backtrace_location'
require 'ddtrace/profiling/events/stack'
require 'ddtrace/utils/only_once'
require 'ddtrace/utils/time'
require 'ddtrace/worker'
require 'ddtrace/workers/polling'

module Datadog
  module Profiling
    module Collectors
      # Collects stack trace samples from Ruby threads for both CPU-time (if available) and wall-clock.
      # Runs on its own background thread.
      class Stack < Worker
        include Workers::Polling

        DEFAULT_MAX_FRAMES = 128
        DEFAULT_MAX_TIME_USAGE_PCT = 2.0
        MIN_INTERVAL = 0.01
        THREAD_LAST_CPU_TIME_KEY = :datadog_profiler_last_cpu_time

        attr_reader \
          :ignore_thread,
          :max_frames,
          :max_time_usage_pct,
          :recorder

        def initialize(recorder, options = {})
          @recorder = recorder
          @max_frames = options[:max_frames] || DEFAULT_MAX_FRAMES
          @ignore_thread = options[:ignore_thread]
          @max_time_usage_pct = options[:max_time_usage_pct] || DEFAULT_MAX_TIME_USAGE_PCT

          # Workers::Async::Thread settings
          # Restart in forks by default
          self.fork_policy = options[:fork_policy] || Workers::Async::Thread::FORK_POLICY_RESTART

          # Workers::IntervalLoop settings
          self.loop_base_interval = options[:interval] || MIN_INTERVAL

          # Workers::Polling settings
          self.enabled = options.key?(:enabled) ? options[:enabled] == true : true

          @warn_about_missing_cpu_time_instrumentation_only_once = Datadog::Utils::OnlyOnce.new
        end

        def start
          @last_wall_time = Datadog::Utils::Time.get_time
          perform
        end

        def perform
          collect_and_wait
        end

        def loop_back_off?
          false
        end

        def collect_and_wait
          run_time = Datadog::Utils::Time.measure do
            collect_events
          end

          # Update wait time to throttle profiling
          self.loop_wait_time = compute_wait_time(run_time)
        end

        def collect_events
          events = []

          # Compute wall time interval
          current_wall_time = Datadog::Utils::Time.get_time
          last_wall_time = if instance_variable_defined?(:@last_wall_time)
                             @last_wall_time
                           else
                             current_wall_time
                           end

          wall_time_interval_ns = ((current_wall_time - last_wall_time).round(9) * 1e9).to_i
          @last_wall_time = current_wall_time

          # Collect backtraces from each thread
          Thread.list.each do |thread|
            next unless thread.alive?
            next if ignore_thread.is_a?(Proc) && ignore_thread.call(thread)

            event = collect_thread_event(thread, wall_time_interval_ns)
            events << event unless event.nil?
          end

          # Send events to recorder
          recorder.push(events) unless events.empty?

          events
        end

        def collect_thread_event(thread, wall_time_interval_ns)
          locations = thread.backtrace_locations
          return if locations.nil?

          # Get actual stack size then trim the stack
          stack_size = locations.length
          locations = locations[0..(max_frames - 1)]

          # Convert backtrace locations into structs
          locations = convert_backtrace_locations(locations)

          thread_id = thread.respond_to?(:native_thread_id) ? thread.native_thread_id : thread.object_id
          trace_id, span_id = get_trace_identifiers(thread)
          cpu_time = get_cpu_time_interval!(thread)

          Events::StackSample.new(
            nil,
            locations,
            stack_size,
            thread_id,
            trace_id,
            span_id,
            cpu_time,
            wall_time_interval_ns
          )
        end

        def get_cpu_time_interval!(thread)
          # Return if we can't get the current CPU time
          unless thread.respond_to?(:cpu_time_instrumentation_installed?) && thread.cpu_time_instrumentation_installed?
            warn_about_missing_cpu_time_instrumentation(thread)
            return
          end

          current_cpu_time_ns = thread.cpu_time(:nanosecond)

          # NOTE: This can still be nil even when all of the checks above passed because of a race: there's a bit of
          # initialization that needs to be done by the thread itself, and it's possible for us to try to sample
          # *before* the thread had time to finish the initialization
          return unless current_cpu_time_ns

          last_cpu_time_ns = (thread[THREAD_LAST_CPU_TIME_KEY] || current_cpu_time_ns)
          interval = current_cpu_time_ns - last_cpu_time_ns

          if interval < 0
            error_message = "Negative interval for cpu time on thread #{thread.inspect}. thread_last_cpu_time: #{thread[THREAD_LAST_CPU_TIME_KEY].inspect}, current_cpu_time_ns: #{current_cpu_time_ns.inspect}, last_cpu_time_set: #{thread[:last_cpu_time_set].inspect}, now: #{Time.now.utc.iso8601(9)}, last_cpu_time_set_pid: #{thread[:last_cpu_time_set_pid].inspect}, pid: #{Process.pid}. Backtrace: #{thread.backtrace}"
            Datadog.logger.error(error_message)

            File.write("/tmp/negative-interval-debug.txt", "#{error_message}\n", mode: "a")
          end

          # Update CPU time for thread
          thread[THREAD_LAST_CPU_TIME_KEY] = current_cpu_time_ns
          thread[:last_cpu_time_set] = Time.now.utc.iso8601(9)
          thread[:last_cpu_time_set_pid] = Process.pid

          # Return interval
          interval
        end

        def get_trace_identifiers(thread)
          return unless thread.is_a?(::Thread)
          return unless Datadog.respond_to?(:tracer) && Datadog.tracer.respond_to?(:active_correlation)

          identifier = Datadog.tracer.active_correlation(thread)
          [identifier.trace_id, identifier.span_id]
        end

        def compute_wait_time(used_time)
          # We took used_time to get the last sample.
          #
          # What we're computing here is -- if used_time corresponds to max_time_usage_pct of the time we should
          # spend working, how much is (100% - max_time_usage_pct) of the time?
          #
          # For instance, if we took 10ms to sample, and max_time_usage_pct is 1%, then the other 99% is 990ms, which
          # means we need to sleep for 990ms to guarantee that we don't spend more than 1% of the time working.
          used_time_ns = used_time * 1e9
          interval = (used_time_ns / (max_time_usage_pct / 100.0)) - used_time_ns
          [interval / 1e9, MIN_INTERVAL].max
        end

        # Convert backtrace locations into structs
        # Re-use old backtrace location objects if they already exist in the buffer
        def convert_backtrace_locations(locations)
          locations.collect do |location|
            # Re-use existing BacktraceLocation if identical copy, otherwise build a new one.
            recorder[Events::StackSample].cache(:backtrace_locations).fetch(
              # Function name
              location.base_label,
              # Line number
              location.lineno,
              # Filename
              location.path,
              # Build function
              &method(:build_backtrace_location)
            )
          end
        end

        def build_backtrace_location(_id, base_label, lineno, path)
          string_table = recorder[Events::StackSample].string_table

          Profiling::BacktraceLocation.new(
            string_table.fetch_string(base_label),
            lineno,
            string_table.fetch_string(path)
          )
        end

        private

        def warn_about_missing_cpu_time_instrumentation(thread)
          @warn_about_missing_cpu_time_instrumentation_only_once.run do
            # Is the profiler thread instrumented? If it is, then we know instrumentation is available, but seems to be
            # missing on this thread we just found.
            #
            # As far as we know, it can be missing due to one the following:
            #
            # a) The thread was started before we installed our instrumentation.
            #    In this case, the fix is to make sure ddtrace gets loaded before any other parts of the application.
            #
            # b) The thread was started using the Ruby native APIs (e.g. from a C extension such as ffi).
            #    We currently have no solution for this case; these threads will always be missing our CPU instrumentation.
            #
            # c) The thread was started with `Thread.start`/`Thread.fork` and hasn't yet enabled the instrumentation.
            #    When threads are started using these APIs, there's a small time window during which the thread has started
            #    but our code to apply the instrumentation hasn't run yet; in these cases it's just a matter of allowing
            #    it to run and our instrumentation to be applied.
            #
            if Thread.current.respond_to?(:cpu_time) && Thread.current.cpu_time
              Datadog.logger.debug("Detected thread ('#{thread}') with missing CPU profiling instrumentation.")
            end
          end
        end
      end
    end
  end
end
