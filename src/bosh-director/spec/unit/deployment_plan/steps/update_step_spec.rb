require 'spec_helper'
require 'bosh/director/deployment_plan/multi_job_updater'
require 'bosh/director/job_updater'

module Bosh::Director
  module DeploymentPlan::Steps
    describe UpdateStep do
      subject { UpdateStep.new(base_job, deployment_plan, multi_job_updater) }
      let(:base_job) { Jobs::BaseJob.new }
      let(:pre_cleanup) { instance_double('Bosh::Director::DeploymentPlan::Steps::PreCleanupStep') }
      let(:setup) { instance_double('Bosh::Director::DeploymentPlan::Steps::SetupStep') }
      let(:update_jobs) { instance_double('Bosh::Director::DeploymentPlan::Steps::UpdateJobsStep') }
      let(:update_errands) { instance_double('Bosh::Director::DeploymentPlan::Steps::UpdateErrandsStep') }
      let(:multi_job_updater) { instance_double('Bosh::Director::DeploymentPlan::SerialMultiJobUpdater', run: nil) }
      let(:vm_deleter) { instance_double('Bosh::Director::VmDeleter') }
      let(:vm_creator) { instance_double('Bosh::Director::VmCreator') }

      let(:deployment_plan) do
        instance_double('Bosh::Director::DeploymentPlan::Planner',
          update_stemcell_references!: nil,
          persist_updates!: nil,
          job_renderer: JobRenderer.create,
        )
      end

      before do
        allow(PreCleanupStep).to receive(:new).with(base_job, deployment_plan).and_return(pre_cleanup)
        allow(SetupStep).to receive(:new).with(base_job, deployment_plan, vm_creator).and_return(setup)
        allow(UpdateJobsStep).to receive(:new).with(base_job, deployment_plan, multi_job_updater).and_return(update_jobs)
        allow(UpdateErrandsStep).to receive(:new).with(deployment_plan).and_return(update_errands)
        allow(VmDeleter).to receive(:new).with(logger, false, Config.enable_virtual_delete_vms).and_return(vm_deleter)
        allow(VmCreator).to receive(:new).with(logger, vm_deleter, anything, anything, anything).and_return(vm_creator)
      end

      describe '#perform' do
        it 'runs deployment plan update steps in the correct order' do
          expect(logger).to receive(:info).with('Updating deployment').ordered
          expect(pre_cleanup).to receive(:perform).ordered
          expect(setup).to receive(:perform).ordered
          expect(update_jobs).to receive(:perform).ordered
          expect(update_errands).to receive(:perform).ordered
          expect(logger).to receive(:info).with('Committing updates').ordered
          expect(deployment_plan).to receive(:persist_updates!).ordered
          expect(logger).to receive(:info).with('Finished updating deployment').ordered

          subject.perform
        end

        context 'when perform fails' do
          let(:some_error) { RuntimeError.new('oops') }

          before do
            allow(logger).to receive(:info).and_raise(some_error)
          end

          it 'still updates the stemcell references' do
            expect(deployment_plan).to receive(:update_stemcell_references!)

            expect{
              subject.perform
            }.to raise_error(some_error)
          end
        end
      end
    end
  end
end
