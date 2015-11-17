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

require 'open3'
require 'shellwords'
require 'etc'

module Specinfra
  module Backend
    class DockerLxc < Docker
      # Helpers to work with the shell and with `sudo`.
      #
      # Uses the following `Specinfra` configuration options:
      #
      # - `:sudo_options`: Sudo command argument list as string or as array.
      # - `:sudo_path`: Sudo binary directory.
      # - `:sudo_password`
      # - `:disable_sudo`: whether to disable Sudo (enabled by default).
      #
      # Based on the official `Specinfra::Backend::Ssh` code.
      #
      # @example
      #   class MyBackend < Specinfra::Backend::Base
      #     include Specinfra::Backend::DockerLxc::ShellHelpers
      #
      #     def my_backend_run!
      #       stdout, stderr, status = shell_command!('uname -a')
      #       CommandResult.new(
      #         stdout: stdout, stderr: stderr, exit_status: status
      #       )
      #     end
      #   end
      module ShellHelpers
        protected

        # Returns the prompt used by Sudo to ask for the password.
        #
        # @return [String] the prompt.
        # @example
        #   sudo_prompt #=> "Password: "
        def sudo_prompt
          'Password: '
        end

        # Reads the `:sudo_password` configuration option.
        #
        # @return [String] the password.
        # @example
        #   set :sudo_password, 'y0mVT1CYM0uRiHxjLfNV'
        #   sudo_password #=> "y0mVT1CYM0uRiHxjLfNV"
        def sudo_password
          Specinfra.configuration.sudo_password
        end

        # Whether the `:sudo_password` is configured.
        #
        # @return [TrueClass, FalseClass] true if password is configured.
        # @example
        #   sudo_password? #=> false
        def sudo_password?
          sudo_password ? true : false
        end

        # Returns the Sudo program arguments to use by default.
        #
        # @return [String] the arguments properly escaped.
        # @example
        #   default_sudo_args #=> ""
        #   default_sudo_args #=> "-S -p Password:\\ "
        def default_sudo_args
          args = []
          args += ['-S', '-p', sudo_prompt] if sudo_password?
          args.shelljoin
        end

        # Returns the Sudo program arguments.
        #
        # Includes both the default and the arguments configured using `set`.
        #
        # @return [String] the arguments properly escaped.
        # @example
        #   set :sudo_options, '-a -b -c'
        #   sudo_args #=> "-S -p Password:\\  -a -b -c"
        def sudo_args
          sudo_options = Specinfra.configuration.sudo_options
          if sudo_options
            sudo_options = sudo_options.shelljoin if sudo_options.is_a?(Array)
            "#{default_sudo_args} #{sudo_options}"
          else
            default_sudo_args
          end
        end

        # Gets the Sudo binary path.
        #
        # @return [String] the Sudo binary.
        # @example
        #   sudo_bin #=> "sudo"
        #   set :sudo_path, '/opt/sudo/bin'
        #   sudo_bin #=> "/opt/sudo/bin/sudo"
        def sudo_bin
          sudo_path = Specinfra.configuration.sudo_path
          sudo_bin = sudo_path ? "#{sudo_path}/sudo" : 'sudo'
          sudo_bin.shellescape
        end

        # Adds Sudo to a command.
        #
        # @param cmd_str [String] the command to run. Must be escaped.
        # @return [String] the command escaped and including `sudo`.
        # @example
        #   set :sudo_password, 'y0mVT1CYM0uRiHxjLfNV'
        #   sudo_command('uname -a') #=> "sudo -S -p Password:\\  -- uname -a"
        #   set :disable_sudo, true
        #   sudo_command('uname -a') #=> "uname -a"
        def sudo_command(cmd_str)
          "#{sudo_bin} #{sudo_args} -- #{cmd_str}"
        end

        # Checks if we need to use Sudo.
        #
        # @return [TrueClass, FalseClass] whether we need to use Sudo.
        # @example
        #   sudo? #=> true
        #   set :disable_sudo, true
        #   sudo? #=> false
        def sudo?
          disable_sudo = Specinfra.configuration.disable_sudo
          Etc.getlogin != 'root' && !disable_sudo
        end

        # Escapes a shell command.
        #
        # It only escapes it when passed as array.
        #
        # @param cmd [Array<String>, String] the command.
        # @return [String] the command escaped.
        # @example
        #   escape_command(['sudo', '-p', 'Password: ')
        #     #=> "sudo -p Password:\\ "
        #   escape_command('uname -a') #=> "uname -a"
        # @api public
        def escape_command(cmd)
          return cmd if cmd.is_a?(String)
          cmd.shelljoin
        end

        # Generates the command to run including the Sudo prefix if configured.
        #
        # The command needs to be escaped only if passed as string.
        #
        # @param cmd [Array<String>, String] the command.
        # @return [String] the command escaped.
        # @example
        #   generate_escaped_command('uname -a') #=> "sudo uname -a"
        #   set :sudo_password, 'y0mVT1CYM0uRiHxjLfNV'
        #   generate_escaped_command('uname -a')
        #     #=> "sudo -p Password:\\  uname -a"
        #   set :disable_sudo, true
        #   generate_escaped_command('uname -a') #=> "uname -a"
        def generate_escaped_command(cmd)
          if sudo?
            sudo_command(escape_command(cmd))
          else
            escape_command(cmd)
          end
        end

        # Writes the password to the *stdin* when asked on *stderr*.
        #
        # @param stdin [IO] stdin file descriptor.
        # @param stderr [IO] stderr file descriptor.
        # @return [String] the string read from stderr without including the
        #   password prompt.
        # @example
        #   write_sudo_password(stdin, stderr) #=> ""
        def write_sudo_password(stdin, stderr)
          return '' unless sudo_password?
          read = stderr.gets(sudo_prompt.length)
          return read.to_s unless read == sudo_prompt
          stdin.puts "#{sudo_password}\n"
          ''
        end

        # Runs a command, including Sudo if required.
        #
        # If the command is passed as string, must be properly escaped.
        #
        # @param cmd [Array<String>, String] the command.
        # @return [Array<String, Fixnum>] the array contents: *stdout*, *stderr*
        #   and the *exit status*.
        # @example
        #   shell_command!('id')
        #     #=> ["", "uid=0(root) gid=0(root) groups=0(root)\n", 0]
        # @api public
        def shell_command!(cmd, opts = {})
          cmd_escaped = generate_escaped_command(cmd)
          Open3.popen3(cmd_escaped, opts) do |stdin, stdout, stderr, wait_thr|
            read = write_sudo_password(stdin, stderr)
            stdin.close
            [stdout.read, read + stderr.read, wait_thr.value.exitstatus]
          end
        end
      end
    end
  end
end
