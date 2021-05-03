# Collect System Memory Metrics
class puppet_metrics_collector::system::memory (
  String  $metrics_ensure            = $puppet_metrics_collector::system::system_metrics_ensure,
  Integer $collection_frequency      = $puppet_metrics_collector::system::collection_frequency,
  Integer $retention_days            = $puppet_metrics_collector::system::retention_days,
  Integer $polling_frequency_seconds = $puppet_metrics_collector::system::polling_frequency_seconds,
  Optional[String] $metrics_shipping_command  = undef,
  ) {
  puppet_metrics_collector::sar_metric { 'system_memory' :
    metric_ensure             => $metrics_ensure,
    cron_minute               => "0/${collection_frequency}",
    retention_days            => $retention_days,
    collection_frequency      => $collection_frequency,
    polling_frequency_seconds => $polling_frequency_seconds,
    metrics_shipping_command  => $metrics_shipping_command,
  }
}
