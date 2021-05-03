require 'spec_helper'

describe 'puppet_metrics_collector::system' do
  context 'with default parameters' do
    it { is_expected.not_to contain_package('sysstat') }
    it { is_expected.not_to contain_package('open-vm-tools') }
  end

  context 'with sysstat' do
    context 'already installed' do
      let(:pre_condition) { 'package{"sysstat": }' }
      let(:facts) { { puppet_metrics_collector: { have_sysstat: true, have_systemd: true } } }

      it { is_expected.not_to contain_notify('sysstat_missing_warning') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::cpu') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::memory') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::processes') }
    end

    context 'not installed and managed' do
      let(:params) { { manage_sysstat: true } }
      let(:facts) { { puppet_metrics_collector: { have_sysstat: false, have_systemd: true } } }

      it { is_expected.not_to contain_notify('sysstat_missing_warning') }
      it { is_expected.to contain_package('sysstat') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::cpu') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::memory') }
      it { is_expected.to contain_class('puppet_metrics_collector::system::processes') }
    end

    context 'not installed and not managed' do
      it { is_expected.to contain_notify('sysstat_missing_warning') }
      it { is_expected.not_to contain_package('sysstat') }
      it { is_expected.not_to contain_class('puppet_metrics_collector::system::cpu') }
      it { is_expected.not_to contain_class('puppet_metrics_collector::system::memory') }
      it { is_expected.not_to contain_class('puppet_metrics_collector::system::processes') }
    end
  end
  context 'when the virtual fact does not report vmware' do
    let(:facts) { { virtual: 'physical' } }

    it { is_expected.not_to contain_class('puppet_metrics_collector::system::vmware') }
  end

  context 'when the virtual fact reports vmware' do
    let(:facts) { { virtual: 'vmware' } }

    it { is_expected.to contain_class('puppet_metrics_collector::system::vmware') }
    it { is_expected.not_to contain_package('open-vm-tools') }

    context 'when management of VMware Tools is enabled' do
      let(:params) { { manage_vmware_tools: true, vmware_tools_pkg: 'foo-tools' } }

      it { is_expected.to contain_package('foo-tools').with_ensure('present') }
    end

    context 'when vmware-toolbox-cmd is present on the PATH' do
      let(:facts) { super().merge(puppet_metrics_collector: { have_vmware_tools: true, have_systemd: true }) }

      it { is_expected.to contain_service('puppet_vmware-metrics.timer').with_ensure('running') }
    end

    context 'when vmware-toolbox-cmd is not present on the PATH' do
      let(:facts) { super().merge(puppet_metrics_collector: { have_vmware_tools: false, have_systemd: true }) }

      it { is_expected.to contain_notify('vmware_tools_warning') }
    end
  end

  context 'when /opt/puppetlabs/server/bin/psql is present' do
    let(:facts) { { puppet_metrics_collector: { have_pe_psql: true, have_systemd: true } } }

    it { is_expected.to contain_service('puppet_postgres-metrics.timer').with_ensure('running') }
  end

  context 'when /opt/puppetlabs/server/bin/psql is absent' do
    let(:facts) { { puppet_metrics_collector: { have_pe_psql: false, have_systemd: true } } }

    it { is_expected.not_to contain_service('puppet_postgres-metrics.timer') }
  end

  context 'when metrics shipping is enabled' do
    let(:params) { {
      metrics_server_type: "influxdb",
      metrics_server_db_name: "puppet_metrics",
      metrics_server_hostname: "influxdb.example"
      }
    }

    it { is_expected.to contain_cron('system_cpu_metrics_collection').with_command(/--influx-db\s+puppet_metrics/) }
  end

  context 'when metrics shipping is enabled in puppet_metrics_collector' do
    let(:pre_condition) do
      <<-PRE_COND
      class {'puppet_metrics_collector':
        metrics_server_type => "influxdb",
        metrics_server_db_name => "puppet_metrics",
        metrics_server_hostname => "influxdb.example"
      }
      PRE_COND
    end

    it { is_expected.to contain_cron('system_cpu_metrics_collection').with_command(/--influx-db\s+puppet_metrics/) }
  end

  context 'when metrics shipping is not enabled' do
    let(:params) { {
      metrics_server_db_name: "puppet_metrics",
      metrics_server_hostname: "influxdb.example"
      }
    }

    it { is_expected.not_to contain_cron('system_cpu_metrics_collection').with_command(/--influx-db\s+puppet_metrics/) }
  end
end
