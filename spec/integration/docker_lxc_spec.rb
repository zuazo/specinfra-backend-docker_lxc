# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe Specinfra::Backend::DockerLxc do
  subject { DisabledDockerLxc.new }
  let(:cmd) { 'ls -la /root/spa\\ ce' }
  let(:container_id) { '0beaf145b190' }
  let(:container) { double('Docker::Container', id: container_id) }
  before do
    subject.instance_variable_set(:@container, container)
    allow(Etc).to receive(:getlogin).and_return('nobody')
    allow(container).to receive(:kill)
  end

  context '#docker_run!' do
    let(:stdin_str) { 'stdin' }
    let(:stdout_str) { 'stdout' }
    let(:stderr_str) { 'Password: stderr' }
    let(:stdin) { StringIO.new(stdin_str) }
    let(:stdout) { StringIO.new(stdout_str) }
    let(:stderr) { StringIO.new(stderr_str) }
    let(:status) { 0 }
    let(:wait_thr) { Thread.new { status } }
    let(:wait_thr_value) { double('Process::Status') }
    let(:final_cmd) do
      'sudo  -- lxc-attach -n 0beaf145b190 -- sh -c '\
      'ls\\ -la\\ /root/spa\\\\\\ ce'
    end
    before do
      allow(wait_thr).to receive(:value).and_return(wait_thr_value)
      allow(Open3).to receive(:popen3).with(final_cmd, {})
        .and_yield(stdin, stdout, stderr, wait_thr)
      allow(wait_thr_value).to receive(:exitstatus).and_return(status)
    end

    it 'runs the lxc-attach command' do
      expect(Open3).to receive(:popen3).once.with(final_cmd, {})
        .and_yield(stdin, stdout, stderr, wait_thr)
      subject.send(:docker_run!, cmd)
    end

    it 'returns stdout' do
      expect(subject.send(:docker_run!, cmd).stdout).to eq stdout_str
    end

    it 'returns stderr' do
      expect(subject.send(:docker_run!, cmd).stderr).to eq stderr_str
    end

    it 'returns the correct exit status' do
      expect(subject.send(:docker_run!, cmd).exit_status).to eq status
    end

    context 'with lxc-attach failures' do
      let(:stderr_str) { 'lxc-attach: failed to get the init pid' }
      let(:status) { 1 }

      it 'raises an exception' do
        expect { subject.send(:docker_run!, cmd) }.to raise_error(
          Specinfra::Backend::DockerLxc::LxcAttachError, /^lxc-attach:/
        )
      end
    end

    context 'with other failures' do
      let(:exception_msg) { 'My Exception message' }
      let(:backtrace) { ["#{__FILE__}:#{__LINE__}"] }
      let(:exception) do
        StandardError.new(exception_msg).tap { |e| e.set_backtrace(backtrace) }
      end
      before do
        expect(Open3).to receive(:popen3).with(final_cmd, {})
          .and_raise(exception)
      end

      it 'returns the exception in stderr' do
        expect(subject.send(:docker_run!, cmd).stderr).to match exception_msg
      end
    end
  end
end
