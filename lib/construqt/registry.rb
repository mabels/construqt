module Construqt
    class Registry
      ADMINCS = :admin_cs
      TECHCS = :tech_cs
      ADMINCS_PUBKEYS = :admincs_pubkeys

      attr_reader :region
      def initialize(region, driver)
        @driver = driver
        driver && @driver.attach(self)
        @region = region
        @objs = {}
      end


      def produce
        region.network.addresses.all.select { |adr| adr.get_ripe }.each do |addr|
          adr = Address.new(region, addr)
          @objs['address'] ||= {}
          @objs['address'][adr.netname] ||= []
          @objs['address'][adr.netname] << adr
        end
        @driver && @driver.produce
      end

      module RipeBase
        def admin_c
          if ADMINCS == @values['admin-c']
            @region.users.find_admin_cs.map{|i| i.admin_c.nic_hdl}
          else
            if @values['admin-c'].respond_to?(:nic_hdl)
              @values['admin-c'].nic_hdl
            else
              @values['admin-c']
            end
          end
        end

        def tech_c
          if TECHCS == @values['tech-c']
            @region.users.find_tech_cs.map{|i| i.tech_c.nic_hdl}
          else
            if @values['tech-c'].respond_to?(:nic_hdl)
              @values['tech-c'].nic_hdl
            else
              @values['tech-c']
            end
          end
        end

        def nic_hdl
          @values["nic-hdl"]
        end
        def mnt_by
          @values["mnt-by"]
        end
      end

      class MntNer
        include RipeBase
        attr_reader :values
        def initialize(region, values)
          @region = region
          @values = values
        end
        def mntner
          @values['mntner']
        end
        def descr
          @values['descr']
        end
        def auth
          auth = @values['auth']
          unless auth.kind_of?(Array)
            auth = [auth]
          end
          auth.map do |a|
            if a == Construqt::Registry::ADMINCS_PUBKEYS
              @region.users.find_admin_cs.select {|i| i.pgp_pub_key  }
            else
              a
            end
          end.flatten.compact
        end
        def mnt_by
          @values['mnt-by']
        end
        def referral_by
          @values['referral-by']
        end
      end

      def mntner(name, values)
        @objs["mntner"] ||= {}
        @objs["mntner"][name] = MntNer.new(region, values.merge("mntner" => name))
        @objs["mntner"][name]
      end

      def mntners
        (@objs["mntner"] ||= {}).values
      end

      class Role
        include RipeBase
        attr_reader :values
        def initialize(region, values)
          @region = region
          @values = values
        end
        def role
          @values['role']
        end
        def address
          @values["address"]
        end
        def phone
          @values["phone"]
        end
        def abuse_mailbox
          @values["abuse-mailbox"]
        end
      end

      def role(name, values)
        @objs["role"] ||= {}
        @objs["role"][name] = Role.new(@region, values.merge("role" => name))
        @objs["role"][name]
      end

      def roles
        (@objs["role"] ||= {}).values
      end


      class Person
        include RipeBase
        attr_reader :values, :user
        def initialize(region, values)
          @values = values
          @region = region
        end
        def set_user(user)
          @user = user
        end
        def person
          @values["person"]
        end
        def address
          @values["address"]
        end
        def email
          @user.email
        end
        def phone
          @values["phone"]
        end
      end

      def person(name, values)
        @objs["person"] ||= {}
        @objs["person"][name] = Person.new(@region, values.merge("person" => name))
        @objs["person"][name]
      end

      class KeyCert
        include RipeBase
        attr_reader :values, :user
        def initialize(region, values)
          @values = values
          @region = region
        end
        def id
          @values['id']
        end
        def fingerprint
          @values['fingerprint']
        end
        def key
          @values['key']
        end
      end

      def key_cert(name, values)
        @objs["key_cert"] ||= {}
        @objs["key_cert"][name] = KeyCert.new(@region, values.merge("id" => name))
        @objs["key_cert"][name]
      end

      def persons
        (@objs["person"] ||= {}).values
      end

      class Address
        include RipeBase
        def initialize(region, addr)
          @region = region
          @addr = addr
          @values = addr.get_ripe
        end
        def v4s
          @addr.v4s
        end
        def v6s
          @addr.v6s
        end

        def netname
          @values['netname']
        end
        def descr
          @values['descr']
        end
        def country
          @values['country']
        end
        def status
          @values['status']
        end
        def mnt_by
          @values['mnt_by']
        end
      end

      def addresses
        (@objs["address"] ||= {}).values
      end


    end
end
