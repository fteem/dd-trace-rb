# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/memory_profiler/all/memory_profiler.rbi
#
# memory_profiler-0.9.14

module MemoryProfiler
  def self.report(opts = nil, &block); end
  def self.start(opts = nil); end
  def self.stop; end
end
class MemoryProfiler::Helpers
  def guess_gem(path); end
  def initialize; end
  def lookup_class_name(klass); end
  def lookup_location(file, line); end
  def lookup_string(obj); end
end
class MemoryProfiler::Polychrome
  def bg_black(str); end
  def bg_blue(str); end
  def bg_brown(str); end
  def bg_cyan(str); end
  def bg_gray(str); end
  def bg_green(str); end
  def bg_magenta(str); end
  def bg_red(str); end
  def black(str); end
  def blue(str); end
  def bold(str); end
  def brown(str); end
  def cyan(str); end
  def gray(str); end
  def green(str); end
  def line(text); end
  def magenta(str); end
  def path(text); end
  def red(str); end
  def reverse_color(str); end
  def string(text); end
end
class MemoryProfiler::Monochrome
  def line(text); end
  def path(text); end
  def string(text); end
end
module MemoryProfiler::TopN
  def top_n(max, metric_method); end
end
class MemoryProfiler::Stat
  def class_name; end
  def file; end
  def gem; end
  def initialize(class_name, gem, file, location, memsize, string_value); end
  def location; end
  def memsize; end
  def string_value; end
end
class MemoryProfiler::StatHash < Hash
  include MemoryProfiler::TopN
end
class MemoryProfiler::Results
  def allocated_memory_by_class; end
  def allocated_memory_by_class=(arg0); end
  def allocated_memory_by_file; end
  def allocated_memory_by_file=(arg0); end
  def allocated_memory_by_gem; end
  def allocated_memory_by_gem=(arg0); end
  def allocated_memory_by_location; end
  def allocated_memory_by_location=(arg0); end
  def allocated_objects_by_class; end
  def allocated_objects_by_class=(arg0); end
  def allocated_objects_by_file; end
  def allocated_objects_by_file=(arg0); end
  def allocated_objects_by_gem; end
  def allocated_objects_by_gem=(arg0); end
  def allocated_objects_by_location; end
  def allocated_objects_by_location=(arg0); end
  def dump_data(io, type, metric, name, options); end
  def dump_strings(io, type, options); end
  def normalize_path(path); end
  def pretty_print(io = nil, **options); end
  def print_output(io, topic, detail); end
  def print_string_reports(io, options); end
  def print_title(io, title); end
  def register_results(allocated, retained, top); end
  def retained_memory_by_class; end
  def retained_memory_by_class=(arg0); end
  def retained_memory_by_file; end
  def retained_memory_by_file=(arg0); end
  def retained_memory_by_gem; end
  def retained_memory_by_gem=(arg0); end
  def retained_memory_by_location; end
  def retained_memory_by_location=(arg0); end
  def retained_objects_by_class; end
  def retained_objects_by_class=(arg0); end
  def retained_objects_by_file; end
  def retained_objects_by_file=(arg0); end
  def retained_objects_by_gem; end
  def retained_objects_by_gem=(arg0); end
  def retained_objects_by_location; end
  def retained_objects_by_location=(arg0); end
  def scale_bytes(bytes); end
  def self.register_type(name, stat_attribute); end
  def string_report(data, top); end
  def strings_allocated; end
  def strings_allocated=(arg0); end
  def strings_retained; end
  def strings_retained=(arg0); end
  def total_allocated; end
  def total_allocated=(arg0); end
  def total_allocated_memsize; end
  def total_allocated_memsize=(arg0); end
  def total_retained; end
  def total_retained=(arg0); end
  def total_retained_memsize; end
  def total_retained_memsize=(arg0); end
end
class MemoryProfiler::Reporter
  def generation; end
  def initialize(opts = nil); end
  def object_list(generation); end
  def report_results; end
  def run(&block); end
  def self.current_reporter; end
  def self.current_reporter=(arg0); end
  def self.report(opts = nil, &block); end
  def start; end
  def stop; end
  def top; end
  def trace; end
end
