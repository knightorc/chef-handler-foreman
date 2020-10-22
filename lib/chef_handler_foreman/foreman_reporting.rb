# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'chef/handler'

module ChefHandlerForeman
  class ForemanReporting < ::Chef::Handler
    attr_accessor :uploader

    def why_run?
      Chef::Config.why_run
    end

    def report
      report                   = { 'host' => node['fqdn'].downcase, 'reported_at' => Time.now.utc.to_s }
      report_status            = Hash.new(0)

      report_status['failed']    = failed? ? 1 : 0
      report_status['applied']   = 0
      report_status['restarted'] = 0
      report_status['pending']   = 0
      report_status['skipped']   = run_status.all_resources.count - run_status.updated_resources.count

      run_status.updated_resources.each do |r|
        if why_run?
          report_status['pending'] += 1
          next
        end

        class_as_restarted = [:restart, :reload, :start, :enable, :disable]

        # Convert from array
        first_action = (r.action.class == :Array) ? r.action.first : r.action

        if class_as_restarted.include?(first_action)
          report_status['restarted'] += 1
        else
          report_status['applied'] += 1
        end
      end

      report['status']         = report_status

      # I can't compute much metrics for now
      metrics                  = {}
      metrics['resources']     = { 'total' => run_status.all_resources.count }

      times = {}
      run_status.all_resources.each do |resource|
        resource_name = resource.resource_name
        if times[resource_name].nil?
          times[resource_name] = resource.elapsed_time
        else
          times[resource_name] += resource.elapsed_time
        end
      end
      metrics['time']   = times.merge!('total' => run_status.elapsed_time)
      report['metrics'] = metrics

      logs = []
      run_status.updated_resources.each do |resource|
        l = { 'log' => { 'sources' => {}, 'messages' => {}, 'level' => 'notice' } }

        case resource.resource_name.to_s
        when 'template', 'cookbook_file'
          message = resource.diff.gsub('\n', "\n")
        when 'package'
          message = "Installed #{resource.package_name} package in #{resource.version}"
        else
          message = resource.action.to_s
        end
        l['log']['messages']['message'] = message
        l['log']['sources']['source']   = [resource.resource_name.to_s, resource.name].join(' ')
        # Chef::Log.info("Diff is #{l['log']['messages']['message']}")
        logs << l
      end

      # I only set failed to 1 if chef run failed
      logs << if failed?
                {
                    'log' => {
                        'sources'  => { 'source' => 'Chef' },
                        'messages' => { 'message' => run_status.exception },
                        'level'    => 'err' },
                }
              else
                {
                    'log' => {
                        'sources'  => { 'source' => 'Chef' },
                        'messages' => { 'message' => 'run' },
                        'level'    => 'notice' },
                }
              end

      report['logs'] = logs
      full_report    = { 'report' => report }

      send_report(full_report)
    end

    private

    def send_report(report)
      if uploader
        uploader.foreman_request('api/reports', report, node.name)
      else
        Chef::Log.error 'No uploader registered for foreman reporting, skipping report upload'
      end
    end
  end
end
