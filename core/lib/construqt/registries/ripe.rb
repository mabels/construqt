module Construqt
  module Registries
    class Ripe
      def initialize
        @registries = []
      end

      def txt_file(str)
        str.downcase.gsub(/[^a-z0-9]/, '_')+".txt"
      end

      def attach(registry)
        @registries << registry
      end

      def render_ripe(header, obj)
        unless obj.kind_of?(Array)
          obj = [obj]
        end
        obj.select{|i| !i.nil? }.map do |o|
          if o.respond_to?("nic_hdl")
            o = o.nic_hdl
          end
          if o.respond_to?("mntner")
            o = o.mntner
          end
          o.lines.map do |line|
            "#{"%-15s"%(header+":")} #{line.chomp}"
          end
        end.compact
      end

      def render_mntner(region, mntner)
        Util.write_str([
          render_ripe("mntner", mntner.mntner),
          render_ripe("descr", mntner.descr),
          render_ripe("admin-c", mntner.admin_c),
          render_ripe("admin-c", mntner.tech_c),
          render_ripe("auth", mntner.auth.map{|i| i.kind_of?(String) ? i : "PGPKEY-#{i.pgp_pub_key.id}"}),
          render_ripe("mnt-by", mntner.mnt_by),
          render_ripe("referral-by", mntner.referral_by),
        ].flatten.compact.join("\n")+"\n", "ripe", "mntner", txt_file(mntner.mntner))
      end

      def render_person(region, person)
        Util.write_str([
          render_ripe("person", person.person),
          render_ripe("address", person.address),
          render_ripe("phone", person.phone),
          render_ripe("e-mail", person.email),
          render_ripe("nic-hdl", person.nic_hdl),
          render_ripe("mnt-by", person.mnt_by),
        ].flatten.compact.join("\n")+"\n", "ripe", "persons", txt_file(person.person))
      end

      def render_key_cert(region, person)
        return unless person.user.pgp_pub_key
        Util.write_str([
          render_ripe("key-cert", "PGPKEY-#{person.user.pgp_pub_key.id}"),
          render_ripe("method", "PGP"),
          render_ripe("owner", "#{person.user.full_name} <#{person.email}>"),
          render_ripe("fingerpr", person.user.pgp_pub_key.fingerprint),
          render_ripe("certif", person.user.pgp_pub_key.key),
          render_ripe("mnt-by", person.mnt_by),
        ].flatten.compact.join("\n")+"\n", "ripe", "key_cert", txt_file("PGPKEY-#{person.user.pgp_pub_key.id}"))
      end

      def render_role(region, role)
        Util.write_str([
          render_ripe("role", role.role),
          render_ripe("address", role.address),
          render_ripe("phone", role.phone),
          render_ripe("e-mail", role.e_mail),
          render_ripe("admin-c", role.admin_c),
          render_ripe("tech-c", role.tech_c),
          render_ripe("nic-hdl", role.nic_hdl),
          render_ripe("mnt-by", role.mnt_by),
          render_ripe("abuse-mailbox", role.abuse_mailbox),
        ].flatten.compact.join("\n")+"\n", "ripe", "role", txt_file(role.role))
      end

      def render_addr_v4s(region, addr, ip)
        Util.write_str([
          render_ripe("inetnum", "#{ip.to_s} - #{ip.broadcast.to_s}"),
          render_ripe("netname", addr.netname),
          render_ripe("descr", addr.descr),
          render_ripe("country", addr.country),
          render_ripe("admin-c", addr.admin_c),
          render_ripe("tech-c", addr.tech_c),
          render_ripe("status", addr.status),
          render_ripe("mnt-by", addr.mnt_by),
        ].flatten.compact.join("\n")+"\n", "ripe", "inetnum", txt_file("#{ip.to_s}-#{addr.netname}"))
      end

      def render_addr_v6s(region, addr, ip)
        Util.write_str([
          render_ripe("inetnum6", ip.network.to_string),
          render_ripe("netname", addr.netname),
          render_ripe("descr", addr.descr),
          render_ripe("country", addr.country),
          render_ripe("admin-c", addr.admin_c),
          render_ripe("tech-c", addr.tech_c),
          render_ripe("status", addr.status),
          render_ripe("mnt-by", addr.mnt_by),
        ].flatten.compact.join("\n")+"\n", "ripe", "inetnum6", txt_file("#{ip.to_s}-#{addr.netname}"))
      end

      def render_addr(region, addr)
        addr.v4s.each { |v4| render_addr_v4s(region, addr, v4) }
        addr.v6s.each { |v6| render_addr_v6s(region, addr, v6) }
      end

      def produce
        @registries.sort.uniq.each do |registry|
          registry.mntners.each do |mntner|
            render_mntner(registry, mntner)
          end

          registry.persons.each do |person|
            render_person(registry, person)
            render_key_cert(registry, person)
          end

          registry.roles.each do |role|
            render_role(registry, role)
          end

          registry.addresses.each do |addrs|
            addrs.each do |addr|
              render_addr(registry, addr)
            end
          end

        end
      end
    end
  end
end
