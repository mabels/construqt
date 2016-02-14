IPSEC_PASSWORDS = lambda do |left, right|
  psk =  {
    "fanout-de" => {
      "fanout-us" => "weg",
      "service-de-hgw" => "weg",
      "scable-1" => "weg",
      "scable-2" => "weg"
    },
    "rt-ab-us" => {
      "fanout-us" => "weg"
    },
    "rt-mam-wl-us" => {
      "fanout-us" => "weg"
    },
    "rt-wl-mgt" => {
      "fanout-de" => "weg"
    },
    "rt-ab-de" => {
      "fanout-de" => "weg"
    }
  }
  tmp = psk[left]
  throw "IPSEC_PASSWORDS not found for left=#{left}(#{right})" unless tmp
  tmp = tmp[right]
  throw "IPSEC_PASSWORDS not found for right=#{right} found left=#{left}" unless tmp
  tmp
end
IPSEC_LEFT_PSK="weg"

MAM_PSK="wlan for free"

VALADON_PSK = "wlan for free"


WIFI_PSKS = {
      "rt-mam-wl-us"    => "wifi for free",
      "rt-mam-wl-de"    => "wifi for free",
      "rt-mam-wl-de-6"  => "wifi for free",
      "rt-ab-us"   => "wifi for free",
      "rt-ab-de"   => "wifi for free",
      "ao-ac-mam-otr" => "wifi for free",
      "ao-ac-mam-otr-de" => "wifi for free",
      "ao-ac-mam-otr-us" => "wifi for free"
}

AICCU_DE = {
  "username" => "murks",
  "password" => "passwort"
}

INTERNAL_PSK = "wifi for free"

def ipsec_users()
  [
    Construqt::Ipsecs::User.new("abels", "weg"),
    Construqt::Ipsecs::User.new("martina", "weg")
  ]
end

FANOUT_US_ADVISER_COM = "1.1.1.1"
FANOUT_DE_ADVISER_COM = "2.2.2.2"

def ipsec_certificate(network)
c1 = network.cert_store.add_cacert("COMODORSADomainValidationSecureServerCA.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT
c2 = network.cert_store.add_cacert("AddTrustExternalCARoot.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT
c3 = network.cert_store.add_cacert("COMODORSAAddTrustCA.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT
fanout_de_cert = network.cert_store.add_cert("fanout-de_adviser_com.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT

fanout_de_key = network.cert_store.add_private("fanout-de.adviser.com.key", <<KEY)
-----BEGIN PRIVATE KEY-----
-----END PRIVATE KEY-----
KEY

network.cert_store.create_package("fanout-de", fanout_de_key, fanout_de_cert, [c3,c2,c1])

fanout_us_cert = network.cert_store.add_cert("fanout-us_adviser_com.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT

fanout_us_key = network.cert_store.add_private("fanout-us.adviser.com.key", <<KEY)
-----BEGIN PRIVATE KEY-----
-----END PRIVATE KEY-----
KEY
network.cert_store.create_package("fanout-us", fanout_us_key, fanout_us_cert, [c3,c2,c1])

end
