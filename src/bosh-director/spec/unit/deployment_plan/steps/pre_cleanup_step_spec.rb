require 'spec_helper'
require 'bosh/director/deployment_plan/multi_job_updater'
require 'bosh/director/job_updater'

module Bosh::Director
  module DeploymentPlan::Steps
    describe PreCleanupStep do
      subject { PreCleanupStep.new(base_job, deployment_plan) }
      let(:base_job) { Jobs::BaseJob.new }
      let(:event_log) { Config.event_log }
      let(:ip_provider) { instance_double('Bosh::Director::DeploymentPlan::IpProvider') }
      let(:existing_instance) { Models::Instance.make }
      let(:existing_instance_plan) { instance_double(DeploymentPlan::InstancePlan, existing_instance: existing_instance) }
      let(:event_log_stage) { instance_double('Bosh::Director::EventLog::Stage') }
      let(:instance_deleter) { instance_double('Bosh::Director::InstanceDeleter') }

      let(:deployment_plan) do
        instance_double('Bosh::Director::DeploymentPlan::Planner',
          update_stemcell_references!: nil,
          persist_updates!: nil,
          instance_groups_starting_on_deploy: [],
          ip_provider: ip_provider,
          tags: {}
        )
      end

      before do
        allow(base_job).to receive(:logger).and_return(logger)
        allow(deployment_plan).to receive(:unneeded_instance_plans).and_return([existing_instance_plan])
        allow(event_log).to receive(:begin_stage)
        allow(InstanceDeleter).to receive(:new).and_return(instance_deleter)
        allow(instance_deleter).to receive(:delete_instance_plans)
      end

      describe '#perform' do
        it 'deletes unneeded instances' do
          expect(instance_deleter).to receive(:delete_instance_plans) do |instance_plans, event_log, _|
            expect(instance_plans.map(&:existing_instance)).to eq([existing_instance])
          end

          subject.perform
        end

        it 'logs information' do
          expect(event_log).to receive(:begin_stage)
                                        .with('Deleting unneeded instances', 1)
                                        .and_return(event_log_stage)

          expect(logger).to receive(:info).with('Deleting no longer needed instances')
          expect(logger).to receive(:info).with('Deleted no longer needed instances')

          subject.perform
        end

        context 'when no instance plans require deletion' do
          before do
            allow(deployment_plan).to receive(:unneeded_instance_plans).and_return([])
          end

          it 'exists early and logs the lack of work needed' do
            expect(logger).to receive(:info).with('Deleting no longer needed instances')
            expect(logger).to receive(:info).with('No unneeded instances to delete')
            expect(instance_deleter).to_not receive(:delete_instance_plans)

            subject.perform
          end
        end
      end
    end
  end
end
