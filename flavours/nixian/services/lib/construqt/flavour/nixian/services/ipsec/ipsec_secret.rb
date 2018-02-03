module Construqt
  module Flavour
    module Nixian
      module Services
          module Ipsec
            class IpsecSecret
              def initialize(result)
                @result = result
                @users = {}
                @lines = []
                @any_lines = []
                @psks = {}
              end

              def render_line(left, right, code, password)
                [left, right, ":", code, "\"#{Util.password(password)}\""].select{|l| !(l.nil? || l.empty?)}.join(" ")
              end

              def add_psk(key, password, comment = nil)
                sykey = "#{key}:PSK:#{password}"
                unless @psks.has_key?(sykey)
                  @psks[sykey] = true
                  @lines << "# #{comment}" if comment
                  @lines << render_line(key, nil, "PSK", password)
                end
              end

              def add_any_psk(key, password, comment = nil)
                @any_lines << "# #{comment}" if comment
                @any_lines << render_line(key, "%any", "PSK", password)
              end

              def add_cert(cert)
                @result.ipsec_cert_store.add(cert)
                @lines << render_line(nil, nil, "RSA", cert.key.name)
              end

              def add_users_psk(host)
                #binding.pry
                host.interfaces.values.each do |iface|
                  next unless iface.kind_of?(Construqt::Flavour::Delegate::IpsecVpnDelegate)
                  next unless iface.users
                  #binding.pry
                  iface.users.each do |user|
                    @users[user.name] = user.psk
                  end
                end
              end

              def render_users
                return "" if @users.empty?
                out = ['# ipsec users']
                @users.each do |name, psk|
                  out << render_line(name, nil, "EAP", psk)
                  out << render_line(name, nil, "XAUTH", psk)
                end
                out.join("\n")
              end

              def commit
                @result.add(self.class, @lines.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "ipsec.secrets")
                @result.add(self.class, @any_lines.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "ipsec.secrets")
                @result.add(self.class, render_users, Construqt::Resources::Rights.root_0644, "etc", "ipsec.secrets")
              end

            end
          end
        end
      end
    end
  end
