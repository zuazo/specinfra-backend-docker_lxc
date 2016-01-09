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

require 'specinfra/backend/docker'
require 'specinfra/backend/docker_lxc/shell_helpers'
require 'specinfra/backend/docker_lxc/exceptions'

# Command Execution Framework for Serverspec, Itamae and so on.
module Specinfra
  # Specinfra backend types.
  module Backend
    # Specinfra and Serverspec backend for Docker LXC execution driver.
    class DockerLxc < Docker
      include Specinfra::Backend::DockerLxc::ShellHelpers

      protected

      # Generates `lxc-attach` command to run.
      #
      # @param cmd [String] the commands to run inside docker.
      # @return [Array] the command to run as unescaped array.
      def lxc_attach_command(cmd)
        id = @container.id
        ['lxc-attach', '-n', id, '--', 'sh', '-c', cmd]
      end

      # Parses `lxc-attach` command output and raises an exception if it is an
      # error from the `lxc-attach` program.
      #
      # @param stderr [String] command *stderr* output.
      # @param exit_status [Fixnum] command exit status.
      # @return nil
      def lxc_attach_result_assert(stderr, exit_status)
        return if exit_status == 0
        return if stderr.match(/\A(lxc-attach|lxc_container|sudo): /).nil?
        fail LxcAttachError, stderr
      end

      # Parses a rescued exception and returns the command result.
      #
      # @param exception [Exception] the exception to parse.
      # @param cmd [Array<String>, String] the command (without `lxc-attach`).
      # @param stdout [String] the *stdout* output.
      # @param stderr [String] the *stderr* output.
      # @param status [Fixnum] the command exit status.
      # @return [Specinfra::CommandResult] the generated result object.
      # @api public
      def erroneous_result(cmd, exception, stdout, stderr, status)
        err =
          if stderr.nil?
            [exception.message] + exception.backtrace
          else
            [stderr]
          end
        sta = status.is_a?(Fixnum) && status != 0 ? status : 1
        rspec_example_metadata(cmd, stdout, err.join)
        CommandResult.new(stdout: stdout, stderr: err.join, exit_status: sta)
      end

      # Updates RSpec metadata used by Serverspec.
      #
      # @param cmd [Array<String>, String] the command (without `lxc-attach`).
      # @param stdout [String] the *stdout* output.
      # @param stderr [String] the *stderr* output.
      # @return nil
      # @api public
      def rspec_example_metadata(cmd, stdout, stderr)
        return unless @example
        @example.metadata[:command] = escape_command(cmd)
        @example.metadata[:stdout] = stdout
        @example.metadata[:stderr] = stderr
      end

      # Runs a command inside a Docker container.
      #
      # @param cmd [String] the command to run.
      # @param opts [Hash] options to pass to {Open3.popen3}.
      # @return [Specinfra::CommandResult] the result.
      # @api public
      def docker_run!(cmd, opts = {})
        stdout, stderr, status = shell_command!(lxc_attach_command(cmd), opts)
        lxc_attach_result_assert(stderr, status)
        rspec_example_metadata(cmd, stdout, stderr)
        CommandResult.new(stdout: stdout, stderr: stderr, exit_status: status)
      rescue LxcAttachError
        raise
      rescue => e
        @container.kill
        erroneous_result(cmd, e, stdout, stderr, status)
      end
    end
  end
end
