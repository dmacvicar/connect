require 'tempfile'
require 'English'

def version_from_spec(spec_glob)
  version = `grep '^Version:' #{spec_glob}`
  version[/(\d\.\d\.\d)/, 0]
end

namespace :package do
  package_dir = 'package/'
  package_name = 'SUSEConnect'
  obs_project = 'systemsmanagement:SCC'
  local_spec_file = "#{package_name}.spec"
  root_path = File.join(File.dirname(__FILE__), '../..')

  desc 'Check local checkout for uncommitted changes'
  task :check_git do
    modified = `git ls-files -m --exclude-standard .`
    if modified.empty?
      puts 'No uncommitted changes detected.'
    else
      raise "Warning: uncommitted changes!\n\n#{modified}\n"
    end
  end

  desc 'Checkout from IBS'
  task :checkout do
    Dir.chdir "#{root_path}/#{package_dir}"
    unless Dir['.osc'].any?
      sh 'mkdir .tmp; mv * .tmp/'
      sh "osc co #{obs_project} #{package_name} -o ."
      sh 'mv .tmp/* .; rm -r .tmp/'
      puts 'Checkout successful.' if $CHILD_STATUS.exitstatus.zero?
    end
    `rm *suse-connect-*.gem` if Dir['*.gem'].any?
    Dir.chdir '..'
  end

  desc 'Build gem and copy to package'
  task :build_gem do
    Dir.chdir "#{root_path}"
    gemfilename = "suse-connect-#{SUSE::Connect::VERSION}.gem"

    `rm suse-connect-*.gem` if Dir['*.gem'].any?
    `gem build suse-connect.gemspec`

    raise 'Gem build failed.' unless $CHILD_STATUS.exitstatus.zero?

    sh "cp #{gemfilename} #{package_dir}"
    puts "Gem built and copied to #{package_dir}." if $CHILD_STATUS.exitstatus.zero?
  end

  desc 'Generate man pages'
  task :generate_manpages do
    Dir.chdir "#{root_path}"
    sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8'
    sh 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5'
  end

  desc 'Check for version bump in specfile'
  task :check_specfile_version do
    Dir.chdir "#{root_path}/#{package_dir}"
    file = Tempfile.new('connect-spec-rake')
    file.close
    `osc -A 'https://api.opensuse.org' cat '#{obs_project}' '#{package_name}' '#{package_name}.spec' > #{file.path}`
    original_version = version_from_spec(file.path)
    new_version      = version_from_spec(local_spec_file)

    if new_version == original_version
      raise "Version in #{package_name}.spec not changed. Please change to the latest version before committing.\n"
    else
      puts "Version change to #{new_version} in #{package_name}.spec detected."
    end
  end

  desc 'Prepare package for checking in to IBS'
  task :prepare do
    puts '== Step 1: check for uncommitted changes'
    # Rake::Task['package:check_git'].invoke
    ##
    puts '== Step 2: Checkout from IBS'
    Rake::Task['package:checkout'].invoke
    ##
    puts '== Step 3: Build gem and copy to package'
    Rake::Task['package:build_gem'].invoke
    ##
    puts '== Step 4: Generate man pages'
    Rake::Task['package:build_gem'].invoke
    ##
    puts "== Step 5: Log changes to #{package_name}.changes"
    Dir.chdir "#{root_path}/#{package_dir}"
    sh 'osc vc'
    Dir.chdir '..'
    ##
    puts '== Step 6: check for version bump in specfile'
    Rake::Task['package:check_specfile_version'].invoke
    ##
    puts 'Package preparation complete. Run `osc ar` to add changes and `osc ci` to check in package to OBS.'
    sh 'osc status'
  end
end
