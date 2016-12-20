module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
          module PackagerSh

            def self.find_cache_file(pkg, *paths)
              fname = nil
              my = paths.find do |path|
                fname = File.join(path, pkg['name'])
                ret = false
                if File.exist?(fname)
                  throw "unknown sum_type #{fname} #{pkg['sum_type']}" unless ['MD5Sum'].include?(pkg['sum_type'])
                  if Digest::MD5.file(fname).hexdigest.casecmp(pkg['sum'].downcase).zero?
                    pkg['fname'] = fname
                    # Construqt.logger.debug "Incache #{fname}"
                    ret = true
                  end
                end

                ret
              end

              my || Construqt.logger.debug("Misscache #{fname}")
              my
            end

            def self.fetch_action(queue, cache_path)
              Thread.new do
                while !queue.empty? && pkg = queue.pop
                  next if find_cache_file(pkg, '/var/cache/apt/archives', cache_path)
                  fname = File.join(cache_path, pkg['name'])
                  Construqt.logger.debug "Download from #{pkg['url']} => #{fname} #{pkg['sum']}"
                  uri = URI(pkg['url'])
                  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
                    res = http.request(Net::HTTP::Get.new(uri))
                    chk = Digest::MD5.hexdigest(res.body).downcase
                    if chk != pkg['sum'].downcase
                      throw "downloaded file #{pkg['url']} checksum missmatch #{pkg['sum']} != #{chk}"
                    end

                    FileUtils.mkdir_p(File.dirname(fname))
                    File.open(fname, 'w') { |file| file.write(res.body) }
                    pkg['fname'] = fname
                  end
                end
              end
            end

            def self.offline_package(host)
              if host.packager
                path = [ENV['HOME'] || './', '.construqt', 'package-cache']
                FileUtils.mkdir_p path
                cacheJd = ENV['JD'] || DateTime.now.jd
                package_params = {
                  'dist' => 'ubuntu',
                  'arch' => host.arch || 'amd64',
                  'version' => (host.lxc_deploy && host.lxc_deploy.get_release) || 'xenial',
                  'packages' => Lxc.package_list(host)
                }
                cacheSha1Packages = Digest::SHA1.hexdigest(package_params['packages'].join(':'))
                cacheFname = File.join(*path, "#{cacheJd}-#{package_params['dist']}-#{package_params['arch']}-#{package_params['version']}-#{cacheSha1Packages}.tag")
                packages = nil
                if File.exist?(cacheFname)
                  packages = JSON.parse(IO.read(cacheFname))
                  Construqt.logger.debug("Used cached Woko for: #{File.basename(cacheFname)}")
                else
                  Construqt.logger.debug "Load Woko for: #{File.basename(cacheFname)}"

                  uri = URI('https://woko.construqt.net/')
                  req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' => 'application/json' })
                  req.body = package_params.to_json
                  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
                    http.request(req)
                  end

                  packages = JSON.parse(res.body)
                  IO.write(cacheFname, res.body)
                  Dir.glob(File.join(File.dirname(cacheFname), '*.tag')).each do |fname|
                    jd, rest = File.basename(fname).split('-')
                    File.delete fname if jd.to_i <= cacheJd - 7
                  end
                end

                queue = Queue.new
                packages.each { |pkg| queue << pkg }
                cache_path = File.join(ENV['HOME'] || './', '.construqt', 'package-cache',
                                       "#{package_params['dist']}-#{package_params['version']}-#{package_params['arch']}")
                threads = Array.new([8, queue.size].min) do
                  fetch_action(queue, cache_path)
                end

                threads.each(&:join)

                var_cache_path = '/var/cache/apt/archives'

                chksum = Digest::SHA1.hexdigest(packages.map do |i|
                  "#{i['name']}:#{i['sum']}"
                end.sort.join("\n"))
                packager_fname = Util.get_filename(host.region, host.name, 'packager.sh')
                packager_checksum = File.exist?(packager_fname) && `sh #{packager_fname} version`.strip
                if chksum == packager_checksum
                  Construqt.logger.debug "Skip packager.sh generation #{packager_fname}"
                else
                  Construqt.logger.debug "Generate packager.sh #{packager_fname}"
                  Util.open_file(host.region, host.name, 'packager.sh') do |f|
                    # binding.pry
                    f.puts Construqt::Util.render(binding, 'packager.header.sh.erb')
                    packages.each do |pkg|
                      f.puts 'echo -n .'
                      f.puts "base64 -d <<BASE64 > #{File.join(var_cache_path, pkg['name'])}"
                      f.puts Base64.encode64(IO.read(pkg['fname']))
                      f.puts 'BASE64'
                    end

                    f.puts Construqt::Util.render(binding, 'packager.footer.sh.erb')
                  end
                end
              end

              [
                'if [ -f "$SCRIPTPATH/packager.sh" ]',
                'then',
                '  bash $SCRIPTPATH/packager.sh',
                'elif [ -f "packager.sh" ]',
                'then',
                '  bash packager.sh',
                'fi'
              ].join("\n")
            end
          end
          end
        end
      end
    end
  end
end
