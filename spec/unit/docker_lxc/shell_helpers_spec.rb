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
  subject { MyBackend.new }

  context '#sudo_prompt' do
    it 'return Sudo prompt' do
      expect(subject.send(:sudo_prompt)).to eq 'Password: '
    end
  end

  context '#sudo_password' do
    context 'without sudo password' do
      before { Specinfra.configuration.sudo_password(false) }

      it 'does not return any password' do
        expect(subject.send(:sudo_password)).to eq false
      end
    end

    context 'with sudo password' do
      let(:password) { 'aofWfoFXAfM2tHCzisbY' }
      before { Specinfra.configuration.sudo_password(password) }

      it 'does not return any password' do
        expect(subject.send(:sudo_password)).to eq password
      end
    end
  end

  context '#sudo_password?' do
    context 'without sudo password' do
      before { Specinfra.configuration.sudo_password(false) }

      it 'returns false' do
        expect(subject.send(:sudo_password?)).to eq false
      end
    end

    context 'with sudo password' do
      let(:password) { 'aofWfoFXAfM2tHCzisbY' }
      before { Specinfra.configuration.sudo_password(password) }

      it 'returns true' do
        expect(subject.send(:sudo_password?)).to eq true
      end
    end
  end

  context '#default_sudo_args' do
    context 'without sudo password' do
      before { expect(subject).to receive(:sudo_password?).and_return(false) }

      it 'returns no args' do
        expect(subject.send(:default_sudo_args)).to eq ''
      end
    end

    context 'with sudo password' do
      before { expect(subject).to receive(:sudo_password?).and_return(true) }

      it 'sets to read the password from stdin (-S)' do
        expect(subject.send(:default_sudo_args)).to match(/(^|\s)-S(\s|$)/)
      end

      it 'sets the password prompt (-p)' do
        expect(subject.send(:default_sudo_args))
          .to match(/(^|\s)-p Password:[\\] (\s|$)/)
      end
    end
  end # context #default_sudo_args

  context '#sudo_args' do
    let(:default_sudo_args) { '--default --sudo --args' }
    before do
      allow(subject).to receive(:default_sudo_args)
        .and_return(default_sudo_args)
    end

    context 'without sudo options' do
      before { Specinfra.configuration.sudo_options(false) }

      it 'returns #default_sudo_args' do
        expect(subject.send(:sudo_args)).to eq default_sudo_args
      end
    end

    context 'with sudo options as string' do
      let(:sudo_options) { '--sudo --options' }
      before { Specinfra.configuration.sudo_options(sudo_options) }

      it 'returns #default_sudo_args' do
        expect(subject.send(:sudo_args))
          .to eq "#{default_sudo_args} #{sudo_options}"
      end
    end

    context 'with sudo options as array' do
      let(:sudo_options) { ['--sudo', '--options', 'with space'] }
      before { Specinfra.configuration.sudo_options(sudo_options) }

      it 'returns #default_sudo_args' do
        expect(subject.send(:sudo_args))
          .to eq "#{default_sudo_args} --sudo --options with\\ space"
      end
    end
  end # context #sudo_args

  context '#sudo_bin' do
    context 'without sudo path' do
      before { Specinfra.configuration.sudo_path(false) }

      it 'returns sudo' do
        expect(subject.send(:sudo_bin)).to eq 'sudo'
      end
    end

    context 'with sudo path' do
      let(:sudo_path) { '/opt/sudo/bin' }
      before { Specinfra.configuration.sudo_path(sudo_path) }

      it 'returns full sudo path' do
        expect(subject.send(:sudo_bin)).to eq "#{sudo_path}/sudo"
      end

      it 'escapes the path properly' do
        sudo_path = '/opt/su do'
        Specinfra.configuration.sudo_path(sudo_path)
        expect(subject.send(:sudo_bin)).to eq '/opt/su\\ do/sudo'
      end
    end
  end # context #sudo_bin

  context '#sudo_command' do
    let(:sudo_bin) { 'sudo/bin' }
    let(:sudo_args) { '--sudo --args' }
    let(:cmd) { 'cmd --to run' }
    before do
      expect(subject).to receive(:sudo_bin).and_return(sudo_bin)
      expect(subject).to receive(:sudo_args).and_return(sudo_args)
    end

    it 'returns the complete command' do
      expect(subject.send(:sudo_command, cmd))
        .to eq "#{sudo_bin} #{sudo_args} -- #{cmd}"
    end
  end

  context '#sudo?' do
    context 'with sudo enabled' do
      before { Specinfra.configuration.disable_sudo(false) }

      context 'as an ordinary user' do
        before { expect(Etc).to receive(:getlogin).and_return('nobody') }

        it 'returns true' do
          expect(subject.send(:sudo?)).to eq true
        end
      end

      context 'as root' do
        before { expect(Etc).to receive(:getlogin).and_return('root') }

        it 'returns true' do
          expect(subject.send(:sudo?)).to eq false
        end
      end
    end

    context 'with sudo disabled' do
      before { Specinfra.configuration.disable_sudo(true) }

      context 'as an ordinary user' do
        before { expect(Etc).to receive(:getlogin).and_return('nobody') }

        it 'returns false' do
          expect(subject.send(:sudo?)).to eq false
        end
      end

      context 'as root' do
        before { expect(Etc).to receive(:getlogin).and_return('root') }

        it 'returns true' do
          expect(subject.send(:sudo?)).to eq false
        end
      end
    end
  end # context #sudo?

  context '#escape_command' do
    context 'with a string command' do
      let(:cmd) { 'A command --with spaces' }
      before { expect(cmd).to receive(:shelljoin).never }

      it 'does not escape strings' do
        expect(subject.send(:escape_command, cmd)).to eq cmd
      end
    end

    context 'with an array command' do
      let(:cmd) { ['A', 'command', '--with spaces'] }

      it 'does escape arrays' do
        expect(subject.send(:escape_command, cmd))
          .to eq 'A command --with\\ spaces'
      end

      it 'uses #shelljoin' do
        shelljoin = 'shelljoin!!'
        expect(cmd).to receive(:shelljoin).once.and_return(shelljoin)
        expect(subject.send(:escape_command, cmd)).to eq shelljoin
      end
    end
  end # context #escape_command

  context '#generate_escaped_command' do
    let(:cmd) { 'plastic-knife' }
    let(:escape_command) { 'escape --command' }

    context 'with sudo' do
      let(:sudo_command) { 'sudo -- escape --command' }
      before do
        expect(subject).to receive(:sudo?).once.and_return(true)
        expect(subject).to receive(:escape_command).with(cmd).once
          .and_return(escape_command)
        expect(subject).to receive(:sudo_command).with(escape_command).once
          .and_return(sudo_command)
      end

      it 'returns sudo command' do
        expect(subject.send(:generate_escaped_command, cmd)).to eq sudo_command
      end
    end

    context 'without sudo' do
      before do
        expect(subject).to receive(:sudo?).once.and_return(false)
        expect(subject).to receive(:escape_command).with(cmd).once
          .and_return(escape_command)
        expect(subject).to receive(:sudo_command).never
      end

      it 'returns escaped command' do
        expect(subject.send(:generate_escaped_command, cmd))
          .to eq escape_command
      end
    end
  end # context #generate_escaped_command

  context '#write_sudo_password' do
    context 'without sudo password' do
      before { expect(subject).to receive(:sudo_password?).and_return(false) }

      it 'returns an empty string' do
        expect(subject.send(:write_sudo_password, StringIO.new, StringIO.new))
          .to eq ''
      end
    end

    context 'with sudo password' do
      let(:stdin) { StringIO.new }
      before { expect(subject).to receive(:sudo_password?).and_return(true) }

      context 'when there is no password prompt' do
        let(:stderr_str) { 'Wrong prompt' }
        let(:stderr) { StringIO.new(stderr_str) }
        before { expect(subject).to receive(:sudo_password).never }

        it 'returns stderr' do
          read_length = 9 # 'Password: '.length - 1
          expect(subject.send(:write_sudo_password, stdin, stderr))
            .to eq stderr_str[0..read_length]
        end

        it 'does not call stdin#puts' do
          expect(stdin).to receive(:puts).never
          subject.send(:write_sudo_password, stdin, stderr)
        end
      end

      context 'when there is a password prompt' do
        let(:stderr) { StringIO.new('Password: ') }
        let(:password) { 'erHCDUDizfdXWfgLCqzd' }
        before do
          expect(subject).to receive(:sudo_password).once.and_return(password)
        end

        it 'writes the password' do
          expect(stdin).to receive(:puts).once.with("#{password}\n")
          subject.send(:write_sudo_password, stdin, stderr)
        end

        it 'returns empty string' do
          expect(subject.send(:write_sudo_password, stdin, stderr)).to eq ''
        end
      end
    end
  end # context #write_sudo_password

  context '#shell_command!' do
    let(:cmd) { 'our --command' }
    let(:generate_escaped_command) { 'generate escaped command' }
    let(:popen3) { %w(popen3 return value) }
    let(:stdin) { double('String.IO') }
    let(:stdout) { double('String.IO') }
    let(:stderr) { double('String.IO') }
    let(:wait_thr) { double('Thread') }
    let(:wait_thr_value) { double('Process::Status') }
    before do
      allow(subject).to receive(:generate_escaped_command)
        .and_return(generate_escaped_command)
      allow(Open3).to receive(:popen3).and_return(popen3)
    end

    it 'calls #generate_escaped_command' do
      expect(subject).to receive(:generate_escaped_command).once.with(cmd)
        .and_return(generate_escaped_command)
      subject.send(:shell_command!, cmd)
    end

    it 'calls Open3#popen3' do
      expect(Open3).to receive(:popen3).once.with(generate_escaped_command, {})
      subject.send(:shell_command!, cmd)
    end

    it 'passes options to Open3#popen3' do
      opts = { option1: 'value1' }
      expect(Open3)
        .to receive(:popen3).once.with(generate_escaped_command, opts)
      subject.send(:shell_command!, cmd, opts)
    end

    context 'Open3.open3 block' do
      let(:write_sudo_password) { 'write sudo password' }
      before do
        allow(Open3).to receive(:popen3)
          .and_yield(stdin, stdout, stderr, wait_thr)
        allow(subject).to receive(:write_sudo_password).with(stdin, stderr)
          .and_return(write_sudo_password)
        allow(stdin).to receive(:close)
        allow(stdout).to receive(:read).and_return('stdout')
        allow(stderr).to receive(:read).and_return('stderr')
        allow(wait_thr).to receive(:value).and_return(wait_thr_value)
        allow(wait_thr_value).to receive(:exitstatus).and_return('status')
      end

      it 'writes sudo password' do
        expect(subject).to receive(:write_sudo_password).with(stdin, stderr)
          .once.and_return(write_sudo_password)
        subject.send(:shell_command!, cmd)
      end

      it 'closes stdin' do
        expect(stdin).to receive(:close).once
        subject.send(:shell_command!, cmd)
      end

      it 'returns stdout, read and exit status' do
        expect(subject.send(:shell_command!, cmd))
          .to eq(['stdout', "#{write_sudo_password}stderr", 'status'])
      end
    end
  end # context #shell_command!
end
