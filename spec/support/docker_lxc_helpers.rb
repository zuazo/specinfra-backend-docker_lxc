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

# Some helper methods for tests related to the gem.
module DockerLxcHelpers
  # Reset used Specinfra configuration options to their default values.
  #
  # @return nil
  # @example
  #   DockerLxcHelpers.configuration_reset
  def self.configuration_reset
    %w(
      sudo_options
      sudo_path
      sudo_password
      disable_sudo
    ).each do |name|
      Specinfra.configuration.instance_variable_set("@#{name}", nil)
      RSpec.configuration.send("#{name}=", nil)
    end
  end
end
