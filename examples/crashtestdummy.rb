IPSEC_PASSWORD="weg"
IPSEC_LEFT_PSK="weg"

VALADON_PSK = "wlan for free"

def ipsec_users()
  [
    Construqt::Ipsecs::User.new("abels", "weg"),
    Construqt::Ipsecs::User.new("martina", "weg")
  ]
end

def ipsec_certificate(network)
  network.cert_store.add_cacert("COMODORSADomainValidationSecureServerCA.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT
  network.cert_store.add_cacert("AddTrustExternalCARoot.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT
  network.cert_store.add_cacert("COMODORSAAddTrustCA.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT

  network.cert_store.add_cert("fanout-de_adviser_com.crt", <<CERT)
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
CERT

  network.cert_store.add_private("fanout-de.adviser.com.key", <<KEY)
-----BEGIN PRIVATE KEY-----
-----END PRIVATE KEY-----
KEY

end
