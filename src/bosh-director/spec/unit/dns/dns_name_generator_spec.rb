require 'spec_helper'

module Bosh::Director
  describe DnsNameGenerator do
    subject(:dns_name_generator) { described_class }

    describe '#dns_record_name' do
      context 'when network is a wildcard' do
        it 'does not escape the network segment' do
          expect(dns_name_generator.dns_record_name('hostname', 'job_Name', '%', 'deployment_Name')).to eq('hostname.job-name.%.deployment-name.bosh')
        end
      end

      context 'when special tokens are used' do
        it 'all segments are escaped' do
          expect(dns_name_generator.dns_record_name('hostname', 'job_Name', 'network_Name', 'deployment_Name')).to eq('hostname.job-name.network-name.deployment-name.bosh')
        end
      end

      context 'when fields are normal' do
        it 'does not escape the network segment' do
          expect(dns_name_generator.dns_record_name('hostname', 'job-name', 'network-name', 'deployment-name')).to eq('hostname.job-name.network-name.deployment-name.bosh')
        end
      end
    end
  end
end
