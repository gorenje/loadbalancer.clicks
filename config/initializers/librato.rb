require 'librato/metrics'
require 'librato-rack'

Librato::Metrics.
  authenticate(ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN'])
$librato_queue      ||= Librato::Metrics::Queue.new(:autosubmit_interval => 60)
$librato_aggregator ||= Librato::Metrics::Aggregator.new(:autosubmit_interval => 60)
