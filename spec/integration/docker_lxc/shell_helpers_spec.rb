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

class MyBackend < Specinfra::Backend::Base
  include Specinfra::Backend::DockerLxc::ShellHelpers
end

describe Specinfra::Backend::DockerLxc::ShellHelpers do
  let(:cmd) { ['ls', '-la', '/root/spa ce'] }
  subject { MyBackend.new }
  before { allow(Etc).to receive(:getlogin).and_return('nobody') }

  context '#shell_command!' do
    context 'as an ordinary user' do
      before { allow(Etc).to receive(:getlogin).and_return('nobody') }

      it 'runs the lxc-attach with sudo' do
        expect(Open3).to receive(:popen3).once
          .with('sudo  -- ls -la /root/spa\\ ce', {}).and_return('ok')
        expect(subject.send(:shell_command!, cmd)).to eq 'ok'
      end

      context 'with sudo disabled' do
        before { Specinfra.configuration.disable_sudo(true) }

        it 'runs the lxc-attach without sudo' do
          expect(Open3).to receive(:popen3).once
            .with('ls -la /root/spa\\ ce', {}).and_return('ok')
          expect(subject.send(:shell_command!, cmd)).to eq 'ok'
        end
      end
    end

    context 'as root' do
      before { allow(Etc).to receive(:getlogin).and_return('root') }

      it 'runs the lxc-attach without sudo' do
        expect(Open3).to receive(:popen3).once
          .with('ls -la /root/spa\\ ce', {}).and_return('ok')
        expect(subject.send(:shell_command!, cmd)).to eq 'ok'
      end
    end

    context 'with sudo options' do
      let(:sudo_options) { %w(-A --preserver-env) }
      before { Specinfra.configuration.sudo_options(sudo_options) }

      it 'passes options to sudo' do
        expect(Open3).to receive(:popen3).once
          .with('sudo  -A --preserver-env -- ls -la /root/spa\\ ce', {})
          .and_return('ok')
        expect(subject.send(:shell_command!, cmd)).to eq 'ok'
      end
    end

    context 'with sudo path' do
      let(:sudo_path) { '/opt/su do' }
      before { Specinfra.configuration.sudo_path(sudo_path) }

      it 'uses the correct sudo path' do
        expect(Open3).to receive(:popen3).once
          .with('/opt/su\\ do/sudo  -- ls -la /root/spa\\ ce', {})
          .and_return('ok')
        expect(subject.send(:shell_command!, cmd)).to eq 'ok'
      end
    end

    context 'with sudo password' do
      let(:sudo_password) { 'WgxpX_aFpi&qzML4(Vp0' }
      before { Specinfra.configuration.sudo_password(sudo_password) }

      it 'adds the necessary sudo options' do
        expect(Open3).to receive(:popen3).once
          .with('sudo -S -p Password:\\  -- ls -la /root/spa\\ ce', {})
          .and_return('ok')
        expect(subject.send(:shell_command!, cmd)).to eq 'ok'
      end
    end

    context 'Open3.popen3 block' do
      let(:stdin) { StringIO.new }
      let(:stdout) { StringIO.new('stdout') }
      let(:stderr) { StringIO.new('Password: stderr') }
      let(:status) { double('Process::Status') }
      let(:wait_thr) { Thread.new { status } }
      before do
        allow(status).to receive(:exitstatus).and_return(0)
        allow(Open3).to receive(:popen3)
          .and_yield(stdin, stdout, stderr, wait_thr)
      end

      it 'returns stdout' do
        expect(subject.send(:shell_command!, cmd)[0]).to eq 'stdout'
      end

      it 'returns the complete stderr' do
        expect(subject.send(:shell_command!, cmd)[1]).to eq 'Password: stderr'
      end

      it 'returns exit status' do
        expect(subject.send(:shell_command!, cmd)[2]).to eq 0
      end

      context 'with sudo password' do
        before { Specinfra.configuration.sudo_password('IDG%SBWj7$9i4at9g') }

        it 'returns stdout' do
          expect(subject.send(:shell_command!, cmd)[0]).to eq 'stdout'
        end

        it 'returns the stderr without the password prompt' do
          expect(subject.send(:shell_command!, cmd)[1]).to eq 'stderr'
        end

        it 'returns exit status' do
          expect(subject.send(:shell_command!, cmd)[2]).to eq 0
        end
      end
    end # context Open3.popen3 block
  end # context #shell_command!
end
